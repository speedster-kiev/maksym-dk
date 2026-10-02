# Working with this project

Guidance for Claude Code to understand this project's conventions and goals.

## Project context

This is a personal homepage + AI chat system for recruiter screening. Built by phases:
- **Phase 0:** Infrastructure setup (Scaleway, buckets, domain).
- **Phase 1:** Walking skeleton (proof that publish → render → chat → logs works).
- **Phase 2:** Hardening (security, cost, quality gates).
- **Phase 3:** Content & eval (30 test questions, red-team 20).
- **Phase 4:** Design & polish.

**Current phase:** Track in `PROGRESS.md`.

**Key constraint:** Nothing private (salary, interviews, family names, health, notes to self) may ever leave the Mac. The publish pipeline's entire purpose is to prevent this via the LLM safety gate + backstop pattern scan.

## Conventions

### Privacy & safety (non-negotiable)

- **Test the privacy fixture before any publish-related change.** Planted private facts must be fully stripped.
  ```bash
  npm run publish -- --dry-run --source tests/fixtures/private-planted
  ```
- **All profile fields must be HTML-escaped** in the render step (§5.5, step 7).
- **Never change the safety gate logic without re-running the privacy fixture.** Even small tweaks can let things slip through.

### Code style

- **No frameworks, no bundlers.** Vanilla HTML/CSS/JS for the site.
- **One Node file per concern:** `collect.js`, `export-llm.js`, `backstop.js`, `render.js`, `upload.js` (each does one job).
- **Minimal comments.** Code should speak for itself; comments only for non-obvious constraints or workarounds.
- **Tests with `node:test`** (no external test runner).

### Commits

- Use the structure: **short subject + what changed, why, and what's next.**
- Example: `Add backstop pattern for salary amounts` (not `fix backstop`).
- Mention spec section where relevant (e.g., "implements spec.md §5.5 step 10").
- If a change affects a Phase checklist, note which step it unblocks.

## When building a phase

1. **Read the spec section** for that phase (e.g., Phase 1 = spec.md §11, steps 6–15).
2. **Check the "done when" criterion.** That is the exit test.
3. **Test the privacy fixture** before any publish/render changes.
4. **Update PROGRESS.md** as steps complete (checkbox `[✓]`).
5. **Run the quality gates** for that phase (spec.md §9).

Example Phase 1 flow:
- Build minimal `profile.json` schema (step 6).
- Implement `render.js` + `upload.js` (step 7).
- Build collect + export LLM (steps 9).
- Build backstop + token count (step 10).
- **Test privacy fixture** (step 11).
- Build chat function (steps 12–13).
- Build chat widget (step 14).
- Build logs CLI (step 15).
- **Phase done when:** edit md → publish → see change on site + chat + logs.

## Things to watch

- **Token budget:** Profile's `promptText` must stay under 4,000 tokens (warn above, block above 8,000). Check before any content change.
- **Cost per message:** Target ≤ €0.0015. Run smoke eval after Phase 1; full eval after Phase 3.
- **Scaleway free tier:** Functions, Object Storage, logs should be free in normal use; Edge Services is the likely recurring cost.
- **Content source is external:** The real md files live on Maks's Mac in a separate project, never in this repo. `SOURCE_DIR` in `.env` points to it.
- **Logs are fire-and-forget:** Chat function never waits for a failed log write; errors are swallowed and printed to stdout.

## Open decisions

See `intent.md` §14 ("open questions") for decisions not yet made:
- **O1:** Node 22 available? (step 5)
- **O2:** Contact path: email-only or + LinkedIn? (step 20)
- **O3:** Font pairing & colour? (step 24)
- **O4:** Is the model good enough for export, or do we need a larger one? (after step 11)

## Git

- **Remote:** `origin` → `https://github.com/speedster-kiev/maksym-dk`
- **Branch:** `main` (no feature branches for now; v1 is too small).
- **Secrets:** Never in git. `.env` is gitignored; `.env.example` is the public template.
- **Squash small commits** if Phase is complete and ready to push (avoid noise).

## Useful commands

```bash
# Test the privacy fixture (critical before any publish change)
npm run publish -- --dry-run --source tests/fixtures/private-planted

# Local function testing
npm run dev                    # Starts on port 8787
curl -X POST http://localhost:8787/chat \
  -H "Origin: http://localhost:3000" \
  -d '{"conversationId":"c_test","messages":[{"role":"user","content":"test"}]}'

# Check logs from the last N days
npm run logs -- --days 7

# Quality gates (Phase 2 onwards)
npm run eval                   # 30-question eval
npm run eval -- --redteam      # Red-team (20 injection/off-topic)
npm test                       # Unit tests
```

## What not to do

- **Don't defer the privacy fixture test.** It's the one gate that must pass before anything goes live.
- **Don't cache the profile in the function** in v1 (spec.md D5: fetch every request).
- **Don't add frameworks or bundlers** without revisiting the scope in Phase 0/1.
- **Don't hardcode content.** Everything comes from `profile.json`.
- **Don't store IP, user agent, or any identifiers in logs.** Spec.md §4.3 lists what is safe to log.
