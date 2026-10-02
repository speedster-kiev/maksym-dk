# Terraform: Scaleway infrastructure

Provisions two projects (`maksym-dk` for site/function/edge, `maksym-dk-private` for logs), both buckets (90-day log expiry), three least-privilege IAM apps with API keys, the Functions namespace (env + secrets) and the Edge Services pipeline.

Not managed here: DNS records at the registrar, billing alerts (no provider resource; set €1 and €5 in the console), the function itself and `api.maksym.dk` (Phase 1), the www to apex redirect.

IAM in Scaleway scopes to projects, not buckets. That is why logs live in a separate project: `fn-chat` and `log-reader` get access to that project only.

## One-time bootstrap (console)

Terraform cannot create its own credentials. Create a dedicated app, not an owner key:

1. IAM > Applications > create `terraform`.
2. IAM > Policies > create a policy for that application with an **organization**-scoped rule and these permission sets: `ProjectManager`, `IAMManager`, `ObjectStorageFullAccess`, `FunctionsFullAccess`, `EdgeServicesFullAccess`. (Organization scope is needed because Terraform creates the projects.)
3. Create an API key for the app.

Permission set names could not be verified offline. If the console or `apply` rejects one, pick the closest valid name.

## Run

```bash
cp terraform.tfvars.example terraform.tfvars   # gitignored; fill in keys, organization_id, email
terraform init
terraform plan
terraform apply
```

Then copy outputs into the repo-root `.env`:

```bash
terraform output publisher_access_key
terraform output -raw publisher_secret_key
terraform output log_reader_access_key
terraform output -raw log_reader_secret_key
```

`LLM_API_KEY` for the publish tool is the publisher secret key. The function's keys are injected as function secrets by Terraform.

## Notes

- **State holds secrets.** `terraform.tfstate` contains every API key in plaintext. It is gitignored; keep it local and never share it.
- After apply, add the DNS records the Edge Services pipeline asks for (see the console) at your registrar.
- `terraform destroy` removes everything, including the buckets' contents only if they are empty; empty them first.
