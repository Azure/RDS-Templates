[string]$userName="user01"
#create a random password that meet's Azure's rules - https://gallery.technet.microsoft.com/office/Generate-Random-Password-ca4c9f07
[string]$password=(-join(65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90|%{[char]$_}|Get-Random -C 2)) + (-join(97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122|%{[char]$_}|Get-Random -C 2)) + (-join(65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90|%{[char]$_}|Get-Random -C 2)) + (-join(97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122|%{[char]$_}|Get-Random -C 2)) + (-join(64,33,35,36|%{[char]$_}|Get-Random -C 1))  + (-join(49,50,51,52,53,54,55,56,57|%{[char]$_}|Get-Random -C 3)) 
$VMNamingPrefix="megaVM"
[string]$batchNamingPrefix="WVDDeploymentBatch"
[string]$vmNamingPrefix="WVDVM"
[string]$uniqueIDforBatch = New-Guid
$deploymentName="$($batchNamingPrefix)-$($uniqueIDforBatch)"
$resourceGroupName = "WVDTestRG-$($uniqueIDforBatch)"
[int]$vmsToDeploy = 2
[string]$userName="user01"
#build a random DNS name that meets Azure's criteria
[string]$dnsPrefixForPublicIP = -join ((65..90) + (97..122) | Get-Random -Count 10 | % {[char]$_})
#create a random password that meet's Azure's rules - https://gallery.technet.microsoft.com/office/Generate-Random-Password-ca4c9f07
[string]$password=(-join(65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90|%{[char]$_}|Get-Random -C 2)) + (-join(97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122|%{[char]$_}|Get-Random -C 2)) + (-join(65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90|%{[char]$_}|Get-Random -C 2)) + (-join(97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122|%{[char]$_}|Get-Random -C 2)) + (-join(64,33,35,36|%{[char]$_}|Get-Random -C 1))  + (-join(49,50,51,52,53,54,55,56,57|%{[char]$_}|Get-Random -C 3)) 
#build the password as a secure string
[securestring]$securePassword = $password | ConvertTo-SecureString -AsPlainText -Force

New-AzResourceGroupDeployment `
        -Name $deploymentName `
        -ResourceGroupName $resourceGroupName `
        -virtualMachineCount $vmsToDeploy `
        -virtualMachineAdminUserName $userName `
        -virtualMachineAdminPassword $securePassword `
        -rdshNamePrefix "$($vmNamingPrefix)" `
        -_artifactsLocation "https://raw.githubusercontent.com/Azure/RDS-Templates/noAVSetSlowerHostAvailableCheck_20200218.1900_v1/wvd-templates/"
        -TemplateUri "https://raw.githubusercontent.com/Azure/RDS-Templates/noAVSetSlowerHostAvailableCheck_20200218.1900_v1/wvd-templates/Create%20and%20provision%20WVD%20host%20pool/mainTemplate.json" 
