import Stripe from "stripe";
import { z } from "zod";
import { env } from "../../config/env.js";
import { AppError } from "../../errors/App.error.js";
import { decimal } from "../Commission/commission.math.js";
import type { CheckoutInput, Provider } from "./payment.validation.js";

export const paymentError = (message: string, status = 409, code = "PAYMENT_CONFLICT"): never => {
  throw new AppError(status, message, true, code);
};
export type GatewayRequest = {
  paymentId: string; businessId: string; saleId: string; amount: string; currency: string;
  invoice: string; customer: CheckoutInput["customer"]; returnUrl: string; callbackBase: string;
};
export type GatewayResult = { reference: string; sessionId: string; url: string; expiresAt: Date | null };
export type VerifiedPayment = {
  paymentId: string; provider: Provider; reference: string; eventId: string;
  amount: string; currency: string; status: "SUCCEEDED" | "PROCESSING" | "AUTHORIZED" | "FAILED" | "CANCELLED";
};

function safeUrl(value: string | undefined) {
  if (!value) return paymentError("Configure payment public and return URLs", 503, "PAYMENT_NOT_CONFIGURED");
  const url = new URL(value);
  if (url.username || url.password || url.hash || !["http:", "https:"].includes(url.protocol) ||
    (env.NODE_ENV === "production" && url.protocol !== "https:")) {
    paymentError("Invalid payment URL configuration", 503, "PAYMENT_NOT_CONFIGURED");
  }
  return url;
}

export function paymentConfig(provider: Provider, businessId: string) {
  const businesses = env.PAYMENT_BUSINESS_IDS?.split(",").map(value => value.trim()) ?? [];
  if (!businesses.includes(businessId)) paymentError("This business is not configured for the merchant account", 503, "PAYMENT_NOT_CONFIGURED");
  if (provider === "STRIPE") {
    stripeClient();
    if (!env.STRIPE_WEBHOOK_SECRET) paymentError("Configure the Stripe webhook secret", 503, "PAYMENT_NOT_CONFIGURED");
  } else sslCredentials();
  return {
    returnUrl: safeUrl(env.PAYMENT_RETURN_URL).toString(),
    callbackBase: safeUrl(env.PAYMENT_PUBLIC_BASE_URL).origin + "/api/v1/payments",
  };
}

// Deliberately support only these two-decimal currencies; never round an unsupported currency.
export function minorUnits(amount: string, currency: string) {
  if (!["BDT", "USD", "EUR", "GBP", "CAD", "AUD", "SGD", "INR", "MYR"].includes(currency)) {
    paymentError("Unsupported checkout currency", 400, "UNSUPPORTED_CURRENCY");
  }
  const units = decimal(amount).mul(100);
  if (!units.isInteger() || units.lte(0) || units.gt(99999999)) paymentError("Invalid checkout amount", 400, "INVALID_PAYMENT_AMOUNT");
  return units.toNumber();
}

export function stripeClient() {
  if (!env.STRIPE_SECRET_KEY) return paymentError("Stripe is not configured", 503, "PAYMENT_NOT_CONFIGURED");
  return new Stripe(env.STRIPE_SECRET_KEY, { timeout: 15000, maxNetworkRetries: 1, httpClient: Stripe.createFetchHttpClient() });
}

function returnUrl(request: GatewayRequest, outcome: string) {
  const url = new URL(request.returnUrl);
  url.searchParams.set("paymentId", request.paymentId);
  url.searchParams.set("outcome", outcome);
  return url.toString();
}

function sslCredentials() {
  if (!env.SSLCOMMERZ_STORE_ID || !env.SSLCOMMERZ_STORE_PASSWORD) {
    return paymentError("SSLCommerz is not configured", 503, "PAYMENT_NOT_CONFIGURED");
  }
  return { store_id: env.SSLCOMMERZ_STORE_ID, store_passwd: env.SSLCOMMERZ_STORE_PASSWORD };
}
const sslBase = () => env.SSLCOMMERZ_SANDBOX ? "https://sandbox.sslcommerz.com" : "https://securepay.sslcommerz.com";
async function sslApi(path: string, params: Record<string, string>, post = false): Promise<unknown> {
  const body = new URLSearchParams({ ...sslCredentials(), ...params, format: "json" });
  const url = new URL(path, sslBase());
  if (!post) url.search = body.toString();
  try {
    const response = await fetch(url, { method: post ? "POST" : "GET", redirect: "error",
      signal: AbortSignal.timeout(15000), ...(post ? { body } : {}) });
    if (!response.ok) throw new Error("Gateway HTTP error");
    return await response.json();
  } catch {
    // Never surface request URLs: SSLCommerz credentials are query parameters.
    return paymentError("SSLCommerz is unavailable; refresh this payment before retrying", 502, "PAYMENT_GATEWAY_UNAVAILABLE");
  }
}

