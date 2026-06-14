/**
 * Seed the Firestore `verified_resources` collection from the bundled
 * data file. Keyless: signs in as an admin user via the Firebase Auth REST
 * API, then writes each document with that ID token (Firestore rules require
 * admin to write). No service-account key needed.
 *
 * Usage (PowerShell):
 *   $env:FIREBASE_API_KEY="<web api key from firebase_options.dart>"
 *   $env:ADMIN_EMAIL="you@admin.com"
 *   $env:ADMIN_PASSWORD="..."
 *   node scripts/seed-resources.mjs
 *
 * Requires Node 18+ (uses global fetch). The admin user must have role
 * 'admin' or 'super_admin' in the users collection.
 */
import { readFile } from 'node:fs/promises';

const PROJECT_ID = process.env.FIREBASE_PROJECT_ID || 'rethics-d47fa';
const API_KEY = process.env.FIREBASE_API_KEY;
const EMAIL = process.env.ADMIN_EMAIL;
const PASSWORD = process.env.ADMIN_PASSWORD;

if (!API_KEY || !EMAIL || !PASSWORD) {
  console.error('Missing env: FIREBASE_API_KEY, ADMIN_EMAIL, ADMIN_PASSWORD are required.');
  process.exit(1);
}

const slug = (s) =>
  s.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '').slice(0, 60);

function toFields(r) {
  const fields = {};
  for (const [key, value] of Object.entries(r)) {
    if (value === undefined || value === null) continue;
    if (typeof value === 'string') fields[key] = { stringValue: value };
    else if (typeof value === 'boolean') fields[key] = { booleanValue: value };
    else if (Array.isArray(value)) {
      fields[key] = { arrayValue: { values: value.map((v) => ({ stringValue: String(v) })) } };
    }
  }
  return fields;
}

async function main() {
  const resources = JSON.parse(
    await readFile(new URL('../src/data/verified-resources.json', import.meta.url), 'utf8'),
  );

  // 1. Sign in as admin → ID token.
  const signInRes = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`,
    {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ email: EMAIL, password: PASSWORD, returnSecureToken: true }),
    },
  );
  if (!signInRes.ok) {
    console.error('Sign-in failed:', await signInRes.text());
    process.exit(1);
  }
  const { idToken } = await signInRes.json();
  console.log(`Signed in as ${EMAIL}. Seeding ${resources.length} resources...`);

  // 2. Write each document (PATCH creates or overwrites).
  let ok = 0;
  for (const r of resources) {
    const id = `${r.country}__${slug(r.org)}`;
    const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/verified_resources/${id}`;
    const res = await fetch(url, {
      method: 'PATCH',
      headers: { Authorization: `Bearer ${idToken}`, 'content-type': 'application/json' },
      body: JSON.stringify({ fields: toFields(r) }),
    });
    if (res.ok) {
      ok += 1;
      console.log(`  ✓ ${id}`);
    } else {
      console.error(`  ✗ ${id}: ${res.status} ${await res.text()}`);
    }
  }

  console.log(`Done. ${ok}/${resources.length} documents written to verified_resources.`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
