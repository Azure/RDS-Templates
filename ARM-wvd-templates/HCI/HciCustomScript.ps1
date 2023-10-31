param
(    
    [Parameter(Mandatory = $true)]
    [string]$HostPoolName,

    [Parameter(Mandatory = $true)]
    [string]$RegistrationInfoToken,

    [Parameter(Mandatory = $true)]
    [string]$ArtifactUri,

    [Parameter(mandatory = $false)] 
    [switch]$EnableVerboseMsiLogging
)

# unzip dsc zip
$dsc_dir = (Get-Item .).FullName

Invoke-WebRequest -Uri $ArtifactUri -outfile $dsc_dir\Configuration.zip -UseBasicParsing
Get-ChildItem $dsc_dir\Configuration.zip | Expand-Archive -DestinationPath $dsc_dir

# pass parameters to configuration.ps1
& $dsc_dir\Script-SetupSessionHost.ps1 -HostPoolName $HostPoolName -RegistrationInfoToken $RegistrationInfoToken -EnableVerboseMsiLogging:$EnableVerboseMsiLogging 