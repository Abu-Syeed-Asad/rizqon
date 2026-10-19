import nodemailer from "nodemailer";
import ejs from "ejs";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { env } from "../config/env.js";
import { mailerConfig } from "../config/mailer.js";
import type { OtpType, PlainMail, SendOtpMailOptions } from "../type/mail_Types.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const TEMPLATES_DIR = path.join(__dirname, "../templates");

let _transporter: nodemailer.Transporter | undefined;

function getTransporter(): nodemailer.Transporter {
  if (_transporter) return _transporter;

  _transporter = nodemailer.createTransport(mailerConfig);

  return _transporter;
}
// mail sender function

export async function sendMail(mail: PlainMail): Promise<void> {
  const transporter = getTransporter();
  await transporter.sendMail({
    from: env.MAIL_FROM,
    to: mail.to,
    subject: mail.subject,
    text: mail.text,
  });
}

const OTP_SUBJECT: Record<OtpType, string> = {
  "email-verification": "Verify your email address",
  "forget-password": "Reset your password",
  "sign-in": "Your sign-in code",
  "change-email": "Confirm your new email address",
};

export async function sendOtpMail(options: SendOtpMailOptions): Promise<void> {
  const { to, otp, type, userName } = options;
  const subject = OTP_SUBJECT[type];

  const html = await ejs.renderFile(
    path.join(TEMPLATES_DIR, "otp.ejs"),
    {
      appName: "RIZQON",
      subject,
      otp,
      type,
      recipientEmail: to,
      userName: userName ?? "",
      expiresInMinutes: 5,
      allowedAttempts: 3,
      supportUrl: `${env.FRONTEND_ORIGIN}/support`,
      companyAddress: "Dhaka, Bangladesh",
    },
    { async: false },
  );

  const transporter = getTransporter();
  // Send the email with both HTML and plain-text versions  
  await transporter.sendMail({
    from: env.MAIL_FROM,
    to,
    subject,
    html,
    // Plain-text fallback
    text: [
      `Your ${subject.toLowerCase()} code is: ${otp}`,
      "",
      "This code expires in 5 minutes.",
      "Do not share this code with anyone.",
      "If you did not request this, please ignore this email.",
    ].join("\n"),
  });
}
