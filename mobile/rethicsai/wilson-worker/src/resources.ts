/**
 * Verified cybersecurity / fraud-reporting resources.
 *
 * Source of truth lives in the Firestore collection `verified_resources` so the
 * team can update contacts WITHOUT redeploying the Worker. The bundled
 * `data/verified-resources.json` is the seed (used to populate Firestore) and
 * also the fallback if Firestore is unreachable, so the chatbot never breaks.
 *
 * Every seed entry was confirmed against an official source. Do NOT add
 * unverified phone numbers or URLs — for a security app, a wrong hotline is
 * dangerous.
 */
import seed from './data/verified-resources.json';

export interface VerifiedResource {
  country: string;
  org: string;
  description: string;
  url?: string;
  email?: string;
  phone?: string;
  shortcode?: string;
  whatsapp?: string;
  topics: string[];
  verified: boolean;
  source?: string;
}

const SEED_RESOURCES = seed as VerifiedResource[];

const ALIASES: Record<string, string> = {
  ng: 'nigeria', nigeria: 'nigeria', naija: 'nigeria',
  ke: 'kenya', kenya: 'kenya',
  gh: 'ghana', ghana: 'ghana',
  za: 'south_africa', rsa: 'south_africa',
  'south africa': 'south_africa', southafrica: 'south_africa',
  rw: 'rwanda', rwanda: 'rwanda',
  ug: 'uganda', uganda: 'uganda',
  tz: 'tanzania', tanzania: 'tanzania',
  eg: 'egypt', egypt: 'egypt',
  zm: 'zambia', zambia: 'zambia',
  ma: 'morocco', morocco: 'morocco',
};

function normalizeCountry(country?: string): string | null {
  if (!country) return null;
  return ALIASES[country.trim().toLowerCase()] ?? null;
}

// ---------------------------------------------------------------------------
// Firestore read (REST API + the caller's Firebase ID token; rules enforced).
// Cached briefly in-memory so we don't read on every tool call.
// ---------------------------------------------------------------------------

const CACHE_TTL_MS = 5 * 60 * 1000;
let cache: { data: VerifiedResource[]; expiresAt: number } | null = null;

/** Convert a Firestore REST `fields` object into a plain VerifiedResource. */
function parseDoc(fields: Record<string, any>): VerifiedResource | null {
  const val = (f: any): any => {
    if (!f) return undefined;
    if ('stringValue' in f) return f.stringValue;
    if ('booleanValue' in f) return f.booleanValue;
    if ('integerValue' in f) return Number(f.integerValue);
    if ('nullValue' in f) return undefined;
    if ('arrayValue' in f) return (f.arrayValue.values ?? []).map(val);
    return undefined;
  };
  const org = val(fields.org);
  if (!org) return null;
  return {
    country: val(fields.country) ?? 'general',
    org,
    description: val(fields.description) ?? '',
    url: val(fields.url),
    email: val(fields.email),
    phone: val(fields.phone),
    shortcode: val(fields.shortcode),
    whatsapp: val(fields.whatsapp),
    topics: (val(fields.topics) ?? []).filter((t: unknown) => typeof t === 'string'),
    verified: val(fields.verified) ?? false,
    source: val(fields.source),
  };
}

async function fetchFromFirestore(projectId: string, idToken: string): Promise<VerifiedResource[]> {
  const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/verified_resources?pageSize=300`;
  const res = await fetch(url, { headers: { Authorization: `Bearer ${idToken}` } });
  if (!res.ok) throw new Error(`Firestore ${res.status}: ${await res.text()}`);
  const body = (await res.json()) as { documents?: Array<{ fields: Record<string, any> }> };
  const docs = (body.documents ?? [])
    .map((d) => parseDoc(d.fields))
    .filter((r): r is VerifiedResource => r !== null);
  return docs;
}

/** Load resources from Firestore (cached), falling back to bundled seed data. */
async function loadResources(projectId?: string, idToken?: string): Promise<VerifiedResource[]> {
  if (cache && cache.expiresAt > Date.now()) return cache.data;

  if (projectId && idToken) {
    try {
      const data = await fetchFromFirestore(projectId, idToken);
      if (data.length) {
        cache = { data, expiresAt: Date.now() + CACHE_TTL_MS };
        return data;
      }
    } catch (e) {
      console.warn('verified_resources Firestore read failed, using bundled seed:', e);
    }
  }
  return SEED_RESOURCES;
}

function filterResources(
  pool: VerifiedResource[],
  country?: string,
  topic?: string,
): { country: string; resources: VerifiedResource[] } {
  const key = normalizeCountry(country);
  let scoped = pool.filter((r) => r.country === 'general' || (key && r.country === key));
  if (!key) scoped = pool.filter((r) => r.country === 'general');

  if (topic) {
    const t = topic.trim().toLowerCase();
    const matched = scoped.filter((r) => r.topics.some((x) => x.includes(t) || t.includes(x)));
    if (matched.length) scoped = matched;
  }

  const seen = new Set<string>();
  const resources = scoped
    .filter((r) => (seen.has(r.org) ? false : (seen.add(r.org), true)))
    .slice(0, 6);

  return { country: key ?? 'general', resources };
}

/**
 * Look up verified resources for a country/topic. Reads from Firestore when
 * project + token are provided (cached), otherwise uses the bundled seed.
 */
export async function getResources(
  opts: { projectId?: string; idToken?: string; country?: string; topic?: string },
): Promise<{ country: string; resources: VerifiedResource[] }> {
  const pool = await loadResources(opts.projectId, opts.idToken);
  return filterResources(pool, opts.country, opts.topic);
}
