# Development Backend Configuration
# Initialize with:
# terraform init -backend-config=environments/dev/backend.tfvars

resource_group_name  = "rg-terraform-state"
storage_account_name = "sttfstatecontosodev"
container_name       = "tfstate"
key                  = "contoso-data-platform-dev.tfstate"
