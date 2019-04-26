
<#
.SYNOPSIS
	ScalingScriptHACoreHelper.ps1 - Script module that provides all functions used for HA implementation
.DESCRIPTION
  	ScalingScriptHACoreHelper.ps1 - Script module that provides all functions used for HA implementation
#>
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$ErrorActionPreference = "Stop"

enum LogLevel
{
    Info
    Warning
    Error
}

enum HAStatuses
{
    Initializing
    Running
    Completed
    Failed
}

enum ExecCodes
{
    ExecInProgressByOwner
    ExecInProgressByMe
    TakeOverThresholdLongRun
    TakeOverThreshold
    OwnershipRenewal
    ExitOwnerWithinThreshold
    UpdateFromOnwer
    NoLongerOwner
    ErrorGettingUpdatedOwnerInfo
	OwnerLogCleanUp
}

class PsOwnerToken
{
    [string]$Owner = [string]::Empty
    [datetime]$LastUpdateUTC=([System.DateTime]::UtcNow)
    [HAStatuses]$Status=[HAStatuses]::Initializing
    [int]$TakeOverThresholdMin=0
    [int]$LongRunningTakeOverThresholdMin=0
    [string]$ActivityId=[string]::Empty
    [bool]$ShouldExit=$false

    PsOwnerToken() {}

    PsOwnerToken([string]$Owner, [datetime]$LastUpdateUTC, [HAStatuses]$Status=[HAStatuses]::Initializing, [int]$TakeOverThresholdMin, [int]$LongRunningTakeOverThresholdMin, [string]$ActivityId)
    {
        $this.Owner = $Owner
        $this.LastUpdateUTC = $LastUpdateUTC
        $this.Status = $Status
        $this.TakeOverThresholdMin = $TakeOverThresholdMin
        $this.LongRunningTakeOverThresholdMin = $LongRunningTakeOverThresholdMin
        $this.ActivityId = $ActivityId
    }

    [object] GetPropertiesAsHashTable() {
        return @{ "Owner"=$this.Owner;
                  "LastUpdateUTC"=$this.LastUpdateUTC;
                  "Status"=($this.Status).ToString();
                  "TakeOverThresholdMin"=$this.TakeOverThresholdMin
                  "LongRunningTakeOverThresholdMin"=$this.LongRunningTakeOverThresholdMin
                  "ActivityId"=$this.ActivityId}
    }
}

function RandomizedDelay
{
    param
    (
        [int]$MinimumMs=500,
        [int]$MaximumMs=2000
    )
    
    # Randomizing start
    [int]$TicksSubset = (Get-Date).Ticks.Tostring().Substring((Get-Date).Ticks.ToString().Length-9)
    [int]$PSProcessId = (Get-Process powershell | Sort-Object cpu -Descending )[0].id
    [int]$RandomMs = (Get-Random -SetSeed ($TicksSubset+$PSProcessId) -Minimum $MinimumMs -Maximum $MaximumMs)
    Start-Sleep -Milliseconds $RandomMs
}

function Add-TableLog
{
    <#
    .SYNOPSIS
        Add a log entry into storage table
    #>
    param
    (
        [string]$EntityName,
        [string]$OwnerStatus,
        [string]$ExecCode,
        [string]$Message,
        [logLevel]$Level,
        [string]$ActivityId,
        $LogTable
    )

    $LogTimeStampUTC = ([System.DateTime]::UtcNow)

    # Creating job submission information
    $logEntryId = [guid]::NewGuid().Guid
    [hashtable]$logProps = @{ "LogTimeStampUTC"=$LogTimeStampUTC;
                              "OwnerStatus"=$OwnerStatus;
                              "ExecCode"=$ExecCode;
                              "ActivityId"=$ActivityId;
                              "EntityName"=$EntityName;
                              "Message"=$message;
                              "LogLevel"=$level.ToString()}

    Add-AzTableRow -table $logTable -partitionKey $ActivityId -rowKey $logEntryId -property $logProps | Out-null
}


