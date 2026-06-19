#requires -Version 5.1
[CmdletBinding()]
param([string]$OutputPath)
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
if([string]::IsNullOrWhiteSpace($OutputPath)){$OutputPath=Join-Path ([Environment]::GetFolderPath('Desktop')) 'Firewall_Inventory_Reports'}
New-Item -ItemType Directory -Path $OutputPath -Force|Out-Null
$profiles=Get-NetFirewallProfile -ErrorAction SilentlyContinue|Select-Object Name,Enabled,DefaultInboundAction,DefaultOutboundAction,NotifyOnListen,AllowInboundRules
$rules=Get-NetFirewallRule -ErrorAction SilentlyContinue|Where-Object Enabled -eq 'True'|Select-Object DisplayName,Name,Profile,Direction,Action,Enabled,PolicyStoreSourceType
$summary=$rules|Group-Object Direction,Action|ForEach-Object{[PSCustomObject]@{Direction=$_.Group[0].Direction;Action=$_.Group[0].Action;Count=$_.Count}}
$profiles|Export-Csv (Join-Path $OutputPath "firewall_profiles_$stamp.csv") -NoTypeInformation -Encoding UTF8
$rules|Export-Csv (Join-Path $OutputPath "enabled_firewall_rules_$stamp.csv") -NoTypeInformation -Encoding UTF8
$summary|Export-Csv (Join-Path $OutputPath "rule_summary_$stamp.csv") -NoTypeInformation -Encoding UTF8
@{Computer=$env:COMPUTERNAME;Generated=Get-Date;Profiles=$profiles;Rules=$rules;Summary=$summary}|ConvertTo-Json -Depth 6|Set-Content (Join-Path $OutputPath "firewall_inventory_$stamp.json") -Encoding UTF8
$html="<h1>Firewall Rule Inventory - $env:COMPUTERNAME</h1><p>Generated $(Get-Date)</p><h2>Profiles</h2>$($profiles|ConvertTo-Html -Fragment)<h2>Summary</h2>$($summary|ConvertTo-Html -Fragment)<h2>Enabled Rules</h2>$($rules|ConvertTo-Html -Fragment)"
$html|ConvertTo-Html -Title 'Firewall Rule Inventory'|Set-Content (Join-Path $OutputPath "firewall_inventory_$stamp.html") -Encoding UTF8
Write-Host "Reports saved to: $OutputPath" -ForegroundColor Green
