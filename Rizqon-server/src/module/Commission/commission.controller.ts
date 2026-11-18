import type { Request, Response } from "express";
import { catchAsync, send_Response } from "../../utils/asyncHandlerOrsendResponse.js";
import { agreementService } from "./agreement.service.js";
import { entryService } from "./entry.service.js";
import { settlementService } from "./settlement.service.js";
import { partnerPaymentService } from "./payment.service.js";
import { saleService } from "../Sale/sale.service.js";
import { returnService } from "../SaleReturn/return.service.js";
import type { Actor } from "./commission.common.js";

type Params = { businessId: string; id: string; paymentId: string };
type Context = { actor: Actor; params: Params; body: unknown; query: unknown };
const handle = (operation: (context: Context) => Promise<unknown>, message: string, statusCode = 200) =>
  catchAsync(async (req: Request<Params>, res: Response) => {
    const data = await operation({ actor: res.locals.user, params: req.params, body: req.body, query: req.query });
    send_Response(res, { statusCode, message, data });
  });

export const commissionController = {
  createAgreement: handle(c => agreementService.create(c.actor, c.params.businessId, c.body), "Agreement draft created", 201),
  listAgreements: handle(c => agreementService.list(c.actor, c.params.businessId, c.query), "Agreements retrieved"),
  getAgreement: handle(c => agreementService.get(c.actor, c.params.businessId, c.params.id), "Agreement retrieved"),
  history: handle(c => agreementService.get(c.actor, c.params.businessId, c.params.id, true), "Agreement history retrieved"),
  updateAgreement: handle(c => agreementService.update(c.actor, c.params.businessId, c.params.id, c.body), "Agreement draft updated"),
  agreementAction: (action: "activate" | "deactivate" | "expire") => handle(c => agreementService.transition(c.actor, c.params.businessId, c.params.id, action), "Agreement updated"),
  listEntries: handle(c => entryService.list(c.actor, c.params.businessId, c.query), "Commission entries retrieved"),
  getEntry: handle(c => entryService.get(c.actor, c.params.businessId, c.params.id), "Commission entry retrieved"),
  createSettlement: handle(c => settlementService.create(c.actor, c.params.businessId, c.body), "Settlement draft created", 201),
  listSettlements: handle(c => settlementService.list(c.actor, c.params.businessId, c.query), "Settlements retrieved"),
  getSettlement: handle(c => settlementService.get(c.actor, c.params.businessId, c.params.id), "Settlement retrieved"),
  updateSettlement: handle(c => settlementService.update(c.actor, c.params.businessId, c.params.id, c.body), "Settlement draft updated"),
  settlementAction: (action: "finalize" | "cancel") => handle(c => settlementService.transition(c.actor, c.params.businessId, c.params.id, action), "Settlement updated"),
  createPayment: handle(c => partnerPaymentService.create(c.actor, c.params.businessId, c.params.id, c.body), "Pending partner payment recorded", 201),
  listPayments: handle(c => partnerPaymentService.list(c.actor, c.params.businessId, c.params.id), "Partner payments retrieved"),
  reconcilePayment: handle(c => partnerPaymentService.reconcile(c.actor, c.params.businessId, c.params.id, c.params.paymentId, c.body), "Payment reconciliation recorded"),
  completeSale: handle(c => saleService.complete(c.actor, c.params.businessId, c.params.id), "Sale completed"),
  createReturn: handle(c => returnService.create(c.actor, c.params.businessId, c.body), "Return requested", 201),
  returnAction: (action: "approve" | "reject" | "complete") => handle(c => returnService.transition(c.actor, c.params.businessId, c.params.id, action), "Return updated"),
};
