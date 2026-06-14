/**
 * Firebase ID token verification at the edge.
 *
 * Firebase ID tokens are RS256 JWTs signed by Google. We verify the signature
 * against Google's public x509 certs (cached, honouring max-age), and check the
 * issuer/audience against the project. No Firebase Admin SDK, no Workers KV.
 */
import { decodeProtectedHeader, importX509, jwtVerify, type JWTPayload } from 'jose';

const CERT_URL =
  'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com';

let certCache: { certs: Record<string, string>; expiresAt: number } | null = null;

async function getCerts(): Promise<Record<string, string>> {
  const now = Date.now();
  if (certCache && certCache.expiresAt > now) return certCache.certs;

  const res = await fetch(CERT_URL);
  if (!res.ok) throw new Error(`Failed to fetch Google certs: ${res.status}`);
  const certs = (await res.json()) as Record<string, string>;

  const cacheControl = res.headers.get('cache-control') || '';
  const maxAge = /max-age=(\d+)/.exec(cacheControl);
  const ttlMs = maxAge ? parseInt(maxAge[1], 10) * 1000 : 3600 * 1000;
  certCache = { certs, expiresAt: now + ttlMs };
  return certs;
}

/** Verify a Firebase ID token. Returns the decoded payload or throws. */
export async function verifyFirebaseToken(token: string, projectId: string): Promise<JWTPayload> {
  const header = decodeProtectedHeader(token);
  if (header.alg !== 'RS256' || !header.kid) {
    throw new Error('Unexpected token header');
  }

  const certs = await getCerts();
  const pem = certs[header.kid];
  if (!pem) throw new Error('Unknown signing key');

  const publicKey = await importX509(pem, 'RS256');
  const { payload } = await jwtVerify(token, publicKey, {
    issuer: `https://securetoken.google.com/${projectId}`,
    audience: projectId,
  });

  if (!payload.sub) throw new Error('Token missing subject');
  return payload;
}

/** Extract a Bearer token from the Authorization header. */
export function getBearerToken(request: Request): string | null {
  const header = request.headers.get('Authorization') || request.headers.get('authorization');
  if (!header) return null;
  const match = /^Bearer\s+(.+)$/.exec(header);
  return match ? match[1] : null;
}
