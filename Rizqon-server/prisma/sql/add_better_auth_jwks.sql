BEGIN;

CREATE TABLE IF NOT EXISTS commerce.jwks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  public_key text NOT NULL,
  private_key text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz,
  alg text,
  crv text
);

COMMIT;
