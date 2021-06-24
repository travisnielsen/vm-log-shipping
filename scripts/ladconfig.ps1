# This script configures the Linux Diagnostics Extension on a virtual machine to forward logs to Azure Event Hub

# Load the configuration from the config.json file
$configuration = Get-Content config.json | ConvertFrom-Json -ErrorAction Stop

# Set variables from the configuration
$subscriptionId = $configuration.subscriptionId
$storageAccountName = $configuration.storageAccountName
$storageAccountResourceGroup = $configuration.storageAccountResourceGroup
$vmName = $configuration.vmNames[0]
$vmResourceGroup = $configuration.vmResourceGroup
$eventHubResourceGroup = $configuration.eventHubResourceGroup
$eventHubNamespace = $configuration.eventHubNamespace
$eventHubName = $configuration.eventHubName
$authRuleName = $configuration.eventHubAuthRuleName

# Connect to Azure
Connect-AzAccount
Set-AzContext -Subscription $subscriptionId

# Get the VM object
$vm = Get-AzVM -Name $vmName -ResourceGroupName $vmResourceGroup

# Enable system-assigned identity on an existing VM
Update-AzVM -ResourceGroupName $VMresourceGroup -VM $vm -IdentityType SystemAssigned

# Update the settings
$publicSettings = Get-Content 'publicSettings-lad3.json' | Out-String
$publicSettings = $publicSettings.Replace('__DIAGNOSTIC_STORAGE_ACCOUNT__', $storageAccountName)
$publicSettings = $publicSettings.Replace('__VM_RESOURCE_ID__', $vm.Id)
$publicSettings | Out-File -FilePath "vmconfig\${vmName}.json"

# If you have your own customized public settings, you can inline those rather than using the preceding template: $publicSettings = '{"ladCfg":  { ... },}'

# Generate a SAS token for the agent to use to authenticate with the storage account
$sasTokenStorage = New-AzStorageAccountSASToken -Service Blob,Table -ResourceType Service,Container,Object -Permission "racwdlup" -Context (Get-AzStorageAccount -ResourceGroupName $storageAccountResourceGroup -AccountName $storageAccountName).Context -ExpiryTime $([System.DateTime]::Now.AddYears(10))
$sasTokenStorageFormatted = $sasTokenStorage.TrimStart('?')

# Generate an SAS token for the Event Hub
$authRule = Get-AzEventHubAuthorizationRule -ResourceGroupName $eventHubResourceGroup -NamespaceName $eventHubNamespace -EventHubName $eventHubName -Name $authRuleName
$startTime = Get-Date
$endTime = $startTime.AddYears(5)
$sasTokenEventHub = New-AzEventHubAuthorizationRuleSASToken -AuthorizationRuleId $authRule.Id -KeyType Primary -ExpiryTime $endTime
$tokenVal = $sasTokenEventHub.SharedAccessSignature.Replace("Primary", "${authRuleName}").Trim()
$eventHubSasUri = "https://" + $eventHubNamespace + ".servicebus.windows.net/" + $eventHubName + "?" + $tokenVal

# Build the protected settings (storage account SAS token)
$protectedSettings = Get-Content 'protectedSettings.json' | Out-String
$protectedSettings = $protectedSettings.Replace('[YOUR_STORAGE_ACCOUNT_NAME]', $storageAccountName)
$protectedSettings = $protectedSettings.Replace('[STORAGE_SAS_TOKEN]', $sasTokenStorageFormatted)
$protectedSettings = $protectedSettings.Replace('[EVENT_HUB_URL_SAS]', $eventHubSasUri)

# Finally, install the extension with the settings you built
Set-AzVMExtension -ResourceGroupName $VMresourceGroup -VMName $vmName -Location $vm.Location -ExtensionType LinuxDiagnostic -Publisher Microsoft.Azure.Diagnostics -Name LinuxDiagnostic -SettingString $publicSettings -ProtectedSettingString $protectedSettings -TypeHandlerVersion 3.0
