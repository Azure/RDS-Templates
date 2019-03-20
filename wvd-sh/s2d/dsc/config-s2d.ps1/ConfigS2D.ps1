
configuration ConfigS2D
{
    param
    (
        [Parameter(Mandatory)]
        [String]$DomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds,

        [Parameter(Mandatory)]
        [String]$ClusterName,

        [Parameter(Mandatory)]
        [String]$SOFSName,

        [Parameter(Mandatory)]
        [String]$ShareName,

        [Parameter(Mandatory)]
        [String]$vmNamePrefix,

        [Parameter(Mandatory)]
        [Int]$vmCount,

        [Parameter(Mandatory)]
        [Int]$vmDiskSize,

        [Parameter(Mandatory)]
        [String]$witnessStorageName,
	
	    [Parameter(Mandatory)]
        [String]$witnessStorageEndpoint,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$witnessStorageKey,

        [String]$DomainNetbiosName=(Get-NetBIOSName -DomainName $DomainName),

        [Int]$RetryCount=20,
        [Int]$RetryIntervalSec=30

    )

    Import-DscResource -ModuleName xComputerManagement, xActiveDirectory, xSOFS, xFailOverCluster
 
    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$($Admincreds.UserName)", $Admincreds.Password)
    [System.Management.Automation.PSCredential]$DomainFQDNCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)

    # Building node list
    [System.Collections.ArrayList]$Nodes=@()
    For ($count=0; $count -lt $vmCount; $count++)
    {
        $Nodes.Add($vmNamePrefix + $Count.ToString())
    }

    # Getting columns to be used when creating volume
    $Columns=(Get-StoragePool -IsPrimordial $true | Get-PhysicalDisk | Where-Object CanPool -eq $True).count

    # Setting up disk name
    $DiskName = "VDisk01"

    # Identifying OS release
    $OSVersionInfo = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
    
    if ($OSVersionInfo -ne $null)
    {
        if ($OSVersionInfo.ReleaseId -ne $null)
        {
            $Is1809OrLaterBool=@{$true = $true; $false = $false}[$OSVersionInfo.ReleaseId -ge 1809]
        }
    }

    Node localhost
    {
        LocalConfigurationManager 
        {
            RebootNodeIfNeeded = $true
        }

        WindowsFeature FC
        {
            Name = "Failover-Clustering"
            Ensure = "Present"
        }

		WindowsFeature FailoverClusterTools 
        { 
            Ensure = "Present" 
            Name = "RSAT-Clustering-Mgmt"
			DependsOn = "[WindowsFeature]FC"
        } 

        WindowsFeature FCPS
        {
            Name = "RSAT-Clustering-PowerShell"
            Ensure = "Present"
            DependsOn = "[WindowsFeature]FailoverClusterTools"
        }

        WindowsFeature FS
        {
            Name = "FS-FileServer"
            Ensure = "Present"
            DependsOn = "[WindowsFeature]FCPS"
        }

        WindowsFeature ADPS
        {
            Name = "RSAT-AD-PowerShell"
            Ensure = "Present"
            DependsOn = "[WindowsFeature]FS"
        }

        xWaitForADDomain DscForestWait 
        { 
            DomainName = $DomainName 
            DomainUserCredential= $DomainCreds
            RetryCount = $RetryCount 
            RetryIntervalSec = $RetryIntervalSec 
	        DependsOn = "[WindowsFeature]ADPS"
        }
        
        xComputer DomainJoin
        {
            Name = $env:COMPUTERNAME
            DomainName = $DomainName
            Credential = $DomainCreds
	        DependsOn = "[xWaitForADDomain]DscForestWait"
        }

        if ($Is1809OrLaterBool) # Windows 2019 Configuration
        {
            WindowsFeature DCBridging
            {
                Name = "Data-Center-Bridging"
                Ensure = "Present"
            }

            Script CreateCluster1809OrGt
            {
                GetScript = {
                    return @{Ensure = if ((Get-Cluster) -ne $null) {'Present'} else {'Absent'}}
                }
                SetScript = {
                    New-Cluster -Name $using:ClusterName -Node $using:Nodes -NoStorage   
                }
                TestScript = {
                    return ((Get-Cluster -ErrorAction SilentlyContinue) -ne $null)
                }
                DependsOn = "[xComputer]DomainJoin"
                PsDscRunAsCredential = $DomainFQDNCreds
            }

            Script CloudWitness1809OrGt
            {
                GetScript = {
                    $result = @{Ensure = 'Absent'}
                    $ClusterQuorum = Get-ClusterQuorum -ErrorAction SilentlyContinue
                    if ($ClusterQuorum -ne $null)
                    {
                        if ($ClusterQuorum.QuorumResource.Name -eq 'Cloud Witness') 
                        {
                            $result = @{Ensure = 'Present'}
                        }
                    }
                    return $result
                }
                SetScript = "Set-ClusterQuorum -CloudWitness -AccountName ${witnessStorageName} -AccessKey $($witnessStorageKey.GetNetworkCredential().Password) -Endpoint ${witnessStorageEndpoint}"
                TestScript = {
                    $result = $false
                    $ClusterQuorum = Get-ClusterQuorum -ErrorAction SilentlyContinue
                    if ($ClusterQuorum -ne $null)
                    {
                        if ($ClusterQuorum.QuorumResource.Name -eq 'Cloud Witness')
                        {
                            $result = $true
                        }
                    }
                    return ($result)
                }
                DependsOn = "[Script]CreateCluster1809OrGt"
                PsDscRunAsCredential = $DomainFQDNCreds
            }

            Script IncreaseClusterTimeouts1809OrGt
            {
                GetScript = {
                    $result = @{Ensure = 'Absent'}
                    $Cluster = Get-Cluster -ErrorAction SilentlyContinue
                    if ($Cluster -ne $null)
                    {
                        if ($Cluster.SameSubnetDelay -eq 2000 -and $Cluster.SameSubnetThreshold -eq 15 -and $Cluster.CrossSubnetDelay -eq 3000 -and $Cluster.CrossSubnetThreshold -eq 15) 
                        {
                            $result = @{Ensure = 'Present'}
                        }
                    }
                    return $result
                }
                SetScript = {
                    $Cluster = Get-Cluster
                    if ($Cluster -ne $null)
                    {
                        $Cluster.SameSubnetDelay = 2000
                        $Cluster.SameSubnetThreshold = 15
                        $Cluster.CrossSubnetDelay = 3000
                        $Cluster.CrossSubnetThreshold = 15
                    }
                }
                TestScript = {
                    $result = $false
                    $Cluster = Get-Cluster -ErrorAction SilentlyContinue
                    if ($Cluster -ne $null)
                    {
                        if ($Cluster.SameSubnetDelay -eq 2000 -and $Cluster.SameSubnetThreshold -eq 15 -and $Cluster.CrossSubnetDelay -eq 3000 -and $Cluster.CrossSubnetThreshold -eq 15) 
                        {
                            $result = $true
                        }
                    }
                    return $result
                }
                DependsOn = "[Script]CloudWitness1809OrGt"
                PsDscRunAsCredential = $DomainFQDNCreds
            }

            Script EnableS2D1809OrGt
            {
                GetScript = {
                    $result = @{Ensure = 'Absent'}
                    $SharedVolume = Get-ClusterSharedVolume -ErrorAction SilentlyContinue
                    if ($SharedVolume -ne $null)
                    {
                        if ($SharedVolume.ShareState -eq 'Online')
                        {
                            $result = @{Ensure = 'Present'}
                        }
                    }
                    return $result
                }
                SetScript = {
                    Enable-ClusterStorageSpacesDirect -Confirm:$false
                    New-Volume -StoragePoolFriendlyName S2D* -FriendlyName $using:DiskName -FileSystem CSVFS_REFS -UseMaximumSize -ResiliencySettingName "Mirror" -NumberOfColumns $using:Columns
                }
                TestScript = {
                    $result = $false
                    $SharedVolume = Get-ClusterSharedVolume -ErrorAction SilentlyContinue
                    if ($SharedVolume -ne $null)
                    {
                        if ($SharedVolume.ShareState -eq 'Online')
                        {
                            $result = $true
                        }
                    }
                    return $result
                }
                DependsOn = "[Script]IncreaseClusterTimeouts1809OrGt"
                PsDscRunAsCredential = $DomainFQDNCreds
            }

            Script EnableSofs1809OrGt
            {
                GetScript = {
                    return @{Ensure = if ((Get-ClusterS2D -ErrorAction SilentlyContinue) -ne $null) {'Present'} Else {'Absent'}}
                }
                SetScript = {
                    Add-ClusterScaleOutFileServerRole -Name $using:SOFSName
                }
                TestScript = {
                    return ((Get-ClusterS2D -ErrorAction SilentlyContinue) -ne $null)
                }
                DependsOn = "[Script]EnableS2D1809OrGt"
                PsDscRunAsCredential = $DomainFQDNCreds
            }

            Script CreateShare1809OrGt
            {
                GetScript = {
                    return @{Ensure = if ( (Get-SmbShare -name $using:ShareName -ErrorAction SilentlyContinue) -ne $null) {'Present'} Else {'Absent'}}
                }
                SetScript = "New-Item -Path C:\ClusterStorage\${diskName}\${shareName} -ItemType Directory; New-SmbShare -Name ${ShareName} -Path C:\ClusterStorage\${diskName}\${shareName} -FullAccess ${DomainName}\$($AdminCreds.Username)"
                TestScript = {
                    return ((Get-SmbShare -name $using:ShareName -ErrorAction SilentlyContinue) -ne $null)
                }
                DependsOn = "[Script]EnableSofs1809OrGt"
                PsDscRunAsCredential = $DomainFQDNCreds
            }
        }
        else # Windows 2016 Configuration
        {
            xCluster FailoverCluster
            {
                Name = $ClusterName
                DomainAdministratorCredential = $DomainCreds
                Nodes = $Nodes
                DependsOn = "[xComputer]DomainJoin"
            }
    
            Script CloudWitness
            {
                SetScript = "Set-ClusterQuorum -CloudWitness -AccountName ${witnessStorageName} -AccessKey $($witnessStorageKey.GetNetworkCredential().Password) -Endpoint ${witnessStorageEndpoint}"
                TestScript = "(Get-ClusterQuorum).QuorumResource.Name -eq 'Cloud Witness'"
                GetScript = "@{Ensure = if ((Get-ClusterQuorum).QuorumResource.Name -eq 'Cloud Witness') {'Present'} else {'Absent'}}"
                DependsOn = "[xCluster]FailoverCluster"
            }
    
            Script IncreaseClusterTimeouts
            {
                SetScript = "(Get-Cluster).SameSubnetDelay = 2000; (Get-Cluster).SameSubnetThreshold = 15; (Get-Cluster).CrossSubnetDelay = 3000; (Get-Cluster).CrossSubnetThreshold = 15"
                TestScript = "(Get-Cluster).SameSubnetDelay -eq 2000 -and (Get-Cluster).SameSubnetThreshold -eq 15 -and (Get-Cluster).CrossSubnetDelay -eq 3000 -and (Get-Cluster).CrossSubnetThreshold -eq 15"
                GetScript = "@{Ensure = if ((Get-Cluster).SameSubnetDelay -eq 2000 -and (Get-Cluster).SameSubnetThreshold -eq 15 -and (Get-Cluster).CrossSubnetDelay -eq 3000 -and (Get-Cluster).CrossSubnetThreshold -eq 15) {'Present'} else {'Absent'}}"
                DependsOn = "[Script]CloudWitness"
            }
    
            Script EnableS2D
            {
                SetScript = "Enable-ClusterS2D -Confirm:0; New-Volume -StoragePoolFriendlyName S2D* -FriendlyName VDisk01 -FileSystem CSVFS_REFS -UseMaximumSize"
                TestScript = "(Get-ClusterSharedVolume).State -eq 'Online'"
                GetScript = "@{Ensure = if ((Get-ClusterSharedVolume).State -eq 'Online') {'Present'} Else {'Absent'}}"
                DependsOn = "[Script]IncreaseClusterTimeouts"
            }
    
            xSOFS EnableSOFS
            {
                SOFSName = $SOFSName
                DomainAdministratorCredential = $DomainCreds
                DependsOn = "[Script]EnableS2D"
            }
    
            Script CreateShare
            {
                SetScript = "New-Item -Path C:\ClusterStorage\Volume1\${ShareName} -ItemType Directory; New-SmbShare -Name ${ShareName} -Path C:\ClusterStorage\Volume1\${ShareName} -FullAccess ${DomainName}\$($AdminCreds.Username)"
                TestScript = "(Get-SmbShare -Name ${ShareName} -ErrorAction SilentlyContinue).ShareState -eq 'Online'"
                GetScript = "@{Ensure = if ((Get-SmbShare -Name ${ShareName} -ErrorAction SilentlyContinue).ShareState -eq 'Online') {'Present'} Else {'Absent'}}"
                DependsOn = "[xSOFS]EnableSOFS"
            }
        }
    }
}

function Get-NetBIOSName
{ 
    [OutputType([string])]
    param(
        [string]$DomainName
    )

    if ($DomainName.Contains('.')) {
        $length=$DomainName.IndexOf('.')
        if ( $length -ge 16) {
            $length=15
        }
        return $DomainName.Substring(0,$length)
    }
    else {
        if ($DomainName.Length -gt 15) {
            return $DomainName.Substring(0,15)
        }
        else {
            return $DomainName
        }
    }
}