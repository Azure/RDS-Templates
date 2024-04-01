<#Author       : Akash Chawla
# Usage        : Windows optimizations for AVD
#>

#############################################
#         Windows optimizations             #
#############################################

# Inspired by and referenced: https://raw.githubusercontent.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/main/Windows_VDOT.ps1

[CmdletBinding()] Param (
     [Parameter(
        Mandatory
    )]
    [ValidateSet('All','WindowsMediaPlayer','ScheduledTasks','DefaultUserSettings','Autologgers','Services','NetworkOptimizations','LGPO','DiskCleanup','Edge','RemoveLegacyIE', 'RemoveOneDrive')] 
    [String[]]$Optimizations
)   

Begin {

        try {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            Write-Host "AVD AIB Customization : Windows Optimizations"

            $WindowsVersion = (Get-ItemProperty "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\").ReleaseId
            $WorkingLocation = (Join-Path $PSScriptRoot $WindowsVersion)
            $templateFilePathFolder = "C:\AVDImage"

            if (!(Test-Path -Path $WorkingLocation)) {
                New-Item -Path $WorkingLocation -ItemType Directory
            }

            Write-Host "AVD AIB Customization : Windows Optimizations - Windows version is $WindowsVersion"
        } 
        catch
        {
            Write-Host 'AVD AIB Customization : Windows Optimizations - Invalid Path $WorkingLocation - Exiting Script!'
            Return
        }
}
PROCESS {

    if (-not ($PSBoundParameters.Keys -match 'Optimizations') )
     {
        Write-Host "AVD AIB Customization : Windows Optimizations - No Optimizations (Optimizations or AdvancedOptimizations) passed, exiting script!"
        Return
    }

    #region Disable, then remove, Windows Media Player including payload
    If ($Optimizations -contains "WindowsMediaPlayer" -or $Optimizations -contains "All") {
        try
        {
            Write-Host "AVD AIB Customization : Windows Optimizations - [VDI Optimize] Disable / Remove Windows Media Player" 
            Disable-WindowsOptionalFeature -Online -FeatureName WindowsMediaPlayer -NoRestart | Out-Null
            Get-WindowsPackage -Online -PackageName "*Windows-mediaplayer*" | ForEach-Object { 
                Write-Host "AVD AIB Customization : Windows Optimizations - Removing $($_.PackageName)" 
                Remove-WindowsPackage -PackageName $_.PackageName -Online -ErrorAction SilentlyContinue -NoRestart | Out-Null
            }
        }
        catch 
        { 
            Write-Host "AVD AIB Customization : Windows Optimizations - Disabling / Removing Windows Media Player - $($_.Exception.Message)"
        }
    }
    #endregion

    #region Disable Scheduled Tasks

    # This section is for disabling scheduled tasks.  If you find a task that should not be disabled
    # change its "VDIState" from Disabled to Enabled, or remove it from the json completely.
    If ($Optimizations -contains 'ScheduledTasks' -or $Optimizations -contains "All") {

        try 
        {
            $ScheduledTasksFilePath = Join-Path -Path $WorkingLocation -ChildPath 'ScheduledTasks.json'
            $ScheduledTaskUrl = "https://raw.githubusercontent.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/main/2009/ConfigurationFiles/ScheduledTasks.json"

            Invoke-WebRequest $ScheduledTaskUrl -OutFile $ScheduledTasksFilePath -UseBasicParsing

            If (Test-Path $ScheduledTasksFilePath)
            {
                Write-Host "AVD AIB Customization : Windows Optimizations - [VDI Optimize] Disable Scheduled Tasks" 
                $SchTasksList = (Get-Content $ScheduledTasksFilePath | ConvertFrom-Json).Where( { $_.VDIState -eq 'Disabled' })
                If ($SchTasksList.count -gt 0)
                {
                    Foreach ($Item in $SchTasksList)
                    {
                        $TaskObject = Get-ScheduledTask $Item.ScheduledTask
                        If ($TaskObject -and $TaskObject.State -ne 'Disabled')
                        {
                            Write-Host "AVD AIB Customization : Windows Optimizations - Attempting to disable Scheduled Task: $($TaskObject.TaskName)" 
                            Write-Verbose "AVD AIB Customization : Windows Optimizations - Attempting to disable Scheduled Task: $($TaskObject.TaskName)"
                            try
                            {
                                Disable-ScheduledTask -InputObject $TaskObject | Out-Null
                                Write-Host "AVD AIB Customization : Windows Optimizations- Disabled Scheduled Task: $($TaskObject.TaskName)"
                            }
                            catch
                            {
                                Write-Host "AVD AIB Customization : Windows Optimizations- Failed to disabled Scheduled Task: $($TaskObject.TaskName) - $($_.Exception.Message)"
                            }
                        }
                        ElseIf ($TaskObject -and $TaskObject.State -eq 'Disabled') 
                        {
                            Write-Host "AVD AIB Customization : Windows Optimizations- $($TaskObject.TaskName) Scheduled Task is already disabled - $($_.Exception.Message)" 
                        }
                        Else
                        {
                            Write-Host "AVD AIB Customization : Windows Optimizations- Unable to find Scheduled Task: $($TaskObject.TaskName) - $($_.Exception.Message)" 
                        }
                    }
                }
                Else
                {
                    Write-Host  "AVD AIB Customization : Windows Optimizations - No Scheduled Tasks found to disable" 
                }
            }
            Else 
            {
                Write-Host  "AVD AIB Customization : Windows Optimizations - File not found! -  $ScheduledTasksFilePath"
            }    
        }
        catch 
        {
            Write-Host "AVD AIB Customization : Windows Optimizations - Scheduled tasks - $($_.Exception.Message)"
        }
    }
    #endregion

     #region Customize Default User Profile

    # Apply appearance customizations to default user registry hive, then close hive file
    If ($Optimizations -contains "DefaultUserSettings" -or $Optimizations -contains "All")
    {
        $DefaultUserSettingsFilePath = Join-Path -Path $WorkingLocation -ChildPath 'DefaultUserSettings.json'
        $DefaultUserSettingsUrl = "https://raw.githubusercontent.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/main/2009/ConfigurationFiles/DefaultUserSettings.json"

        Invoke-WebRequest $DefaultUserSettingsUrl -OutFile $DefaultUserSettingsFilePath -UseBasicParsing

        If (Test-Path $DefaultUserSettingsFilePath)
        {
            Write-Host "AVD AIB Customization : Windows Optimizations - - Set Default User Settings"
            $UserSettings = (Get-Content $DefaultUserSettingsFilePath | ConvertFrom-Json).Where( { $_.SetProperty -eq $true })
            If ($UserSettings.Count -gt 0)
            {
                Write-Host "AVD AIB Customization : Windows Optimizations - Processing Default User Settings (Registry Keys)" 
                $null = Start-Process reg -ArgumentList "LOAD HKLM\VDOT_TEMP C:\Users\Default\NTUSER.DAT" -PassThru -Wait
                # & REG LOAD HKLM\VDOT_TEMP C:\Users\Default\NTUSER.DAT | Out-Null

                Foreach ($Item in $UserSettings)
                {
                    If ($Item.PropertyType -eq "BINARY")
                    {
                        $Value = [byte[]]($Item.PropertyValue.Split(","))
                    }
                    Else
                    {
                        $Value = $Item.PropertyValue
                    }

                    If (Test-Path -Path ("{0}" -f $Item.HivePath))
                    {
                        Write-Host "AVD AIB Customization : Windows Optimizations - Found $($Item.HivePath) - $($Item.KeyName)"

                        If (Get-ItemProperty -Path ("{0}" -f $Item.HivePath) -ErrorAction SilentlyContinue)
                        {
                            Write-Host "AVD AIB Customization : Windows Optimizations - Set $($Item.HivePath) - $Value"
                            Set-ItemProperty -Path ("{0}" -f $Item.HivePath) -Name $Item.KeyName -Value $Value -Type $Item.PropertyType -Force 
                        }
                        Else
                        {
                            Write-Host "AVD AIB Customization : Windows Optimizations- New $($Item.HivePath) Name $($Item.KeyName) PropertyType $($Item.PropertyType) Value $Value"
                            New-ItemProperty -Path ("{0}" -f $Item.HivePath) -Name $Item.KeyName -PropertyType $Item.PropertyType -Value $Value -Force | Out-Null
                        }
                    }
                    Else
                    {
                        Write-Host "AVD AIB Customization : Windows Optimizations- Registry Path not found $($Item.HivePath)" 
                        Write-Host "AVD AIB Customization : Windows Optimizations- Creating new Registry Key $($Item.HivePath)"
                        $newKey = New-Item -Path ("{0}" -f $Item.HivePath) -Force
                        If (Test-Path -Path $newKey.PSPath)
                        {
                            New-ItemProperty -Path ("{0}" -f $Item.HivePath) -Name $Item.KeyName -PropertyType $Item.PropertyType -Value $Value -Force | Out-Null
                        }
                        Else
                        {
                            Write-Host "AVD AIB Customization : Windows Optimizations- Failed to create new Registry Key" 
                        } 
                    }
                }
                $null = Start-Process reg -ArgumentList "UNLOAD HKLM\VDOT_TEMP" -PassThru -Wait
                # & REG UNLOAD HKLM\VDOT_TEMP | Out-Null
            }
            Else
            {
                Write-Host "AVD AIB Customization : Windows Optimizations- No Default User Settings to set" 
            }
        }
        Else
        {
            Write-Host "AVD AIB Customization : Windows Optimizations- File not found: $DefaultUserSettingsFilePath"
        }    
    }
    #endregion

     #region Disable Windows Traces
    If ($Optimizations -contains "AutoLoggers" -or $Optimizations -contains "All")
    {
        $AutoLoggersUrl = "https://raw.githubusercontent.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/main/2009/ConfigurationFiles/Autologgers.Json"
        $AutoLoggersFilePath = Join-Path -Path $WorkingLocation -ChildPath 'Autologgers.json'
        
        Invoke-WebRequest $AutoLoggersUrl -OutFile $AutoLoggersFilePath -UseBasicParsing
      
        If (Test-Path $AutoLoggersFilePath)
        {
            Write-Host "AVD AIB Customization : Windows Optimizations- Disable AutoLoggers"

            $DisableAutologgers = (Get-Content $AutoLoggersFilePath | ConvertFrom-Json).Where( { $_.Disabled -eq 'True' })
            If ($DisableAutologgers.count -gt 0)
            {
                Write-Host "AVD AIB Customization : Windows Optimizations- Disable AutoLoggers, Processing Autologger configuration file"
                Foreach ($Item in $DisableAutologgers)
                {
                    Write-Host "AVD AIB Customization : Windows Optimizations- Updating Registry Key for: $($Item.KeyName)"

                    Try 
                    {
                        New-ItemProperty -Path ("{0}" -f $Item.KeyName) -Name "Start" -PropertyType "DWORD" -Value 0 -Force -ErrorAction Stop | Out-Null
                    }
                    Catch
                    {
                        Write-Host "AVD AIB Customization : Windows Optimizations- Failed to add $($Item.KeyName)`n`n $($Error[0].Exception.Message)"
                    }
                    
                }
            }
            Else 
            {
                Write-Host "AVD AIB Customization : Windows Optimizations- No Autologgers found to disable"
            }
        }
        Else
        {
            Write-Host -EventId 150 -Message "File not found: $AutoLoggersFilePath" -Source 'AutoLoggers' -EntryType Error
            Write-Warning "File Not Found: $AutoLoggersFilePath"
        }
    }
    #endregion
                   

    #region Disable Services
    If ($Optimizations -contains "Services" -or $Optimizations -contains "All")
    {

        $ServicesUrl = "https://raw.githubusercontent.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/main/2009/ConfigurationFiles/Services.json"
        $ServicesFilePath = Join-Path -Path $WorkingLocation -ChildPath 'Services.json'
        
        Invoke-WebRequest $ServicesUrl -OutFile $ServicesFilePath -UseBasicParsing

        If (Test-Path $ServicesFilePath)
        {
            Write-Host "AVD AIB Customization : Windows Optimizations- Disable Services" 
            $ServicesToDisable = (Get-Content $ServicesFilePath | ConvertFrom-Json ).Where( { $_.VDIState -eq 'Disabled' })

            If ($ServicesToDisable.count -gt 0)
            {
                Write-Host "AVD AIB Customization : Windows Optimizations- Processing Services Configuration File" 

                Foreach ($Item in $ServicesToDisable)
                {
                    #Write-Host "AVD AIB Customization : Windows Optimizations - Attempting to Stop Service $($Item.Name) - $($Item.Description)" 
                    #Write-Verbose "Attempting to Stop Service $($Item.Name) - $($Item.Description)"
                    #try
                    #{
                    #    Stop-Service $Item.Name -Force -ErrorAction SilentlyContinue
                    #}
                    #catch
                    #{
                    #    Write-Host "AVD AIB Customization : Windows Optimizations - Failed to disable Service: $($Item.Name) `n $($_.Exception.Message)" -Source 'Services' -EntryType Error
                    #    Write-Warning "Failed to disable Service: $($Item.Name) `n $($_.Exception.Message)"
                    #}
                    Write-Host "AVD AIB Customization : Windows Optimizations- Attempting to disable Service $($Item.Name) - $($Item.Description)" 
                    Set-Service $Item.Name -StartupType Disabled 
                }
            }  
            Else
            {
                Write-Host "AVD AIB Customization : Windows Optimizations- No Services found to disable" 
            }
        }
        Else
        {
            Write-Host "AVD AIB Customization : Windows Optimizations- File not found: $ServicesFilePath" 

        }   
    }
    #endregion

    #region Network Optimization
    # LanManWorkstation optimizations
    If ($Optimizations -contains "NetworkOptimizations" -or $Optimizations -contains "All")
    {
        $NetworkOptimizationsUrl = "https://raw.githubusercontent.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/main/2009/ConfigurationFiles/LanManWorkstation.json"

        $NetworkOptimizationsFilePath = Join-Path -Path $WorkingLocation -ChildPath 'LanManWorkstation.json'
        Invoke-WebRequest $NetworkOptimizationsUrl -OutFile $NetworkOptimizationsFilePath -UseBasicParsing
        
        If (Test-Path $NetworkOptimizationsFilePath)
        {
            Write-Host "AVD AIB Customization : Windows Optimizations- Configure LanManWorkstation Settings" 
            $LanManSettings = Get-Content $NetworkOptimizationsFilePath | ConvertFrom-Json
            If ($LanManSettings.Count -gt 0)
            {
                Write-Host "AVD AIB Customization : Windows Optimizations- Processing LanManWorkstation Settings ($($LanManSettings.Count) Hives)" 
                Foreach ($Hive in $LanManSettings)
                {
                    If (Test-Path -Path $Hive.HivePath)
                    {
                        Write-Host "AVD AIB Customization : Windows Optimizations- Found $($Hive.HivePath)" 

                        $Keys = $Hive.Keys.Where{ $_.SetProperty -eq $true }
                        If ($Keys.Count -gt 0)
                        {
                            Write-Host "AVD AIB Customization : Windows Optimizations- Create / Update LanManWorkstation Keys" 
                            Foreach ($Key in $Keys)
                            {
                                If (Get-ItemProperty -Path $Hive.HivePath -Name $Key.Name -ErrorAction SilentlyContinue)
                                {
                                    Write-Host "AVD AIB Customization : Windows Optimizations- Setting $($Hive.HivePath) -Name $($Key.Name) -Value $($Key.PropertyValue)" 
                                    Set-ItemProperty -Path $Hive.HivePath -Name $Key.Name -Value $Key.PropertyValue -Force
                                }
                                Else
                                {
                                    Write-Host "AVD AIB Customization : Windows Optimizations- New $($Hive.HivePath) -Name $($Key.Name) -Value $($Key.PropertyValue)" 
                                    New-ItemProperty -Path $Hive.HivePath -Name $Key.Name -PropertyType $Key.PropertyType -Value $Key.PropertyValue -Force | Out-Null
                                }
                            }
                        }
                        Else
                        {
                            Write-Host "AVD AIB Customization : Windows Optimizations- No LanManWorkstation Keys to create / update"
                        }  
                    }
                    Else
                    {
                        Write-Host "AVD AIB Customization : Windows Optimizations- Registry Path not found $($Hive.HivePath)"
                    }
                }
            }
            Else
            {
                Write-Host "AVD AIB Customization : Windows Optimizations - No LanManWorkstation Settings found"
            }
        }
        Else
        {
            Write-Host "AVD AIB Customization : Windows Optimizations - File not found - $NetworkOptimizationsFilePath"
        }

        # NIC Advanced Properties performance settings for network biased environments
        Write-Host "AVD AIB Customization : Windows Optimizations - Configuring Network Adapter Buffer Size" 
        Set-NetAdapterAdvancedProperty -DisplayName "Send Buffer Size" -DisplayValue 4MB -NoRestart
        <#  NOTE:
            Note that the above setting is for a Microsoft Hyper-V VM.  You can adjust these values in your environment...
            by querying in PowerShell using Get-NetAdapterAdvancedProperty, and then adjusting values using the...
            Set-NetAdapterAdvancedProperty command.
        #>
    }
    #endregion

       #region Local Group Policy Settings
    # - This code does not:
    #   * set a lock screen image.
    #   * change the "Root Certificates Update" policy.
    #   * change the "Enable Windows NTP Client" setting.
    #   * set the "Select when Quality Updates are received" policy
    If ($Optimizations -contains "LGPO" -or $Optimizations -contains "All")
    {
        $LocalPolicyFilePath = Join-Path -Path $WorkingLocation -ChildPath 'PolicyRegSettings.json'
        $LocalPolicyUrl = "https://raw.githubusercontent.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/main/2009/ConfigurationFiles/PolicyRegSettings.json"
        Invoke-WebRequest $LocalPolicyUrl -OutFile $LocalPolicyFilePath -UseBasicParsing

        If (Test-Path $LocalPolicyFilePath)
        {
            Write-Host "AVD AIB Customization : Windows Optimizations - Local Group Policy Items"
            $PolicyRegSettings = Get-Content $LocalPolicyFilePath | ConvertFrom-Json
            If ($PolicyRegSettings.Count -gt 0)
            {
                Write-Host "AVD AIB Customization : Windows Optimizations - Processing PolicyRegSettings Settings ($($PolicyRegSettings.Count) Hives)"
                Foreach ($Key in $PolicyRegSettings)
                {
                    If ($Key.VDIState -eq 'Enabled')
                    {
                        If (Get-ItemProperty -Path $Key.RegItemPath -Name $Key.RegItemValueName -ErrorAction SilentlyContinue) 
                        { 
                            Write-Host "AVD AIB Customization : Windows Optimizations - Found key, $($Key.RegItemPath) Name $($Key.RegItemValueName) Value $($Key.RegItemValue)"
                            Set-ItemProperty -Path $Key.RegItemPath -Name $Key.RegItemValueName -Value $Key.RegItemValue -Force 
                        }
                        Else 
                        { 
                            If (Test-path $Key.RegItemPath)
                            {
                                Write-Host "AVD AIB Customization : Windows Optimizations - Path found, creating new property -Path $($Key.RegItemPath) -Name $($Key.RegItemValueName) -PropertyType $($Key.RegItemValueType) -Value $($Key.RegItemValue)"
                                New-ItemProperty -Path $Key.RegItemPath -Name $Key.RegItemValueName -PropertyType $Key.RegItemValueType -Value $Key.RegItemValue -Force | Out-Null 
                            }
                            Else
                            {
                                Write-Host "AVD AIB Customization : Windows Optimizations - Creating Key and Path"
                                New-Item -Path $Key.RegItemPath -Force | New-ItemProperty -Name $Key.RegItemValueName -PropertyType $Key.RegItemValueType -Value $Key.RegItemValue -Force | Out-Null 
                            }
            
                        }
                    }
                }
            }
            Else
            {
                Write-Host "AVD AIB Customization : Windows Optimizations - No LGPO Settings Found!" 
            }
        }
        Else 
        {
            If (Test-Path (Join-Path $PSScriptRoot "LGPO\LGPO.exe"))
            {
                Write-Host "AVD AIB Customization : Windows Optimizations - [VDI Optimize] Import Local Group Policy Items"
                Start-Process (Join-Path $PSScriptRoot "LGPO\LGPO.exe") -ArgumentList "/g .\LGPO" -Wait
            }
            Else
            {
                Write-Host "AVD AIB Customization : Windows Optimizations - File not found $PSScriptRoot\LGPO\LGPO.exe" 
            }
        }    
    }
    #endregion

    #region Edge Settings
    If ($Optimizations -contains "Edge" -or $Optimizations -contains "All")
    {
        $EdgeFilePath = Join-Path -Path $WorkingLocation -ChildPath 'EdgeSettings.json'
        $EdgeSettingsUrl = "https://raw.githubusercontent.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/main/2009/ConfigurationFiles/EdgeSettings.json"
        Invoke-WebRequest $EdgeSettingsUrl -OutFile $EdgeFilePath -UseBasicParsing

        If (Test-Path $EdgeFilePath)
        {
            Write-Host "AVD AIB Customization : Windows Optimizations - Edge Policy Settings"
            $EdgeSettings = Get-Content $EdgeFilePath | ConvertFrom-Json
            If ($EdgeSettings.Count -gt 0)
            {
                Write-Host "AVD AIB Customization : Windows Optimizations - Processing Edge Policy Settings ($($EdgeSettings.Count) Hives)"
                Foreach ($Key in $EdgeSettings)
                {
                    If ($Key.VDIState -eq 'Enabled')
                    {
                        If ($key.RegItemValueName -eq 'DefaultAssociationsConfiguration')
                        {
                            Copy-Item .\ConfigurationFiles\DefaultAssociationsConfiguration.xml $key.RegItemValue -Force
                        }
                        If (Get-ItemProperty -Path $Key.RegItemPath -Name $Key.RegItemValueName -ErrorAction SilentlyContinue) 
                        { 
                            Write-Host "AVD AIB Customization : Windows Optimizations - Found key, $($Key.RegItemPath) Name $($Key.RegItemValueName) Value $($Key.RegItemValue)"
                            Set-ItemProperty -Path $Key.RegItemPath -Name $Key.RegItemValueName -Value $Key.RegItemValue -Force 
                        }
                        Else 
                        { 
                            If (Test-path $Key.RegItemPath)
                            {
                                Write-Host "AVD AIB Customization : Windows Optimizations - Path found, creating new property -Path $($Key.RegItemPath) -Name $($Key.RegItemValueName) -PropertyType $($Key.RegItemValueType) -Value $($Key.RegItemValue)"
                                New-ItemProperty -Path $Key.RegItemPath -Name $Key.RegItemValueName -PropertyType $Key.RegItemValueType -Value $Key.RegItemValue -Force | Out-Null 
                            }
                            Else
                            {
                                Write-Host "AVD AIB Customization : Windows Optimizations - Creating Key and Path"
                                New-Item -Path $Key.RegItemPath -Force | New-ItemProperty -Name $Key.RegItemValueName -PropertyType $Key.RegItemValueType -Value $Key.RegItemValue -Force | Out-Null 
                            }
            
                        }
                    }
                }
            }
            Else
            {
                Write-Host "AVD AIB Customization : Windows Optimizations - No Edge Policy Settings Found!"
            }
        }
        Else 
        {
           # nothing to do here"
        }    
    }
    #endregion

     #region Remove Legacy Internet Explorer
    If ($Optimizations -contains "RemoveLegacyIE" -or $Optimizations -contains "All")
    {
        Write-Host "AVD AIB Customization : Windows Optimizations - Remove Legacy Internet Explorer"
        Get-WindowsCapability -Online | Where-Object Name -Like "*Browser.Internet*" | Remove-WindowsCapability -Online 
    }
    #endregion

     #region Remove OneDrive Commercial
    If ($Optimizations -contains "RemoveOneDrive" -or $Optimizations -contains "All")
    {
        Write-Host "AVD AIB Customization : Windows Optimizations - Remove OneDrive Commercial"
        $OneDrivePath = @('C:\Windows\System32\OneDriveSetup.exe', 'C:\Windows\SysWOW64\OneDriveSetup.exe')   
        $OneDrivePath | ForEach-Object {
            If (Test-Path $_)
            {
                Write-Host "`tAttempting to uninstall $_"
                Start-Process $_ -ArgumentList "/uninstall" -Wait
            }
        }
        
        Write-Host "AVD AIB Customization : Windows Optimizations - Removing shortcut links for OneDrive"
        Get-ChildItem 'C:\*' -Recurse -Force -EA SilentlyContinue -Include 'OneDrive','OneDrive.*' | Remove-Item -Force -Recurse -EA SilentlyContinue
    }

    #endregion

    #region Disk Cleanup
    # Delete not in-use files in locations C:\Windows\Temp and %temp%
    # Also sweep and delete *.tmp, *.etl, *.evtx, *.log, *.dmp, thumbcache*.db (not in use==not needed)
    # 5/18/20: Removing Disk Cleanup and moving some of those tasks to the following manual cleanup
    If ($Optimizations -contains "DiskCleanup" -or $Optimizations -contains "All")
    {
        Write-Host "AVD AIB Customization : Windows Optimizations - Removing .tmp, .etl, .evtx, thumbcache*.db, *.log files not in use"
        Get-ChildItem -Path c:\ -Include *.tmp, *.dmp, *.etl, *.evtx, thumbcache*.db, *.log -File -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -ErrorAction SilentlyContinue

        # Delete "RetailDemo" content (if it exits)
        Write-Host "AVD AIB Customization : Windows Optimizations - Removing Retail Demo content (if it exists)"
        Get-ChildItem -Path $env:ProgramData\Microsoft\Windows\RetailDemo\* -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -ErrorAction SilentlyContinue

        # Delete not in-use anything in the C:\Windows\Temp folder
        Write-Host "AVD AIB Customization : Windows Optimizations - Removing all files not in use in $env:windir\TEMP"
        Remove-Item -Path $env:windir\Temp\* -Recurse -Force -ErrorAction SilentlyContinue -Exclude packer*.ps1

        # Clear out Windows Error Reporting (WER) report archive folders
        Write-Host "AVD AIB Customization : Windows Optimizations - Cleaning up WER report archive"
        Remove-Item -Path $env:ProgramData\Microsoft\Windows\WER\Temp\* -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $env:ProgramData\Microsoft\Windows\WER\ReportArchive\* -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $env:ProgramData\Microsoft\Windows\WER\ReportQueue\* -Recurse -Force -ErrorAction SilentlyContinue

        # Delete not in-use anything in your %temp% folder
        Write-Host "AVD AIB Customization : Windows Optimizations - Removing files not in use in $env:temp directory"
        Remove-Item -Path $env:TEMP\* -Recurse -Force -ErrorAction SilentlyContinue -Exclude packer*.ps1

        # Clear out ALL visible Recycle Bins
        Write-Host "AVD AIB Customization : Windows Optimizations - Clearing out ALL Recycle Bins"
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue

        # Clear out BranchCache cache
        Write-Host "AVD AIB Customization : Windows Optimizations - Clearing BranchCache cache" 
        Clear-BCCache -Force -ErrorAction SilentlyContinue
    }    
    #endregion
}
END {
    #Cleanup
    if ((Test-Path -Path $templateFilePathFolder -ErrorAction SilentlyContinue)) {
        Remove-Item -Path $templateFilePathFolder -Force -Recurse -ErrorAction Continue
    }

    if ((Test-Path -Path $WorkingLocation -ErrorAction SilentlyContinue)) {
        Remove-Item -Path $WorkingLocation -Force -Recurse -ErrorAction Continue
    }
    
    $stopwatch.Stop()
    $elapsedTime = $stopwatch.Elapsed
    Write-Host "*** AVD AIB CUSTOMIZER PHASE : Windows Optimizations - Exit Code: $LASTEXITCODE ***"    
    Write-Host "AVD AIB Customization : Windows Optimizations - Ending AVD AIB Customization : Windows Optimizations - Time taken: $elapsedTime"
}