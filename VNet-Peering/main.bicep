@description('Name for vNet 1')
@minLength(2)
@maxLength(64)
param vnet1Name string = 'vNet1-${location1}'

@description('Name for vNet 2')
@minLength(2)
@maxLength(64)
param vnet2Name string = 'vNet2-${location2}'

@description('Location for the Vnet 1 and resources inside it: ')
param location1 string = 'eastus'

@description('Location for the Vnet 1 and resources inside it: ')
param location2 string = 'centralindia'

@description('Name for virtual machine 1: ')
@minLength(1)
@maxLength(64)
param vm1Name string = 'vm-1-${location1}'

@description('Name for virtual machine 2: ')
@minLength(1)
@maxLength(64)
param vm2Name string = 'vm-2-${location2}'

@description('Unique DNS Name for the Public IP used to access the Virtual Machine 1: ')
param dnsLabelPrefix1 string = toLower('${vm1Name}-${uniqueString(resourceGroup().id)}')

@description('Unique DNS Name for the Public IP used to access the Virtual Machine 2: ')
param dnsLabelPrefix2 string = toLower('${vm2Name}-${uniqueString(resourceGroup().id)}')

@description('Name of the admin of the virtual machine: ')
param adminUsername string = 'azureuser'

@description('Password of the admin account of virtual machine: ')
@secure()
param adminPassword string

var vnet1Config = {
  addressSpacePrefix: '10.0.0.0/24'
  subnetName: 'subnet1'
  subnetPrefix: '10.0.0.0/24'
}
var vnet2Config = {
  addressSpacePrefix: '192.168.0.0/24'
  subnetName: 'subnet1'
  subnetPrefix: '192.168.0.0/24'
}
var storageAccountType = 'Standard_LRS'
var storageAccount1Name = 'stacc${uniqueString(vm1Name)}'
var storageAccount2Name = 'stacc${uniqueString(vm2Name)}'


resource networkSecurityGroup1 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: 'nsg-${vnet1Name}'
  location: location1
  properties: {
    securityRules: [
      {
        name: 'AllowSSHInbound'
        properties: {
          description: 'Allow SSH Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource networkSecurityGroup2 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: 'nsg-${vnet2Name}'
  location: location2
  properties: {
    securityRules: [
      {
        name: 'AllowSSHInbound'
        properties: {
          description: 'Allow SSH Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource vNet1 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnet1Name
  location: location1
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet1Config.addressSpacePrefix
      ]
    }
    subnets: [
      {
        name: vnet1Config.subnetName
        properties: {
          addressPrefix: vnet1Config.subnetPrefix
        }
      }
    ]
  }
}

resource vNet2 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnet2Name
  location: location2
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet2Config.addressSpacePrefix
      ]
    }
    subnets: [
      {
        name: vnet2Config.subnetName
        properties: {
          addressPrefix: vnet2Config.subnetPrefix
        }
      }
    ]
  }
}

resource vnetPeering1 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-09-01' = {
  parent: vNet1
  name: 'peer-${vnet1Name}-${vnet2Name}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vNet2.id
    }
  }
}

resource vnetPeering2 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-09-01' = {
  parent: vNet2
  name: 'peer-${vnet2Name}-${vnet1Name}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vNet1.id
    }
  }
}

resource publicIPAddress1 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: '${vm1Name}-pip'
  location: location1
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix2
    }
  }
}

resource publicIPAddress2 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: '${vm2Name}-pip'
  location: location2
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix1
    }
  }
}

resource nic1 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: '${vm1Name}-nic'
  location: location1
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddress1.id
          }
          subnet: {
            id: vNet1.properties.subnets[0].id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroup1.id
    }
  }
}

resource nic2 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: '${vm2Name}-nic'
  location: location2
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddress2.id
          }
          subnet: {
            id: vNet2.properties.subnets[0].id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroup2.id
    }
  }
}

resource storageAccount1 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccount1Name
  location: location1
  kind: 'StorageV2'
  sku: {
    name: storageAccountType
  }
}

resource storageAccount2 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccount2Name
  location: location2
  kind: 'StorageV2'
  sku: {
    name: storageAccountType
  }
}

resource vm1 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vm1Name
  location: location1
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B1s'
    }
    osProfile: {
      computerName: vm1Name
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest' 
      }
      osDisk: { 
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic1.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageAccount1.properties.primaryEndpoints.blob
      }
    }
  }
}

resource vm2 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vm2Name
  location: location2
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B1s'
    }
    osProfile: {
      computerName: vm2Name
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest' 
      }
      osDisk: { 
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic2.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageAccount2.properties.primaryEndpoints.blob
      }
    }
  }
}
