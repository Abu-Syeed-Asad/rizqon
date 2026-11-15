import type { Request, Response } from "express";
import { StatusCodes } from "http-status-codes";
import { catchAsync, send_Response } from "../../utils/asyncHandlerOrsendResponse.js";
import { partnerService } from "./partner.service.js";
import type { PartnerParams, CreatePartnerInput, UpdatePartnerInput } from "./partner.validation.js";

const createPartner = catchAsync(async (req: Request<Record<string, string>, unknown, CreatePartnerInput>, res: Response) => {
  const result = await partnerService.createPartner(req.body);
  send_Response(res, {
    statusCode: StatusCodes.CREATED,
    message: "Partner created successfully",
    data: result,
  });
});

const updatePartner = catchAsync(async (req: Request<PartnerParams, unknown, UpdatePartnerInput>, res: Response) => {
  const result = await partnerService.updatePartner(req.params, req.body);
  send_Response(res, {
    statusCode: StatusCodes.OK,
    message: "Partner updated successfully",
    data: result,
  });
});

const deletePartner = catchAsync(async (req: Request<PartnerParams>, res: Response) => {
  const result = await partnerService.deletePartner(req.params);
  send_Response(res, {
    statusCode: StatusCodes.OK,
    message: "Partner deleted successfully",
    data: result,
  });
});

const getPartner = catchAsync(async (req: Request<PartnerParams>, res: Response) => {
  const result = await partnerService.getPartner(req.params);
  send_Response(res, {
    statusCode: StatusCodes.OK,
    message: "Partner retrieved successfully",
    data: result,
  });
});

const getAllPartners = catchAsync(async (_req: Request, res: Response) => {
  const result = await partnerService.getAllPartners();
  send_Response(res, {
    statusCode: StatusCodes.OK,
    message: "Partners retrieved successfully",
    data: result,
  });
});

export const partnerController = { createPartner, updatePartner, deletePartner, getPartner, getAllPartners };
