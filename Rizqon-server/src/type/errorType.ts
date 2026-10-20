export type ErrorDetail = {
  field: string;
  message: string;
};

export type NormalizedError = {
  statusCode: number;
  code: string;
  message: string;
  details?: ErrorDetail[];
};
