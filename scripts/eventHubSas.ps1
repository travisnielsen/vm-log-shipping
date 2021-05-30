# From: https://docs.microsoft.com/en-us/rest/api/eventhub/generate-sas-token#powershell

[Reflection.Assembly]::LoadWithPartialName("System.Web")| out-null
$URI="[YOUR_EVENTHUB_NAMESPACE].servicebus.windows.net/vmlogs"
$Access_Policy_Name="RootManageSharedAccessKey"
$Access_Policy_Key="[YOUR_PUBLIC_KEY]"

#Token expires now+300
$Expires=([DateTimeOffset]::Now.ToUnixTimeSeconds())+31536000
$SignatureString=[System.Web.HttpUtility]::UrlEncode($URI)+ "`n" + [string]$Expires
$HMAC = New-Object System.Security.Cryptography.HMACSHA256
$HMAC.key = [Text.Encoding]::ASCII.GetBytes($Access_Policy_Key)
$Signature = $HMAC.ComputeHash([Text.Encoding]::ASCII.GetBytes($SignatureString))
$Signature = [Convert]::ToBase64String($Signature)
$SASToken = "SharedAccessSignature sr=" + [System.Web.HttpUtility]::UrlEncode($URI) + "&sig=" + [System.Web.HttpUtility]::UrlEncode($Signature) + "&se=" + $Expires + "&skn=" + $Access_Policy_Name
$SASToken