# ThorNetLab - Azure Security Lab Environment

This repository contains Infrastructure as Code (IaC) templates for deploying a security lab environment in Azure using Bicep templates.

## Azure Managed Identity Configuration

This lab environment uses Azure Managed Identities for authentication instead of traditional username/password combinations, providing enhanced security through:

- **No embedded credentials** in deployment files or workflows
- **Automatic credential management** by Azure
- **Simplified authentication** process
- **Reduced attack surface** by eliminating password-based authentication

### Managed Identity Setup

The deployment creates a Virtual Machine with:
- **System-assigned managed identity** enabled automatically
- **Password authentication disabled** for SSH access
- **Key-based authentication required** for secure access

### Required Role Assignments

After deployment, you'll need to assign appropriate roles to the VM's managed identity to access Azure resources:

```bash
# Get the VM's managed identity principal ID
VM_PRINCIPAL_ID=$(az vm show --name thornetlab-ubuntu --resource-group thornetlab-rg --query identity.principalId -o tsv)

# Example: Grant reader access to the resource group
az role assignment create \
  --assignee $VM_PRINCIPAL_ID \
  --role "Reader" \
  --scope "/subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/thornetlab-rg"

# Example: Grant specific permissions for security operations
az role assignment create \
  --assignee $VM_PRINCIPAL_ID \
  --role "Security Reader" \
  --scope "/subscriptions/YOUR_SUBSCRIPTION_ID"
```

### Accessing the VM

Since password authentication is disabled, you'll need to:

1. **Use SSH key authentication** - Configure your SSH public key during deployment
2. **Use Azure Bastion** - For browser-based access without exposing SSH ports
3. **Use Azure CLI** - Connect directly through Azure portal

### GitHub Actions Workflow

The deployment workflow uses GitHub's OIDC provider with Azure for authentication:
- No secrets stored in GitHub (except for the managed identity client ID)
- Automatic token exchange for secure deployment
- Federated credentials eliminate long-lived secrets

### Security Benefits

1. **Credential Rotation** - Managed identities automatically handle token refresh
2. **Least Privilege** - Assign only necessary permissions to the managed identity
3. **Audit Trail** - All operations are logged through Azure Activity Log
4. **Zero Trust** - No persistent credentials or passwords in the environment

## Deployment

The infrastructure is deployed automatically via GitHub Actions when changes are pushed to the main branch or manually triggered. The workflow:

1. Authenticates using Azure Service Principal credentials
2. Deploys the Bicep template to East US 2
3. Configures the VM with security tools (Microsoft Defender for Endpoint)
4. Sets up auto-shutdown at 7:00 PM EST daily

## Resources Created

- Virtual Machine (Ubuntu 20.04 LTS) with auto-shutdown at 7:00 PM EST
- Network Interface
- System-assigned Managed Identity
- Custom Script Extension for MDE installation
