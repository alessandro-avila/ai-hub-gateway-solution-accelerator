@description('Name of the Cognitive Services Speech service.')
param speechServiceName string
@description('Location for the Cognitive Services Speech service.')
param location string = resourceGroup().location
@description('Tags to be applied to resources.')
param tags object = {}
@description('Name of the managed identity.')
param managedIdentityName string = ''
@description('Name of the Cognitive Services Speech service kind.')
param kind string = 'SpeechServices'

// Networking
@description('Name of the VNet.')
param vnetName string
@description('Location of the VNet.')
param vNetLocation string
@description('Name of the subnet for private endpoints.')
param subnetName string
@description('Resource Group of the VNet.')
param vNetRG string
@description('DNS Zone Resource Group')
param dnsZoneRG string
@description('Speech service DNS zone name')
param speechAiDnsZoneName string
@description('Public network access for the Cognitive Services Speech service.')
param publicNetworkAccess string = 'Disabled'
@description('Speech service private endpoint name.')
param speechAiPrivateEndpointName string
@description('DNS Subscription ID')
param dnsSubscriptionId string

resource vnet 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  name: vnetName
  scope: resourceGroup(vNetRG)
}

// Get existing subnet  
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' existing = {
  name: subnetName
  parent: vnet
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: managedIdentityName
}

resource account 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: speechServiceName
  location: location
  kind: kind
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    publicNetworkAccess: publicNetworkAccess
    customSubDomainName: toLower(speechServiceName)
    networkAcls: {
      defaultAction: 'Deny'
      virtualNetworkRules: [
        {
          id: subnet.id
          ignoreMissingVnetServiceEndpoint: false
        }
      ]
    }
  }
  tags: tags
}

module privateEndpoint '../networking/private-endpoint.bicep' = {
  name: '${account.name}-privateEndpoint'
  params: {
    groupIds: [
      'account'
    ]
    dnsZoneName: speechAiDnsZoneName
    name: speechAiPrivateEndpointName
    privateLinkServiceId: account.id
    location: vNetLocation
    privateEndpointSubnetId: subnet.id
    dnsZoneRG: dnsZoneRG
    dnsSubId: dnsSubscriptionId
  }
}

output speechServiceName string = account.name
output speechServiceEndpointUri string = account.properties.endpoint
