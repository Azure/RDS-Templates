Configuration SelfhostConfig {

    param(
                    [parameter(Mandatory=$true)][string]$Prof,
                    [parameter(Mandatory=$true)][string[]] $Admins,
                    [parameter(Mandatory=$true)][string[]] $FSXLogPath
            )

	Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

	$defaultProf = @(@{path="HKLM:\TempDefault\Software\Policies\Microsoft\Office\16.0\common"; name="InsiderSlabBehavior"; value ="2"},
			@{path="HKLM:\TempDefault\software\policies\microsoft\office\16.0\outlook\cached mode"; name="enable"; value = 1},
			@{path="HKLM:\TempDefault\software\policies\microsoft\office\16.0\outlook\cached mode"; name="CalendarSyncWindowSetting"; value = 1},
			@{path="HKLM:\TempDefault\software\policies\microsoft\office\16.0\outlook\cached mode"; name="CalendarSyncWindowSettingMonths"; value = 1},
			@{path="HKLM:\TempDefault\software\policies\microsoft\office\16.0\outlook\cached mode"; name="syncwindowsetting"; value=1})


	Node "localhost"
	{

#FSLogix Keys
		Registry ProfileEnable
		{
			Ensure      = "Present"
                        Key         = "HKEY_LOCAL_MACHINE\SOFTWARE\FSLogix\Profiles"
                        ValueName   = "Enabled"
                        ValueData   = 1
                        ValueType   = "DWORD"
		}
		Registry ProfileLocation
		{
			Ensure      = "Present"
                        Key         = "HKEY_LOCAL_MACHINE\SOFTWARE\FSLogix\Profiles"
                        ValueName   = "VHDLocations"
                        ValueData   = $Prof
		}
		Registry PreventLoginFailure
		{
			Ensure      = "Present"
                        Key         = "HKEY_LOCAL_MACHINE\SOFTWARE\FSLogix\Profiles"
                        ValueName   = "PreventLoginWithFailure"
                        ValueData   = 1
                        ValueType   = "DWORD"
		}
		Registry PreventLoginWithTempProfile
		{
			Ensure      = "Present"
                        Key         = "HKEY_LOCAL_MACHINE\SOFTWARE\FSLogix\Profiles"
                        ValueName   = "PreventLoginWithTempProfile"
                        ValueData   = 1
                        ValueType   = "DWORD"
		}
		Registry LogPeriod
		{
			Ensure      = "Present"
                        Key         = "HKEY_LOCAL_MACHINE\SOFTWARE\FSLogix\Logging"
                        ValueName   = "LogFileKeepingPeriod"
                        ValueData   = 10
                        ValueType   = "DWORD"
		}
		Registry LogLocation
		{
			Ensure      = "Present"
                        Key         = "HKEY_LOCAL_MACHINE\SOFTWARE\FSLogix\Logging"
                        ValueName   = "LogDir"
                        ValueData   = "$FSXLogPath\$($env:computername)"
		}
		Registry DisableRegistryLocalRedirect
		{
			Ensure      = "Present"
                        Key         = "HKEY_LOCAL_MACHINE\SOFTWARE\FSLogix\Profiles"
                        ValueName   = "DisableRegistryLocalRedirect"
                        ValueData   = 0
                        ValueType   = "DWORD"
		}
		Registry DeleteLocalProfileWhenVHDShouldApply
		{
			Ensure      = "Present"
                        Key         = "HKEY_LOCAL_MACHINE\SOFTWARE\FSLogix\Profiles"
                        ValueName   = "DeleteLocalProfileWhenVHDShouldApply"
                        ValueData   = 1
                        ValueType   = "DWORD"
		}

# Diasble MMA to change watson settings

		Registry DisableMMAWatson
		{
			Ensure      = "Present"
                        Key         = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\HealthService\Parameters"
                        ValueName   = "Disable CDR Agent"
                        ValueData   = 1
                        ValueType   = "DWORD"
		}

# Configure Automatic Update set to Disabled

		Registry DisableUA
		{
			Ensure      = "Present"
                        Key         = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
                        ValueName   = "NoAutoUpdate"
                        ValueData   = 1
                        ValueType   = "DWORD"
		}

# TermServ limits       

		Registry MaxIdleTime
		{
			Ensure      = "Present"
                        Key         = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
                        ValueName   = "MaxIdleTime"
                        ValueData   = 7200000
                        ValueType   = "DWORD"
		}
		Registry MaxDisconnectionTime
		{
			Ensure      = "Present"
                        Key         = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
                        ValueName   = "MaxDisconnectionTime"
                        ValueData   = 28800000
                        ValueType   = "DWORD"
		}
		Registry RemoteAppLogoffTimeLimit
		{
			Ensure      = "Present"
                        Key         = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
                        ValueName   = "RemoteAppLogoffTimeLimit"
                        ValueData   = 28800000
                        ValueType   = "DWORD"
		}

# TermServ Redirection

		Registry TimeZoneRedirection
		{
			Ensure      = "Present"
                        Key         = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
                        ValueName   = "fEnableTimeZoneRedirection"
                        ValueData   = 1
                        ValueType   = "DWORD"
		}

# Multimedia Redirection

		Registry AllowRdpMultimediaRedirection 
		{
			Ensure      = "Present"
                        Key         = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server"
                        ValueName   = "AllowRdpMultimediaRedirection"
                        ValueData   = 1
                        ValueType   = "DWORD"
		}
		Registry TSMMRemotingAllowedApps_wmp
		{
			Ensure      = "Present"
                        Key         = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\TSMMRemotingAllowedApps"
                        ValueName   = "wmplayer.exe"
                        ValueData   = 1
                        ValueType   = "DWORD"
		}
                
# 5k resolution
#		Registry MaxMonitors
#		{
#			Ensure      = "Present"  # You can also set Ensure to "Absent"
#				Key         = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
#				ValueName   = "MaxMonitors"
#				ValueData   = 4
#		}
#		Registry MaxXResolution
#		{
#			Ensure      = "Present"  # You can also set Ensure to "Absent"
#				Key         = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
#				ValueName   = "MaxXResolution"
#				Hex         = $true
#				ValueData   = "00001400"
#		}
#		Registry MaxYResolution
#		{
#			Ensure      = "Present"  # You can also set Ensure to "Absent"
#				Key         = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
#				ValueName   = "MaxYResolution"
#				Hex         = $true
#				ValueData   = "00000b40"
#		}
#		Registry MaxMonitorsS
#		{
#			Ensure      = "Present"  # You can also set Ensure to "Absent"
#				Key         = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\rdp-sxs"
#				ValueName   = "MaxMonitors"
#				ValueData   = 4
#		}
#		Registry MaxXResolutionS
#		{
#			Ensure      = "Present"  # You can also set Ensure to "Absent"
#				Key         = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\rdp-sxs"
#				ValueName   = "MaxXResolution"
#				Hex         = $true
#				ValueData   = "00001400"
#		}
#		Registry MaxYResolutionS
#		{
#			Ensure      = "Present"  # You can also set Ensure to "Absent"
#				Key         = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\rdp-sxs"
#				ValueName   = "MaxYResolution"
#				Hex         = $true
#				ValueData   = "00000b40"
#		}
# End of 5k Resolution


# Edge defaults

		Registry ConfigureOpenMicrosoftEdgeWith
		{
			Ensure      = "Present"
                        Key         = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Internet Settings"
                        ValueName   = "ConfigureOpenMicrosoftEdgeWith"
                        ValueData   = 3
                        ValueType   = "DWORD"
		}
		Registry DisableLockdownOfStartPages
		{
			Ensure      = "Present"
                        Key         = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Internet Settings"
                        ValueName   = "DisableLockdownOfStartPages"
                        ValueData   = 1
                        ValueType   = "DWORD"
		}
		Registry ConfigureHomeButton
		{
			Ensure      = "Present"
                        Key         = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Internet Settings"
                        ValueName   = "ConfigureHomeButton"
                        ValueData   = 0
                        ValueType   = "DWORD"
		}
		Registry UnlockHomeButton
		{
			Ensure      = "Present"
                        Key         = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Internet Settings"
                        ValueName   = "UnlockHomeButton"
                        ValueData   = 1
                        ValueType   = "DWORD"
		}
		Registry ProvisionedHomePages
		{
			Ensure      = "Present"
                        Key         = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Internet Settings"
                        ValueName   = "ProvisionedHomePages"
                        ValueData   = "<https://www.office.com/?auth=2&from=WVD>"
		}

		`
		Group AddAdminGroups {
			GroupName        = 'administrators'
				Ensure           = 'Present'
				MembersToInclude = $Admins
		}

# End Edge defaults

# Start Outlook

		Registry PreventIndexingEmailAttachments
		{
			Ensure      = "Present"
                        Key         = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
                        ValueName   = "PreventIndexingEmailAttachments"
                        ValueData   = 1
                        ValueType   = "DWORD"
		}

				Script OutlookCacheMode {

			SetScript = {

                                        reg load HKLM\TempDefault C:\Users\Default\NTUSER.DAT

                                        Start-Sleep -Seconds  1

					foreach ($a in $defaultProf)
					{
						if(Test-Path $a.path)
						{
							New-ItemProperty -Path $a.path -Name $a.name -Value $a.value -Force
						}
						else
						{
							New-Item -Path $a.path -Force
							New-ItemProperty -Path $a.path -Name $a.name -Value $a.value    
						}
					}

					Start-Sleep -Seconds 5

                                        reg unload HKLM\TempDefault
			}

			TestScript = {
                                        reg load HKLM\TempDefault C:\Users\Default\NTUSER.DAT

                                        Start-Sleep -Seconds  1


				$result = $true

					foreach ($a in $defaultProf)
					{
						if(!(Test-Path $a.path))
						{
							Write-Information -message '$($s.path) not found'
							$result = $false
						}
						else
						{
							$value = Get-ItemProperty -Path $a.path -Name $a.name  |Select-Object -ExpandProperty $a.name 
								if($value -ne $a.value)
								{ 
									Write-Information -message '$($s.path) has no compliant value $($a.name):$value'
									$result = $false
								}
								else
								{
									Write-Information -message 'Compliant:$($s.path) $($a.name):$value'
								}
						}

					}
					Start-Sleep -Seconds 5


					reg unload HKLM\TempDefault

					$result
			}
			GetScript = {@{Result="Ok"}}
		}

        Script RestartFSLogix {
            SetScript = {
                Restart-Service -Name frxsvc
            }

            TestScript = {
                $result = $false
                Get-Service -Name frxsvc
                $result
            }
            GetScript = {@{Result="Ok"}}
            DependsOn = "[Registry]LogLocation"
        } 
	}
}
