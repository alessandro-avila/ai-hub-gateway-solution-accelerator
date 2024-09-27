@description('Name of the Container App environment. Leave blank to use default naming conventions.')
param containerAppEnvName string = ''

@description('Name of the Container App. Leave blank to use default naming conventions.')
param containerAppName string = ''

@description('Location for the Container App.')
param location string

@description('Name of the VNet.')
param vnetName string

@description('Name of the subnet for Container Apps.')
param subnetName string

@description('Resource Group of the VNet.')
param vnetResourceGroup string

@description('Tags to be applied to resources.')
param tags object

@description('Log Analytics Workspace resource ID.')
param logAnalyticsWorkspaceId string

resource containerAppEnv 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: !empty(containerAppEnvName) ? containerAppEnvName : 'containerappenv-${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    vnetConfiguration: {
      infrastructureSubnetId: resourceId(
        vnetResourceGroup,
        'Microsoft.Network/virtualNetworks/subnets',
        vnetName,
        subnetName
      )
    }
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: reference(logAnalyticsWorkspaceId, '2021-06-01').customerId
        sharedKey: listKeys(logAnalyticsWorkspaceId, '2021-06-01').primarySharedKey
      }
    }
  }
  tags: tags
}

resource containerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: !empty(containerAppName) ? containerAppName : 'containerapp-${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      ingress: {
        external: true
        targetPort: 80
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      }
    }
    template: {
      containers: [
        {
          name: 'app'
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          resources: {
            cpu: '0.25'
            memory: '0.5Gi'
          }
        }
      ]
    }
  }
  tags: tags
}

output containerAppEnvName string = containerAppEnv.name
output containerAppName string = containerApp.name
