# Intent: Personal homepage with "Ask about Maks" chat

Status: Draft v1 · Owner: Maks · Date: 2026-10-01
Related: [`../spec.md`](../spec.md) (architecture, contracts, build plan)

## Problem statement

Recruiters, headhunters and TA partners screening Maks get a compressed, keyword-driven view of him through LinkedIn and a CV. They cannot easily ask follow-up questions ("has he led offshore teams?", "regulated environments?", "hands-on .NET or only management?") without booking a call, so good-fit roles may be dropped early. A personal homepage with a professional profile and a chat that answers questions about his career gives them richer, on-demand context and makes Maks stand out as an AI-native engineering leader.

## Goals

1. **Faster qualification:** a recruiter can get answers to typical screening questions in under 2 minutes without contacting Maks.
2. **Always current:** content shown on the site and used by the chat reflects the source md files as soon as Maks runs the publish command, with zero manual site edits.
3. **Safe by default:** no private or non-professional information (salary, interview notes, family, health, other people's names) ever reaches the public site or the chat.
4. **Conversion:** visitors who engage with the chat are nudged to a clear next step (CV download, LinkedIn, email).
5. **Near-zero running cost:** stays within Scaleway free tiers in normal use.

## Non-goals

- **No CMS or admin UI.** The md files in the source project are the CMS.
- **No multilingual UI.** UI is English only; the chat answers in the visitor's language (EN/DA/UK).
- **No personal or hobby content.** Professional only; hobbies are out to keep the scope and the privacy surface small.
- **No visitor accounts, visitor tracking or CRM.** Questions are logged anonymously (see P0 #8), but visitors are never identified. Keeps GDPR overhead minimal.
- **No blog.** Possible later, not needed to solve the screening problem.

## Personas

- **Headhunter / external recruiter:** skims quickly, compares many candidates, wants fit signals and availability.
- **In-house TA / HR:** checks role fit, location, languages, work rights, seniority.
- **Hiring manager / CTO:** wants depth: architecture, leadership style, concrete outcomes.
- **Maks (owner):** updates md files in his other project and wants the site to follow without effort or risk.

## User stories

### Recruiter / TA
- As a headhunter, I want a one-screen summary of Maks's role, seniority and focus so that I can decide in seconds whether to read further.
- As a TA partner, I want to ask the chat specific screening questions so that I can qualify him without a call.
- As a recruiter, I want answers in Danish if I write in Danish so that the conversation feels natural.
- As a recruiter, I want to download a current CV so that I can submit him to a client.
- As a recruiter, when the chat does not know something, I want to be told so and offered a way to contact Maks so that I am not misled.

### Hiring manager
- As a hiring manager, I want concrete outcomes (e.g. cycle time 48 to 18 days, TV2 platform with 1M+ daily users) so that I can judge impact, not just titles.

### Owner
- As Maks, I want to publish updated md files with one command so that the site and chat stay current.
- As Maks, I want a safety gate that flags potentially private content before it goes public so that I never leak sensitive info by accident.
- As Maks, I want to see what the chat is asked (anonymised, aggregated) so that I can improve my content.

## Content and data flow

Source of truth: md files in a separate local project on Maks's Mac. Chosen approach: **runtime fetch from a bucket on every chat request, no cache** (decided 2026-10-02). The fetch adds ~20 to 100 ms, negligible next to the 1 to 3 s LLM response, and keeps content always current with no cache logic.

```
[Mac: source project md files]
        │  publish command (manual or launchd)
        ▼
[Safety gate] ── report (blocked / warnings) ──► Maks reviews
        │  only if passed or explicitly overridden
        ▼
[Scaleway bucket: /profile/profile.json (condensed public profile)]
        │
        ├──► Chat function: fetches profile.json on every request, adds it to the system prompt
        └──► Static site: renders public sections from the same profile.json
```

### Safety gate (core of the sharing mechanism)
Decided 2026-10-01: **no marking in the source files.** Maks maintains a single rules file; an LLM applies it on export.
- Runs locally before upload, never in the browser.
- **Rules file** (e.g. `publish-rules.md` in this repo): plain-language description of what may be published (professional history, skills, outcomes, languages, location at city level, availability) and what must never be (salary/rates, interview processes and companies in progress, names of private individuals, family, health, hobbies, anything marked as notes to self).
- **LLM export step:** one LLM call takes the raw md files + rules file and returns (a) the condensed, public `profile` text and (b) a strip report listing what was removed and why. Source files are never modified.
- **Deterministic backstop:** after the LLM, a cheap pattern scan on the output (money amounts, phone numbers, emails other than the public one, CPR-like numbers, words like "salary", "interview", "offer", "health"). Any hit blocks the publish, because the LLM can miss things.
- **Output:** strip report + backstop result + token count. Maks reviews the report; blocked items stop the publish, `--accept-warnings` overrides warnings only.
- The gate's output is the only thing ever uploaded.

## Requirements

### P0: Must have
1. **Static homepage** with: hero (name, title, one-line pitch), about, career timeline, selected projects/outcomes, skills, contact links, CV PDF download.
   - [ ] Loads under 1 s on 4G (Lighthouse performance ≥ 95)
   - [ ] Fully usable on mobile (≥ 360 px) and keyboard-accessible; WCAG AA contrast
2. **Minimalist, stylish design:** one typeface pairing, restrained palette, generous whitespace, light and dark mode.
   - [ ] No UI framework required; no layout shift on load
3. **Chat widget** answering professional questions about Maks.
   - [ ] Answers only from published profile content; says "I don't know" otherwise and points to contact
   - [ ] Refuses non-professional / personal questions politely
   - [ ] Replies in the visitor's language (EN, DA, UK)
   - [ ] Resists prompt injection ("ignore your instructions", role-play requests)
   - [ ] Clear label that it is an AI assistant and may be imperfect
4. **Publish pipeline with safety gate** (see above).
   - [ ] One command publishes; blocked content never reaches the bucket
   - [ ] No changes or markers required in the source md files; behaviour is controlled only by the rules file
   - [ ] Strip report lists every removed item with source file and reason
   - [ ] Backstop pattern scan runs on the LLM output and blocks on any hit
   - [ ] A test fixture with planted private facts (salary, interview, family name) is fully stripped before first launch
5. **Runtime content loading** in the chat function.
   - [ ] Function fetches `profile.json` from the bucket on every chat request; no cache, no warm-up ping
   - [ ] A newly published profile is used by the very next chat message
   - [ ] If the fetch fails, the chat returns a friendly "temporarily unavailable, contact Maks at ..." message instead of answering without the profile
   - [ ] Caching may be added later only if logs show a latency or cost need
6. **Cost and abuse safeguards** (see spec.md §5.3, §7): max_tokens ~400, last ~6 messages, ~1000 chars per message, CORS to own domain, billing alerts.
7. **Token budget for the profile.** The model is stateless: every chat request sends system prompt + full profile + recent history + new question. The profile is therefore the dominant cost and must stay compact.
   - [ ] Publish step produces a condensed, fact-dense `profile.json` / prompt text from the md files (not the raw files)
   - [ ] Safety gate reports the profile's token count; warns above 4,000 tokens, blocks above 8,000 (thresholds adjustable)
   - [ ] Target cost: ≤ €0.0015 per chat message (≈ 5,000 input + 300 output tokens at current Scaleway prices)
   - [ ] No retrieval/RAG in v1; revisit only if the profile outgrows the budget
8. **Question log.** Every visitor question is logged so Maks can see what recruiters ask and where content is missing.
   - [ ] Logged per message: timestamp, conversation id (random, per browser session), visitor question, model answer, detected language, token usage, flags (refused / "don't know" / possible injection)
   - [ ] Not logged: IP address, user agent, cookies or any other identifier
   - [ ] Stored in EU as one JSON object per message in a private bucket prefix (e.g. `logs/YYYY-MM-DD/<conversationId>-<seq>.json`), never publicly readable
   - [ ] A bucket lifecycle rule deletes log objects after 90 days
   - [ ] Logging failure never breaks the chat (fire-and-forget)
   - [ ] Chat widget shows a short notice: "Questions are stored for 90 days to improve this assistant. Please don't share personal data."
   - [ ] Maks can review logs with a simple local script or command (e.g. list last N days, show "don't know" answers first)

### P1: Nice to have
- Suggested starter questions in the chat ("What teams has he led?", "Is he open to contract work?").
- Static page content also generated from the md files, so the page and the chat never disagree.
- Weekly digest of the question log: top topics, unanswered questions, suggested content gaps (could be generated by the LLM).
- "Email Maks this conversation" or a contact CTA after N messages.
- CV PDF generated from the same source files.

### P2: Future considerations
- Role-fit mode: recruiter pastes a job description, chat returns a fit summary with evidence.
- Blog / writing section.
- Scheduling link for an intro call.
- Multilingual UI.
- Design should keep content in structured files (not hard-coded HTML) so these stay cheap to add.

## Success metrics

**Leading (first 4 weeks after launch)**
- Chat engagement: ≥ 30% of visitors who scroll past the hero open the chat.
- Answer quality: ≥ 90% of a 30-question test set answered correctly and grounded (run before launch and after each content publish).
- Safety: 0 private items in published content; 0 successful jailbreaks in a red-team set of 20 prompts.
- Freshness: published changes used by the very next chat message after publish.

**Lagging (1 to 3 months)**
- Recruiter mentions of the site or chat in inbound contacts (tracked manually): ≥ 3.
- CV downloads per month trend up.
- Running cost: €0 / month within free tier; average cost per message ≤ €0.0015 (from logged token usage).
- Content gaps closed: share of "don't know" answers in the log trends down after content updates.

## Open questions

| # | Question | Owner | Blocking? |
|---|----------|-------|-----------|
| 1 | ~~Caching strategy?~~ **Decided 2026-10-02:** fetch `profile.json` from the bucket on every request, no cache. In-memory cache + warm-up rejected (more code, lost on cold starts); bundling with redeploy rejected (every publish becomes a deploy). | Engineering | Resolved |
| 2 | How is the publish triggered: manual command, git hook in the source project, or a launchd job watching the folder? | Maks | No |
| 3 | ~~Marking convention for public content?~~ **Decided 2026-10-01:** no marking; a rules file applied by an LLM on export, plus a pattern backstop. | Maks | Resolved |
| 4 | ~~Which LLM runs the export step?~~ **Default 2026-10-02:** same EU-hosted Scaleway endpoint, model configurable; whether a larger model is needed is decided after the privacy fixture test (spec O4). | Maks / Engineering | Resolved |
| 5 | ~~Runtime render or regenerate on publish?~~ **Default 2026-10-02:** site HTML rendered from profile.json at publish time (spec D8). | Engineering | Resolved |
| 6 | What is the canonical contact path: email, LinkedIn, or a form? | Maks | No |
| 7 | Does any analytics (even cookieless) need a privacy notice under GDPR? | Legal / Maks | No |
| 8 | ~~Update architecture doc~~ **Done 2026-10-02:** replaced by `spec.md`. | Engineering | Resolved |
| 9 | ~~Where to store the question log?~~ **Decided 2026-10-01:** one JSON object per message in a private bucket prefix, 90-day lifecycle rule. Cockpit logs rejected (limited retention and querying). | Engineering | Resolved |
| 10 | Does Scaleway Generative APIs support prompt caching for repeated system prompts? If yes, the per-message cost drops sharply. | Engineering | No |
| 11 | Visitors may type personal data into the chat (their own name, a client's name). Is the 90-day retention plus notice enough under GDPR, or should obvious PII be masked before logging? | Legal / Maks | No |

## Timeline and phasing

Build order (decided 2026-10-02): **infrastructure first, content and design last.** See `spec.md` §11 for steps.

- **Phase 0 (½ day):** Scaleway project, IAM, buckets, domain + TLS.
- **Phase 1 (2 to 3 days):** walking skeleton end to end: publish pipeline with safety gate, plain page, chat function, bare widget, question log. Placeholder content, minimal styling. The privacy fixture test is not postponed.
- **Phase 2 (1 day):** hardening: security headers, rollback and kill switch drills, cost check, smoke eval. Infrastructure is "ready".
- **Phase 3 (2 to 3 days):** content: extended sections (case studies, how I work, what I'm looking for, testimonials, certifications), full eval and red-team sets.
- **Phase 4 (2 days):** look and feel: design system, polished chat widget, SEO, Lighthouse.
- No hard external deadline, but value is highest while actively job searching.
