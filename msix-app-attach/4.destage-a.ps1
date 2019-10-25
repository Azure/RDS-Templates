#MSIX app attach de staging sample
#region variables 
$packageName = "<package name>" 

$msixJunction = "C:\temp\AppAttach\" 
#endregion

#region derregister
Remove-AppxPackage -AllUsers -Package $packageName

cd $msixJunction 
rmdir $packageName -Force -Verbose 
#endregion 