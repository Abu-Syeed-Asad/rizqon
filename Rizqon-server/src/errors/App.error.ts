import { StatusCodes } from "http-status-codes";

export class AppError extends Error {
  constructor(
    public readonly statusCode: number,
    public readonly message: string,
    public readonly isOperational: boolean = true,
    public readonly code: string = "App_Error"
  ) {
    super(message);
    this.name = this.constructor.name;
    if(!Number.isInteger(statusCode) || statusCode<StatusCodes.BAD_REQUEST ||  statusCode>599){
      throw new Error(`AppError requires an HTTP error status: ${statusCode}`);
    } 
    this.statusCode = statusCode;
    this.code = code;

  }
}