configuration AddSessionHost
{
    param
    (    
        [Parameter(Mandatory = $true)]
        [string]$HostPoolName,

        [Parameter(Mandatory = $true)]
        [string]$RegistrationInfoToken,

        [Parameter(Mandatory = $false)]
        [bool]$AadJoin = $false,

        [Parameter(Mandatory = $false)]
        [string]$SessionHostConfigurationLastUpdateTime = "",

        [Parameter(Mandatory = $false)]
        [bool]$EnableVerboseMsiLogging = $false
    )

    $ErrorActionPreference = 'Stop'
    
    $ScriptPath = [system.io.path]::GetDirectoryName($PSCommandPath)
    . (Join-Path $ScriptPath "Functions.ps1")

    $rdshIsServer = isRdshServer

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
                    . (Join-Path $using:ScriptPath "Functions.ps1")

                    try {
                        & "$using:ScriptPath\Script-AddRdshServer.ps1" -HostPoolName $using:HostPoolName -RegistrationInfoToken $using:RegistrationInfoToken -EnableVerboseMsiLogging:($using:EnableVerboseMsiLogging)
                        if ($using:AadJoin -eq $true) {
                            # 6 Minute sleep to guarantee intune metadata logging
                            Write-Log -Message ("Configuration.ps1 complete, sleeping for 6 minutes")
                            Start-Sleep -Seconds 360
                            Write-Log -Message ("Configuration.ps1 complete, waking up from 6 minute sleep")
                        }
                    }
                    catch {
                        $ErrMsg = $PSItem | Format-List -Force | Out-String
                        Write-Log -Err $ErrMsg
                        throw [System.Exception]::new("Some error occurred in DSC ExecuteRdAgentInstallServer SetScript: $ErrMsg", $PSItem.Exception)
                    }
                    
                    $rdInfraAgentRegistryPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent"
                    If (Test-path $rdInfraAgentRegistryPath) {
                        Write-Log -Message ("Write SessionHostConfigurationLastUpdateTime '$using:SessionHostConfigurationLastUpdateTime' to $rdInfraAgentRegistryPath")
                        Set-ItemProperty -Path $rdInfraAgentRegistryPath -Name "SessionHostConfigurationLastUpdateTime" -Value $using:SessionHostConfigurationLastUpdateTime
                    }
                }
                TestScript = {
                    . (Join-Path $using:ScriptPath "Functions.ps1")
                    
                    try {
                        $rdInfraAgentRegistryPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent"
                        
                        if (Test-path $rdInfraAgentRegistryPath) {
                            $regTokenProperties = Get-ItemProperty -Path $rdInfraAgentRegistryPath -Name "RegistrationToken"
                            $isRegisteredProperties = Get-ItemProperty -Path $rdInfraAgentRegistryPath -Name "IsRegistered"
                            return ($regTokenProperties.RegistrationToken -eq "") -and ($isRegisteredProperties.isRegistered -eq 1)
                        } else {
                            return $false;
                        }
                    }
                    catch {
                        $ErrMsg = $PSItem | Format-List -Force | Out-String
                        Write-Log -Err $ErrMsg
                        throw [System.Exception]::new("Some error occurred in DSC ExecuteRdAgentInstallServer TestScript: $ErrMsg", $PSItem.Exception)
                    }

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
                    . (Join-Path $using:ScriptPath "Functions.ps1")
                    
                    try {
                        & "$using:ScriptPath\Script-AddRdshServer.ps1" -HostPoolName $using:HostPoolName -RegistrationInfoToken $using:RegistrationInfoToken -EnableVerboseMsiLogging:($using:EnableVerboseMsiLogging)
                        if ($using:AadJoin -eq $true) {
                            # 6 Minute sleep to guarantee intune metadata logging
                            Write-Log -Message ("Configuration.ps1 complete, sleeping for 6 minutes")
                            Start-Sleep -Seconds 360
                            Write-Log -Message ("Configuration.ps1 complete, waking up from 6 minute sleep")
                        }
                    }
                    catch {
                        $ErrMsg = $PSItem | Format-List -Force | Out-String
                        Write-Log -Err $ErrMsg
                        throw [System.Exception]::new("Some error occurred in DSC ExecuteRdAgentInstallClient SetScript: $ErrMsg", $PSItem.Exception)
                    }

                    $rdInfraAgentRegistryPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent"
                    If (Test-path $rdInfraAgentRegistryPath) {
                        Write-Log -Message ("Write SessionHostConfigurationLastUpdateTime '$using:SessionHostConfigurationLastUpdateTime' to $rdInfraAgentRegistryPath")
                        Set-ItemProperty -Path $rdInfraAgentRegistryPath -Name "SessionHostConfigurationLastUpdateTime" -Value $using:SessionHostConfigurationLastUpdateTime
                    }
                }
                TestScript = {
                    . (Join-Path $using:ScriptPath "Functions.ps1")
                    
                    try {
                        $rdInfraAgentRegistryPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent"
                        
                        if (Test-path $rdInfraAgentRegistryPath) {
                            $regTokenProperties = Get-ItemProperty -Path $rdInfraAgentRegistryPath -Name "RegistrationToken"
                            $isRegisteredProperties = Get-ItemProperty -Path $rdInfraAgentRegistryPath -Name "IsRegistered"
                            return ($regTokenProperties.RegistrationToken -eq "") -and ($isRegisteredProperties.isRegistered -eq 1)
                        } else {
                            return $false;
                        }
                    }
                    catch [Microsoft.PowerShell.Commands.ServiceCommandException] {
                        return true;
                    }
                    catch {
                        $ErrMsg = $PSItem | Format-List -Force | Out-String
                        Write-Log -Err $ErrMsg
                        throw [System.Exception]::new("Some error occurred in DSC ExecuteRdAgentInstallClient TestScript: $ErrMsg", $PSItem.Exception)
                    }

                }
            }
        }
    }
}