<#Author       : Akash Chawla
# Usage        : Admin sys prep  
#>

#######################################
#    Admin sys prep                   #
#######################################

((Get-Content -path C:\\DeprovisioningScript.ps1 -Raw) -replace 'Sysprep.exe /oobe /generalize /quiet /quit','Sysprep.exe /oobe /generalize /quit /mode:vm' ) | Set-Content -Path C:\\DeprovisioningScript.ps1