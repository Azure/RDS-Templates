[cmdletbinding()]
param(
    [parameter(mandatory = $true)][ValidateNotNullOrEmpty()] [string]$appId,
    [parameter(mandatory = $true)][ValidateNotNullOrEmpty()] [string]$appPassword,
    [parameter(mandatory = $true)][ValidateNotNullOrEmpty()] [string]$tenantId,
    [parameter(mandatory = $true)][ValidateNotNullOrEmpty()] [string]$vaultName,
    [parameter(mandatory = $true)][ValidateNotNullOrEmpty()] [string]$secretName,
    [parameter(mandatory = $true)][ValidateNotNullOrEmpty()] [string]$adminUsername,
    [parameter(mandatory = $true)][ValidateNotNullOrEmpty()] [string]$adminPassword,
    [parameter(mandatory = $true)][ValidateNotNullOrEmpty()] [string]$adDomainName,
    [Parameter(ValueFromRemainingArguments = $true)]
    $extraParameters
)

function log
{
    param([string]$message)
    "`n`n$(get-date -f o)  $message" 
}

log "script running..."
whoami

# $PSBoundParameters

if ($extraParameters)
{
    log "any extra parameters:"
    $extraParameters
}

#  determine broker info
#
$brokerInstalled = (Get-WindowsFeature -Name RDS-Connection-Broker).Installed

if (-not $brokerInstalled)
{
    log "error: this machine is NOT a broker! exiting. computer: '$env:COMPUTERNAME'"
    Get-WindowsFeature | Where-Object Installed -eq $true
    exit 1
}

#  requires WMF 5.0
#  verify NuGet package
#
$nuget = get-packageprovider nuget -Force
if (-not $nuget -or ($nuget.Version -lt 2.8.5.22))
{
    log "installing nuget package..."
    install-packageprovider -name NuGet -minimumversion 2.8.5.201 -force
}

#  install AzureRM module
#  min need AzureRM.profile, AzureRM.KeyVault
#
if (-not (get-module AzureRM -ListAvailable))
{ 
    log "installing AzureRm powershell module..." 
    install-module AzureRM -force 
} 

#  log onto azure account
#
log "logging onto azure account with app id = $appId ..."

$creds = new-object System.Management.Automation.PSCredential ($appId, (convertto-securestring $appPassword -asplaintext -force))
login-azurermaccount -credential $creds -serviceprincipal -tenantid $tenantId -confirm:$false

#  get the secret from key vault
#
log "getting secret '$secretName' from keyvault '$vaultName'..."
$secret = get-azurekeyvaultsecret -vaultname $vaultName -name $secretName

$certCollection = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection

$bytes = [System.Convert]::FromBase64String($secret.SecretValueText)
$certCollection.Import($bytes, $null, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)
	
add-type -AssemblyName System.Web
$password = [System.Web.Security.Membership]::GeneratePassword(38, 5)
$protectedCertificateBytes = $certCollection.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12, $password)

$pfxFilePath = join-path $env:TEMP "$([guid]::NewGuid()).pfx"
log "writing the cert as '$pfxFilePath'..."
[io.file]::WriteAllBytes($pfxFilePath, $protectedCertificateBytes)

#  get cert info
#
$selfsigned = $false
$wildcard = $false
$cert = $null
$foundcert = $false
$san = $false

# look for enhanced key usage having 'server authentication' and ca false
#
foreach ($cert in $certCollection)
{
    if (!($cert.Extensions.CertificateAuthority) -and $cert.EnhancedKeyUsageList -imatch "Server Authentication")
    {
        $foundcert = $true
        break
    }
}

if ($foundcert -and $cert)
{
    $certSubject = $cert.Subject.Replace("CN=", "").Split(",")[0]
    
    #  see if trusted or non-trusted
    #
    if ($cert.Subject -ieq $cert.Issuer)
    {
        $selfsigned = $true
    }

    log "cert '$certSubject' is self-signed:'$selfsigned'"

    if ($certSubject.StartsWith("*"))
    {
        $wildcard = $true   
    }

    log "cert '$certSubject' is wildcard:'$wildcard'"

    if ($cert.DnsNameList.Count -gt 1)
    {
        $san = $true   
    }

    log "cert '$certSubject' is SAN cert:'$san'"

}
else
{
    log "unable to find cert $pfxFilePath. exiting..."
    exit 1
}

