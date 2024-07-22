@description('Virtual machine size')
param vmSize string = 'Standard_D2s_v3'

@description('First Azure Region')
param location1 string

@description('Second Azure Region')
param location2 string

@description('Admin username')
param adminUsername string

@description('Admin password')
@secure()
param adminPassword string

var locationNames = [
  location1
  location1
  location2
]
var vmName = 'az104-05-vm'
var nicName = 'az104-05-nic'
var subnetName = 'subnet0'
var VnetName = 'az104-05-vnet'
var pipName = 'az104-05-pip'
var nsgName = 'az104-05-nsg'

resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' = [
  for (item, i) in locationNames: {
    name: concat(vmName, i)
    location: item
    properties: {
      osProfile: {
        computerName: concat(vmName, i)
        adminUsername: adminUsername
        adminPassword: adminPassword
        windowsConfiguration: {
          provisionVmAgent: 'true'
        }
      }
      hardwareProfile: {
        vmSize: vmSize
      }
      storageProfile: {
        imageReference: {
          publisher: 'MicrosoftWindowsServer'
          offer: 'WindowsServer'
          sku: '2019-Datacenter'
          version: 'latest'
        }
        osDisk: {
          createOption: 'fromImage'
        }
        dataDisks: []
      }
      networkProfile: {
        networkInterfaces: [
          {
            properties: {
              primary: true
            }
            id: resourceId('Microsoft.Network/networkInterfaces', concat(nicName, i))
          }
        ]
      }
    }
    dependsOn: [
      concat(nicName, i)
    ]
  }
]

resource Vnet 'Microsoft.Network/virtualNetworks@[variables(\'networkApiVersion\')]' = [
  for (item, i) in locationNames: {
    name: concat(VnetName, i)
    location: item
    properties: {
      addressSpace: {
        addressPrefixes: [
          '10.5${i}.0.0/22'
        ]
      }
      subnets: [
        {
          name: subnetName
          properties: {
            addressPrefix: '10.5${i}.0.0/24'
          }
        }
      ]
    }
  }
]

resource nic 'Microsoft.Network/networkInterfaces@[variables(\'networkApiVersion\')]' = [
  for (item, i) in locationNames: {
    name: concat(nicName, i)
    location: item
    properties: {
      ipConfigurations: [
        {
          name: 'ipconfig1'
          properties: {
            subnet: {
              id: resourceId('Microsoft.Network/virtualNetworks/subnets', concat(VnetName, i), subnetName)
            }
            privateIPAllocationMethod: 'Dynamic'
            publicIpAddress: {
              id: resourceId('Microsoft.Network/publicIpAddresses', concat(pipName, i))
            }
          }
        }
      ]
      networkSecurityGroup: {
        id: resourceId('Microsoft.Network/networkSecurityGroups', concat(nsgName, i))
      }
    }
    dependsOn: [
      concat(pipName, i)
      concat(nsgName, i)
      concat(VnetName, i)
    ]
  }
]

resource pip 'Microsoft.Network/publicIpAddresses@[variables(\'networkApiVersion\')]' = [
  for (item, i) in locationNames: {
    name: concat(pipName, i)
    location: item
    properties: {
      publicIpAllocationMethod: 'Dynamic'
    }
  }
]

resource nsg 'Microsoft.Network/networkSecurityGroups@[variables(\'networkApiVersion\')]' = [
  for (item, i) in locationNames: {
    name: concat(nsgName, i)
    location: item
    properties: {
      securityRules: [
        {
          name: 'default-allow-rdp'
          properties: {
            priority: 1000
            sourceAddressPrefix: '*'
            protocol: 'Tcp'
            destinationPortRange: '3389'
            access: 'Allow'
            direction: 'Inbound'
            sourcePortRange: '*'
            destinationAddressPrefix: '*'
          }
        }
      ]
    }
  }
]
