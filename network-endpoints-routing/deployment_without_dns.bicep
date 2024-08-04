param vNetName string = 'sajal-vnet-1'
param nsgName string = 'sajal-nsg-1'
param location string = 'eastus'
param vmSize string = 'Standard_DS1_v2'
param adminUser string = 'sajal'
@secure()
param adminPassword string

var subnetPrefix = 'sajal-subnet'
var vnicPrefix = 'sajal-vnic'
var vmPrefix = 'sajal-vm'
var publicIPPrefix = 'sajal-pip'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vNetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.40.0.0/20'
      ]
    }
    subnets: [for i in range(0,2): {
      name: '${subnetPrefix}-${i}'
      properties: {
        addressPrefix: '10.40.${i}.0/24'
      }
    }]
  }
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowRDPAccess'
        properties: {
          description: 'Allow RDP access on port 3389'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
  dependsOn: [
    virtualNetwork
  ]
}

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2023-11-01' = [for i in range(0,2): {
  name: '${publicIPPrefix}-${i}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}]

resource networkInterface 'Microsoft.Network/networkInterfaces@2023-11-01' = [for i in range(0,2): {
  name: '${vnicPrefix}-${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.40.${i}.4'
          publicIPAddress: {
            id: publicIPAddress[i].id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets/', '${vNetName}', '${subnetPrefix}-${i}')
          }          
        }
      }      
    ]
    networkSecurityGroup: {
      id: networkSecurityGroup.id
    }
  }
  dependsOn:[
    virtualNetwork
    publicIPAddress
  ]
}]

resource windowsVM 'Microsoft.Compute/virtualMachines@2024-03-01' = [for i in range(0,2): {
  name: '${vmPrefix}-${i}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: '${vmPrefix}-${i}'
      adminUsername: adminUser
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface[i].id
        }
      ]
    }
  }
  dependsOn: [
    networkInterface
  ]
}
]