#  load RD module
#
Import-Module remotedesktop -DisableNameChecking  

#  impersonate as admin 
#  from .\New-ImpersonateUser.ps1 in gallery https://gallery.technet.microsoft.com/scriptcenter/Impersonate-a-User-9bfeff82
#
$ImpersonatedUser = @{}
log "impersonating as '$adminUsername'..."
Add-Type -Namespace Import -Name Win32 -MemberDefinition @'
        [DllImport("advapi32.dll", SetLastError = true)]
        public static extern bool LogonUser(string user, string domain, string password, int logonType, int logonProvider, out IntPtr token);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool CloseHandle(IntPtr handle);
'@

$tokenHandle = 0
$returnValue = [Import.Win32]::LogonUser($adminUserName, $adDomainName, $adminPassword, 2, 0, [ref]$tokenHandle)

if (!$returnValue)
{
    $errCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error();
    log "failed a call to LogonUser with error code: $errCode"
    throw [System.ComponentModel.Win32Exception]$errCode
}
else
{
    $ImpersonatedUser.ImpersonationContext = [System.Security.Principal.WindowsIdentity]::Impersonate($tokenHandle)
    [void][Import.Win32]::CloseHandle($tokenHandle)
    log "impersonating user $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name) returnValue: '$returnValue'"
}

whoami

#  set client access name
#
$gatewayConfig = get-rddeploymentgatewayconfiguration
$gatewayConfig | format-list *
(get-wmiobject -Namespace root\cimv2\terminalservices -Class Win32_RDCentralPublishedRemoteDesktop).RDPFileContents

