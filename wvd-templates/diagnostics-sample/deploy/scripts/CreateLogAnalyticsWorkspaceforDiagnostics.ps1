<#

.SYNOPSIS
Create Log Analytics workspace

.DESCRIPTION
This script is used to create Log Analytics workspace

.ROLE
Administrator

#>

Param(

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $ResourcegroupName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $LogAnalyticsworkspaceName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $Location,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $SubscriptionId

)
# Import the Az module
Import-Module Az

# Get the context
$context= Get-AzContext
if($context -eq $null)
{
  Write-Error "Please authenticate to Azure using Login-AzAccount cmdlet and then run this script"
  exit
}

# Select the specified subscription
Select-AzSubscription -SubscriptionId $SubscriptionId

# Get Role Assignments for the Context
$RoleAssignment = (Get-AzRoleAssignment -SignInName $context.Account)

if($RoleAssignment.RoleDefinitionName -eq "Owner" -or $RoleAssignment.RoleDefinitionName -eq "Contributor")
{

# Check the specified resourcegroup exist/not if not will create new resource group in your Azure subscription
$CheckRG = Get-AzResourceGroup -Name $ResourcegroupName -Location $Location -ErrorAction SilentlyContinue
if (!$CheckRG) {
    Write-Output "The specified resourcegroup does not exist, creating the resourcegroup $ResourcegroupName"
    New-AzResourceGroup -Name $ResourcegroupName -Location $Location -Force
    Write-Output "ResourceGroup $ResourcegroupName created suceessfully"
}

# Create new Log Analytics workspace
$result=$null

$CheckLAW = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourcegroupName -Name $LogAnalyticsworkspaceName -ErrorAction SilentlyContinue
if (!$CheckLAW) {
   Write-Output "The Log Analytics workspace with the name $LogAnalyticsworkspaceName does not exist, creating..."
   $result = New-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $LogAnalyticsworkspaceName -Location $Location -Sku free -ErrorAction Ignore
   if($result)
   {
    Write-Output "Log Analytics workspace created suceessfully"
   }
   else
   {
   Write-Host "The given Log Analytics workspace name is not unique"
   $LogAnalyticsworkspaceName = Read-Host -Prompt "Provide an unique Log Analytics workspace Name"
   $result = New-AzOperationalInsightsWorkspace -ResourceGroupName $ResourcegroupName -Name $LogAnalyticsworkspaceName -Location $Location -Sku free -ErrorAction Ignore
   Write-Output "Log Analytics workspace created suceessfully"
   }
}
if($result)
{
Write-Output "Adding the Performance Counters to the Log Analytics workspace"

# Adding the Logical Disk(% Free Space) Performance counter
New-AzOperationalInsightsWindowsPerformanceCounterDataSource `
                         -ResourceGroupName $ResourcegroupName `
                         -WorkspaceName $LogAnalyticsworkspaceName `
                         -ObjectName "LogicalDisk" `
                         -InstanceName "*" `
                         -CounterName "% Free Space" `
                         -IntervalSeconds 60 `
                         -Name "Windows Performance Counter"

# Adding the Logical Disk(Avg. Disk Queue Length)Performance counter
New-AzOperationalInsightsWindowsPerformanceCounterDataSource `
                         -ResourceGroupName $ResourcegroupName `
                         -WorkspaceName $LogAnalyticsworkspaceName `
                         -ObjectName "LogicalDisk" `
                         -InstanceName "C:" `
                         -CounterName "Avg. Disk Queue Length" `
                         -IntervalSeconds 60 `
                         -Name "Windows Performance Counter1"

# Adding the Memory(Available MBytes)Performance counter
New-AzOperationalInsightsWindowsPerformanceCounterDataSource `
                         -ResourceGroupName $ResourcegroupName `
                         -WorkspaceName $LogAnalyticsworkspaceName `
                         -ObjectName "Memory" `
                         -InstanceName "*" `
                         -CounterName "Available MBytes" `
                         -IntervalSeconds 60 `
                         -Name "Windows Performance Counter2"

# Adding the Processor Information(% Processor Time)Performance counter
New-AzOperationalInsightsWindowsPerformanceCounterDataSource `
                         -ResourceGroupName $ResourcegroupName `
                         -WorkspaceName $LogAnalyticsworkspaceName `
                         -ObjectName "Processor Information" `
                         -InstanceName "*" `
                         -CounterName "% Processor Time" `
                         -IntervalSeconds 60 `
                         -Name "Windows Performance Counter3"

# Adding the User Input Delay per Session(Max Input Delay)Performance counter
New-AzOperationalInsightsWindowsPerformanceCounterDataSource `
                         -ResourceGroupName $ResourceGroupName `
                         -WorkspaceName $LogAnalyticsworkspaceName `
                         -ObjectName "User Input Delay per Session" `
                         -InstanceName "*" `
                         -CounterName "Max Input Delay" `
                         -IntervalSeconds 60 `
                         -Name "Windows Performance Counter4"

Write-Output "Performance Counters are successfully added to the Log Analytics workspace"

# Get the Log Analytics workspace
$Workspace=Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourcegroupName -Name $LogAnalyticsworkspaceName

# Get the Log Analytics workspace id
$WorkspaceId=$workspace.CustomerId

Write-Output "The Log Analytics workspace Id: $WorkspaceId"
}
else
{
Write-Host "Please provide the unique names for Log Analytics workspace"
}
}
else
{
Write-Output "Authenticated user should have the Owner/Contributor permissions"
}


