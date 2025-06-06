param location string = resourceGroup().location
param vmName string = 'thornetlab-ubuntu'
param adminUsername string = 'admin'
@secure()
param adminPassword string

resource nic 'Microsoft.Network/networkInterfaces@2023-02-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '/subscriptions/e440a65b-7418-4865-9821-88e411ffdd5b/resourceGroups/thornetlab-rg/providers/Microsoft.Network/virtualNetworks/thornetlab-vnet/subnets/default'
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-focal'
        sku: '20_04-lts'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

// Custom Script Extension to install MDE
resource mdeInstall 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = {
  name: '${vmName}/installMDE'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/microsoft/mdefordemos/main/linux/install_mde.sh'
      ]
      commandToExecute: 'bash install_mde.sh'
    }
  }
}
