[CmdletBinding()]
param (
    [Parameter(
        Position = 0,
        ValuefromPipelineByPropertyName = $true,
        ValuefromPipeline = $true,
        Mandatory = $true
    )]
    [Alias("DiskImage")]
    [Alias("FullName")]
    [System.IO.FileInfo[]]$Path
)

begin {
    #requires -RunAsAdministrator
    Set-StrictMode -Version Latest
    #See https://learn.microsoft.com/en-us/azure/virtual-desktop/app-attach for docs on this
}

process {
    foreach ($Disk in $Path) {
  
        if (-not( Test-Path $Disk )) {
            Write-Error "$Disk cannot be reached from this location"
            return
        }

        $fileInfo = Get-ChildItem -Path $Disk

        function mountvhd { 
            $mnt = Mount-Diskimage -ImagePath $Disk -PassThru -NoDriveLetter -Access ReadOnly
            $partition = Get-Partition -DiskNumber $mnt.Number
            $out = [PSCustomObject]@{
                DeviceId = $partition.AccessPaths
                ImagePath = $mnt.ImagePath
            }
            Write-Output $out
        }

        #Mount the disk as read only
        switch ($fileInfo.Extension) {
            '.vhdx' { $mount = mountvhd ; break }
            '.vhd' { $mount = mountvhd ; break }
            '.Cim' {
                try {
                    Import-Module -Name CimDiskImage -ErrorAction Stop
                }
                catch {
                    Install-Module CimDiskImage -Scope CurrentUser -SkipPublisherCheck -Force
                    Import-Module CimDiskImage
                }
        
                $mount = Mount-CimDiskimage -ImagePath $Disk -PassThru -NoMountPath
                break
            }
            Default {
                Write-Error "File $Disk did not match supported diskimage types Vhd(x) or Cim"
                return
            }
        }

        If (-Not ($mount.PSobject.Properties.Name -contains "DeviceId") ) {
            Write-Error "File $Disk failed to mount"
            return
        }

        if ($PSVersionTable.PSEdition -eq 'Core') {
           
            $nuGetPackageName = 'Microsoft.Windows.SDK.NET.Ref'
            try {
                $winRT = Get-Package $nuGetPackageName -ErrorAction Stop
            }
            catch {
                if (-Not (Get-PackageProvider -Name Nuget)) {
                    Register-PackageSource -Name MyNuGet -Location https://www.nuget.org/api/v2 -ProviderName NuGet -Confirm:$false
                }
                Find-Package $nuGetPackageName | Install-Package -Force
                $winRT = Get-Package $nuGetPackageName
            }

            $dllWinRT = Get-Childitem (Split-Path -Parent $winRT.Source) -Recurse -File WinRT.Runtime.dll
            $dllSdkNet = Get-Childitem (Split-Path -Parent $winRT.Source) -Recurse -File Microsoft.Windows.SDK.NET.dll
            Add-Type -AssemblyName $dllWinRT.FullName
            Add-Type -AssemblyName $dllSdkNet.FullName
        }

        if ($PSVersionTable.PSEdition -eq 'Desktop') {

            [Windows.Management.Deployment.PackageManager, Windows.Management.Deployment, ContentType = WindowsRuntime] | Out-Null
            Add-Type -AssemblyName System.Runtime.WindowsRuntime

        }

        $manifest = Get-Childitem -LiteralPath $mount.DeviceId -Recurse -File AppxManifest.xml

        $manifestFolder = $manifest.DirectoryName
        $msixPackageFullName = $manifestFolder.Split('\')[-1]
        $folderUri = $maniFestFolder.Replace('\\?\', 'file:\\\')
        $folderAbsoluteUri = ([Uri]$folderUri).AbsoluteUri

        $asTask = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.ToString() -eq 'System.Threading.Tasks.Task`1[TResult] AsTask[TResult,TProgress](Windows.Foundation.IAsyncOperationWithProgress`2[TResult,TProgress])' })[0]
        $asTaskAsyncOperation = $asTask.MakeGenericMethod([Windows.Management.Deployment.DeploymentResult], [Windows.Management.Deployment.DeploymentProgress])

        $packageManager = New-Object -TypeName Windows.Management.Deployment.PackageManager

        $asyncOperation = $packageManager.StagePackageAsync($folderAbsoluteUri, $null, "StageInPlace")
        $stagingResult = $asTaskAsyncOperation.Invoke($null, @($asyncOperation))

        $out = [PSCustomObject]@{
            MsixPackageFullName = $msixPackageFullName
            DeviceId              = $mount.DeviceId
            AbsoluteUri           = $folderAbsoluteUri
            StagingOperation      = $stagingResult
        }

        Write-Output $out
    }
}
end {}