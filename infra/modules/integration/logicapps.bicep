@description('Name of the Logic App.')
param logicAppName string = 'ai-logicapp'

@description('Location for the Service Bus Namespace.')
param location string

@description('Tags to be applied to resources.')
param tags object = {}

@description('Name of the VNet.')
param vNetName string

@description('Name of the subnet for Service Bus.')
param subnetName string

@description('Resource Group of the VNet.')
param vNetRG string

@description('DNS Zone Resource Group')
param dnsZoneRG string

@description('DNS Subscription ID')
param dnsSubscriptionId string

@description('Private endpoint name for the Logic App.')
param logicAppPrivateEndpointName string

@description('DNS Zone name for the Logic App.')
param logicAppDnsZoneName string

resource vnet 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  name: vNetName
  scope: resourceGroup(vNetRG)
}

// Get existing subnet
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' existing = {
  name: subnetName
  parent: vnet
}

resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  tags: union(tags, { 'azd-service-name': logicAppName })
  properties: {
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      actions: {}
      contentVersion: '1.0.0.0'
      outputs: {}
      triggers: {}
    }
    parameters: {}
  }
}

// module privateEndpoint '../networking/private-endpoint.bicep' = {
//   name: '${logicApp.name}-privateEndpoint'
//   params: {
//     groupIds: [
//       'workflow'
//     ]
//     dnsZoneName: logicAppDnsZoneName
//     name: logicAppPrivateEndpointName
//     privateLinkServiceId: logicApp.id
//     location: location
//     dnsZoneRG: dnsZoneRG
//     privateEndpointSubnetId: subnet.id
//     dnsSubId: dnsSubscriptionId
//   }
// }

output logicAppName string = logicApp.name