if ($gatewayConfig -and $gatewayConfig.GatewayExternalFqdn)
{
    $gatewayExternalFqdn = $gatewayConfig.GatewayExternalFqdn
    log "gateway external fqdn: '$gatewayExternalFqdn'"
		
    $externalDomainSuffix = $gatewayExternalFqdn.substring($gatewayExternalFqdn.IndexOf('.') + 1)
    log "gateway external domain suffix: '$externalDomainSuffix'"
    $externalDomainName = $gatewayExternalFqdn.substring(0, $gatewayExternalFqdn.IndexOf('.'))
    log "gateway external domain name: '$externalDomainName'"
    $haDeployment = $false

    if (Get-RDConnectionBrokerHighAvailability)
    {
        $haDeployment = $true
    }

    log "deployment is HA? '$haDeployment'"

    $brokerInternalDomainSuffix = ([System.Net.Dns]::GetHostByName($env:COMPUTERNAME).HostName) -ireplace "$($env:COMPUTERNAME).", ""
    log "broker internal domain suffix: '$brokerInternalDomainSuffix'"

    $localIpAddresses = (Get-NetIPAddress).IPAddress
    log "local ip addresses $localIpAddresses"
    
    $certSuffix = $certSubject -ireplace "^.+?\."
    $wmi = new-object Management.ManagementClass "\\.\root\cimv2\rdms:Win32_RDMSDeploymentSettings"

    # if one of the local ip addresses matches dns lookup for 'clientaccessname'.%certSubject%
    # then modify clientaccessname suffix to match external suffix for sso
    # if it does not match, do not modify as it will break connection
    #
    if ($haDeployment)
    {
        $oldClientAccessName = (Get-RDConnectionBrokerHighAvailability).ClientAccessName
    }
    else
    {
        
        $oldClientAccessName = $wmi.GetStringProperty("DeploymentRedirectorServer").Value
    }

    log "current client access name: '$oldClientAccessName'"

    $newClientAccessNamePrefix = $oldClientAccessName -ireplace "\..*$"

    # default value
    $clientAccessName = $certSubject

    # check dns to see if oldClientAccessNamePrefix with external domain suffix from cert resolves to one of the ips on broker
    # if so, change client access name
    # this requires a wildcard or san cert
    #
    $newClientAccessName = "$($newClientAccessNamePrefix).$($certSuffix)"

    if ($wildcard -or ($san -and $cert.DnsNameList.Unicode -imatch $newClientAccessName))
    {
        log "querying dns for possible clientaccessname $newClientAccessName"
        $dnsResolve = (Resolve-DnsName -Name $newClientAccessName -ErrorAction SilentlyContinue).IPAddress
        log "dns addresses $dnsResolve"
    
        if ($localIpAddresses -and $dnsResolve)
        {
            $notMatchedCount = (Compare-Object -ReferenceObject $localIpAddresses -DifferenceObject $dnsResolve).Count
         
            if (($dnsResolve.Count + $localIpAddresses.Count - 2) -le $notMatchedCount)
            {
                log "local address was found in dns query using external suffix"
                $clientAccessName = $newClientAccessName
                $continue = $true

                # update rap on all gateways to include new client access name
                #
                foreach ($server in (Get-RDServer -Role RDS-GATEWAY).Server)
                {
                    $wmi = Invoke-Command -ComputerName $server -ScriptBlock `
                    {
                        Get-WmiObject -Namespace root\cimv2\terminalservices -Class Win32_TSGatewayResourceGroup | Where-Object Name -eq RDG_DNSRoundRobin
                    }
                    
                    log $wmi 
                    
                    if ($wmi -and $wmi.Resources -inotmatch $clientAccessName)
                    {
                        $ret = Invoke-Command -ComputerName $server -ScriptBlock `
                        {
                            (Get-WmiObject -Namespace root\cimv2\terminalservices -Class Win32_TSGatewayResourceGroup | Where-Object Name -eq RDG_DNSRoundRobin).InvokeMethod("AddResources", $clientAccessName)
                        }

                        log $ret
                        
                        if ($ret -eq 0)
                        {
                            log "updated rap on gateway $server"
                        }
                        else
                        {
                            log "unable to update rap on gateway  $server"
                            $continue = $false
                        }
                    }
                    elseif (!$wmi)
                    {
                        log "unable to connect to gateway $server"
                        $continue = $false
                    }
                    else
                    {
                        log "gateway $server rap already contains $clientAccessName"
                    }

                    # dont error but dont continue if above fails
                    #
                    if (!$continue)
                    {
                        break
                    }
                } # end for

                if ($haDeployment)
                {
                    log "setting client access name for ha sso"
                    $ret = Set-RDClientAccessName -ClientAccessName $clientAccessName
                }
                else
                {
                    log "setting client access name for sso"
                    # from https://gallery.technet.microsoft.com/Change-published-FQDN-for-2a029b80
                    $ret = $wmi.SetStringProperty("DeploymentRedirectorServer", $clientAccessName).ReturnValue			
                }
            } # end if dns match
        } # end if ips resolved
    } # end if wildcard or san check

    log "setting new client access name to '$clientAccessName'..."
        
    if ($wildcard)
    {
        $gatewayExternalFQDN = $externalDomainName + '.' + $certSuffix
    }
    else
    {
        $gatewayExternalFqdn = $certSubject
    }     
    
    log "setting gateway external FQDN to '$gatewayExternalFqdn'..."
    $gatewayConfig = get-rddeploymentgatewayconfiguration
    $gatewayConfig | format-list *

    $ret = Set-RDDeploymentGatewayConfiguration -GatewayMode "Custom" `
        -GatewayExternalFqdn $gatewayExternalFqdn `
        -LogonMethod $gatewayConfig.LogonMethod `
        -UseCachedCredentials $gatewayConfig.UseCachedCredentials `
        -BypassLocal $gatewayConfig.BypassLocal `
        -Force

    $gatewayConfig = get-rddeploymentgatewayconfiguration
    $gatewayConfig | format-list *
}
	
#  apply certificate
#
foreach ($role in @("RDGateway", "RDWebAccess", "RDRedirector", "RDPublishing"))
{
    log "applying certificate for role: $role ..."
    set-rdcertificate -role $role -importpath $pfxFilePath -password (convertto-securestring $password -asplaintext -force) -force
}

$gatewayConfig
(get-wmiobject -Namespace root\cimv2\terminalservices -Class Win32_RDCentralPublishedRemoteDesktop).RDPFileContents
	
log "remove impersonation..."
$ImpersonatedUser.ImpersonationContext.Undo()

whoami

#  clean up
#  
if (test-path($pfxFilePath))
{
    log "running cleanup..."
    remove-item $pfxFilePath
}
    
log "done."

if (!$clientAccessName)
{
    exit 1
}
