Configuration SelfhostConfig {

        param(
                        [parameter(Mandatory=$true)][string]$Prof,
                        [parameter(Mandatory=$true)][string] $BaseUrl,
                        [parameter(Mandatory=$true)][string[]] $Admins,
                        [string] $SXSMsi,
                        [string] $enableScript
             )

	Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

		$defaultProf = @(  @{path="HKLM:\TempDefault\Software\Microsoft\Office\16.0\common\Logging "; name="EnableLogging"; value = 1},
				@{path="HKLM:\TempDefault\Software\Policies\Microsoft\Office\16.0\common"; name="InsiderSlabBehavior"; value ="1"},
				@{path="HKLM:\TempDefault\software\policies\microsoft\office\16.0\outlook\cached mode"; name="enable"; value = 1},
				@{path="HKLM:\TempDefault\software\policies\microsoft\office\16.0\outlook\cached mode"; name="syncwindowsetting"; value=1})

#Find the SKU
$osinfo = Get-WmiObject -Class Win32_OperatingSystem -Namespace "root\cimv2"
if($osinfo.Caption.Contains("Enterprise"))
{
        $rdshName = "AppServerClient"
}
else
{
        $rdshName = "RDS-RD-Server"
}



$msiUrl = "$BaseUrl/$SXSMsi"
$scriptUrl = "$BaseUrl/$enableScript"



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
		Registry OfficeEnabled
		{
			Ensure      = "Present"
                        Key         = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\FSLogix\ODFC"
                        ValueName   = "Enabled"
                        ValueData   = 1
                        ValueType   = "DWORD"
		}
		Registry OfficeLocation
		{
			Ensure      = "Present"
                        Key         = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\FSLogix\ODFC"
                        ValueName   = "VHDLocations"
                        ValueData   = $Prof
		}
		Registry LogPeriod
		{
			Ensure      = "Present"
                        Key         = "HKEY_LOCAL_MACHINE\SOFTWARE\FSLogix\Logging"
                        ValueName   = "LogFileKeepingPeriod"
                        ValueData   = 10
                        ValueType   = "DWORD"
		}
		Registry DisableRegistryLocalRedirect
		{
			Ensure      = "Present"
                        Key         = "HKEY_LOCAL_MACHINE\SOFTWARE\FSLogix\Profiles"
                        ValueName   = "DisableRegistryLocalRedirect"
                        ValueData   = 1
                        ValueType   = "DWORD"
		}


# TermServ limits       

		Registry MaxIdleTime
		{
			Ensure      = "Present"
                        Key         = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
                        ValueName   = "MaxIdleTime"
                        ValueData   = 3600000
                        ValueType   = "DWORD"
		}
		Registry MaxDisconnectionTime
		{
			Ensure      = "Present"
                        Key         = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
                        ValueName   = "MaxDisconnectionTime"
                        ValueData   = 86400000
                        ValueType   = "DWORD"
		}
		Registry RemoteAppLogoffTimeLimit
		{
			Ensure      = "Present"
                        Key         = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
                        ValueName   = "RemoteAppLogoffTimeLimit"
                        ValueData   = 86400000
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
                


# 5k resolution
		Registry MaxMonitors
		{
			Ensure      = "Present"  # You can also set Ensure to "Absent"
				Key         = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
				ValueName   = "MaxMonitors"
				ValueData   = 4
                                DependsOn ="[Script]SXSStack"
		}
		Registry MaxXResolution
		{
			Ensure      = "Present"  # You can also set Ensure to "Absent"
				Key         = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
				ValueName   = "MaxXResolution"
				Hex         = $true
				ValueData   = "00001400"
                                DependsOn ="[Script]SXSStack"
		}
		Registry MaxYResolution
		{
			Ensure      = "Present"  # You can also set Ensure to "Absent"
				Key         = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
				ValueName   = "MaxYResolution"
				Hex         = $true
				ValueData   = "00000b40"
                                DependsOn ="[Script]SXSStack"
		}
		Registry MaxMonitorsS
		{
			Ensure      = "Present"  # You can also set Ensure to "Absent"
				Key         = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\rdp-sxs"
				ValueName   = "MaxMonitors"
				ValueData   = 4
                                DependsOn ="[Script]SXSStack"
		}
		Registry MaxXResolutionS
		{
			Ensure      = "Present"  # You can also set Ensure to "Absent"
				Key         = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\rdp-sxs"
				ValueName   = "MaxXResolution"
				Hex         = $true
				ValueData   = "00001400"
                                DependsOn ="[Script]SXSStack"
		}
		Registry MaxYResolutionS
		{
			Ensure      = "Present"  # You can also set Ensure to "Absent"
				Key         = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\rdp-sxs"
				ValueName   = "MaxYResolution"
				Hex         = $true
				ValueData   = "00000b40"
                                DependsOn ="[Script]SXSStack"
		}



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


                Script SXSStack {

                        SetScript = { 
                                function Download($url, $output)
                                {

                                        $wc = New-Object System.Net.WebClient
                                                $wc.DownloadFile($url, $output)   

                                }

                                if([environment]::OSversion.Version.Build -lt 16773)
                                {
# Intall SXS msi

                                        Download $using:msiUrl ".\sxs.msi"

# Wait for msi to finish
                                                Start-Process msiexec.exe -Wait -ArgumentList '/I .\sxs.msi /quiet'

                                                $DataStamp = get-date -Format yyyyMMddTHHmmss
                                                $logFile = 'SXSinstall-{0}.log' -f $DataStamp
                                                $MSIArguments = @(
                                                                "/i"
                                                                "sxs.msi"
                                                                "/qn"
                                                                "/norestart"
                                                                "/L*v"
                                                                $logFile
                                                                )
                                                Start-Process "msiexec.exe" -ArgumentList $MSIArguments -Wait -NoNewWindow 

                                }
                                else
                                { 
                                        Get-Location|Write-Verbose
                                        Write-Verbose "Donloading $($using:scriptUrl)"
                                        Download $using:scriptUrl  ".\enable.ps1"
                                        Write-Verbose "Calling .\enable.ps1"

                                        $enablesxs_deploy_status = PowerShell.exe -ExecutionPolicy Unrestricted -File "enable.ps1"
                                        $sts = $enablesxs_deploy_status.ExitCode
                                        Write-Verbose "Enabling Built-in RD SxS Stack on VM Complete. Exit code=$sts"
                                }
                        }
                        TestScript = {
                                $out = qwinsta
                                $result =$false
                                foreach($line in $out)
                                {
                                        if($line.Contains("rdp-sxs")) {
                                                Write-Verbose "Found sxs stack:$line"
                                                $result = $true
                                        }

                                }

                                $result        
                        }
			GetScript = {@{Result="Ok"}}
                }

	}

}
