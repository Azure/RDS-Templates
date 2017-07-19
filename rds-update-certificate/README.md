# Configure certificates for RDS deployment

Click the button below to deploy:

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fazure-quickstart-templates%2Fmaster%2Frds-update-certificate%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fazure-quickstart-templates%2Fmaster%2Frds-update-certificate%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>
<br><br>

This Template allows you configure certificates in an RDS deployment.  
Remote Desktop Services require certificaties for
 server authentication, single sign-on (SSO), and to secure RDP connections.  
 For a good overview of certificates use in RDS see 
 [Configuring RDS 2012 Certificates and SSO](https://ryanmangansitblog.com/2013/03/10/configuring-rds-2012-certificates-and-sso/) and 
 [How to Create a (Mostly) Seamless Logon Experience For Your Remote Desktop Services Environment](http://www.rdsgurus.com/windows-2012-r2-how-to-create-a-mostly-seamless-logon-experience-for-your-remote-desktop-services-environment/) by RDS MVP Toby Phipps.

The Template makes use of a single SSL certificate. The certificate's Subject Name must match external DNS name of RD Gateway server in the deployment.  
The certificate with the private key (in .PFX format) must be stored in Azure Key Vault.  
For information on managing certificates with Azure Key Vault see:  [Get started with Azure Key Vault certificates](https://blogs.technet.microsoft.com/kv/2016/09/26/get-started-with-azure-key-vault-certificates/) and  
[Manage certificates via Azure Key Vault](https://blogs.technet.microsoft.com/kv/2016/09/26/manage-certificates-via-azure-key-vault/).

## Certificate Subject Naming Conventions

The certificate subject name suffix can either be the same or different than the internal Active Directory domain name. An example of each is below:

+ Matching DNS domain name suffixes
	+ certificate subject: gateway.contoso.com
	+ external domain name: contoso.com
	+ internal client access name: broker.contoso.com
	+ High Availability internal client access name / DNS RR: hardcb.contoso.com
	+ internal Active Directory name: contoso.com

+ Non-matching DNS domain name suffixes
	+ certificate subject: gateway.contoso.com
	+ external domain name: contoso.com
	+ internal client access name: broker.contoso.org
	+ High Availability internal client access name / DNS RR: hardcb.contoso.org
	+ internal Active Directory name: contoso.org

## Supported Certificate Types

The following certificate types can be used for authentication into an RDS environment using this template. To use a certificate for RDS authentiation, the certificate must contain Enhanced Key Usage Server Authentication (1.3.6.1.5.5.7.3.1) :

+ Self-signed / untrusted
	+ **NOTE: Self-signed certificates REQUIRE that the certificate be installed on all client machines in the 'Trusted Root' certificate store accessing an RDS environment.**
	+ [/scripts/rds-certreq.ps1](https://github.com/Azure/azure-quickstart-templates/tree/master/rds-update-certificate/scripts/rds-certreq.ps1) can be used to generate a self-signed single, multiple (SAN), or wild card certificate with sha256 hash for use with RDS. 

		Example:
		```
		.\rds-certreq.ps1 -subject *.contoso.com -password B@kedPotat0
		```
	+ [Azure Resource Manager Post Deployment RDP Connectivity](https://aka.ms/azure-rm-rdp-post-deployment.ps1) script can be used to connect to RDWeb web site, download certificate, install certificate into Trusted Root certificate store
+ Trusted
	+ Trusted certificates should not require modification of client machines accessing an RDS environment assuming that the intermediate and / or root CA is installed.
+ Wildcard trusted / untrusted
	+ option for single sign-on
+ Subject Alternative Name (SAN) / Multi-Domain trusted / untrusted
	+ option for single sign-on


## Single sign-on

For single sign-on, a SAN or wildcard certificate is required. In addition, if using different domain suffixes, the client access name needs to be resolvable using the external domain suffix. This would require adding A records for each brokers internal IP address to the external DNS domain. During template deployment, if all conditions are met, the client access name domain suffix will be modified from internal AD domain name to external domain name.

Example SAN domain names when using different domain suffixes:
+ SAN for certificate: gateway.contoso.com, broker.contoso.com
+ High Availability SAN for certificate: gateway.contoso.com, hardcb.contoso.com
+ external domain name: contoso.com
+ internal client access name: broker.contoso.com
+ High Availability internal client access name / DNS RR: hardcb.contoso.com
+ internal Active Directory name: contoso.org

## Pre-Requisites

0. Template is intended to run against an existing RDS deployment. The deployment can be created using one of RDS QuickStart templates 
   ([Basic RDS Deployment Template](https://github.com/Azure/azure-quickstart-templates/tree/master/rds-deployment), or [RDS Deployment using existing VNET and AD](https://github.com/Azure/azure-quickstart-templates/tree/master/rds-deployment-existing-ad), etc.).

1. A certificate with the private key needs to be created (or acquired from CA) and imported to Azure Key Vault in tenant's subscription
	(see [Get started with Azure Key Vault](https://azure.microsoft.com/en-us/documentation/articles/key-vault-get-started)).
    Certificate's Subject Name should match external DNS name of the RDS Gateway server.

	For example, to import an existing certificate stored as a .pfx file on your local hard drive run the following PowerShell:
	```PowerShell
	$vaultName = "myVault"
	$certNameInVault = "certificate"    # cert name in vault, has to be '^[0-9a-zA-Z-]+$' pattern (digits, letters or dashes only, no spaces)
	$pfxFilePath = "c:\certificate.pfx"
	$password = "B@kedPotat0"           # password that was used to secure the pfx file at the time of export 

	Import-AzureKeyVaultCertificate -vaultname $vaultName -name $certNameInVault -filepath $pfxFilePath -password ($password | convertto-securestring -asplaintext -force)
	```
    Mark down 1) key vault name, and 2) certificate name in vault from this step - these will need to be supplied as input parameters to the Template.

2. A Service Principal account needs to be created with permissions to access certificates in the Key Vault
(see [Use Azure PowerShell to create a service principal to access resources](https://azure.microsoft.com/en-us/documentation/articles/resource-group-authenticate-service-principal/)).

	Sample powershell (alternatively you see Scripts\New-ServicePrincipal.ps1):
	```PowerShell
	$appPassword = "R@bberDuck"
	$uri = "https://www.contoso.com/script"   #  a valid formatted URL, not validated for single-tenant deployments
	$vaultName = "myVault"                    #  same key vault name as in step #1 above

	$app = New-AzureRmADApplication -DisplayName "script" -HomePage $uri -IdentifierUris $uri -password $appPassword
	$sp = New-AzureRmADServicePrincipal -ApplicationId $app.ApplicationId

	Set-AzureRmKeyVaultAccessPolicy -vaultname $vaultName -serviceprincipalname $sp.ApplicationId -permissionstosecrets get
	```

	Note: Certificates stored in Key Vault as secrets with content type 'application/x-pkcs12', this is why 
    `Set-AzureRmKeyVaultAccessPolivy` cmdlet grants `-PremissionsToSecrets` (rather than `-PermissionsToCertificates`).
    
    You will need 1) application id (`$app.ApplicationId`), and 2) the password from above step supplied as input parameters to the Template.  
	You will also need your tenant Id. To get tenant Id run the following powershell:
	```PowerShell
	$tenantId = (Get-AzureRmSubscription).TenantId | select -Unique
	```
3. If configuring for single sign-on, and using different internal vs external domain names, add A records to external domain DNS for brokers internal IP address.

## Running the Template

Template applies same certificate to all 4 roles in the deployment: `{ RDGateway | RDWebAccess | RDRedirector | RDPublishing }`.

Template performs the following steps:
+ installs azurerm powershell sdk
+ downloads certificate from the key vault using Service Principal credentials;
+ impersonates provided domain admin credentials
+ checks certificate type
+ checks gatewayExternalFqdn
+ checks client access name
+ if external and internal domain suffixes are different, certificate is SAN or wildcard, and client access name resolves to the internal IP address of broker, client access name will be modified to use external domain suffix for single sign-on
