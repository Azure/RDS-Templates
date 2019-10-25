#MSIX app attach deregistration sample
#region variables 
$packageName = "<package name>" 
#endregion

#region derregister
Remove-AppxPackage -PreserveRoamableApplicationData $packageName 
#endregion 