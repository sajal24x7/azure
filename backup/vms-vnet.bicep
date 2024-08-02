param noOfVMs int = 2
param vNetName string = 'sajal-vnet-1'
param vnetAddress string = '10.0.0.0/24'
param subnetName string = 'sajal-subnet-1'
param subnetAddress string = '10.0.0.0/26'
param nsgName string = 'sajal-nsg-1'
param location string = 'eastus'
param vmSize string = 'Standard_DS1_v2'
param adminUser string = 'sajal'
@secure()
param adminPassword string

var vnicPrefix = 'sajal-vnic'
var vmPrefix = 'sajal-vm'
var publicIPPrefix = 'sajal-pip'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vNetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddress
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddress
        }
      }
    ]
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

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2023-11-01' = [for i in range(0,noOfVMs): {
  name: '${publicIPPrefix}-${i}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}]

resource networkInterface 'Microsoft.Network/networkInterfaces@2023-11-01' = [for i in range(0,noOfVMs): {
  name: '${vnicPrefix}-${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddress[i].id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets/', '${vNetName}', '${subnetName}')
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

resource windowsVM 'Microsoft.Compute/virtualMachines@2024-03-01' = [for i in range(0,noOfVMs): {
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
