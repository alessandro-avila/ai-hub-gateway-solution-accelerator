@description('Name of the Service Bus Namespace.')  
param name string

@description('Name of the Service Bus Queue.')
param serviceBusQueueName string = 'ai-queue'

@description('Location for the Service Bus Namespace.')  
param location string  

@description('SKU for the Service Bus Namespace.')
param sku string = 'Standard'
  
@description('Tags to be applied to resources.')  
param tags object = {}  
  
@description('Maximum size of the queue in megabytes.')  
@allowed([1024, 2048, 3072, 4096, 5120])  
param maxQueueSizeInMB int = 1024  
  
@description('Name of the VNet.')  
param vNetName string  
  
@description('Name of the subnet for Service Bus.')  
param subnetName string

@description('Name of the DNS Zone for Service Bus.')
param serviceBusDnsZoneName string

@description('Name of the Private Endpoint for Service Bus.')
param serviceBusPrivateEndpointName string
  
@description('Resource Group of the VNet.')  
param vNetRG string  

@description('DNS Zone Resource Group')  
param dnsZoneRG string  
  
@description('DNS Subscription ID')  
param dnsSubscriptionId string  
  
resource vnet 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {  
  name: vNetName
  scope: resourceGroup(vNetRG)
}  
  
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' existing = {  
  name: subnetName
  parent: vnet
}  
  
resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-06-01-preview' = {  
  name: name
  location: location
  sku: {
    name: sku
    tier: sku
  } 
  tags: union(tags, { 'azd-service-name': name })
}  
  
resource serviceBusQueue 'Microsoft.ServiceBus/namespaces/queues@2021-06-01-preview' = {  
  parent: serviceBusNamespace  
  name: serviceBusQueueName  
  properties: {  
    maxSizeInMegabytes: maxQueueSizeInMB  
    defaultMessageTimeToLive: 'P14D' // 14 days  
    enablePartitioning: true  
  }  
}  
  
module privateEndpoint '../networking/private-endpoint.bicep' = {
  name: '${serviceBusNamespace.name}-privateEndpoint'
  params: {
    groupIds: [
      'namespace'
    ]
    dnsZoneName: serviceBusDnsZoneName
    name: serviceBusPrivateEndpointName
    privateLinkServiceId: serviceBusNamespace.id
    location: location
    dnsZoneRG: dnsZoneRG
    privateEndpointSubnetId: subnet.id
    dnsSubId: dnsSubscriptionId
  }
}
  
output name string = serviceBusNamespace.name  
output serviceBusQueueName string = serviceBusQueue.name  
