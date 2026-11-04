# Overview

Deploys Crawl4AI 0.9.5 to Azure Container Apps using Terraform. The app has public HTTPS ingress, scales between zero and one replica, and exposes a health endpoint.

# Setup

Install Terraform 1.7 or later, Azure CLI, and OpenSSL. Sign in to an Azure subscription, then run:

```bash
az login
export TF_VAR_crawl4ai_api_token="$(openssl rand -hex 32)"
terraform init
terraform plan
terraform apply
```

The token must be at least 32 characters long. Save it securely for API access. The default Azure region is `southeastasia`; override it with `TF_VAR_location` if needed.

Get the application URL and check its health:

```bash
export CRAWL4AI_URL="$(terraform output -raw crawl4ai_url)"
curl "$CRAWL4AI_URL/health"
```
