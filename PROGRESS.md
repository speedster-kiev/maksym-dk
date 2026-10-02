# Build Progress

Personal homepage + chat assistant. Based on [`spec.md`](spec.md) and [`intents/intent.md`](intents/intent.md).

## Phase 0: Foundations (~½ day)

Scaleway infrastructure setup.

- [ ] **Step 1:** Repo scaffold (`package.json`, scripts, `.gitignore`)
- [ ] **Step 2:** Scaleway project + IAM + API keys
- [ ] **Step 3:** Buckets A & B + placeholder HTML
- [ ] **Step 4:** Domain + TLS + Edge Services
- [ ] **Step 5:** Confirm runtime facts (Node version, Edge Services price, prompt caching)

## Phase 1: Walking skeleton, end to end (~2–3 days)

Prove the full flow: publish → safety gate → render → deploy → chat → logs.

- [ ] **Step 6:** Minimal profile schema (`profile.json`)
- [ ] **Step 7:** Template + render + upload (`render.js`, `upload.js`)
- [ ] **Step 8:** `publish-rules.md` (starter content)
- [ ] **Step 9:** Collect + export LLM call (`collect.js`, `export-llm.js`)
- [ ] **Step 10:** Backstop + token count + report (`backstop.js`)
- [ ] **Step 11:** Privacy fixture test passes
- [ ] **Step 12:** Chat function (`handler.js`, `guard.js`, `prompt.js`, `log.js`)
- [ ] **Step 13:** Deploy function + custom domain
- [ ] **Step 14:** Bare chat widget (text box, send, messages)
- [ ] **Step 15:** Logs CLI basic (`npm run logs`)
  - ✅ Phase done when: edit source md → `npm run publish` → change visible on site + in chat + in logs

## Phase 2: Hardening (~1 day)

Infrastructure is ready.

- [ ] **Step 16:** Security headers + CSP
- [ ] **Step 17:** Rollback drill + kill switch drill
- [ ] **Step 18:** Cost check (50 test messages, avg ≤ €0.0015)
- [ ] **Step 19:** Smoke eval (10 + 10 red-team prompts)
  - ✅ Phase done when: drills pass, headers verified, cost on target

## Phase 3: Content (~2–3 days)

Expanded profile sections and content refinement.

- [ ] **Step 20:** Extend profile schema + renderer (case studies, how I work, FAQ, etc.)
- [ ] **Step 21:** Write & enrich source md files, refine `publish-rules.md`
- [ ] **Step 22:** Full eval set (30 Qs, 5 DA, 5 UK) + red-team (20) + tune prompt
- [ ] **Step 23:** CV PDF
  - ✅ Phase done when: all eval gates pass (§9 in spec)

## Phase 4: Look and feel (~2 days)

Design and polish.

- [ ] **Step 24:** Design system (fonts, colours, dark mode, layout, timeline, motion)
- [ ] **Step 25:** Chat widget polish (floating button, mobile sheet, starter chips, a11y)
- [ ] **Step 26:** SEO + social (meta, OG, JSON-LD, sitemap)
- [ ] **Step 27:** Lighthouse ≥ 95 all categories (mobile, both themes)
  - ✅ Phase done when: all visual gates pass

## Launch

- [ ] **Step 28:** Update LinkedIn, CV, email signature
  - ✅ Done when: every gate in §9 (spec) passes

## Notes

- **Content source:** External project on the Mac (not in this repo). Publish CLI reads from `SOURCE_DIR`.
- **Privacy first:** Fixture test (Step 11) is **not deferred**—nothing private may go live.
- **Walking skeleton:** Phase 1 uses placeholder content; focus is infrastructure, not design.
- **Scaleway:** All EU-hosted. Three IAM apps (publisher, fn-chat, log-reader), each with minimal privileges.

---

## Open blockers

See intent.md §14 (open questions) for decisions still needed from Maks.

| # | Item | Owner | Blocking? |
|---|------|-------|-----------|
| O1 | Node runtime version, Edge Services price, prompt caching (Step 5) | Engineering | Phase 0 |
| O2 | Contact path: email only, or email + LinkedIn (Step 20) | Maks | Phase 3 |
| O3 | Font + accent colour final choice (Step 24) | Maks | Phase 4 |
| O4 | Chat model reliability for export step (Step 11) | Engineering | Phase 1 |
| O5 | PII masking, generated CV, streaming, digest: P1 backlog | Maks | No |
