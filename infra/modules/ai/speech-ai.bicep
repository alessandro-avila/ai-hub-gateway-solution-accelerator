@description('Name of the Cognitive Services Speech service.')  
param speechServiceName string  
  
@description('Location for the Cognitive Services Speech service.')  
param location string = resourceGroup().location  
  
@description('Tags to be applied to resources.')  
param tags object = {} 

@description('Name of the managed identity.')
param managedIdentityName string = ''
  
@description('Name of the VNet.')  
param vnetName string  
  
@description('Name of the subnet for private endpoints.')  
param subnetName string  
  
@description('Resource Group of the VNet.')  
param vnetResourceGroup string  
  
@description('DNS Zone Resource Group')  
param dnsZoneRG string  
  
@description('DNS Subscription ID')  
param dnsSubscriptionId string  
  
resource vnet 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {  
  name: vnetName  
  scope: resourceGroup(vnetResourceGroup)  
}  
  
// Get existing subnet  
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' existing = {  
  name: subnetName  
  parent: vnet
}  

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: managedIdentityName
}
  
resource speechService 'Microsoft.CognitiveServices/accounts@2023-05-01' = {  
  name: speechServiceName  
  location: location  
  kind: 'SpeechServices'  
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
  
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {  
  name: '${speechServiceName}-pe'  
  location: location  
  properties: {  
    subnet: {  
      id: subnet.id  
    }  
    privateLinkServiceConnections: [  
      {  
        name: 'speechServiceLink'  
        properties: {  
          privateLinkServiceId: speechService.id  
          groupIds: [  
            'account'  
          ]  
        }  
      }  
    ]  
  }  
}  
  
resource privateDnsZoneGroup 'Microsoft.Network/privateDnsZoneGroups@2021-05-01' = {  
  name: '${speechServiceName}-dnsZoneGroup'  
  location: location  
  properties: {  
    privateDnsZoneConfigs: [  
      {  
        name: 'speechDnsZone'  
        properties: {  
          privateDnsZoneId: resourceId(dnsZoneRG, 'Microsoft.Network/privateDnsZones', 'privatelink.cognitiveservices.azure.com')  
        }  
      }  
    ]  
    privateEndpointId: privateEndpoint.id  
  }  
}  
  
output speechServiceName string = speechService.name  
output speechServiceEndpointUri string = '${speechService.properties.endpoint}'  
