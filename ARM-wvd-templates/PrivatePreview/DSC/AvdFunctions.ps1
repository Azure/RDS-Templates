function GetAvdSessionHostName {
    $Wmi = (Get-WmiObject win32_computersystem)
    
    if ($Wmi.Domain -eq "WORKGROUP") {
        return "$($Wmi.DNSHostName)"
    }

    return "$($Wmi.DNSHostName).$($Wmi.Domain)"
}