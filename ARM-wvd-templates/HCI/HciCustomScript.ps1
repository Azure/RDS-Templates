param
(    
    [Parameter(Mandatory = $true)]
    [string]$HostPoolName,

    [Parameter(Mandatory = $true)]
    [string]$RegistrationInfoToken,

    [Parameter(mandatory = $false)] 
    [switch]$EnableVerboseMsiLogging
)

# unzip dsc zip
$dsc_dir = (Get-Item .).FullName
$dsc_ps_path = [IO.Path]::Combine($dsc_dir, 'Configuration.ps1')

Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Azure/RDS-Templates/master/ARM-wvd-templates/DSC/Configuration.zip' -outfile $dsc_dir\Configuration.zip -UseBasicParsing
Get-ChildItem $dsc_dir\Configuration.zip | Expand-Archive -DestinationPath $dsc_dir

# pass parameters to configuration.ps1
& $dsc_dir\Script-SetupSessionHost.ps1 -HostPoolName $HostPoolName -RegistrationInfoToken $RegistrationInfoToken -EnableVerboseMsiLogging:$EnableVerboseMsiLogging 