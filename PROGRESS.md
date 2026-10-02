# Progress

Steps match `specs/spec.md` §11. Legend: [x] done, [ ] to do.

## Phase 0: Foundations
- [x] 1. Repo scaffold, GitHub repo (public)
- [x] 1b. Terraform written and `terraform validate` passes (projects, buckets, IAM, function namespace, Edge Services)
- [x] 2a. Bootstrap `terraform` IAM app + API key in console (terraform/README.md)
- [x] 2b. `terraform apply` complete (projects, buckets, IAM, function namespace, Edge plan + pipeline stages)
- [ ] 2d. Copy publisher and log-reader keys from `terraform output` into `.env`
- [ ] 2c. Billing alerts at €1 and €5 (console, not in Terraform)
- [x] 3. Verify placeholder on bucket website endpoint; anonymous GET on logs bucket returns 403
- [ ] 4. Console: attach `maksym.dk` + `www.maksym.dk` to the Edge pipeline (DNS stage is not creatable via API/Terraform), add DNS records at registrar, www to apex redirect; `https://maksym.dk` serves placeholder over TLS
- [ ] 5. Confirm runtime facts (Node version, Edge Services price, prompt caching) and Terraform permission set names

## Phase 1: Walking skeleton
- [ ] 6 Minimal profile schema · [ ] 7 Render + upload · [ ] 8 `publish-rules.md` · [ ] 9 Collect + export LLM
- [ ] 10 Backstop, report, confirm · [ ] 11 Privacy fixture passes · [ ] 12 Chat function · [ ] 13 Deploy function + `api.maksym.dk`
- [ ] 14 Bare chat widget · [ ] 15 Logs CLI

## Phase 2: Hardening
- [ ] 16 Security headers · [ ] 17 Rollback and kill-switch drills · [ ] 18 Cost check · [ ] 19 Smoke eval

## Phase 3: Content
- [ ] 20 Extend schema and renderer · [ ] 21 Source content and rules · [ ] 22 Full eval and red-team sets · [ ] 23 CV PDF

## Phase 4: Look and feel
- [ ] 24 Design system · [ ] 25 Chat widget polish · [ ] 26 SEO and social · [ ] 27 Lighthouse ≥ 95

## Launch
- [ ] 28 LinkedIn, CV, email signature

## Open items
See spec §13 and intent "Open questions".
