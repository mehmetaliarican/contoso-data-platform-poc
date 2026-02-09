# Terraform Infrastructure - Contoso Data Platform

This directory contains Terraform configurations for deploying the Contoso Data Platform from your local machine.

---

## 📁 Directory Structure

```
infrastructure/terraform/
├── main.tf                 # Root module orchestration
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── providers.tf            # Provider configuration
├── locals.tf               # Local values
├── modules/
│   ├── storage/            # ADLS Gen2 module
│   ├── databricks/         # Databricks workspace module
│   ├── keyvault/           # Key Vault module
│   └── networking/         # VNet/subnet module
└── environments/
    └── dev.tfvars          # Development environment variables
```

---

## 🚀 Quick Start

### Prerequisites

1. **Azure CLI** installed and authenticated
   ```bash
   az login
   ```

2. **Terraform** >= 1.3.0 installed
   ```bash
   terraform -v
   ```

3. **Azure Subscription** with appropriate permissions (Owner or Contributor + User Access Administrator)

4. **Resource Providers Registered**
   ```bash
   az provider register --namespace Microsoft.Storage
   az provider register --namespace Microsoft.KeyVault
   az provider register --namespace Microsoft.Network
   az provider register --namespace Microsoft.OperationalInsights
   az provider register --namespace Microsoft.Databricks
   ```

---

## 📦 Resources Created

| Resource | Purpose | SKU |
|----------|---------|-----|
| Resource Group | Resource organization | - |
| Storage Account | ADLS Gen2 for Raw & Data Hub | Standard LRS |
| Key Vault | Secret management | Standard |
| Databricks Workspace | Data processing | Premium |
| **Databricks Cluster** | Auto-created compute | Standard_DS3_v2 |
| **Databricks Secret Scope** | Auto-linked to Key Vault | - |
| Virtual Network | Network isolation | - |
| Service Principal | Databricks storage access | - |
| Log Analytics (opt) | Monitoring | PerGB2018 |
| Data Factory (opt) | Orchestration | - |
| SQL Server (opt) | Metadata store | - |

---

## 🔧 Deployment Steps

### 1. Navigate to Terraform Directory
```bash
cd infrastructure/terraform
```

### 2. Configure Environment

Edit `environments/dev/terraform.tfvars`:

```hcl
environment   = "dev"
location      = "westeurope"
project_name  = "contoso"

# Optional features
create_data_factory  = false
create_sql_server    = false
create_log_analytics = true
```

### 3. Initialize Terraform
```bash
terraform init
```

### 4. Plan Changes
```bash
terraform plan -var-file="environments/dev/terraform.tfvars"
```

### 5. Apply Changes
```bash
terraform apply -var-file="environments/dev.tfvars"
```

**Takes ~10-15 minutes. Creates:**
- ✅ All Azure infrastructure
- ✅ Databricks cluster (ready to use)
- ✅ Databricks secret scope (linked to Key Vault)
- ✅ All secrets in Key Vault

**Outputs include:**
- `databricks_workspace_url` - URL to access Databricks
- `storage_account_name` - Name of the ADLS Gen2 account
- `key_vault_name` - Name of the Key Vault
- `cluster_id` - ID of the auto-created cluster
- `service_principal_client_id` - SP Client ID (sensitive)

---

## 🔐 Security

### Service Principal

A Service Principal is automatically created for Databricks to access storage:

- **Role**: Storage Blob Data Contributor
- **Scope**: Storage account
- **Secrets**: Stored in Key Vault automatically

### Databricks Configuration (Auto-Created)

Terraform automatically configures Databricks:
- **Cluster**: `poc-cluster` (1 node, auto-terminate after 30 min)
- **Secret Scope**: `contoso-secrets` (backed by Key Vault)

No manual setup needed!

### Key Vault Secrets

After deployment, the following secrets are available in Key Vault:

| Secret Name | Description |
|-------------|-------------|
| `sp-client-id` | Service Principal Client ID |
| `sp-client-secret` | Service Principal secret |
| `sp-tenant-id` | Azure AD Tenant ID |
| `storage-account-key` | Storage account access key |
| `storage-account-name` | Storage account name |
| `sql-admin-password` | SQL Server admin password (if created) |

---

## 🛠️ Customization

### Add New Data Source

Edit `metadata/sources.json` and add:

```json
{
  "source_id": "src_005",
  "name": "New Source",
  "type": "sql",
  "connection": { ... },
  "extraction": { ... },
  "destination": { ... }
}
```

### Enable SQL Server

In `environments/dev/terraform.tfvars`:
```hcl
create_sql_server = true
sql_admin_password = "YourSecurePassword123!"
```

Or use environment variable:
```bash
export TF_VAR_sql_admin_password="YourSecurePassword123!"
terraform apply -var-file="environments/dev/terraform.tfvars"
```

### Change Location

In `environments/dev/terraform.tfvars`:
```hcl
location = "northeurope"  # or any Azure region
```

---

## 📊 Viewing Outputs

After deployment, view all outputs:
```bash
terraform output
```

View a specific output:
```bash
terraform output databricks_workspace_url
terraform output -raw storage_account_name
```

---

## 🧹 Cleanup / Destroy

To remove all resources:
```bash
terraform destroy -var-file="environments/dev/terraform.tfvars"
```

⚠️ **Warning**: This deletes all data and resources! Terraform will ask for confirmation before destroying.

---

## 🔍 Troubleshooting

### "Provider not registered" Error

```bash
# Register the missing provider
az provider register --namespace {ProviderName}

# Check registration status
az provider show --namespace {ProviderName} --query "registrationState"
```

### Storage Account Name Already Exists

Storage account names must be globally unique. If you get this error:
1. Change `project_name` in `environments/dev/terraform.tfvars`
2. Run `terraform apply` again

Terraform automatically adds a 6-character random suffix to make names unique.

### Authentication Errors

Ensure you're logged into Azure CLI:
```bash
az account show
# If not logged in:
az login
```

### "Authorization failed" Errors

Your Azure account needs:
- **Contributor** role on the subscription (to create resources)
- **User Access Administrator** role (to assign roles to Service Principal)

```bash
# Check your role assignments
az role assignment list --assignee $(az account show --query user.name -o tsv)
```

### Databricks Workspace URL Not Working

It takes a few minutes after deployment for the Databricks workspace to be fully ready. Wait 2-3 minutes and try again.

---

## 📚 Next Steps

After infrastructure is deployed:

1. **Configure Databricks**: Follow the [Deployment Guide](../../docs/deployment_guide.md)
2. **Add Data Sources**: Edit `metadata/sources.json`
3. **Run Notebooks**: Execute the pipeline in Databricks
4. **Production**: Copy `environments/dev/terraform.tfvars` to `environments/prod/terraform.tfvars` and deploy to production subscription

---

## 📖 References

- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Databricks Terraform Provider](https://registry.terraform.io/providers/databricks/databricks/latest/docs)
- [Azure AD Terraform Provider](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs)
