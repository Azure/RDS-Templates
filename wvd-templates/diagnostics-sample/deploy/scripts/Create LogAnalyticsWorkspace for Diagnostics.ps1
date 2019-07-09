<#

.SYNOPSIS
Create Log Analytics Workspace

.DESCRIPTION
This script is used to create Log Analytics Workspace

.ROLE
Administrator

#>

Param(

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $LogAnalyticsWorkspaceName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $Location,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $SubscriptionId

)
# Import the AzureRm module
Import-Module Az

# Provide the credentias to authenticate to Azure
$Credential=Get-Credential

# Authenticate to Azure
Login-AzAccount -Credential $Credential

# Select the specified subscription
Select-AzSubscription -SubscriptionId $SubscriptionId

# Check the specified resourcegroup exist/not if not will create new resource group
$CheckRG = Get-AzResourceGroup -Name $ResourceGroupName -Location $Location -ErrorAction SilentlyContinue
if (!$CheckRG) {
    Write-Output "The specified resourcegroup does not exist, creating the resourcegroup $ResourceGroupName"
    New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force
    Write-Output "ResourceGroup $ResourceGroupName created suceessfully"
}

# Create new Log Analytics Workspace
$result=$null

$CheckLAW = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $LogAnalyticsWorkspaceName -ErrorAction SilentlyContinue
if (!$CheckLAW) {
   Write-Output "The workspace $LogAnalyticsWorkspaceName does not exist, Creating..."
   $result = New-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $LogAnalyticsWorkspaceName -Location $Location -Sku free -ErrorAction Ignore
   if($result)
   {
    Write-Output "Log Analytics Workspace created suceessfully"
   }
   else
   {
   Write-Host "The given LogAnalyticsWorkspace name is not unique"
   $LogAnalyticsWorkspaceName = Read-Host -Prompt "Provide unique Log Analytics Workspace Name"
   $result = New-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $LogAnalyticsWorkspaceName -Location $Location -Sku free -ErrorAction Ignore
   Write-Output "Log Analytics Workspace created suceessfully"
   }
}
if($result)
{
Write-Output "Adding the Performance Counters to the Log Analytics Workspace"

# Adding the Logical Disk(% Free Space) Performance counter
New-AzOperationalInsightsWindowsPerformanceCounterDataSource `
                         -ResourceGroupName $ResourceGroupName `
                         -WorkspaceName $LogAnalyticsWorkspaceName `
                         -ObjectName "LogicalDisk" `
                         -InstanceName "*" `
                         -CounterName "% Free Space" `
                         -IntervalSeconds 60 `
                         -Name "Windows Performance Counter"

# Adding the Logical Disk(Avg. Disk Queue Length)Performance counter
New-AzOperationalInsightsWindowsPerformanceCounterDataSource `
                         -ResourceGroupName $ResourceGroupName `
                         -WorkspaceName $LogAnalyticsWorkspaceName `
                         -ObjectName "LogicalDisk" `
                         -InstanceName "C:" `
                         -CounterName "Avg. Disk Queue Length" `
                         -IntervalSeconds 60 `
                         -Name "Windows Performance Counter1"

# Adding the Memory(Available MBytes)Performance counter
New-AzOperationalInsightsWindowsPerformanceCounterDataSource `
                         -ResourceGroupName $ResourceGroupName `
                         -WorkspaceName $LogAnalyticsWorkspaceName `
                         -ObjectName "Memory" `
                         -InstanceName "*" `
                         -CounterName "Available MBytes" `
                         -IntervalSeconds 60 `
                         -Name "Windows Performance Counter2"

# Adding the Processor Information(% Processor Time)Performance counter
New-AzOperationalInsightsWindowsPerformanceCounterDataSource `
                         -ResourceGroupName $ResourceGroupName `
                         -WorkspaceName $LogAnalyticsWorkspaceName `
                         -ObjectName "Processor Information" `
                         -InstanceName "*" `
                         -CounterName "% Processor Time" `
                         -IntervalSeconds 60 `
                         -Name "Windows Performance Counter3"

# Adding the User Input Delay per Session(Max Input Delay)Performance counter
New-AzOperationalInsightsWindowsPerformanceCounterDataSource `
                         -ResourceGroupName $ResourceGroupName `
                         -WorkspaceName $LogAnalyticsWorkspaceName `
                         -ObjectName "User Input Delay per Session" `
                         -InstanceName "*" `
                         -CounterName "Max Input Delay" `
                         -IntervalSeconds 60 `
                         -Name "Windows Performance Counter4"

Write-Output "Performance Counters are successfully added to the workspace"

# Get the Log Analytics Workspace
$Workspace=Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $LogAnalyticsWorkspaceName

# Get the log analytics workspace id
$WorkspaceId=$workspace.CustomerId

Write-Output "The Log Analytics Workspace Id: $WorkspaceId"
}
else
{
Write-Host "Please provide the unique names for LogAnalyticsWorkspace"
}


