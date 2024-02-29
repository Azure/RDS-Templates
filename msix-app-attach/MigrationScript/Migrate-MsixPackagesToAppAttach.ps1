<#
    .SYNOPSIS
        
    Script to migrate MSIX Package objects to app attach package objects. 
    .DESCRIPTION
        
    This script will create a new app attach package object and delete the original MSIX package object if requested.  
    It can also copy permissions from the application group(s) associated with the hostpool that the MSIX package is associated with.  
    It can also copy the location and resource group of the hostpool that the MSIX package is associated with if not specified.
    It will write logs to a file in the temp folder by default, but this can be changed with the -LogFilePath parameter.
        
    .PARAMETER MsixPackage
    This is Msix package to migrate to an app attach package, can be passed in via pipeline.

    .PARAMETER PermissionSource
    Where to get permissions from for the new package, defaults to no permissions granted. The options are:
    1) The DAG associated with the hostpool that the MSIX package is associated with
    2) The RAGs associated with the hostpool that the MSIX package is associated with
    In either case it will grant permissions to all users and groups with any permission that is scoped specifically to the application group.

    .PARAMETER HostpoolsForNewPackage
    ResourceIds of hostpools to associate new object with, defaults to no hostpools. Hostpools have to be in the same location as the app attach packages they are associated with

    .PARAMETER TargetResourceGroupName
    Resource group to put new package in, defaults to resource group of hostpool that the MSIX package is associated with.

    .PARAMETER Location
    Location to create new package in, defaults to location of hostpool that the MSIX package is associated with.
    App attach packages have to be in the same location as the hostpool they are associated with.

    .PARAMETER DeleteOrigin
    Delete source msix package after migration.

    .PARAMETER DeactivateOrigin
    Deactivates source msix package after migration.

    .PARAMETER IsActive
    Creates new app attach package as active.

    .PARAMETER PassThru
    Passes new app attach package thru.

    .PARAMETER LogInJSON
    Write to log file in JSON Format.

    .PARAMETER LogFilePath
    Path of logfile, defaults to MsixMigration[Timestamp].log in a temp folder. The path being logged to will be written to the console at the beginning of the script run.

    .EXAMPLE
    Get-AzWvdMsixPackage -SubscriptionId $SubscriptionId -ResourceGroupName $MsixResourceGroupName -HostPoolName $HostpoolName -FullName $MsixName | .\Migrate-MsixPackagesToAppAttach
    Migrates a specific MSIX package to an app attach package in the same resource group and location as the MSIX package it came from, but assigning it no permissions or to any hostpools, leaving the old package present and active, and writing logs to the default file path.

    .EXAMPLE
    .\Migrate-MsixPackagesToAppAttach -MsixPackage $msixPackage -PermissionSource "DAG" -HostpoolsForNewPackage $hostpoolId -TargetResourceGroupName $newResourceGroup -Location $newLocation -DeleteOrigin -PassThru -LogInJSON -LogFilePath $logFilePath
    Migrates the specified MSIX package to an app attach package, copying permissions from the DAG associated with the hostpool that the MSIX package is associated with, and deleting the original MSIX package.

    .EXAMPLE
    .\Migrate-MsixPackagesToAppAttach -MsixPackage $msixPackage -PermissionSource "DAG" -HostpoolsForNewPackage $hostpoolId -TargetResourceGroupName $newResourceGroup -Location $newLocation -DeactivateOrigin -PassThru -LogInJSON -LogFilePath $logFilePath
    Migrates the specified MSIX package to an app attach package, copying permissions from the DAG associated with the hostpool that the MSIX package is associated with, and deactivates the original MSIX package so it will no longer be staged on hostpools.

    .EXAMPLE
    Get-AzWvdMsixPackage -SubscriptionId $SubscriptionId -ResourceGroupName $MsixResourceGroupName -HostPoolName $HostpoolName | .\Migrate-MsixPackagesToAppAttach -PermissionSource "DAG" -HostpoolsForNewPackage $hostpoolId -TargetResourceGroupName $newResourceGroup -Location $newLocation -DeleteOrigin -LogFilePath $logFilePath
    Gets all MSIX packages associated with the specified hostpool and migrates them to app attach packages, copying permissions from the DAG associated with the hostpool that the MSIX package is associated with, and deleting the original MSIX packages.
    
