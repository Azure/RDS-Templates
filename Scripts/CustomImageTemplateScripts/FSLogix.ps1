<#Author       : Dean Cefola
# Creation Date: 10-15-2020
# Usage        : Setup FSLogix

#********************************************************************************
# Date                         Version      Changes
#------------------------------------------------------------------------
# 10/15/2020                     1.0        Intial Version
#
#
#*********************************************************************************
#
#>

Param (        
    [Parameter(Mandatory=$true)]
        [string]$ProfilePath,

    [Parameter(Mandatory=$false)]
        [string]$VHDSize
)

######################
#    WVD Variables   #
######################
$LocalWVDpath            = "c:\temp\wvd\"
$FSLogixURI              = 'https://aka.ms/fslogix_download'
$FSInstaller             = 'FSLogixAppsSetup.zip'
$templateFilePathFolder = "C:\AVDImage"

####################################
#    Test/Create Temp Directory    #
####################################
if((Test-Path c:\temp) -eq $false) {
    Write-Host "AVD AIB Customization - Install FSLogix : Creating temp directory"
    New-Item -Path c:\temp -ItemType Directory
}
else {
    Write-Host "AVD AIB Customization - Install FSLogix : C:\temp already exists"
}
if((Test-Path $LocalWVDpath) -eq $false) {
    Write-Host "AVD AIB Customization - Install FSLogix : Creating directory: $LocalWVDpath"
    New-Item -Path $LocalWVDpath -ItemType Directory
}
else {
    Write-Host "AVD AIB Customization - Install FSLogix : $LocalWVDpath already exists"
}

#################################
#    Download WVD Componants    #
#################################
Write-Host "AVD AIB Customization - Install FSLogix : Downloading FSLogix from URI: $FSLogixURI"
Invoke-WebRequest -Uri $FSLogixURI -OutFile "$LocalWVDpath$FSInstaller"


##############################
#    Prep for WVD Install    #
##############################
Write-Host "AVD AIB Customization - Install FSLogix : Unzipping FSLogix installer"
Expand-Archive `
    -LiteralPath "C:\temp\wvd\$FSInstaller" `
    -DestinationPath "$LocalWVDpath\FSLogix" `
    -Force `
    -Verbose
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Set-Location $LocalWVDpath 
Write-Host "AVD AIB Customization - Install FSLogix : UnZip of FSLogix complete"


#########################
#    FSLogix Install    #
#########################
Write-Host "AVD AIB Customization - Install FSLogix : Starting to install FSLogix"
$fslogix_deploy_status = Start-Process `
    -FilePath "$LocalWVDpath\FSLogix\x64\Release\FSLogixAppsSetup.exe" `
    -ArgumentList "/install /quiet" `
    -Wait `
    -Passthru

if(!($PSBoundParameters.ContainsKey('VHDSize'))) {
    $VHDSize = "30000"
}
#######################################
#    FSLogix User Profile Settings    #
#######################################
Write-Host "AVD AIB Customization - Install FSLogix : Configure FSLogix Profile Settings"
Push-Location 
Set-Location HKLM:\SOFTWARE\
New-Item `
    -Path HKLM:\SOFTWARE\FSLogix `
    -Name Profiles `
    -Value "" `
    -Force
New-Item `
    -Path HKLM:\Software\FSLogix\Profiles\ `
    -Name Apps `
    -Force
Set-ItemProperty `
    -Path HKLM:\Software\FSLogix\Profiles `
    -Name "Enabled" `
    -Type "Dword" `
    -Value "1"
New-ItemProperty `
    -Path HKLM:\Software\FSLogix\Profiles `
    -Name "VHDLocations" `
    -Value "$ProfilePath" `
    -PropertyType String `
    -Force
Set-ItemProperty `
    -Path HKLM:\Software\FSLogix\Profiles `
    -Name "SizeInMBs" `
    -Type "Dword" `
    -Value $VHDSize
Set-ItemProperty `
    -Path HKLM:\Software\FSLogix\Profiles `
    -Name "IsDynamic" `
    -Type "Dword" `
    -Value "1"
Set-ItemProperty `
    -Path HKLM:\Software\FSLogix\Profiles `
    -Name "VolumeType" `
    -Type String `
    -Value "vhdx"
Set-ItemProperty `
    -Path HKLM:\Software\FSLogix\Profiles `
    -Name "FlipFlopProfileDirectoryName" `
    -Type "Dword" `
    -Value "1" 
Set-ItemProperty `
    -Path HKLM:\Software\FSLogix\Profiles `
    -Name "SIDDirNamePattern" `
    -Type String `
    -Value "%username%%sid%"
Set-ItemProperty `
    -Path HKLM:\Software\FSLogix\Profiles `
    -Name "SIDDirNameMatch" `
    -Type String `
    -Value "%username%%sid%"
Set-ItemProperty `
    -Path HKLM:\Software\FSLogix\Profiles `
    -Name DeleteLocalProfileWhenVHDShouldApply `
    -Type DWord `
    -Value 1

#Cleanup
if ((Test-Path -Path $templateFilePathFolder -ErrorAction SilentlyContinue)) {
    Remove-Item -Path $templateFilePathFolder -Force -Recurse -ErrorAction Continue
}

if ((Test-Path -Path $LocalWVDpath -ErrorAction SilentlyContinue)) {
    Remove-Item -Path $LocalWVDpath -Force -Recurse -ErrorAction Continue
}

#############
#    END    #
#############