function GetHaOwnerTokenInfo
{
    <#
    .SYNOPSIS
        Returns current values of OwnerToken
    #>
    param
    (
        $HaTable,
        [string]$PartitionKey,
        [string]$RowKey,
        [string]$Owner
    )

    # Initializing owner record if it does not exist yet
    $OwnerToken = $null
    $OwnerRow = Get-AzTableRow -Table $HaTable -PartitionKey $PartitionKey -RowKey $RowKey

    if ($OwnerRow -ne $null)
    {
        $OwnerToken = [PSOwnerToken]::new($OwnerRow.Owner,$OwnerRow.LastUpdateUTC,$OwnerRow.Status,$OwnerRow.TakeOverThresholdMin,$OwnerRow.LongRunningTakeOverThresholdMin,$OwnerRow.ActivityId)
    }

    return $OwnerToken
}

function GetHaOwnerToken
{
    <#
    .SYNOPSIS
        Returns the OwnerToken, upadtes the ha table and set value of ShouldExit
    #>
    param
    (
        $HaTable,
        $LogTable,
        [string]$PartitionKey,
        [string]$RowKey,
        [string]$Owner,
        [int]$TakeOverMin,
        [int]$LongRunningTakeOverMin,
        [string]$ActivityId
    )

    # Initializing owner record if it does not exist yet
    RandomizedDelay -MinimumMs 1000 -MaximumMs 10000

    $OwnerRow = Get-AzTableRow -Table $HaTable -PartitionKey $PartitionKey -RowKey $RowKey

    if ($OwnerRow -eq $null)
    {
        $OwnerToken = [PSOwnerToken]::new($Owner,([datetime]::UtcNow),[HAStatuses]::Running,$TakeOverMin,$LongRunningTakeOverMin,$ActivityId)
        Add-AzTableRow -table $HaTable -partitionKey $PartitionKey -rowKey $RowKey -property $OwnerToken.GetPropertiesAsHashTable() | Out-Null

        $msg = "Created new owner record"
        GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
    }
    else
    {
        $OwnerToken = [PSOwnerToken]::new($OwnerRow.Owner,$OwnerRow.LastUpdateUTC,$OwnerRow.Status,$OwnerRow.TakeOverThresholdMin,$OwnerRow.LongRunningTakeOverThresholdMin,$OwnerRow.ActivityId)
    }

    $msg = "$($OwnerToken.GetPropertiesAsHashTable() | ConvertTo-Json -Compress)"
    GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable -Owner $Owner -ActivityId $ActivityId

    # Check last time if it is still owner
    RandomizedDelay -MinimumMs 1000 -MaximumMs 10000
    $LatestOwnerToken = GetHaOwnerTokenINfo -PartitionKey $PartitionKey -RowKey $RowKey -HaTable $HaTable
    if ($LatestOwnerToken -ne $null)
    {
        if ($LatestOwnerToken.Owner -ne $OwnerToken.Owner)
        {
            $OwnerToken = $LatestOwnerToken
        }
    }

    # Deciding whether or not move forward, get ownership or exit
    $LastUpdateInMinutes = (([System.DateTime]::UtcNow).Subtract($OwnerToken.LastUpdateUTC).TotalMinutes) 

    if ($OwnerToken.Status -eq [HAStatuses]::Running)
    {
        if(($OwnerToken.Owner -ne $Owner) -and ($LastUpdateInMinutes -lt $OwnerToken.LongRunningTakeOverThresholdMin))
        {
            $msg = "Exiting due to execution in progress by another owner `($($OwnerToken.Owner)`)"
            GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $LogTable -ExecutionCode ([ExecCodes]::ExecInProgressByOwner) -Owner $Owner -ActivityId $ActivityId
            $OwnerToken.ShouldExit = $true
        }
        elseif (($OwnerToken.Owner -eq $Owner) -and ($OwnerToken.ActivityId -ne $ActivityId) -and ($LastUpdateInMinutes -lt $OwnerToken.LongRunningTakeOverThresholdMin)) 
        {
            $msg = "Exiting due to execution in progress by same owner `($($OwnerToken.Owner)`) and this is a new process"
            GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $LogTable -ExecutionCode ([ExecCodes]::ExecInProgressByMe) 
            $OwnerToken.ShouldExit = $true
        }
        elseif ($LastUpdateInMinutes -gt $OwnerToken.LongRunningTakeOverThresholdMin)
        {
            $msg =  "Taking over from current owner `($($OwnerToken.Owner)`) due to staleness and last update being greater than long running threshold $($OwnerToken.LongRunningTakeOverThresholdMin)"
            GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $LogTable -ExecutionCode ([ExecCodes]::TakeOverThresholdLongRun) -Owner $Owner -ActivityId $ActivityId

            $OwnerToken.Status = [HAStatuses]::Running
            $OwnerToken.LastUpdateUTC = [System.DateTime]::UtcNow
            $OwnerToken.ActivityId = $ActivityId
            $OwnerToken.Owner = $Owner
            Add-AzTableRow -table $HaTable -partitionKey $PartitionKey -rowKey $RowKey -property $OwnerToken.GetPropertiesAsHashTable() -UpdateExisting | Out-Null
        }
    }
    elseif (($OwnerToken.Status -ne [HAStatuses]::Running) -and ($OwnerToken.Owner -eq $Owner))
    {
        $OwnerToken.Status = [HAStatuses]::Running
        $OwnerToken.LastUpdateUTC = [System.DateTime]::UtcNow
        $OwnerToken.ActivityId = $ActivityId
        Add-AzTableRow -table $HaTable -partitionKey $PartitionKey -rowKey $RowKey -property $OwnerToken.GetPropertiesAsHashTable() -UpdateExisting | Out-Null

        $msg = "Renewed ownership of $($OwnerToken.Owner)"
        GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $LogTable -ExecutionCode ([ExecCodes]::OwnershipRenewal)
    }
    elseif ($LastUpdateInMinutes -gt $OwnerToken.TakeOverThresholdMin) 
    {
        if ($OwnerToken.Owner -ne $Owner)
        {
            msg = "Taking over from current owner $($OwnerToken.Owner) due to last update being greater than threshold $($OwnerToken.TakeOverThresholdMin)"
            GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $LogTable -ExecutionCode ([ExecCodes]::TakeOverThreshold) -Owner $Owner -ActivityId $ActivityId
            $OwnerToken.Owner = $Owner
        }
        else
        {
            $msg = "Renewing ownership of $($OwnerToken.Owner) due to last update being greater than threshold $($OwnerToken.TakeOverThresholdMin)"
            GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $LogTable -ExecutionCode ([ExecCodes]::OwnershipRenewal) -ActivityId $ActivityId
        }

        $OwnerToken.Status = [HAStatuses]::Running
        $OwnerToken.LastUpdateUTC = [System.DateTime]::UtcNow
        $OwnerToken.ActivityId = $ActivityId
        Add-AzTableRow -table $HaTable -partitionKey $PartitionKey -rowKey $RowKey -property $OwnerToken.GetPropertiesAsHashTable() -UpdateExisting | Out-Null
    }
    else
    {
        $msg = "Exiting due to last update from current owner $($OwnerToken.Owner) is still within threshold ($LastUpdateInMinutes) in minutes"
        GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $LogTable -ExecutionCode ([ExecCodes]::ExitOwnerWithinThreshold) -Owner $Owner -ActivityId $ActivityId
        $OwnerToken.ShouldExit = $true
    }

    return $OwnerToken
}