export async function startCheckout(provider: Provider, request: GatewayRequest): Promise<GatewayResult> {
  if (provider === "STRIPE") {
    try {
      const session = await stripeClient().checkout.sessions.create({
        mode: "payment", client_reference_id: request.paymentId,
        metadata: { paymentId: request.paymentId, businessId: request.businessId, saleId: request.saleId },
        customer_email: request.customer.email,
        line_items: [{ quantity: 1, price_data: { currency: request.currency.toLowerCase(),
          unit_amount: minorUnits(request.amount, request.currency), product_data: { name: `Invoice ${request.invoice}` } } }],
        success_url: returnUrl(request, "returned"), cancel_url: returnUrl(request, "cancelled"),
      }, { idempotencyKey: `rizqon-payment-${request.paymentId}` });
      if (!session.url) throw new Error("No checkout URL");
      return { reference: session.id, sessionId: session.id, url: session.url, expiresAt: new Date(session.expires_at * 1000) };
    } catch {
      return paymentError("Stripe checkout could not be confirmed; retry with the same idempotency key", 502, "PAYMENT_GATEWAY_UNAVAILABLE");
    }
  }
  const customer = request.customer;
  const result = z.object({ status: z.string(), sessionkey: z.string().optional(), GatewayPageURL: z.url().optional() })
    .parse(await sslApi("/gwprocess/v4/api.php", {
      total_amount: request.amount, currency: request.currency, tran_id: request.paymentId,
      success_url: `${request.callbackBase}/sslcommerz/success`, fail_url: `${request.callbackBase}/sslcommerz/fail`,
      cancel_url: `${request.callbackBase}/sslcommerz/cancel`, ipn_url: `${request.callbackBase}/sslcommerz/ipn`,
      cus_name: customer.name, cus_email: customer.email, cus_phone: customer.phone, cus_add1: customer.address,
      cus_city: customer.city, cus_postcode: customer.postcode, cus_country: customer.country,
      shipping_method: "NO", num_of_item: "1", product_name: `Invoice ${request.invoice}`.slice(0, 255),
      product_category: "Retail", product_profile: "general", emi_option: "0",
    }, true));
  if (result.status !== "SUCCESS" || !result.sessionkey || !result.GatewayPageURL) {
    return paymentError("SSLCommerz did not confirm checkout; refresh this payment before retrying", 502, "PAYMENT_GATEWAY_UNAVAILABLE");
  }
  const url = new URL(result.GatewayPageURL);
  if (url.protocol !== "https:" || !(url.hostname === "sslcommerz.com" || url.hostname.endsWith(".sslcommerz.com"))) {
    return paymentError("SSLCommerz returned an invalid checkout URL", 502);
  }
  return { reference: request.paymentId, sessionId: result.sessionkey, url: result.GatewayPageURL, expiresAt: null };
}

export function stripePayment(session: Stripe.Checkout.Session, eventId: string, failed = false): VerifiedPayment {
  const paymentId = session.metadata?.paymentId;
  if (!paymentId || session.client_reference_id !== paymentId || session.mode !== "payment" ||
    !Number.isSafeInteger(session.amount_total) || !session.currency) paymentError("Invalid Stripe payment details", 400);
  return { paymentId: paymentId!, provider: "STRIPE", reference: session.id, eventId,
    amount: decimal(session.amount_total!).div(100).toFixed(2), currency: session.currency!.toUpperCase(),
    status: session.payment_status === "paid" ? "SUCCEEDED" : session.status === "expired" ? "CANCELLED" : failed ? "FAILED" : "PROCESSING" };
}

const sslRecord = z.object({
  status: z.string(), tran_id: z.string(), val_id: z.string().optional(),
  amount: z.union([z.string(), z.number()]).transform(String), currency: z.string(),
  risk_level: z.union([z.string(), z.number()]).transform(String).optional(),
});
export async function validateSsl(paymentId: string, validationId: string): Promise<VerifiedPayment> {
  const record = sslRecord.parse(await sslApi("/validator/api/validationserverAPI.php", { val_id: validationId }));
  if (!["VALID", "VALIDATED"].includes(record.status) || record.tran_id !== paymentId || record.val_id !== validationId) {
    return paymentError("SSLCommerz validation failed", 400, "INVALID_PAYMENT_NOTIFICATION");
  }
  return { paymentId, provider: "SSLCOMMERZ", reference: paymentId,
    eventId: `${validationId}:${record.risk_level === "0" ? "safe" : "review"}`,
    amount: record.amount, currency: record.currency,
    status: record.risk_level === "0" ? "SUCCEEDED" : "AUTHORIZED" };
}

export async function querySsl(paymentId: string, sessionId: string | null): Promise<VerifiedPayment | null> {
  const result = z.object({ APIConnect: z.string(), element: z.array(z.unknown()).optional() }).passthrough()
    .parse(await sslApi("/validator/api/merchantTransIDvalidationAPI.php", sessionId ? { sessionkey: sessionId } : { tran_id: paymentId }));
  if (result.APIConnect !== "DONE") return paymentError("SSLCommerz query failed", 502);
  const records = sessionId ? [result] : result.element ?? [];
  for (const raw of records) {
    const record = sslRecord.safeParse(raw);
    if (record.success && record.data.tran_id === paymentId && ["VALID", "VALIDATED"].includes(record.data.status) && record.data.val_id) {
      return validateSsl(paymentId, record.data.val_id);
    }
  }
  // Individual failed attempts do not prove a hosted session is closed. Only a
  // session-level query may release its reservation; an empty query never does.
  if (sessionId && result.tran_id === paymentId && result.sessionkey === sessionId && ["FAILED", "CANCELLED"].includes(String(result.status))) {
    const record = sslRecord.parse(result);
    return { paymentId, provider: "SSLCOMMERZ", reference: paymentId, eventId: `${sessionId}:${record.status}`,
      amount: record.amount, currency: record.currency, status: record.status === "FAILED" ? "FAILED" : "CANCELLED" };
  }
  return null;
}
