param location1 string = 'eastus'
param location2 string = 'westus'
param vmSize string = 'Standard_DS1_v2'
param adminUser string = 'sajal'
@secure()
param adminPassword string

var vnetPrefix = 'sajalvnet'
var subnetPrefix = 'sajalsubnet'
var vnicPrefix = 'sajalvnic'
var vmPrefix = 'sajalvm'
var locations = [
  location1
  location1
  location2
]

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-11-01' = [for (location,i) in locations: {
  name: '${vnetPrefix}-${i}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.5${i}.0.0/22'
      ]
    }
    subnets: [
      {
        name: '${subnetPrefix}-${i}'
        properties: {
          addressPrefix: '10.5${i}.0.0/24'
        }
      }
    ]
  }
}]

resource networkInterface 'Microsoft.Network/networkInterfaces@2023-11-01' = [for (location,i) in locations: {
  name: '${vnicPrefix}-${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.5${i}.0.4'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets/', '${vnetPrefix}-${i}', '${subnetPrefix}-${i}')            
          }
        }
      }
    ]
  }
}]

resource windowsVM 'Microsoft.Compute/virtualMachines@2024-03-01' = [for (location,i) in locations: {
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
    virtualNetwork
    networkInterface
  ]
}
]