function UpdateOwnerToken
{
    <#
    .SYNOPSIS
        Updates OwnerToken if still owner
    #>
    param
    (
        $HaTable,
        $LogTable,
        [string]$PartitionKey,
        [string]$RowKey,
        [PsOwnerToken]$OwnerToken
    )

    # Will return $false if no longer owner
    [bool]$IsOwner = $false

    $LatestOwnerToken = GetHaOwnerTokenINfo -PartitionKey $PartitionKey -RowKey $RowKey -HaTable $HaTable

    if ($LatestOwnerToken -ne $null)
    {
        if ($LatestOwnerToken.Owner -eq $OwnerToken.Owner)
        {
            $OwnerToken.LastUpdateUTC = [System.DateTime]::UtcNow
            $OwnerToken.Status =  $OwnerToken.Status
            Add-AzTableRow -table $ScalingHATable -partitionKey $PartitionKey -rowKey $RowKey -property $OwnerToken.GetPropertiesAsHashTable() -UpdateExisting | Out-null

            $msg = "Updating timestamp..."
            GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $LogTable

            $IsOwner = $true
        }
        else
        {
            $msg = "`($($OwnerToken.Owner)`) is no longer owner, current owner is $($LatestOwnerToken.Owner), will not update HA Table."
            GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $LogTable -ExecutionCode ([ExecCodes]::NoLongerOwner)
        }
    }
    else
    {
        $msg = "`($($OwnerToken.Owner)`) could not obtain latest owner record."
        GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $LogTable -ExecutionCode ([ExecCodes]::ErrorGettingUpdatedOwnerInfo)
    }

    return $IsOwner
}


