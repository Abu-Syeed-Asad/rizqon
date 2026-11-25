import { randomBytes } from "node:crypto";
import type Stripe from "stripe";
import { Prisma, type Payment } from "../../../prisma/generated/prisma/client.js";
import { prisma } from "../../lib/prisma.js";
import { env } from "../../config/env.js";
import { audit, authorize, hash, json, requireBranch, tenantKey, transaction, type Actor } from "../Commission/commission.common.js";
import { decimal, sum } from "../Commission/commission.math.js";
import { idSchema } from "../Commission/commission.validation.js";
import { checkoutSchema, providerSchema, sslNotificationSchema } from "./payment.validation.js";
import { minorUnits, paymentConfig, paymentError, querySsl, startCheckout, stripeClient, stripePayment, validateSsl,
  type GatewayRequest, type VerifiedPayment } from "./payment.gateway.js";

const reservedStatuses = ["PENDING", "PROCESSING", "AUTHORIZED", "SUCCEEDED"] as const;
const terminal = (payment: Payment) => ["SUCCEEDED", "FAILED", "CANCELLED"].includes(payment.status);
export function publicPayment(payment: Payment) {
  return { id: payment.id, businessId: payment.businessId, saleId: payment.saleId, provider: payment.provider,
    status: payment.status, amount: payment.amount, currency: payment.currency, paidAt: payment.paidAt,
    checkoutUrl: terminal(payment) || payment.status === "AUTHORIZED" ||
      (payment.checkoutExpiresAt && payment.checkoutExpiresAt <= new Date()) ? null : payment.checkoutUrl,
    checkoutExpiresAt: payment.checkoutExpiresAt, createdAt: payment.createdAt };
}

async function checkout(actor: Actor, tenant: string, saleId: string, payload: unknown) {
  const input = checkoutSchema.parse(payload);
  const businessId = idSchema.parse(tenant);
  idSchema.parse(saleId);
  const requestHash = hash({ saleId, ...input });
  const payment = await transaction(async tx => {
    const scope = await authorize(tx, actor, businessId, "sale");
    await tx.$queryRaw`SELECT id FROM commerce."Sale" WHERE "businessId" = ${businessId} AND id = ${saleId} FOR UPDATE`;
    const sale = await tx.sale.findUnique({ where: tenantKey(businessId, saleId) });
    if (!sale) return paymentError("Sale not found", 404);
    await requireBranch(tx, scope, sale.branchId);
    const existing = await tx.payment.findUnique({ where: { businessId_idempotencyKey: { businessId, idempotencyKey: input.idempotencyKey } } });
    if (existing) {
      if (existing.requestHash !== requestHash || existing.saleId !== saleId || existing.direction !== "IN") {
        return paymentError("Idempotency key was used with another request");
      }
      return existing;
    }
    const config = paymentConfig(input.provider, businessId);
    if (sale.status !== "COMPLETED" || sale.currency !== scope.currency) {
      return paymentError("Payment collection requires a completed sale in the business currency");
    }
    // Returns have a separate refund workflow. Do not collect the original total after a return.
    if (await tx.saleReturn.count({ where: { businessId, saleId, status: { notIn: ["REJECTED"] } } })) {
      return paymentError("Resolve sale returns before collecting an online payment");
    }
    const payments = await tx.payment.findMany({ where: { businessId, saleId, direction: "IN", status: { in: [...reservedStatuses] } },
      select: { amount: true, currency: true, status: true } });
    if (payments.some(p => p.currency !== sale.currency)) return paymentError("Existing payment currency does not match the sale");
    if (payments.some(p => p.status !== "SUCCEEDED")) return paymentError("A checkout is already pending; refresh or reuse that payment", 409, "PAYMENT_PENDING");
    const amount = sale.grandTotal.minus(sum(payments.map(p => p.amount)));
    minorUnits(amount.toFixed(2), sale.currency);
    if (input.provider === "SSLCOMMERZ" && (sale.currency !== "BDT" || amount.lt(10) || amount.gt(500000))) {
      return paymentError("SSLCommerz checkout requires BDT 10.00–500000.00", 400);
    }
    const id = randomBytes(12).toString("hex");
    const gatewayRequest: GatewayRequest = { paymentId: id, businessId, saleId, amount: amount.toFixed(2),
      currency: sale.currency, invoice: sale.invoiceNumber, customer: input.customer, ...config };
    const created = await tx.payment.create({ data: { id, businessId, saleId, direction: "IN", method: "ONLINE_GATEWAY",
      status: "PENDING", amount, currency: sale.currency, provider: input.provider,
      providerReference: input.provider === "SSLCOMMERZ" ? id : null,
      idempotencyKey: input.idempotencyKey, requestHash, recorderId: scope.employeeId, gatewayRequest: json(gatewayRequest) } });
    await audit(tx, scope, "PAYMENT_INITIATED", "PAYMENT", id, undefined, publicPayment(created));
    return created;
  });
  return publicPayment(await initialize(payment));
}

