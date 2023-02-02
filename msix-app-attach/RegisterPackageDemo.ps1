[CmdletBinding()]

Param (
    [Parameter(
        Position = 0,
        ValuefromPipelineByPropertyName = $true,
        ValuefromPipeline = $true,
        Mandatory = $true
    )]
    [System.String]$MsixPackageFullName
)

begin {
    Set-StrictMode -Version Latest
} # begin
process {

    $manifestPath = Join-Path (Join-Path $Env:ProgramFiles 'WindowsApps') (Join-Path $msixPackageFullName AppxManifest.xml)

    if (-not( Test-Path $manifestPath )) {
        Write-Error "$manifestPath cannot be reached"
        return
    }
    
    Add-AppxPackage -Path $manifestPath -DisableDevelopmentMode -Register
        
} # process
end {} # end
