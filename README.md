# maksym.dk

Personal homepage + "Ask about Maks" chat assistant.

A professional site for recruiters with an AI chat that answers screening questions directly from a privacy-safe profile extracted from source markdown files.

## Key docs

- **[`PROGRESS.md`](PROGRESS.md)** — Build phases & checklist. Start here to track what's done.
- **[`spec.md`](spec.md)** — How: architecture, contracts, data formats, security model, step-by-step build plan (Phases 0–4).
- **[`intents/intent.md`](intents/intent.md)** — Why: problem, goals, user stories, success metrics.
- **[`publish-rules.md`](publish-rules.md)** — Safety rules: what may/must never be published (edit as needed).

## Stack

- **Content source:** Markdown files in a separate local project (kept private).
- **Infrastructure:** Scaleway (Object Storage, Serverless Functions, Generative APIs).
- **Site:** Vanilla HTML/CSS/JS, no framework, rendered from `profile.json` at publish time.
- **Chat:** Node 22 serverless function, gemma-4-26b-a4b-it LLM, EU-hosted.
- **Safety:** LLM-powered export (rules file applied) + deterministic backstop pattern scan before any publish.
- **Logging:** Anonymous question log in a private bucket, 90-day lifecycle.

## Getting started

### Setup (Phase 0)

1. Copy `.env.example` to `.env` and fill in Scaleway API keys (see spec.md §6, §8).
2. Create Scaleway project, buckets, IAM apps, domain + TLS (spec.md steps 1–4).
3. Confirm Node 22 is available locally: `node --version`.

### Build phases

Follow [`PROGRESS.md`](PROGRESS.md) in order. Each phase has a "done when" criterion.

**Phase 1** is the walking skeleton: proves the full flow (publish → safety gate → site → chat → logs) with placeholder content and minimal styling. Phase 2–4 add content and design.

### Scripts

```bash
npm install                  # Install workspace dependencies
npm run publish              # Publish from source files with safety gate (manual)
npm run publish -- --dry-run # See what would publish, without uploading
npm run publish -- --rollback # Restore previous profile.json + HTML
npm run logs                 # List recent questions (default: last 7 days)
npm run logs -- --stats      # Cost and usage summary
npm run eval                 # Test answer quality (30 Qs, optionally red-team)
npm test                     # Unit tests
npm run dev                  # Local dev server for the chat function (port 8787)
```

## Privacy & security

- **Source files stay private.** Only the sanitised `profile.json` is published.
- **Safety gate:** before upload, an LLM applies rules from `publish-rules.md`, then a pattern backstop blocks money amounts, phone numbers, emails other than the public one, CPR-like patterns, and words like "salary", "interview", "offer", "health".
- **Logs are private:** one JSON per message, stored in a private bucket, auto-deleted after 90 days.
- **Input limits:** max 1,000 chars per message, 6 message history, CORS restricted to own domain.
- **No analytics or cookies** in v1.

See spec.md §5, §7 for full security & privacy model.

## Project structure

```
maksym-dk/
├─ PROGRESS.md              # Build checklist
├─ spec.md                  # Architecture & plan
├─ intents/intent.md        # Goals & stories
├─ publish-rules.md         # Safety rules (you edit this)
├─ .env.example             # Config template
├─ package.json             # Workspaces root + scripts
├─ site/
│  ├─ template/index.html   # HTML template with {{placeholders}}
│  ├─ assets/               # CSS, JS, fonts, favicon
│  └─ dist/                 # Output (gitignored)
├─ function/
│  ├─ handler.js            # Chat function entry point
│  ├─ guard.js              # Input validation
│  ├─ prompt.js             # System prompt builder
│  ├─ log.js                # Log writer
│  ├─ dev-server.js         # Local testing
│  └─ package.json
├─ publish/
│  ├─ index.js              # npm run publish
│  ├─ collect.js            # Read source files
│  ├─ export-llm.js         # LLM safety gate
│  ├─ backstop.js           # Pattern scan
│  ├─ render.js             # profile.json → HTML
│  ├─ upload.js             # Upload to Scaleway
│  └─ package.json
├─ tools/
│  ├─ logs.js               # npm run logs
│  ├─ eval.js               # npm run eval
│  └─ package.json
└─ tests/
   ├─ fixtures/private-planted/  # Test data with planted private facts
   ├─ eval-questions.json        # 30 Q&A for quality gates
   ├─ redteam-prompts.json       # 20 injection/off-topic prompts
   └─ *.test.js                  # Unit tests
```

## Cost model

Per chat message: ~€0.0013 (4,500 input + 300 output tokens).
First 1M tokens free → ~200 free messages, then ~€1.30 per 1,000 messages.
Export per publish: ~€0.005.

Edge Services is the likely main recurring cost (verify in step 5). See spec.md §10.

## Phases at a glance

| Phase | Time | Focus | Done when |
|-------|------|-------|-----------|
| **0** | ½ day | Scaleway setup | Buckets, domain, TLS working |
| **1** | 2–3 days | Walking skeleton | Edit source → publish → change visible on site + chat + logs |
| **2** | 1 day | Hardening | Drills pass, headers verified, cost on target |
| **3** | 2–3 days | Content | Eval gates pass, full profile built out |
| **4** | 2 days | Design | Lighthouse ≥ 95, all visual gates pass |
| **Launch** | — | Go live | Link on LinkedIn, CV, email signature |

## License

Private use (personal homepage).

---

Questions? See intent.md for open questions and contact Maks.