async function initialize(payment: Payment): Promise<Payment> {
  if (payment.checkoutUrl || terminal(payment) || payment.status === "AUTHORIZED") return payment;
  const provider = providerSchema.parse(payment.provider);
  paymentConfig(provider, payment.businessId);
  // Stripe keeps idempotency keys for at least 24h. Never recreate an unknown
  // checkout outside that window. SSLCommerz has no equivalent safe retry API.
  const canRetry = provider === "STRIPE" && payment.createdAt.getTime() > Date.now() - 23 * 3600000;
  const claimed = await prisma.payment.updateMany({ where: { id: payment.id, checkoutUrl: null,
    status: { in: ["PENDING", "PROCESSING"] }, OR: [{ initializationStartedAt: null },
      ...(canRetry ? [{ initializationStartedAt: { lt: new Date(Date.now() - 60000) } }] : [])] },
  data: { initializationStartedAt: new Date(), status: "PROCESSING" } });
  if (!claimed.count) return payment;
  const request = payment.gatewayRequest as unknown as GatewayRequest;
  // Network calls must never run inside the retryable database transaction.
  const result = await startCheckout(provider, request);
  return transaction(async tx => {
    await tx.$queryRaw`SELECT id FROM commerce."Sale" WHERE "businessId" = ${payment.businessId} AND id = ${payment.saleId} FOR UPDATE`;
    const current = await tx.payment.findUniqueOrThrow({ where: { id: payment.id } });
    if (current.providerReference && current.providerReference !== result.reference) return paymentError("Provider reference mismatch");
    return tx.payment.update({ where: { id: payment.id }, data: { providerReference: result.reference,
      gatewaySessionId: result.sessionId, checkoutUrl: result.url, checkoutExpiresAt: result.expiresAt } });
  });
}

async function getAuthorized(actor: Actor, tenant: string, id: string) {
  return transaction(async tx => {
    const scope = await authorize(tx, actor, idSchema.parse(tenant), "sale");
    const payment = await tx.payment.findUnique({ where: tenantKey(scope.businessId, idSchema.parse(id)), include: { sale: true } });
    if (!payment?.sale || payment.direction !== "IN" || !providerSchema.safeParse(payment.provider).success) return paymentError("Payment not found", 404);
    await requireBranch(tx, scope, payment.sale.branchId);
    return payment;
  });
}
async function get(actor: Actor, tenant: string, id: string) { return publicPayment(await getAuthorized(actor, tenant, id)); }

async function list(actor: Actor, tenant: string, saleId: string) {
  return transaction(async tx => {
    const scope = await authorize(tx, actor, idSchema.parse(tenant), "sale");
    const sale = await tx.sale.findUnique({ where: tenantKey(scope.businessId, idSchema.parse(saleId)) });
    if (!sale) return paymentError("Sale not found", 404);
    await requireBranch(tx, scope, sale.branchId);
    const payments = await tx.payment.findMany({ where: { businessId: scope.businessId, saleId, direction: "IN" }, orderBy: { createdAt: "desc" } });
    const paid = sum(payments.filter(p => p.status === "SUCCEEDED").map(p => p.amount));
    return { payments: payments.map(publicPayment), paid, remaining: sale.grandTotal.minus(paid), currency: sale.currency };
  });
}

