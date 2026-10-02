# Project notes for Claude

- Source of truth: `specs/spec.md` (how) and `intents/intent.md` (why). Progress log: `PROGRESS.md`; tick steps off there as they complete.
- The repo is public. Never commit `.env`, `terraform.tfvars`, `terraform.tfstate`, keys, or the private source markdown (Maks's real profile content).
- Nothing private may be published. Do not change publish/safety-gate logic without running the privacy fixture (`tests/fixtures/private-planted`, spec §9).
- Infrastructure is Terraform in `terraform/`; run `terraform validate` after edits. Verify provider resources against current docs, do not guess names.
- Plain HTML/CSS/vanilla JS, Node 22, `node:test`, no bundler or framework (spec D7).
