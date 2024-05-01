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
$dir = (Get-Item .).FullName

# Invoke-WebRequest -Uri $ArtifactUri -outfile $dir\Configuration.zip -UseBasicParsing
Get-ChildItem $dir\Configuration.zip | Expand-Archive -DestinationPath $dir

# pass parameters to configuration.ps1
& $dir\Script-SetupSessionHost.ps1 -HostPoolName $HostPoolName -RegistrationInfoToken $RegistrationInfoToken -EnableVerboseMsiLogging:$EnableVerboseMsiLogging 