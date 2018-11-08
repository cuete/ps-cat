param ([string]$sub,[string]$rgroup,[string]$dbserver)

Write-Host "This script adds, modifies or removes a firewall rule on a Azure SQL Server."
Write-Host "./firewallrule.ps1 -sub [subscription id] -rgroup [resource group name] -dbserver [database servre name]`n"

if (!$sub) {
    $sub = Read-Host -Prompt "Subscription id?" }

Select-AzureRmSubscription -SubscriptionId $sid

if (!$rgroup) {
    $rgroup = Read-Host -Prompt "Resource group? (name)" }
    
if (!$dbserver) {
    $dbserver = Read-Host -Prompt "SQL DB server name? (name)" }

Get-AzureRmSqlServerFirewallRule -ResourceGroupName $rgroup -ServerName $dbserver | Select-Object -Property ("FirewallRuleName", "StartIpAddress", "EndIpAddress") | Format-Table -AutoSize

$action = Read-Host "Add/modify, remove firewall rule or quit? (a|r|q)"

switch ($action)
{
    a {
        $rulename = Read-Host -Prompt "Name of rule (existing or new)"
        $ip = Read-Host -Prompt "IP: "

        $ip = $ip.Split(".")
        $startIp = $ip[0] + "." + $ip[1] + "." + $ip[2] + ".0"
        $endIp = $ip[0] + "." + $ip[1] + "." + $ip[2] + ".255"

        Set-AzureRmSqlServerFirewallRule -ResourceGroupName $rgroup -ServerName $dbserver -FirewallRuleName $rulename -StartIpAddress $startIp -EndIpAddress $endIp
    }
    r {
        $rulename = Read-Host -Prompt "Name of rule to remove"
        Remove-AzureRmSqlServerFirewallRule -ResourceGroupName $rgroup -ServerName $dbserver -FirewallRuleName $rulename
    }
    q { Write-Host "Bye.`n"}
}
