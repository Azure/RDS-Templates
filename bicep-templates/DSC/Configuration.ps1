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
                        & "$using:ScriptPath\Script-SetupSessionHost.ps1" -HostPoolName $using:HostPoolName -RegistrationInfoToken $using:RegistrationInfoToken -AadJoin $using:AadJoin -SessionHostConfigurationLastUpdateTime $using:SessionHostConfigurationLastUpdateTime -EnableVerboseMsiLogging:($using:EnableVerboseMsiLogging)
                    }
                    catch {
                        $ErrMsg = $PSItem | Format-List -Force | Out-String
                        Write-Log -Err $ErrMsg
                        throw [System.Exception]::new("Some error occurred in DSC ExecuteRdAgentInstallServer SetScript: $ErrMsg", $PSItem.Exception)
                    }
                }
                TestScript = {
                    . (Join-Path $using:ScriptPath "Functions.ps1")
                    
                    try {
                        return (& "$using:ScriptPath\Script-TestSetupSessionHost.ps1" -HostPoolName $using:HostPoolName)
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
                        & "$using:ScriptPath\Script-SetupSessionHost.ps1" -HostPoolName $using:HostPoolName -RegistrationInfoToken $using:RegistrationInfoToken -AadJoin $using:AadJoin -SessionHostConfigurationLastUpdateTime $using:SessionHostConfigurationLastUpdateTime -EnableVerboseMsiLogging:($using:EnableVerboseMsiLogging)
                    }
                    catch {
                        $ErrMsg = $PSItem | Format-List -Force | Out-String
                        Write-Log -Err $ErrMsg
                        throw [System.Exception]::new("Some error occurred in DSC ExecuteRdAgentInstallClient SetScript: $ErrMsg", $PSItem.Exception)
                    }
                }
                TestScript = {
                    . (Join-Path $using:ScriptPath "Functions.ps1")
                    
                    try {
                        return (& "$using:ScriptPath\Script-TestSetupSessionHost.ps1" -HostPoolName $using:HostPoolName)
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