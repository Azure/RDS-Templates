configuration SessionHost
{
    param
    (
        [Parameter(mandatory = $true)]
        [string]$RDBrokerURL,
    
        [Parameter(mandatory = $true)]
        [string]$DefinedTenantGroupName,
    
        [Parameter(mandatory = $true)]
        [string]$TenantName,
    
        [Parameter(mandatory = $true)]
        [string]$HostPoolName,
    
        [Parameter(mandatory = $false)]
        [string]$Description,
    
        [Parameter(mandatory = $false)]
        [string]$FriendlyName,
    
        [Parameter(mandatory = $true)]
        [string]$Hours,
    
        [Parameter(mandatory = $true)]
        [PSCredential]$TenantAdminCredentials,
    
        [Parameter(mandatory = $true)]
        [PSCredential]$ADAdminCredentials,
    
        [Parameter(mandatory = $false)]
        [string]$isServicePrincipal = "False",
    
        [Parameter(Mandatory = $false)]
        [string]$AadTenantId,
    
        [Parameter(Mandatory = $true)]
        [string]$ActivationKey,
    
        [Parameter(Mandatory = $true)]
        [string]$EnablePersistentDesktop="False"
    )

    $rdshIsServer = $true
    $rdshIs1809OrLater = $false
    $ScriptPath = [system.io.path]::GetDirectoryName($PSCommandPath)

    $OSVersionInfo = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
    
    if ($OSVersionInfo -ne $null)
    {
        if ($OSVersionInfo.ReleaseId -ne $null)
        {
            Write-Log -Message "Build: $($OSVersionInfo.ReleaseId)"
            $rdshIs1809OrLater=@{$true = $true; $false = $false}[$OSVersionInfo.ReleaseId -ge 1809]
        }
    
        if ($OSVersionInfo.InstallationType -ne $null)
        {
            Write-Log -Message "OS Installation type: $($OSVersionInfo.InstallationType)"
            $rdshIsServer=@{$true = $true; $false = $false}[$OSVersionInfo.InstallationType -eq "Server"]
        }
    }

    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
            ConfigurationMode = "ApplyOnly"
        }

        if ($rdshIsServer)
        {
            "$(get-date) - rdshIsServer = true: $rdshIsServer" | out-file c:\windows\temp\rdshIsServerResult.txt -Append
            WindowsFeature RDS-RD-Server
            {
                Ensure = "Present"
                Name = "RDS-RD-Server"
            }

            Script ExecuteRdAgentInstallServer
            {
                DependsOn = "[WindowsFeature]RDS-RD-Server"
                GetScript = {
                    return @{'Result' = ''}
                }
                SetScript = {
                    & "$using:ScriptPath\Script.ps1" -RdBrokerURL $using:RDBrokerURL -DefinedTenantGroupName $using:DefinedTenantGroupName -TenantName $using:TenantName -TenantAdminCredentials $using:TenantAdminCredentials -ADAdminCredentials $using:ADAdminCredentials -HostPoolName $using:HostPoolName -FriendlyName $using:FriendlyName -Description $using:Description -Hours $using:Hours -isServicePrincipal $using:isServicePrincipal -aadTenantId $using:AadTenantId -EnablePersistentDesktop $using:EnablePersistentDesktop
                }
                TestScript = {
                    return (Test-path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent")
                }
            }
        }
        else
        {
            "$(get-date) - rdshIsServer = false: $rdshIsServer" | out-file c:\windows\temp\rdshIsServerResult.txt -Append
            Script ExecuteRdAgentInstallClient
            {
                GetScript = {
                    return @{'Result' = ''}
                }
                SetScript = {
                    & "$using:ScriptPath\Script.ps1" -RdBrokerURL $using:RDBrokerURL -DefinedTenantGroupName $using:DefinedTenantGroupName -TenantName $using:TenantName -TenantAdminCredentials $using:TenantAdminCredentials -ADAdminCredentials $using:ADAdminCredentials -HostPoolName $using:HostPoolName -FriendlyName $using:FriendlyName -Description $using:Description -Hours $using:Hours -isServicePrincipal $using:isServicePrincipal -aadTenantId $using:AadTenantId -EnablePersistentDesktop $using:EnablePersistentDesktop
                }
                TestScript = {
                    return (Test-path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent")
                }
            }

            if ($rdshIs1809OrLater)
            {
                Script ActivateWindowsClient
                {
                    DependsOn = "[Script]ExecuteRdAgentInstallClient"
                    GetScript = {
                        return @{'Result' = ''}
                    }
                    SetScript = {
                        # Activating Windows EVD
                        & cscript c:\windows\system32\slmgr.vbs /ipk $using:ActivationKey
                        dism /online /Enable-Feature /FeatureName:AppServerClient /NoRestart /Quiet

                        # Need to change DscExtensionHandler in order to wait for WinRM to start
                        $DscRoot = "C:\Packages\Plugins\Microsoft.Powershell.DSC"
                        $DscExtHandlerFileName = "DscExtensionHandler.psm1"

                        $DscModuleFile = (Get-ChildItem $DscRoot\ -Filter $DscExtHandlerFileName -Recurse | Select-Object).FullName
                        
                        if ($DscModuleFile.Count -gt 1)
                        {
                            $SortedList = @()
                            foreach ($File in $DscModuleFile)
                            {
                                [version]$version = $File.split("\")[4]
                                $SortedList += New-Object -TypeName psobject -Property @{"version"=$version;"fullName"=$File}
                            }
                            $DscModuleFile = ($SortedList | Sort-Object version -Descending)[0].FullName
                        }

                        $CodeToSearch = "Write-Log `"Starting DSC Extension ...`""
                        $CodeToReplace = "Write-Log `"Starting DSC Extension ...`"`n
            `$Start = Get-Date
            `$TimeOutInMin = 15
            While ((get-service -Name WinRM).Status -ne `"Running`")
            {
                Write-Log `"Waiting for WinRM...`"
                if (-(`$Start.Subtract((Get-Date)).minutes) -ge `$TimeOutInMin)
                {
                    throw(`"Reached out timeout of `$TimeOutInMin minute(s) while waiting for WinRM`")
                }
                Start-Sleep 10
            }"

                        (Get-Content $DscModuleFile).replace($CodeToSearch, $CodeToReplace) | Set-Content $DscModuleFile

                        # Reboot
                        $global:DSCMachineStatus = 1 
                    }
                    TestScript = {
                        $ActivationKey = $using:ActivationKey
                        $output = & cscript c:\windows\system32\slmgr.vbs /dli
                        $PartialKey = ($output | Where-Object { $_.contains("Partial Product Key:")}).split(":",[System.StringSplitOptions]::RemoveEmptyEntries)[1].trim()

                        "Partial Key: $PartialKey" | Out-File "$env:SystemRoot\temp\SlmgrOutput.txt" -Append
                        "Activation Key: $ActivationKey" | Out-File "$env:SystemRoot\temp\SlmgrOutput.txt" -Append

                        if ($ActivationKey.Contains($PartialKey))
                        {
                            return $true
                        }
                        else
                        {
                            return $false 
                        }
                    }
                }
            }
        }
    }
}