// Shared by signed webhooks and authenticated server-to-server reconciliation.
export async function applyVerifiedPayment(verified: VerifiedPayment) {
  return transaction(async tx => {
    const beforeLock = await tx.payment.findUnique({ where: { id: verified.paymentId } });
    if (!beforeLock?.saleId || beforeLock.direction !== "IN" || beforeLock.provider !== verified.provider) return paymentError("Payment not found", 404);
    await tx.$queryRaw`SELECT id FROM commerce."Sale" WHERE "businessId" = ${beforeLock.businessId} AND id = ${beforeLock.saleId} FOR UPDATE`;
    const payment = await tx.payment.findUniqueOrThrow({ where: { id: beforeLock.id } });
    if ((payment.providerReference && payment.providerReference !== verified.reference) ||
      payment.currency !== verified.currency || !decimal(verified.amount).isFinite() || !payment.amount.eq(decimal(verified.amount))) {
      return paymentError("Provider payment amount, currency or reference does not match", 400, "PAYMENT_VERIFICATION_FAILED");
    }
    const existing = await tx.paymentEvent.findUnique({ where: { provider_providerEventId: { provider: verified.provider, providerEventId: verified.eventId } } });
    const payloadHash = hash(verified);
    if (existing) {
      if (existing.paymentId !== payment.id || existing.payloadHash !== payloadHash) return paymentError("Payment event mismatch", 400);
      return payment;
    }
    // Success is authoritative even if an earlier failure arrived out of order.
    // Never downgrade success or a payment held for risk review on a stale event.
    const change = payment.status !== "SUCCEEDED" && (verified.status === "SUCCEEDED" ||
      (!terminal(payment) && (payment.status !== "AUTHORIZED" || verified.status === "AUTHORIZED")));
    const after = change ? await tx.payment.update({ where: { id: payment.id }, data: {
      status: verified.status, providerReference: verified.reference,
      paidAt: verified.status === "SUCCEEDED" ? new Date() : null,
    } }) : payment;
    await tx.paymentEvent.create({ data: { businessId: payment.businessId, paymentId: payment.id, provider: verified.provider,
      providerEventId: verified.eventId, payloadHash, processedAt: new Date() } });
    if (change && ["SUCCEEDED", "FAILED", "CANCELLED"].includes(verified.status)) {
      await tx.auditLog.create({ data: { businessId: payment.businessId, entityType: "PAYMENT", entityId: payment.id,
        action: verified.status === "SUCCEEDED" ? "PAYMENT_SUCCEEDED" : verified.status === "FAILED" ? "PAYMENT_FAILED" : "PAYMENT_CANCELLED",
        before: json(publicPayment(payment)), after: json(publicPayment(after)) } });
    }
    return after;
  });
}

async function refresh(actor: Actor, tenant: string, id: string) {
  let payment: Payment = await getAuthorized(actor, tenant, id);
  if (terminal(payment)) return publicPayment(payment);
  if (payment.provider === "STRIPE") {
    if (!payment.providerReference) payment = await initialize(payment);
    if (payment.providerReference) {
      const session = await stripeClient().checkout.sessions.retrieve(payment.providerReference);
      const verified = stripePayment(session, `refresh:${session.id}:${session.status}:${session.payment_status}`);
      payment = await applyVerifiedPayment(verified);
    }
  } else {
    const verified = await querySsl(payment.id, payment.gatewaySessionId);
    if (verified) payment = await applyVerifiedPayment(verified);
  }
  return publicPayment(payment);
}

async function stripeWebhook(body: Buffer, signature: string | undefined) {
  if (!env.STRIPE_WEBHOOK_SECRET) return paymentError("Stripe webhook is not configured", 503);
  if (!signature || !Buffer.isBuffer(body)) return paymentError("Missing Stripe signature or raw body", 400);
  let event: Stripe.Event;
  try { event = stripeClient().webhooks.constructEvent(body, signature, env.STRIPE_WEBHOOK_SECRET); }
  catch { return paymentError("Invalid Stripe signature", 400, "INVALID_PAYMENT_SIGNATURE"); }
  if (!["checkout.session.completed", "checkout.session.async_payment_succeeded", "checkout.session.async_payment_failed", "checkout.session.expired"].includes(event.type)) return;
  const session = event.data.object as Stripe.Checkout.Session;
  // Other integrations may share the Stripe account.
  if (!session.metadata?.paymentId) return;
  await applyVerifiedPayment(stripePayment(session, event.id, event.type === "checkout.session.async_payment_failed"));
}

async function sslNotification(payload: unknown) {
  const input = sslNotificationSchema.parse(payload);
  const payment = await prisma.payment.findUnique({ where: { id: input.tran_id } });
  if (!payment || payment.provider !== "SSLCOMMERZ" || payment.direction !== "IN" || !payment.saleId) return paymentError("Payment not found", 404);
  const verified = input.val_id ? await validateSsl(payment.id, input.val_id) : await querySsl(payment.id, payment.gatewaySessionId);
  if (verified) await applyVerifiedPayment(verified);
  // Never expose a payment record on public callback endpoints.
  const request = payment.gatewayRequest as Prisma.JsonObject;
  const url = new URL(String(request.returnUrl));
  url.searchParams.set("paymentId", payment.id);
  url.searchParams.set("outcome", "returned");
  return url.toString();
}

export const paymentService = { checkout, get, list, refresh, stripeWebhook, sslNotification };
