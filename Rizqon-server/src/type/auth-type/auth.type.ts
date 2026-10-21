export interface ICreateUserPayload {
  name: string;
  email: string;
  password: string;
  image?: string;
  phone?: string;
}

export interface IVerifyEmailPayload {
  email: string;
  otp: string;
}

export interface ISignInPayload {
  email: string;
  password: string;
  rememberMe?: boolean;
}
