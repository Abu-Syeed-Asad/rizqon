import { z } from "zod";

const email = z.string().trim().toLowerCase().pipe(z.email());
const currentPassword = z.string().min(1, "Password is required");
const newPassword = z.string()
  .min(8, "Password must contain at least 8 characters")
  .max(128, "Password must contain at most 128 characters");
const otp = z.string().regex(/^\d{6}$/, "OTP must contain exactly 6 digits");
const emailBody = z.object({ email });

export const authValidation = {
  signInWithGoogleAccount: z.strictObject({}).default({}),
  completeGoogleSignIn: z.strictObject({}).default({}),
  createUser: z.object({
    name: z.string().trim().min(1, "Name is required"),
    email,
    password: newPassword,
    image: z.url({ protocol: /^https?$/ }).optional(),
    phone: z.string().trim().min(1, "Phone must not be empty").optional(),
  }),
  signInUser: z.object({ email, password: currentPassword }),
  verifyEmailWithOtp: z.object({ email, otp }),
  sendVerificationOtp: emailBody,
  signOutUser: z.strictObject({}).default({}),
  forgotPassword: emailBody,
  resetPasswordWithOtp: z.object({ email, otp, newPassword }),
  changePassword: z.object({ currentPassword, newPassword }),
};
