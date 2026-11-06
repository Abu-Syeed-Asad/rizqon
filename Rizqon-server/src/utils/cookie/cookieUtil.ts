import type { Request, Response, CookieOptions } from "express";
import { env } from "../../config/env";
import ms from "ms";


// Constants
const IS_PRODUCTION = env.NODE_ENV === "production";

const COOKIE_NAMES = {
  SESSION_TOKEN:"sessionToken",
  ACCESS_TOKEN: "accessToken",
  REFRESH_TOKEN: "refreshToken",
} as const;



const COOKIE_MAX_AGE = {
  ACCESS_TOKEN: ms(env.JWT_ACCESS_TOKEN_EXPIRE_TIME),
  REFRESH_TOKEN: ms(env.JWT_REFRESH_TOKEN_EXPIRE_TIME),
  SESSION_TOKEN:ms(env.SESSION_TOKEN_EXPIRE_TIME)
} as const;

// Common cookie configuration
const BASE_COOKIE_OPTIONS: CookieOptions = {
  httpOnly: true,
  secure: IS_PRODUCTION,
  sameSite: "lax",
};

// Individual cookie configurations
const ACCESS_COOKIE_OPTIONS: CookieOptions = {
  ...BASE_COOKIE_OPTIONS,
  path: "/",
  maxAge: COOKIE_MAX_AGE.ACCESS_TOKEN,
};

const REFRESH_COOKIE_OPTIONS: CookieOptions = {
  ...BASE_COOKIE_OPTIONS,
  path: "/",
  maxAge: COOKIE_MAX_AGE.REFRESH_TOKEN,
};
const SESSION_COOKIE_OPTIONS: CookieOptions = {
  ...BASE_COOKIE_OPTIONS,
  path: "/",
  maxAge: COOKIE_MAX_AGE.SESSION_TOKEN,
};

// Reusable helpers
 const setCookie = (
  res: Response,
  name: string,
  value: string,
  options: CookieOptions,
): void => {
  res.cookie(name, value, options);
};
 const clearCookie = (
  res: Response,
  name: string,
  options?: CookieOptions,
): void => {
  const {  ...clearOptions } = options;

  res.clearCookie(name, clearOptions);
};

const getCookie = (req: Request, name: string): string | null => {
  const value: unknown = req.cookies?.[name];

  return typeof value === "string" ? value : null;
};

// Authentication helpers
const setSessionCookie = (res: Response, sessionToken: string): void => {
  setCookie(res, COOKIE_NAMES.SESSION_TOKEN, sessionToken, SESSION_COOKIE_OPTIONS);
};

export const setAuthCookies = (
  res: Response,
  accessToken: string,
  refreshToken: string,
  sessionToken:string,
): void => {
  setCookie(
    res,
    COOKIE_NAMES.ACCESS_TOKEN,
    accessToken,
    ACCESS_COOKIE_OPTIONS
  );

  setCookie(
    res,
    COOKIE_NAMES.REFRESH_TOKEN,
    refreshToken,
    REFRESH_COOKIE_OPTIONS,
  );
  setCookie(
    res,
    COOKIE_NAMES.SESSION_TOKEN,
    sessionToken,
    SESSION_COOKIE_OPTIONS,
  );
};

 const clearAuthCookies = (res: Response): void => {
  clearCookie(res, COOKIE_NAMES.ACCESS_TOKEN, ACCESS_COOKIE_OPTIONS);

  clearCookie(res, COOKIE_NAMES.REFRESH_TOKEN, REFRESH_COOKIE_OPTIONS);
};

 const getAccessToken = (req: Request): string | null => {
  return getCookie(req, COOKIE_NAMES.ACCESS_TOKEN);
};

 const getRefreshToken = (req: Request): string | null => {
  return getCookie(req, COOKIE_NAMES.REFRESH_TOKEN);
};

export const cookieUtills = {
  setSessionCookie,
  setAuthCookies,
  clearAuthCookies,
  getAccessToken,
  getRefreshToken,
  setCookie,
  getCookie,
  clearCookie
}
