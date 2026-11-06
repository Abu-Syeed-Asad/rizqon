import jwt, {
  type SignOptions,
  type Algorithm,
  type JwtPayload,
} from "jsonwebtoken";
import type { ITokenPayload } from "../../type/token_Type/token_payload_Type";
import { env } from "../../config/env";

const createToken = (
  payload: ITokenPayload,
  secret: string,
  time: SignOptions["expiresIn"] = "1d",
): string => {
  const token = jwt.sign(payload, secret, {
    expiresIn: time,
    algorithm:env.JWT_ALGORITHM as Algorithm,
    issuer: env.JWT_ISSUER,
    audience:env.JWT_AUDIENCE
  });

  return token;
};

// Verify JWT
export const verifyToken = (token: string, secretKey: string): JwtPayload => {
  const verifiedToken = jwt.verify(token, secretKey, {
    algorithms: [env.JWT_ALGORITHM  as Algorithm ],
    issuer: env.JWT_ISSUER,
    audience: env.JWT_AUDIENCE,
  });

  if (typeof verifiedToken === "string") {
    throw new Error("Invalid JWT payload");
  }

  return verifiedToken;
};

// Decode JWT
export const decodeToken = (token: string): JwtPayload | null => {
  const decodedToken = jwt.decode(token);

  if (!decodedToken || typeof decodedToken === "string") {
    return null;
  }

  return decodedToken;
};


export const tokenUtilitis = {
  createToken,
  verifyToken,
  decodeToken,
}