#>
#Requires -Version 5.0 
#Requires -Modules Az.DesktopVirtualization, Microsoft.Graph.Authentication, Az.Resources, Az.Accounts
[CmdletBinding(DefaultParameterSetName= 'Default')]
param(
    [Parameter(Mandatory, ValueFromPipeline, HelpMessage = "MSIX Package to migrate")]
    [Microsoft.Azure.Powershell.Cmdlets.DesktopVirtualization.Models.Api20220901PrivatePreview.MsixPackage]
    $MsixPackage,

    [Parameter(ValueFromPipelineByPropertyName, HelpMessage = "Where to get permissions from for the new package, defaults to no permissions granted")]
    [ValidateSet("DAG", "RAG", "NONE")]
    [System.String]
    $PermissionSource = "NONE",

    [Parameter(ValueFromPipelineByPropertyName, HelpMessage = "ResourceIds of hostpools to associate new object with, defaults to no hostpools")]
    [System.String[]]
    $HostpoolsForNewPackage,

    [Parameter(ValueFromPipelineByPropertyName, HelpMessage = "Resource group to put new package in, defaults to resource group of hostpool that the MSIX package is associated with")]
    [System.String]
    $TargetResourceGroupName,

    [Parameter(ValueFromPipelineByPropertyName, HelpMessage = "Location to create new package in, defaults to location of hostpool that the MSIX package is associated with")]
    [System.String]
    $Location,

    [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'DeleteOrigin', Mandatory, HelpMessage = "Delete source msix package object after migration")]
    [System.Management.Automation.SwitchParameter]
    $DeleteOrigin,

    [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'DeactivateOrigin', Mandatory, HelpMessage = "Deactivates source msix package object after migration")]
    [System.Management.Automation.SwitchParameter]
    $DeactivateOrigin,

    [Parameter(HelpMessage = "Creates new app attach package as active")]
    [System.Management.Automation.SwitchParameter]
    $IsActive,

    [Parameter(ValueFromPipelineByPropertyName, HelpMessage = "Passes new app attach package thru")]
    [System.Management.Automation.SwitchParameter]
    $PassThru,

    [Parameter(ValueFromPipelineByPropertyName, HelpMessage = "Log in JSON Format")]
    [System.Management.Automation.SwitchParameter]
    $LogInJSON,

    [Parameter(ValueFromPipelineByPropertyName, HelpMessage = "Path of logfile, defaults to MsixMigration[Timestamp].log in a temp folder")]
    [System.String]
    $LogFilePath = "$env:temp\MsixMigration" + (Get-Date -Format "yyyyMMddhhmmss") + ".log"
)
begin {
    # Copied with Jim's permission from https://github.com/JimMoyle/YetAnotherWriteLog/blob/master/Write-Log.ps1
    function Write-Log {
        <#
                .SYNOPSIS
        
                Single function to enable logging to file
                .DESCRIPTION
        
                The Log file can be output to any directory. A single log entry looks like this:
                2018-01-30 14:40:35 INFO:    'My log text'
        
                Log entries can be Info, Warning, Error or Debug
        
                The function takes pipeline input and you can pipe exceptions straight to the function for automatic error logging.
        
                It's not part of this function, but it can be useful to use the $PSDefaultParameterValues built-in Variable can be used to conveniently set the path and/or JSONformat switch at the top of the script:
        
                $PSDefaultParameterValues = @{"Write-Log:Path" = 'C:\YourPathHere.log'}
        
                $PSDefaultParameterValues = @{"Write-Log:JSONformat" = $true}
        
                .PARAMETER Message
        
                This is the body of the log line and should contain the information you wish to log.
                .PARAMETER Level
        
                One of four logging levels: INFO, WARNING, ERROR or DEBUG.  This is an optional parameter and defaults to INFO
                .PARAMETER Path
        
                The path where you want the log file to be created.  This is an optional parameter and defaults to "$env:temp\PowershellScript.log"
                .PARAMETER StartNew
        
                This will blank any current log in the path, it should be used at the start of your code if you don't want to append to an existing log.
                .PARAMETER Exception
        
                Used to pass a powershell exception to the logging function for automatic logging, this will log the excption message as an error.
                .PARAMETER JSONFormat
        
                Used to change the logging format from human readable to machine readable format, this will be a single line like the example format below:
                In this format the timestamp will include a much more granular time which will also include timezone information.  The format is optimised for Splunk input, but should work for any other platform.
        
                {"TimeStamp":"2018-02-01T12:01:24.8908638+00:00","Level":"Warning","Message":"My message"}
        
                .EXAMPLE
                Write-Log -StartNew
                Starts a new logfile in the default location
        
                .EXAMPLE
                Write-Log -StartNew -Path c:\logs\new.log
                Starts a new logfile in the specified location
        
                .EXAMPLE
                Write-Log 'This is some information'
                Appends a new information line to the log.
        
                .EXAMPLE
                Write-Log -level Warning 'This is a warning'
                Appends a new warning line to the log.
        
                .EXAMPLE
                Write-Log -level Error 'This is an Error'
                Appends a new Error line to the log.
        
                .EXAMPLE
                Write-Log -Exception $error[0]
                Appends a new Error line to the log with the message being the contents of the exception message.
        
                .EXAMPLE
                $error[0] | Write-Log
                Appends a new Error line to the log with the message being the contents of the exception message.
        
                .EXAMPLE
                'My log message' | Write-Log
                Appends a new Info line to the log with the message being the contents of the string.
        
                .EXAMPLE
                Write-Log 'My log message' -JSONFormat
                Appends a new Info line to the log with the message. The line will be in JSONFormat.
            #>
        
        [CmdletBinding(DefaultParametersetName = "LOG")]
        Param (
        
            [Parameter(Mandatory = $true,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true,
                ParameterSetName = 'LOG',
                Position = 0)]
            [ValidateNotNullOrEmpty()]
            [string]$Message,
        
            [Parameter(Mandatory = $false,
                ValueFromPipelineByPropertyName = $true,
                ParameterSetName = 'LOG',
                Position = 1 )]
            [ValidateSet('Error', 'Warning', 'Info', 'Debug')]
            [string]$Level = "Info",
        
            [Parameter(Mandatory = $false,
                ValueFromPipelineByPropertyName = $true,
                Position = 2)]
            [Alias('PSPath')]
            [string]$Path,
        
            [Parameter(Mandatory = $false,
                ValueFromPipelineByPropertyName = $true)]
            [switch]$JSONFormat,
        
            [Parameter(Mandatory = $false,
                ValueFromPipelineByPropertyName = $true,
                ParameterSetName = 'STARTNEW')]
            [switch]$StartNew,
        
            [Parameter(Mandatory = $true,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true,
                ParameterSetName = 'EXCEPTION')]
            [System.Management.Automation.ErrorRecord]$Exception
        )
        
        BEGIN {
            Set-StrictMode -version Latest #Enforces most strict best practice.
        }
        
        PROCESS {
            #Switch on parameter set
            switch ($PSCmdlet.ParameterSetName) {
                LOG {
                    #Get human readable date
                    $formattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
                    switch ( $Level ) {
                        'Info' { $levelText = "INFO:   "; break }
                        'Error' { $levelText = "ERROR:  "; break }
                        'Warning' { $levelText = "WARNING:"; break }
                        'Debug' { $levelText = "DEBUG:  "; break }
                    }
        
                    #Build an object so we can later convert it
        
                    $logObject = @{
                        #TimeStamp = Get-Date -Format o  #Get machine readable date
                        Level   = $levelText
                        Message = $Message
                    }
        
                    if ($JSONFormat) {
                        $logobject = [PSCustomObject][ordered]@{
                            TimeStamp = Get-Date -Format o
                            Level     = $levelText
                            Message   = $Message
                        }
                        #Convert to a single line of JSON and add it to the file
                        $logMessage = $logObject | ConvertTo-Json -Compress
                        $logMessage | Add-Content -Path $Path
                    }
                    else {
                        $logobject = [PSCustomObject][ordered]@{
                            TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                            Level     = $levelText
                            Message   = $Message
                        }
                        $logMessage = "$formattedDate`t$levelText`t$Message" #Build human readable line
                        $logObject | Export-Csv -Path $Path -Delimiter "`t" -NoTypeInformation -Append
                    }
        
                    Write-Verbose $logMessage #Only verbose line in the function
        
                } #LOG
        
                EXCEPTION {
                    #Splat parameters
                    $writeLogParams = @{
                        Level      = 'Error'
                        Message    = $Exception.Exception.Message
                        Path       = $Path
                        JSONFormat = $JSONFormat
                    }
                    Write-Log @writeLogParams #Call itself to keep code clean
                    break
        
                } #EXCEPTION
        
                STARTNEW {
                    if (Test-Path $Path) {
                        Remove-Item $Path -Force
                    }
                    #Splat parameters
                    $writeLogParams = @{
                        Level      = 'Info'
                        Message    = 'Starting Logfile'
                        Path       = $Path
                        JSONFormat = $JSONFormat
                    }
                    Write-Log @writeLogParams
                    break
        
                } #STARTNEW
        
            } #switch Parameter Set
        }
        
        END {
        }
    } #function Write-Log

    $PSDefaultParameterValues = @{
        "Write-Log:JSONformat" = $LogInJSON
        "Write-Log:Path"       = $LogFilePath
    }
    $locations = Get-AzLocation | Select-Object -ExpandProperty Location
}
process {        
    Write-Warning "Logging output to $LogFilePath"
    Write-Log "Starting migration of package $($MsixPackage.Name)"
    $PSBoundParameters.GetEnumerator() | ForEach-Object {
        if ($_.Key -eq "MsixPackage") {
            $paramValue = $_.Value.Name
        }
        else {
            $paramValue = $_.Value.ToString()
        }
        Write-Log "Parameter: $($_.Key) Value: $($paramValue)"
    } 
    
    # Start Validation
    if ($PermissionSource -ne 'NONE') {
        try {
            $mgContext = Get-MgContext -ErrorAction Stop
            if ($null -eq $mgContext) {
                $message = "No Microsoft Graph context found, please run Connect-MgGraph -Scopes 'Group.Read.All' before running this script"
                Write-Log -Level 'Error' -Message $message
                Write-Error $message
                return
            }
            elseif ($mgContext.Scopes -notcontains "Group.Read.All") {
                $message = "Microsoft Graph context found, but it does not have the required Group.Read.All scope, please run Connect-MgGraph -Scopes 'Group.Read.All' before running this script"
                Write-Log -Level 'Error' -Message $message
                Write-Error $message
                return
            }
        }
        catch {
            $Error[0] | Write-Log
            Write-Error $Error[0]
            return
        }
    }

    # Get relevant information from the id of the msix package
    $idArray = $msixPackage.Id.Split("/")
    $SubscriptionId = $idArray[2]
    $MsixResourceGroupName = $idArray[4]
    $HostpoolName = $idArray[8]
    $MsixName = $idArray[10]

    Write-Log "SubscriptionId: $SubscriptionId"
    Write-Log "MsixResourceGroupName: $MsixResourceGroupName"
    Write-Log "HostpoolName: $HostpoolName"
    Write-Log "MsixName: $MsixName"

    $newLocation = $Location
    $newResourceGroup = $TargetResourceGroupName
        
    # Fetch the hostpool the package is associated with
    try {
        $hostpool = Get-AzWvdHostPool -SubscriptionId $SubscriptionId -ResourceGroupName $MsixResourceGroupName -Name $HostpoolName -ErrorAction Stop
    }
    catch {
        $Error[0] | Write-Log
        Write-Error $Error[0]
        return
    }
    # You cannot have two copies of the same full name active at the same time on the same hostpool
    $setActiveAfterCreate = $false
    if ($null -ne $HostpoolsForNewPackage -and $HostpoolsForNewPackage -Contains ($hostpool.Id) -and $IsActive -and $MsixPackage.IsActive) {
        $setActiveAfterCreate = $true
        if (-not $DeactivateOrigin -and -not $DeleteOrigin) {
            $message = "Hostpools can only be associated with one active package per msix full name. Please either remove the -IsActive flag or set the -DeactivateOrigin flag."
            Write-Log -Level 'Error' -Message $message
            Write-Error $message
            return
        }
    }

    if (-not ($Location)) {
        $newLocation = $hostpool.Location
        Write-Log "Location not specified for package $MsixName, using location of $HostpoolName : $newLocation"
    } 
    else {
        try {
            if ($locations -notcontains $newLocation) {
                $message = "Location $newLocation is not a valid Azure location"
                Write-Log -Level 'Error' -Message $message
                Write-Error $message
                return
            }
        }
        catch {
            $Error[0] | Write-Log
            Write-Error $Error[0]
            return
        }
    }

    foreach ($newHostpool in $HostpoolsForNewPackage) {
        $hpIdArray = $newHostpool.Split("/")
        if ($hpIdArray.Count -lt 8) {
            $message = "Hostpool $newHostpool not in correct format, please provide resource id of hostpool"
            Write-Log -Level 'Error' -Message $message
            Write-Error $message
            return
        }
        $hpSubscriptionId = $hpIdArray[2]
        $hpResourceGroupName = $hpIdArray[4]
        $hpName = $hpIdArray[8]
        try {
            $hp = Get-AzWvdHostPool -SubscriptionId $hpSubscriptionId -ResourceGroupName $hpResourceGroupName -Name $hpName -ErrorAction Stop
            if ($null -eq $hp) {
                $message = "Hostpool $newHostpool does not exist"
                Write-Log -Level 'Error' -Message $message
                Write-Error $message
                return
            } elseif ($hp.Location -ne $newLocation) {
                $message = "Hostpool $newHostpool is in a different location than the new package, please provide hostpools in the same location as the new package"
                Write-Log -Level 'Error' -Message $message
                Write-Error $message
                return
            }
        }
        catch {
            $Error[0] | Write-Log
            Write-Error $Error[0]
            return
        }
    }

    if (-not ($newResourceGroup)) {
        $newResourceGroup = $MsixResourceGroupName
        Write-Log "Resource group not specified for package $MsixName, using resource group of package: $newResourceGroup"
    } 
    else {
        try {
            $rg = Get-AzResourceGroup -Name $newResourceGroup -ErrorAction Stop
            if (-not ($rg)) {
                $message = "Resource group $newResourceGroup does not exist"
                Write-Log -Level 'Error' -Message $message
                Write-Error $message
                return
            }
        }
        catch {
            $Error[0] | Write-Log
            Write-Error $Error[0]
            return
        }
    }

    if ($null -eq $hostpool.ApplicationGroupReference -and $PermissionSource -ne 'NONE') {
        $message = "No application groups are associated with hostpool $($hostpool.Name), cannot copy permissions."
        Write-Log -Level 'Error' -Message $message
        Write-Error $message
        return
    }


    $appGroups = foreach ($applicationGroupReference in $hostpool.ApplicationGroupReference) {

        $idArray = $applicationGroupReference.Split("/")
        $AgSubscriptionId = $idArray[2]
        $AgResourceGroupName = $idArray[4]
        $AgName = $idArray[8]
        try {
            Get-AzWvdApplicationGroup -SubscriptionId $AgSubscriptionId -ResourceGroupName $AgResourceGroupName -Name $AgName -ErrorAction Stop
        }
        catch {
            $message = "Failed to get application group information for $appName associated with hostpool $($hostpool.Name): $_"
            Write-Log -Level 'Error' -Message $message
            Write-Error $message
            return
        }
        
    }

    switch ($PermissionSource) {
        NONE { $appGroup = $null ; break }
        DAG { $appGroup = $appGroups | Where-Object { $_.ApplicationGroupType -eq 'Desktop' } ; break }
        RAG {
            $ragGroups = $appGroups | Where-Object { $_.ApplicationGroupType -eq 'RemoteApp' }

            try {
                $remoteApps = foreach ($ragGroup in $ragGroups) {
                    $idArray = $ragGroups.Id.Split("/")
                    $AgSubscriptionId = $idArray[2]
                    $AgResourceGroupName = $idArray[4]
                    Get-AzWvdApplication -SubscriptionId $AgSubscriptionId -ResourceGroupName $AgResourceGroupName -GroupName $ragGroup.Name -ErrorAction Stop
                }
            }
            catch {
                $message = "Failed to get application information for $($ragGroup.Name): $_"
                Write-Log -Level 'Error' -Message $message
                Write-Error $message
                return
            }

            $msixRemoteApps = $remoteApps | Where-Object { $_.MsixPackageFamilyName -eq $MsixPackage.PackageFamilyName }
            if ($null -ne $msixRemoteApps) {
                $remoteAppNames = $msixRemoteApps.Name
                $appGroupNames = $remoteAppNames | ForEach-Object { $_.Split("/")[0] }
                $appGroup = $ragGroups | Where-Object { $appGroupNames -contains $_.Name }
            }
            break
        }
        Default {}
    }


    if ($null -eq $appGroup -and $PermissionSource -ne 'NONE') {
        $message = "No application group found to copy permissions from for package $MsixName"
        Write-Log -Level 'Error' -Message $message
        Write-Error $message
        return
    }

    # We add permissions for all users and groups with any permission that is scoped specifically to the application group
    if ($appGroup) {
        Write-Log "Applying permissions from application group $($appGroup.Name) to new package $MsixName"
        try {
            $roleAssignments = Get-AzRoleAssignment -Scope $appGroup.Id -ErrorAction Stop
            Write-Log "Got role assignments for application group $($appGroup.Name)"
        }
        catch {
            $Error[0] | Write-Log
            Write-Error $Error[0]
            return
        }

        $permissionsToAdd = foreach ($roleAssignment in $roleAssignments) {
            if ($roleAssignment.Scope -eq $appGroup.Id) {

                if ($roleAssignment.ObjectType -eq "User") {
                    $roleAssignment.SignInName
                    Write-Log ("Granting user " + $roleAssignment.SignInName + "access to package $MsixName")
                }
                if ($roleAssignment.ObjectType -eq "Group") {
                    $roleAssignment.DisplayName
                    Write-Log ("Granting group " + $roleAssignment.DisplayName + "access to package $MsixName")
                }

            }
        }
    }
    else {
        $permissionsToAdd = $null
    }
    
    #App attach package creation paramters
    $appAttachParameters = @{
        SubscriptionId                  = $SubscriptionId
        ResourceGroupName               = $newResourceGroup
        Name                            = $MsixName
        Location                        = $newLocation
        FailHealthCheckOnStagingFailure = 'NeedsAssistance'
        ImageDisplayName                = $MsixPackage.DisplayName
        HostPoolReference               = $HostpoolsForNewPackage
        ImagePath                       = $MsixPackage.ImagePath
        ImageLastUpdated                = $MsixPackage.LastUpdated
        ImagePackageApplication         = $MsixPackage.PackageApplication
        ImagePackageDependency          = $MsixPackage.PackageDependency
        ImagePackageFamilyName          = $MsixPackage.PackageFamilyName
        ImagePackageFullName            = $MsixName
        ImagePackageName                = $MsixPackage.PackageName
        ImagePackageRelativePath        = $MsixPackage.PackageRelativePath
        ImageVersion                    = $MsixPackage.Version
        ImageIsActive                   = $IsActive -and -not $setActiveAfterCreate
        ImageIsRegularRegistration      = $MsixPackage.IsRegularRegistration
    }

    try {
        # catch the debug output in a variable so we can extract the object in a success and the activity id in a failure
        $newOutput = New-AzWvdAppAttachPackage @appAttachParameters -ErrorAction Stop 5>&1
        $appAttachPackage = $newOutput | Where-Object { $_.GetType().Name -eq "AppAttachPackage" }
        Write-Log "Package $MsixName migrated to app attach package object type"
    }
    catch {
        if ($null -ne $_.Message) {
            # this would complain if there was an app attach package object in the output but there won't be in this case
            $activityIds = $newOutput | Where-Object { $_.Message.Contains("x-ms-correlation-id") }
            if ($null -ne $activityIds) {
                $activityId = $activityIds.Message.Split("x-ms-correlation-id")[1].Trim().Substring(2, 38).Trim()
                $logOutput = ("ActivityId: " + $activityId + " " + $Error[0])
            } 
        }
        else {
            $logOutput = $Error[0]
        }
        $logOutput | Write-Log
        Write-Error $logOutput
        return
    }

    foreach ($item in $permissionsToAdd) {
        try {
            # check if it is an email address
            if ($item -match $emailRegex) {
                $role = Get-AzRoleAssignment -SignInName $item -RoleDefinitionName "Desktop Virtualization User" -Scope $appAttachPackage.Id
                if ($null -eq $role) {
                    $null = New-AzRoleAssignment -SignInName $item -RoleDefinitionName "Desktop Virtualization User" -Scope $appAttachPackage.Id
                }
            }
            # if not email, assume group
            else {
                $group = Get-MgGroup -Filter "DisplayName eq '$item'"
                if ($null -ne $group) {
                    # this is a nullable field and at least some groups where this is null are assignable
                    if ($group.IsAssignableToRole -ne $false) {
                        $retryCount = 0
                        $retryMax = 5
                        $retryDelay = 2
                        $maximalWait = (Get-Date).AddSeconds(10)
                        # add a retry policy here because sometimes the group is not assignable immediately after creation
                        while ($retryCount -lt $retryMax -and (Get-Date) -lt $maximalWait) {
                            try {
                                $retryCount++
                                $role = Get-AzRoleAssignment -ObjectId $group.Id -RoleDefinitionName "Desktop Virtualization User" -Scope $appAttachPackage.Id
                                if ($null -eq $role) {
                                    $null = New-AzRoleAssignment -ObjectId $group.Id -RoleDefinitionName "Desktop Virtualization User" -Scope $appAttachPackage.Id
                                }
                            }
                            catch {
                                if ($retryCount -eq $retryMax -or (Get-Date) -gt $maximalWait) {
                                    throw $_
                                }
                                else {
                                    Start-Sleep -Seconds $retryDelay
                                }
                            }
                        }
                    }
                    else {
                        Write-Log ("Group $item is not assignable to a role, skipping assigning permissions to this group")
                    }
                }
                else {
                    Write-Log ("Unable to find group $item, skipping assigning permissions to this group")
                }
            }        
        }
        catch {
            $message = "An exception occurred adding permissions for $item $_ Please manually check permissions."
            Write-Log -Level Warning $message
            Write-Warning $message
            if ($DeleteOrigin) {
                $message = "Skipping deletion for package $MsixName because permissions could not be added to the new package"
                Write-Log -Level Warning $message
                $DeleteOrigin = $false
            }
            if ($DeactivateOrigin -and -not $DeleteOrigin) {
                $message = "Skipping deactivation for package $MsixName because permissions could not be added to the new package"
                Write-Log -Level Warning $message
                $DeleteOrigin = $false
            }
        }
    }
            
    if ($DeactivateOrigin -and -not $DeleteOrigin) {
        try { 
            Update-AzWvdMsixPackage -SubscriptionId $SubscriptionId -ResourceGroupName $MsixResourceGroupName -HostPoolName $HostpoolName -FullName $MsixName -IsActive:$false -ErrorAction Stop
            Write-Log "Origin package $MsixName deactivated"
        }
        catch {
            if ($setActiveAfterCreate) {
                Write-Log "Error deactivating origin package $MsixName, not activating new package object"
            }
            $Error[0] | Write-Log
            Write-Error $Error[0]
            return
        }
    }    
    if ($DeleteOrigin) {
        try { 
            Remove-AzWvdMsixPackage -SubscriptionId $SubscriptionId -ResourceGroupName $MsixResourceGroupName -HostPoolName $HostpoolName -FullName $MsixName -ErrorAction Stop
            Write-Log "Package $MsixName deleted"
        }
        catch {            
            if ($setActiveAfterCreate) {
                Write-Log "Error deleting origin package $MsixName, not activating new package object"
            }
            $Error[0] | Write-Log
            Write-Error $Error[0]
            return
        }
    }
    if ($setActiveAfterCreate) {
        try { 
            Update-AzWvdAppAttachPackage -SubscriptionId $SubscriptionId -ResourceGroupName $newResourceGroup -Name $MsixName -IsActive -Location $newLocation -ErrorAction Stop
            Write-Log "Package $MsixName activated"
        }
        catch {
            $Error[0] | Write-Log
            Write-Error $Error[0]
            return
        }
    }

    if ($PassThru) {
        Write-Output $appAttachPackage
    }    
}