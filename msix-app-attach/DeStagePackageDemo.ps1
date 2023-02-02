[CmdletBinding()]

Param (
    [Parameter(
        Position = 0,
        ValuefromPipelineByPropertyName = $true,
        ValuefromPipeline = $true,
        Mandatory = $true
    )]
    [System.String]$MsixPackageFullName,

    [Parameter(
        ValuefromPipelineByPropertyName = $true
    )]
    [System.String]$DeviceId
)

begin {
    Set-StrictMode -Version Latest
    #requires -RunAsAdministrator
}
process {

    $manifestPath = Join-Path (Join-Path $Env:ProgramFiles 'WindowsApps') $MsixPackageFullName

    $pathPresent = Test-Path $manifestPath

    if (-not($deviceId)) {
        if (-Not($pathPresent)) {
            Write-Error "Application $MsixPackageFullName not found on this machine"
            return
        }
        $folderInfo = Get-Item $manifestPath
        $DeviceId = '\\?\' + $folderInfo.LinkTarget.Split('\')[0] +'\'
    }

    $diskType = $null

    try {
        $mount = Get-DiskImage -DevicePath $DeviceId.TrimEnd('\') -ErrorAction Stop
        $diskType = 'VHD(X)'
    }
    catch {
        try {
            Import-Module -Name CimDiskImage -ErrorAction Stop
        }
        catch {
            Install-Module CimDiskImage -Scope CurrentUser -SkipPublisherCheck -Force -Comfirm:$false
            Import-Module CimDiskImage
        }
        $mount = Get-CimDiskImage -DeviceId $DeviceId
        $diskType = 'Cim'
    }

    if($pathPresent){
        Remove-AppxPackage -AllUsers -Package $MsixPackageFullName -ErrorAction SilentlyContinue
        Remove-AppxPackage -Package $MsixPackageFullName 
    }

    switch ($diskType) {
        'VHD(X)' { $mount | Dismount-DiskImage ; break }
        'Cim' { $mount | Dismount-CimDiskImage ; break }
        Default {Write-Error "Could not dismount Disk $MsixPackageFullName"}
    } 
}
end {}
