const TURNSTILE_SECRET_KEY = process.env.TURNSTILE_SECRET_KEY;
const VERIFY_URL = "https://challenges.cloudflare.com/turnstile/v0/siteverify";

interface TurnstileVerifyResponse {
  success: boolean;
  "error-codes"?: string[];
  challenge_ts?: string;
  hostname?: string;
}

/**
 * Verify a Turnstile token server-side.
 * Returns true if verification passes or if Turnstile is not configured (graceful degradation).
 */
export async function verifyTurnstileToken(token: string | undefined, ip?: string | null): Promise<boolean> {
  // If no secret key configured, skip verification (allows dev without Turnstile)
  if (!TURNSTILE_SECRET_KEY) {
    return true;
  }

  // If key is configured but no token provided, reject
  if (!token) {
    return false;
  }

  const formData = new URLSearchParams();
  formData.append("secret", TURNSTILE_SECRET_KEY);
  formData.append("response", token);
  if (ip) {
    formData.append("remoteip", ip);
  }

  const res = await fetch(VERIFY_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: formData.toString(),
  });

  if (!res.ok) {
    return false;
  }

  const data: TurnstileVerifyResponse = await res.json();
  return data.success;
}
