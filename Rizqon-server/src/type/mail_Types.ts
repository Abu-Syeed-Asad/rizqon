export interface PlainMail {
  to: string;
  subject: string;
  text: string;
}

export type OtpType = | "email-verification" | "forget-password" | "sign-in" | "change-email";

export interface SendOtpMailOptions {
  to: string;
  otp: string;
  type: OtpType;
  userName?: string;
}
