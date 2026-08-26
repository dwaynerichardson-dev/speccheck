// SpecCheck lab - one template, every environment.
// Deploy: az deployment group create -g speccheck -<env> -f main.bicep -p env=env>

@allowed(['dev', 'qe', 'rod'])
param env string
param location string = resourceGroup().location

// Key Vault names are globally unique; salt with the resource group id.
var suffix = uniqueString(resourceGroup().id)
var prefix = 'speccheck-${env}'

resource logs 'Microsoft.OperationalInsights/workspaces@2023-09-01'={
  name: '${prefix}-logs'
  location: location
  properties: {
    sku: {name: 'PerGB2018'}
    retentionInDays: 30 // lab settings; raise for real workloads
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02'={
  name: '${prefix}-ai'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logs.id
  }
}


resource containerEnv 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: '${prefix}-cae'
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logs.properties.customerId
        sharedKey: logs.listKeys().primarySharedKey
      }

  } 
  //Week 3 breadcrumb: zone redundancy needs a VNet-integrated environment
    //and is set at creation time - this default (non-redundant) is the
    //tier-3 posture; know where the toggle lives for the tier-1 conversation.

}
}
   
  
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'sc-${env}-${take(suffix,11)}' //vault names: 3-24 chars, globally unique
  location: location
  properties: {
    sku: {family: 'A', name: 'standard'}
    tenantId: subscription().tenantId
    enableRbacAuthorization: true // RBAC, not access policies - current practice

  }
}

output containerEnvName string =  containerEnv.name
output keyVaultName string = keyVault.name
output appInsightsConnectionString string = appInsights.properties.ConnectionString
