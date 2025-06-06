# ThorNetLab Bicep Deployment

This directory contains the complete Bicep Infrastructure as Code (IaC) solution for deploying an Ubuntu VM in Azure using the thornetlab naming scheme.

## Resources Deployed

- **Virtual Network** (`thornetlab-vnet`) - 10.0.0.0/16 address space
- **Subnet** (`thornetlab-subnet`) - 10.0.1.0/24 address space  
- **Network Security Group** (`thornetlab-nsg`) - Allows SSH access on port 22
- **Public IP** (`thornetlab-pip`) - Static IP with DNS label (optional)
- **Network Interface** (`thornetlab-ubuntu-nic`) - Connects VM to subnet
- **Ubuntu VM** (`thornetlab-ubuntu`) - Ubuntu 20.04 LTS with:
  - System-assigned managed identity enabled
  - SSH key authentication (password authentication disabled)
  - Premium SSD storage
  - Microsoft Defender for Endpoint (MDE) extension
  - Auto-shutdown at 7:00 PM EST daily

## Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `location` | string | No | `eastus2` | Azure region (restricted to East US 2) |
| `vmName` | string | No | `thornetlab-ubuntu` | Virtual machine name |
| `adminUsername` | string | No | `azureuser` | Admin username for the VM |
| `sshPublicKey` | string | **Yes** | - | SSH public key for VM access |
| `vmSize` | string | No | `Standard_B2s` | VM size |
| `enablePublicIP` | bool | No | `true` | Whether to create a public IP |

## Deployment

### Prerequisites

1. Azure CLI installed and authenticated
2. Resource group created
3. SSH public key generated

### Generate SSH Key (if needed)

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/thornetlab_rsa
```

### Update Parameters

1. Edit `parameters/lab.parameters.json`
2. Replace `YOUR_SSH_PUBLIC_KEY_HERE` with your actual SSH public key:

```bash
# Get your public key
cat ~/.ssh/thornetlab_rsa.pub
```

### Deploy with Azure CLI

```bash
# Create resource group (if not exists)
az group create --name thornetlab-rg --location "East US 2"

# Deploy the template
az deployment group create \
  --resource-group thornetlab-rg \
  --template-file bicep/main.bicep \
  --parameters @bicep/parameters/lab.parameters.json
```

### Deploy with Custom Parameters

```bash
az deployment group create \
  --resource-group thornetlab-rg \
  --template-file bicep/main.bicep \
  --parameters adminUsername="myuser" \
               sshPublicKey="$(cat ~/.ssh/id_rsa.pub)"
```

## Outputs

After successful deployment, the template provides:

- `publicIPAddress` - Public IP address of the VM (if enabled)
- `fqdn` - Fully qualified domain name
- `sshCommand` - Ready-to-use SSH connection command
- `vmId` - Resource ID of the virtual machine
- `vmPrincipalId` - Principal ID of the VM's managed identity

## SSH Access

### With Public IP (default)

```bash
# Use the output from deployment
ssh azureuser@thornetlab-uniqueid.eastus.cloudapp.azure.com
```

### Without Public IP

Use Azure Bastion or Azure CLI:

```bash
az vm user update \
  --resource-group thornetlab-rg \
  --name thornetlab-ubuntu \
  --username azureuser \
  --ssh-key-value "$(cat ~/.ssh/id_rsa.pub)"

az ssh vm \
  --resource-group thornetlab-rg \
  --name thornetlab-ubuntu
```

## Security Notes

- Password authentication is disabled
- Only SSH key authentication is allowed
- Network security group allows SSH (port 22) from any source
- VM has system-assigned managed identity for Azure resource access
- Microsoft Defender for Endpoint is automatically installed

## Managed Identity Role Assignments

After deployment, assign appropriate roles to the VM's managed identity:

```bash
# Get the VM's managed identity principal ID
VM_PRINCIPAL_ID=$(az vm show --name thornetlab-ubuntu --resource-group thornetlab-rg --query identity.principalId -o tsv)

# Grant reader access to the resource group
az role assignment create \
  --assignee $VM_PRINCIPAL_ID \
  --role "Reader" \
  --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/thornetlab-rg"
```