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
    [Switch]$PassThru
)

begin {
    Set-StrictMode -Version Latest
} # begin
process {

    $packagePath = Join-Path (Join-Path $Env:ProgramFiles 'WindowsApps') $msixPackageFullName

    if (-not( Test-Path $packagePath )) {
        Write-Error "$packagePath cannot be reached"
        return
    }

    $folderInfo = Get-Item $packagePath
    $deviceId = '\\?\' + $folderInfo.LinkTarget.Split('\')[0] +'\'

    $out = [PSCustomObject]@{
        DeviceId = $deviceId
        msixPackageFullName = $MsixPackageFullName
    }

    Remove-AppxPackage $msixPackageFullName -PreserveRoamableApplicationData

    if ($PassThru) {
        Write-Output $out
    }
        
} # process
end {} # end