
=========================================================================
Steps to setup a new RDmi Portal
=========================================================================

1. Search for Powershell ISE in the Start Menu
2. Run the Powershell ISE with administrator rights
3. Open the New-RdmiMgmtSetup.ps1 powershell script file which is existed in the project folder
4. To Execute the powershell script press F5 key or click on the RunScript Icon
5. Provide the parameters in the console window as below :
	
   	a. SubscriptionId (ex: f657519e-2b49-38ke-85ec-3acfg0ac67a6)
	b. ResourceGroupName (ex: SampleRg)
	c. Location (ex : westus, centralus, southcentralus, ... etc.,)
	d. ApplicationID (ex: 871642dd-a962-4b36-a467-979143cdae0f)
	e. RDBrokerURL (ex: https://rdbroker-qxpjwe4gnswme.azurewebsites.net)
	f. ResourceURL (ex: https://contoso.onmicrosoft.com/RDInframsftrdmisaasf657519e2b4948fe85e)
	g. CodeBitPath (ex: D:\contoso\msft-rdmi-saas-offering)

6. Wait approximately 20 minutes to complete the process.
7. After successful completion, copy the web url. 
        Web URL : : http://rdmimgmtweb-100720180548.azurewebsites.net
	
 