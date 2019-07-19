# Join virtual machine to an Windows Virtual Desktop host pool

This template adds a virtual machine to a WVD host pools. The host pool needs to be alrady created.
To create a host pool follow this [doc](https://docs.microsoft.com/en-us/azure/virtual-desktop/create-host-pools-powershell).

This template has 2 parameters:

- Registration Token
- Vm Name

There is a third parameter but you should ignore it. It is just a timestamp for the custom script extension used by this template.

The template performs the following actions:
- Download the WVD agents
- Install the agents
- Performs a simple verification of the installation
 
To deploy the template you need the registration token of the host pool you want to add the virtual machine.

To obtain the registration token, you need the *Windows Virtual Desktop Cmdlets for Windows PowerShell*.
This [article](https://docs.microsoft.com/en-us/powershell/windows-virtual-desktop/overview) has the instrunction on how to download and import the modulre.

Once you have imported the *Windows Virtual Desktop Cmdlets for Windows PowerShell*, you need to sign in to WVD.

```powershell
Add-RdsAccount -DeploymentUrl https://rdbroker.wvd.microsoft.com
```

Now, you generate a registration token that is used to join virtual machiens to the wvd host pool:
```powershell
New-RdsRegistrationInfo -TenantName <tenantname> -HostPoolName <hostpoolname> -ExpirationHours <number of hours>
```

You can obtain th token by running the follwong command:
```powershell
(Export-RdsRegistrationInfo -TenantName <tenantname> -HostPoolName <hostpoolname>).Token
```




Click the button below to deploy:

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https:%2F%2Fraw.githubusercontent.com%2FAzure%2FRDS-Templates%2Fmbastos%2Fjoinhostpool%2Fwvd-sh%2Fjoinhostpool%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
