import nodemailer, { type Transporter } from "nodemailer";

type OutgoingMail = {
  to: string;
  subject: string;
  text: string;
};

let transporter: Transporter | undefined;
let sender: string | undefined;

function getTransport(): Transporter {
  if (transporter) {
    return transporter;
  }

  const host = process.env.SMTP_HOST;
  const port = Number(process.env.SMTP_PORT ?? "587");
  const from = process.env.SMTP_FROM;
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;

  if (!host || !from || !Number.isInteger(port) || port < 1 || port > 65535) {
    throw new Error(
      "Set valid SMTP_HOST, SMTP_PORT, and SMTP_FROM to send auth emails",
    );
  }
  if ((user && !pass) || (!user && pass)) {
    throw new Error("Set both SMTP_USER and SMTP_PASS, or leave both unset");
  }

  sender = from;
  transporter = nodemailer.createTransport({
    host,
    port,
    secure: process.env.SMTP_SECURE === "true" || port === 465,
    ...(user && pass ? { auth: { user, pass } } : {}),
  });

  return transporter;
}

export async function sendMail(mail: OutgoingMail): Promise<void> {
  const transport = getTransport();
  await transport.sendMail({ ...mail, from: sender });
}
