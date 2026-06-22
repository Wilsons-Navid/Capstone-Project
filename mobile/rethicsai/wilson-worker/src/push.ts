/**
 * Push delivery via FCM HTTP v1 — free, no Firebase Blaze plan required.
 *
 * The Worker holds a Firebase service-account key (secret SERVICE_ACCOUNT_JSON)
 * and uses it to (a) mint a short-lived Google OAuth access token, (b) read the
 * recipient's fcmToken from Firestore (admin access, bypassing client rules),
 * and (c) send a push through FCM v1. Everything runs on the Cloudflare Workers
 * free tier.
 */
import { SignJWT, importPKCS8 } from 'jose';

interface ServiceAccount {
  client_email: string;
  private_key: string;
  token_uri?: string;
}

// Access tokens last ~1h; cache across requests on a warm isolate.
let tokenCache: { token: string; expiresAt: number } | null = null;

/** Mint (or reuse) a Google OAuth access token for the service account. */
export async function getAccessToken(saJson: string): Promise<string> {
  if (tokenCache && tokenCache.expiresAt > Date.now() + 60_000) {
    return tokenCache.token;
  }

  const sa = JSON.parse(saJson) as ServiceAccount;
  const tokenUri = sa.token_uri || 'https://oauth2.googleapis.com/token';
  const key = await importPKCS8(sa.private_key, 'RS256');
  const now = Math.floor(Date.now() / 1000);

  const assertion = await new SignJWT({
    scope: 'https://www.googleapis.com/auth/cloud-platform',
  })
    .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
    .setIssuer(sa.client_email)
    .setSubject(sa.client_email)
    .setAudience(tokenUri)
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(key);

  const res = await fetch(tokenUri, {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });
  if (!res.ok) {
    throw new Error(`OAuth token exchange failed: ${res.status} ${await res.text()}`);
  }
  const data = (await res.json()) as { access_token: string; expires_in: number };
  tokenCache = { token: data.access_token, expiresAt: Date.now() + data.expires_in * 1000 };
  return data.access_token;
}

const FS_BASE = 'https://firestore.googleapis.com/v1';

/** Read a single string field from a users/{uid} doc via Firestore REST. */
export async function getUserField(
  projectId: string,
  accessToken: string,
  uid: string,
  field: string,
): Promise<string | undefined> {
  const res = await fetch(
    `${FS_BASE}/projects/${projectId}/databases/(default)/documents/users/${uid}`,
    { headers: { Authorization: `Bearer ${accessToken}` } },
  );
  if (res.status === 404) return undefined;
  if (!res.ok) throw new Error(`Firestore read failed: ${res.status} ${await res.text()}`);
  const doc = (await res.json()) as { fields?: Record<string, { stringValue?: string }> };
  return doc.fields?.[field]?.stringValue;
}

/** Map a stored NotificationType.name to the Android channel the app registered. */
export function channelForType(type?: string): string {
  switch (type) {
    case 'caseUpdate':
      return 'case_updates';
    case 'educationAchievement':
      return 'education';
    case 'securityAlert':
      return 'security_alerts';
    default:
      return 'general';
  }
}

export interface FcmSendResult {
  ok: boolean;
  status: number;
  stale: boolean;
  detail?: string;
}

/** Send one push via FCM HTTP v1. Reports `stale` when the token is dead. */
export async function sendFcm(
  projectId: string,
  accessToken: string,
  token: string,
  opts: { title: string; body: string; channelId: string; data: Record<string, string> },
): Promise<FcmSendResult> {
  const res = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${accessToken}`, 'content-type': 'application/json' },
    body: JSON.stringify({
      message: {
        token,
        notification: { title: opts.title, body: opts.body },
        data: opts.data,
        android: { priority: 'HIGH', notification: { channel_id: opts.channelId } },
        apns: { payload: { aps: { sound: 'default' } } },
      },
    }),
  });

  if (res.ok) return { ok: true, status: res.status, stale: false };
  const text = await res.text();
  const stale = res.status === 404 || /UNREGISTERED|INVALID_ARGUMENT/.test(text);
  return { ok: false, status: res.status, stale, detail: text };
}
