import { Router, raw } from "express";
import type { Request, Response } from "express";
import auth_Checker from "../../middleware/auth_Check.js";
import { catchAsync, send_Response } from "../../utils/asyncHandlerOrsendResponse.js";
import { validateBody } from "../../middleware/validateBody.js";
import { emptySchema } from "../Commission/commission.validation.js";
import { paymentService } from "./payment.service.js";

// Mount before express.json(): Stripe verifies the exact bytes sent by Stripe.
export const stripeWebhookRoute = Router();
stripeWebhookRoute.post("/stripe/webhook", raw({ type: "application/json", limit: "1mb" }), catchAsync(async (req: Request, res: Response) => {
  await paymentService.stripeWebhook(req.body, req.get("stripe-signature"));
  res.status(200).json({ received: true });
}));

export const paymentCallbackRoutes = Router();
for (const action of ["ipn", "success", "fail", "cancel"]) {
  paymentCallbackRoutes.post(`/sslcommerz/${action}`, catchAsync(async (req: Request, res: Response) => {
    const url = await paymentService.sslNotification(req.body);
    if (action === "ipn") res.status(200).json({ received: true });
    else res.redirect(303, url);
  }));
}

type Params = { businessId: string; saleId: string; paymentId: string };
export const paymentRoutes = Router({ mergeParams: true });
// Route-level authentication avoids intercepting unrelated business routes.
paymentRoutes.post("/sales/:saleId/payments/checkout", auth_Checker(), catchAsync(async (req: Request<Params>, res: Response) => {
  const data = await paymentService.checkout(res.locals.user, req.params.businessId, req.params.saleId, req.body);
  send_Response(res, { statusCode: 200, message: "Payment checkout retrieved", data });
}));
paymentRoutes.get("/sales/:saleId/payments", auth_Checker(), catchAsync(async (req: Request<Params>, res: Response) => {
  const data = await paymentService.list(res.locals.user, req.params.businessId, req.params.saleId);
  send_Response(res, { statusCode: 200, message: "Sale payments retrieved", data });
}));
paymentRoutes.get("/payments/:paymentId", auth_Checker(), catchAsync(async (req: Request<Params>, res: Response) => {
  const data = await paymentService.get(res.locals.user, req.params.businessId, req.params.paymentId);
  send_Response(res, { statusCode: 200, message: "Payment retrieved", data });
}));
paymentRoutes.post("/payments/:paymentId/refresh", auth_Checker(), validateBody(emptySchema), catchAsync(async (req: Request<Params>, res: Response) => {
  const data = await paymentService.refresh(res.locals.user, req.params.businessId, req.params.paymentId);
  send_Response(res, { statusCode: 200, message: "Payment status refreshed", data });
}));
