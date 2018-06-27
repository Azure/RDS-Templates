Param(
    [Parameter(Mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    [string] $RdbrokerURI,

    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string] $fileURI,

    [Parameter(Mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    [string] $TenantName,

    [Parameter(Mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    [string] $AadTenantId,

    [Parameter(Mandatory=$false)]
    [string] $FriendlyName,

    [Parameter(Mandatory=$false)]
    [string] $Description,

    [Parameter(Mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    [string] $HostPoolName,

    [Parameter(Mandatory=$false)]
    [string] $HostPoolFriendlyName,

    [Parameter(Mandatory=$false)]
    [string] $HostPoolDescription,
         
    [Parameter(Mandatory=$True)]
    [String] $Username,
    [Parameter(Mandatory=$True)]
    [string] $Password,
    [Parameter(Mandatory=$True)]
    [string] $ResourceGroupName
 
)

function Disable-ieESC {
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
    Stop-Process -Name Explorer
    Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green
}

Disable-ieESC


Invoke-WebRequest -Uri $fileURI -OutFile "C:\PSModules.zip"
New-Item -Path "C:\PSModules" -ItemType directory -Force -ErrorAction SilentlyContinue
Expand-Archive "C:\PSModules.zip" -DestinationPath "C:\PSModules" -ErrorAction SilentlyContinue
Set-Location "C:\PSModules"
Import-Module .\PowershellModules\Microsoft.RDInfra.RDPowershell.dll
$SecurePass = $Password | ConvertTo-SecureString -asPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential($Username,$SecurePass)
Set-RdsContext -DeploymentUrl $RdbrokerURI -Credential $Credential
$newRdsTenant=New-RdsTenant -Name $TenantName -AadTenantId $AadTenantId -FriendlyName $FriendlyName -Description $Description
$newRDSHostPool=New-RdsHostPool -TenantName $newRdsTenant.TenantName  -Name $HostPoolName -Description $HostPoolDescription -FriendlyName $HostPoolFriendlyName
<#
Remove-Item -Path "C:\PowershellModules.zip" -Recurse -force
Remove-Item -Path "C:\PowershellModules" -Recurse -Force
#>
.\RemoveRG.ps1 -AadTenantId $AadTenantId -Username $Username -Password $Password -ResourceGroupName $ResourceGroupName