function RunActionIfOwnerOrExit
{
    param
    (
        $HaTable,
        $LogTable,
        $Action,
        [string]$PartitionKey,
        [string]$RowKey,
        [PsOwnerToken]$OwnerToken
    )

    # HA owner checking before execution 
    if (UpdateOwnerToken -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken)
    {
       Invoke-Expression($Action)
    }
    else
    {
        $msg  = "`($($OwnerToken.Status)`) `($([ExecCodes]::NoLongerOwner)`) $($OwnerToken.Owner) is no longer owner, no action will be performed and will exit execution now."
        GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $LogTable -ExecutionCode ([ExecCodes]::NoLongerOwner)
        exit     
    }
}

function ExitIfNotOwner
{
    param
    (
        $HaTable,
        $LogTable,
        [string]$PartitionKey,
        [string]$RowKey,
        [PsOwnerToken]$OwnerToken
    )

    # HA owner checking before execution 
    if (-not (UpdateOwnerToken -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken))
    {
        $msg = "`($($OwnerToken.Status)`) `($([ExecCodes]::NoLongerOwner)`) $($OwnerToken.Owner) is no longer owner, no action will be performed and will exit execution now."
        GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $LogTable -ExecutionCode ([ExecCodes]::NoLongerOwner)
        exit     
    }
}

function GlobalLog
{
    param
    (
        [string]$Message,
        [LogLevel]$LogLevel,
        [PsOwnerToken]$OwnerToken,
        $LogTable,
        [ExecCodes]$ExecutionCode = [ExecCodes]::UpdateFromOnwer,
        [string]$Owner = [string]::empty,
        [string]$ActivityId = [string]::empty
    )

    if ([string]::IsNullOrEmpty($Owner))
    {
        $Owner = $OwnerToken.Owner 
    }

    if ([string]::IsNullOrEmpty($ActivityId))
    {
        $ActivityId = $OwnerToken.ActivityId 
    }

    Add-TableLog -OwnerStatus $OwnerToken.Status -ExecCode ($ExecutionCode) -Message $msg -EntityName $Owner -Level ($LogLevel.ToString()) -ActivityId $ActivityId -LogTable $LogTable | Out-Null
    Write-Log $msg $LogLevel.ToString()
}

function LogTableCleanUp
{
	param
	(
	   $LogTable,
	   [int]$LogTableKeepLastDays,
	   [string]$ActivityId
	)

	$filter = "LogTimeStampUTC gt datetime'$((get-date).AddDays($LogTableKeepLastDays*(-1)).ToString("yyyy-MM-dd'T'HH:mm:ss.fffffff'Z'"))'"
	$LogEntriesForDeletion = Get-AzTableRow -Table $ScalingLogTable -CustomFilter $filter

	if ($LogEntriesForDeletion -ne $null)
	{
		Add-TableLog -OwnerStatus $OwnerToken.Status -ExecCode (([ExecCode]::OwnerLogCleanUp).ToString()) -Message "Old log entries cleanup. Cleaning up $($LogEntriesForDeletion.Count) old entries" -EntityName $Owner -Level (([LogLevel]::Info).ToString()) -ActivityId $ActivityId -LogTable $LogTable | Out-Null
		foreach ($entry in $LogEntriesForDeletion)
		{
			Remove-AzTableRow -table $LogTable –entity $entry
		}
	}
}