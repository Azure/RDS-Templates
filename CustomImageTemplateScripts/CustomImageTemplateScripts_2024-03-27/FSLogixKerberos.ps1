<#Author       : Akash Chawla
# Usage        : Access to Azure File shares for FSLogix profiles
#>

#################################################################
#    Access to Azure File shares for FSLogix profiles           #
#################################################################

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
Write-Host "*** Starting AVD AIB CUSTOMIZER PHASE: Access to Azure File shares for FSLogix profiles  ***"

# Enable Azure AD Kerberos

Write-Host '*** WVD AIB CUSTOMIZER PHASE *** Enable Azure AD Kerberos ***'
$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters"
$registryKey= "CloudKerberosTicketRetrievalEnabled"
$registryValue = "1"

IF(!(Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force | Out-Null
}

try {
    New-ItemProperty -Path $registryPath -Name $registryKey -Value $registryValue -PropertyType DWORD -Force | Out-Null
}
catch {
    Write-Host "*** AVD AIB CUSTOMIZER PHASE ***  Enable Azure AD Kerberos - Cannot add the registry key $registryKey *** : [$($_.Exception.Message)]"
    Write-Host "Message: [$($_.Exception.Message)"]
}


# Create new reg key "LoadCredKey"
 
Write-Host '*** AVD AIB CUSTOMIZER PHASE *** Create new reg key LoadCredKey ***'

$LoadCredRegPath = "HKLM:\Software\Policies\Microsoft\AzureADAccount"
$LoadCredName = "LoadCredKeyFromProfile"
$LoadCredValue = "1"

IF(!(Test-Path $LoadCredRegPath)) {
     New-Item -Path $LoadCredRegPath -Force | Out-Null
}

try {
    New-ItemProperty -Path $LoadCredRegPath -Name $LoadCredName -Value $LoadCredValue -PropertyType DWORD -Force | Out-Null
}
catch {
    Write-Host "*** AVD AIB CUSTOMIZER PHASE ***  LoadCredKey - Cannot add the registry key $LoadCredName *** : [$($_.Exception.Message)]"
    Write-Host "Message: [$($_.Exception.Message)"]
}

$stopwatch.Stop()
$elapsedTime = $stopwatch.Elapsed
Write-Host "*** AVD AIB CUSTOMIZER PHASE : Access to Azure File shares for FSLogix profiles - Exit Code: $LASTEXITCODE ***"
Write-Host "*** Ending AVD AIB CUSTOMIZER PHASE: Access to Azure File shares for FSLogix profiles - Time taken: $elapsedTime "


#############
#    END    #
#############