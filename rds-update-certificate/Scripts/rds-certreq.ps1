<#
Copyright 2017 Microsoft Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

.SYNOPSIS
    powershell script to create sha256 self-signed single, multiple, or wildcard certificate for testing.

.DESCRIPTION
    powershell script to create a self-signed certificate for a Remote Desktop Services Deployment.
    script uses builtin exe certreq.exe.
    upon successful completion, a certificate will be stored in the localmachine\my certificate store
    upon successful completion, a pfx file will be generated in the working directory that can be imported into RDS
    to enable script execution, you may need to Set-ExecutionPolicy Bypass -Force

    this script is a modification of script from here:
    <https://blog.kloud.com.au/2013/07/30/ssl-san-certificate-request-and-import-from-powershell/> 
    
    https://github.com/Azure/azure-quickstart-templates/tree/master/rds-update-certificate/scripts/rds-certreq.ps1
     
.NOTES
   file name  : rds-certreq.ps1
   version    : 170614 original

.EXAMPLE
    .\rds-certreq.ps1 -subject gateway.contoso.com -password N0tMyP@ssw0rd
    this will generate a self-signed single domain certificate that will expire in 3 months

.EXAMPLE
    .\rds-certreq.ps1 -subject *.contoso.com -password N0tMyP@ssw0rd
    this will generate a self-signed wildcard certificate that will expire in 3 months

.EXAMPLE
    .\rds-certreq.ps1 -subject gateway.contoso.com -sans @("gateway.contoso.com","broker.contoso.com") -password N0tMyP@ssw0rd -expirationDate 6/14/2018
    this will generate a self-signed san certificate that will expire in 1 year

.PARAMETER subject
    required parameter that is the subject of the certificate. 
    this should be the same as the external name that will be used to connect to RDWeb

#>


param(
    [Parameter(Mandatory = $true)]
    [string]$subject = "",
    [array]$sans = @(),
    [dateTime]$expirationDate = (get-date).AddMonths(3).ToShortDateString(),
    [Parameter(Mandatory = $true)]
    [string]$password
)       
       
function New-CertificateRequest ()
{
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Please enter the subject beginning with CN=")]
        [ValidatePattern("CN=")]
        [string]$subject,
        [Parameter(Mandatory = $false, HelpMessage = "Please enter the SAN domains as a comma separated list")]
        [array]$SANs,
        [Parameter(Mandatory = $false, HelpMessage = "Please enter the Online Certificate Authority")]
        [string]$OnlineCA,
        [Parameter(Mandatory = $false, HelpMessage = "Please enter the Online Certificate Authority")]
        [string]$CATemplate = "WebServer",
        [Parameter(Mandatory = $false, HelpMessage = "Please enter the expiration Date")]
        [dateTime]$expirationDate,
        [Parameter(Mandatory = $false, HelpMessage = "Please enter password for PFX certificate")]
        [string]$password
    )
        
    ### Preparation
    $subjectDomain = $subject.split(',')[0].split('=')[1]
    if ($subjectDomain -match "\*.")
    {
        $subjectDomain = $subjectDomain -replace "\*", "star"
    }
    $CertificateINI = "$subjectDomain.ini"
    $CertificateREQ = "$subjectDomain.req"
    $CertificateRSP = "$subjectDomain.rsp"
    $CertificateCER = "$subjectDomain.cer"
    $CertificatePFX = "$subjectDomain.pfx"
        
    ### INI file generation
    new-item -type file $CertificateINI -force
    add-content $CertificateINI '[Version]'
    add-content $CertificateINI 'Signature="$Windows NT$"'
    add-content $CertificateINI ''
    add-content $CertificateINI '[NewRequest]'
    add-content $CertificateINI ('Subject="' + $subject + '"')
    add-content $CertificateINI 'Exportable=TRUE'
    add-content $CertificateINI 'KeyLength=2048'
    add-content $CertificateINI 'KeySpec=1'
    add-content $CertificateINI 'KeyUsage=0x30'
    add-content $CertificateINI 'MachineKeySet=True'
    add-content $CertificateINI 'ProviderName="Microsoft RSA SChannel Cryptographic Provider"'
    add-content $CertificateINI 'ProviderType=12'
    add-content $CertificateINI 'SMIME=FALSE'

    ### Date Ranges
    add-content $CertificateINI ('NotBefore="' + (get-date).ToShortDateString() + '"')
    add-content $CertificateINI ('NotAfter="' + $expirationDate.ToShortDateString() + '"')
        
    add-content $CertificateINI 'RequestType=Cert'
    add-content $CertificateINI 'HashAlgorithm=sha256'
    add-content $CertificateINI '[EnhancedKeyUsageExtension]'
    add-content $CertificateINI 'OID=1.3.6.1.5.5.7.3.1 ; this is for Server Authentication / Token Signing'

    if ($SANs) 
    {
        add-content $CertificateINI '[Extensions]'
        add-content $CertificateINI '2.5.29.17 = "{text}"'
        
        foreach ($SAN in $SANs) 
        {
            add-content $CertificateINI ('_continue_ = "dns=' + $SAN + '&"')
        }
    }
        
    ### Certificate request generation
    if (test-path $CertificateREQ)
    {
        remove-item $CertificateREQ
    }

    $ret = certreq -new $CertificateINI $CertificateREQ
    write-host ($ret | out-string)
        
    ### Online certificate request and import
    if ($OnlineCA)
    {
        if (test-path $CertificateCER)
        {
            remove-item $CertificateCER
        }

        if (test-path $CertificateRSP)
        {
            remove-item $CertificateRSP
        }
        
        certreq -submit -attrib "CertificateTemplate:$CATemplate" -config $OnlineCA $CertificateREQ $CertificateCER
        certreq -accept $CertificateCER
    }

    # export pfx to file
    if ($ret)
    {
        $thumb = ([regex]::Match($ret, "Thumbprint: (.+?) ")).Captures[0].Groups[1].value

        if ($thumb)
        {
            $securePassword = ConvertTo-SecureString -String $password -Force -AsPlainText
            Export-PfxCertificate -FilePath $CertificatePFX -Password $securePassword -ChainOption BuildChain -Cert "cert:\localmachine\my\$($thumb)" -Force
        }
        else
        {
            Write-Warning "unable to enumerate thumbprint"
        }
    }
    else
    {
        Write-Warning "failure in certreq.exe"
    }
}
 
New-CertificateRequest -subject "CN=$($subject)" -SANs $sans -expirationDate $expirationDate -password $password
write-host "finished" -ForegroundColor Cyan
