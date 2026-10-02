# Scaleway Infrastructure as Code

Terraform configuration to set up the entire maksym.dk infrastructure on Scaleway.

## What gets created

✅ Scaleway project (`maksym-dk`)
✅ Object Storage buckets:
  - Bucket A (`maksym-dk-site`): public, website hosting
  - Bucket B (`maksym-dk-private`): private, 90-day log lifecycle
✅ IAM applications (3, least-privilege):
  - `publisher`: write to Bucket A + Generative APIs
  - `fn-chat`: write to Bucket B + Generative APIs
  - `log-reader`: read Bucket B only
✅ Functions namespace with environment variables & secrets
✅ Billing alerts (€1 and €5)

## Prerequisites

1. **Terraform** >= 1.0: https://www.terraform.io/downloads
2. **Scaleway account** with API credentials
3. **Domain** (e.g., `maksym.dk`) — you'll configure DNS separately

## Setup

### 1. Create a Terraform IAM application (recommended)

For security, create a separate IAM application just for Terraform instead of using your owner API key.

1. Log in: https://console.scaleway.com
2. Go to **IAM** → **Applications** → **Create new application**
3. Name: `terraform` (or similar)
4. Create the app
5. In the app, create a **policy** with these permissions:
   - **Scope:** Organization (not project-specific)
   - **Permissions:**
     - `AccountProjectsWrite` (to create projects)
     - `ObjectStorageBucketCreateDelete` (to create/delete buckets)
     - `ObjectStorageACLManage` (to manage bucket policies)
     - `IAMApplicationsManage` (to create IAM apps)
     - `IAMPoliciesManage` (to create policies)
     - `IAMAPIKeysManage` (to create API keys)
     - `LambdaFunctionCreate` (to create function namespaces)
     - `BillingAlertsWrite` (to create billing alerts)
6. Generate an **API key** for this app
7. Copy the `access_key` and `secret_key`

### 2. (Alternative) Use your owner API key once, then rotate

If you prefer, use your owner API key just for the initial `terraform apply`, then:
1. Get it: https://console.scaleway.com/account/api-keys
2. After Terraform succeeds, revoke this key
3. Never use it again

This works, but is less secure than step 1.

### 3. Copy and fill `terraform.tfvars`

```bash
cd terraform/
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
- Paste the **Terraform app's** `scaleway_access_key` and `scaleway_secret_key` (from step 1 or 2)
- Set your domain (e.g., `maksym.dk`)
- Set your contact email

### 4. Initialize Terraform

```bash
terraform init
```

### 5. Review what will be created

```bash
terraform plan
```

Review the output to ensure everything looks right.

### 6. Apply the configuration

```bash
terraform apply
```

Terraform will ask for confirmation. Type `yes`.

This takes 2–5 minutes. Watch for any errors.

### 7. Save the outputs

Once complete, Terraform prints sensitive values (API keys). **Save these or save the state file:**

```bash
terraform output -json > outputs.json  # Save for later reference
```

Or view outputs individually:

```bash
terraform output publisher_api_key
terraform output fn_chat_api_key
terraform output log_reader_api_key
```

### 8. Update your `.env` file

Copy the outputs into `.env` at the root of the project. Example:

```bash
# From terraform output
S3_ACCESS_KEY=<publisher_api_key>
S3_SECRET_KEY=<publisher_secret_key>
LLM_API_KEY=<publisher_secret_key>  # Same as above

# For logs CLI (separate credentials)
LOG_S3_ACCESS_KEY=<log_reader_api_key>
LOG_S3_SECRET_KEY=<log_reader_secret_key>
```

### 9. Configure DNS at your registrar

Terraform creates the buckets and functions, but DNS is manual (outside Terraform for now).

At your domain registrar (GoDaddy, Namecheap, etc.):

- [ ] Add CNAME for `maksym.dk` → your Scaleway Edge Services endpoint (you'll add Edge Services next)
- [ ] Add CNAME for `www.maksym.dk` → same endpoint

For now, just verify buckets work:

```bash
# Should return 200 with your placeholder HTML
curl https://maksym-dk-site.fr-par.scw.cloud
```

## Verify everything works

After step 9 (DNS configured), verify:

```bash
# Test publish tool connectivity
npm run publish -- --dry-run

# Check buckets exist
aws s3 ls --endpoint-url https://s3.fr-par.scw.cloud
```

## Next steps

1. **Edge Services + custom domain** (Phase 0, step 4): Add manually in Scaleway console for now
2. **Phase 1: Walking skeleton** (2–3 days): Build site, chat, publish pipeline

## Terraform state management

⚠️ **Important:** `terraform.tfstate` contains sensitive data (API keys). **Do not commit it to git.**

It's already in `.gitignore`, but be careful:
- Never share the state file
- Back it up securely if you need disaster recovery
- For team collaboration later, consider Terraform Cloud

## Destroying everything

To tear down all resources (useful for testing):

```bash
terraform destroy
```

Type `yes` to confirm. This deletes buckets, IAM apps, functions namespace, etc. Use with caution!

## Troubleshooting

**Error: "access_key not set"**
→ Check `terraform.tfvars` has `scaleway_access_key` and `scaleway_secret_key` filled in.

**Error: "Invalid project ID"**
→ Terraform creates the project; if this fails, the project may already exist. Check Scaleway console.

**API key not working after apply**
→ Scaleway API keys may take a few seconds to activate. Wait 30 seconds and retry.

**Buckets created but can't access**
→ Check bucket policy (Bucket A should be public). Run `terraform apply` again if needed.

## Notes

- Region is set to `fr-par` (Paris, EU) in variables — change in `terraform.tfvars` if needed
- All resources are tagged with `environment = "production"`
- Function secrets are stored securely in Scaleway and not in state
