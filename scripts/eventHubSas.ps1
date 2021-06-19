$rgName = ""
$nameSpace = ""
$eventHubName = ""
$authRuleName = ""
$authRule = Get-AzEventHubAuthorizationRule -ResourceGroupName $rgName -NamespaceName $nameSpace -EventHubName $eventHubName -Name $authRuleName
$startTime = Get-Date
$endTime = $startTime.AddYears(1)
$sasToken = New-AzEventHubAuthorizationRuleSASToken -AuthorizationRuleId $authRule.Id -KeyType Primary -ExpiryTime $endTime
$tokenVal = $sasToken.SharedAccessSignature.Replace("Primary", "${authRuleName}").Trim()
$result = "https://" + $nameSpace + ".servicebus.windows.net/" + $eventHubName + "?" + $tokenVal
$result
