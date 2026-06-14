# Wilson Worker

Free, no-credit-card backend for the RethicsAI mobile chatbot. A Cloudflare
Worker that verifies the caller's Firebase ID token and proxies requests to
Claude Haiku. Replaces the Firebase Cloud Functions path (which requires the
paid Blaze plan).

## Why this exists

Firebase Cloud Functions require the Blaze (pay-as-you-go) plan to deploy.
Cloudflare Workers have a generous free tier and need **no payment method**, so
the chatbot can run for free. You still pay Anthropic for Claude tokens from
your API credit — that part is unavoidable.

## Endpoints

All `POST`, all require `Authorization: Bearer <firebaseIdToken>`:

| Path            | Purpose                                  |
| --------------- | ---------------------------------------- |
| `/chat`         | Conversational assistant                 |
| `/analyze`      | Assess suspicious content (JSON)         |
| `/insights`     | Daily cybersecurity tips (JSON)          |
| `/threat-intel` | Regional threat intelligence (JSON)      |
| `/training`     | Generate training content                |

## One-time setup

```bash
cd mobile/rethicsai/wilson-worker
npm install

# Log in to Cloudflare (opens a browser; free account, no card needed)
npx wrangler login

# Store the Claude API key as an encrypted secret (paste the NEW, rotated key)
npx wrangler secret put ANTHROPIC_API_KEY
```

## Deploy

```bash
npm run deploy
```

Wrangler prints the deployed URL, e.g. `https://wilson-worker.<your-subdomain>.workers.dev`.
Put that URL into the Flutter app at `lib/core/constants/wilson_worker.dart`.

## Local development

```bash
# Put the key in a local-only file (gitignored), then:
echo 'ANTHROPIC_API_KEY = "sk-ant-..."' > .dev.vars
npm run dev
```

## Verified resources (Firestore)

The `get_verified_resources` tool reads from the Firestore collection
`verified_resources` (using the caller's ID token; rules require admin to
write, any signed-in user to read). This lets you update official contacts
WITHOUT redeploying the Worker. If Firestore is unreachable, the Worker falls
back to the bundled `src/data/verified-resources.json`.

Seed / update the collection from the bundled data (keyless — signs in as an
admin user, no service-account key):

```powershell
# Web API key is in the app at lib/firebase_options.dart (apiKey). Not secret.
$env:FIREBASE_API_KEY="<web api key>"
$env:ADMIN_EMAIL="<an admin/super_admin account>"
$env:ADMIN_PASSWORD="<password>"
node scripts/seed-resources.mjs
```

Deploy the rule for the new collection too: `firebase deploy --only firestore:rules`.

After seeding, edit contacts directly in the Firebase console (or re-run the
script); the Worker picks up changes within ~5 minutes (in-memory cache TTL).

## Notes

- `FIREBASE_PROJECT_ID` is set in `wrangler.toml` (`rethics-d47fa`); it is not a
  secret. The Worker only accepts ID tokens issued for that project.
- The Worker is stateless. Chat history is persisted by the app, client-side,
  to Firestore under the signed-in user's UID.
