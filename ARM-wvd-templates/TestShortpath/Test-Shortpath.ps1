function Checking
{
  param ( $what )
  Write-Host "Checking $what ... " -NoNewline -ForegroundColor White
}
function Ok
{
  Write-Host "OK" -ForegroundColor Green
}
function Fail
{
  Write-Host "FAIL" -ForegroundColor Red
}

function Test-StunEndpoint 
{
  param
  (
    [Parameter(Mandatory)]
    $UdpClient,
    [Parameter(Mandatory)]
    $StunEndpoint
  )
  $ipendpoint = $null

  Checking "STUN on server $StunEndpoint"
  try 
  {
    $UdpClient.client.ReceiveTimeout = 5000 
    $listenport = $UdpClient.client.localendpoint.port
    $endpoint = New-Object -TypeName System.Net.IPEndPoint -ArgumentList ([IPAddress]::Any, $listenport)

  
    [Byte[]] $payload = 
    0x00, 0x01, # Message Type: 0x0001 (Binding Request)
    0x00, 0x00, # Message Length: 0 bytes excluding header
    0x21, 0x12, 0xa4, 0x42 # Magic Cookie: Always 0x2112A442

    $LocalTransactionId = ([guid]::NewGuid()).ToByteArray()[1..12]
    $payload = $payload + $LocalTransactionId

    try 
    {
      $null = $UdpClient.Send($payload, $payload.length, $StunEndpoint)
    }
    catch 
    {
      throw "Unable to send data, check if $($StunEndpoint.AddressFamily) is configured"
    }
  
  
    try 
    {
      $content = $UdpClient.Receive([ref]$endpoint)
    }
    catch 
    {
      try 
      {
        $null = $UdpClient.Send($payload, $payload.length, $StunEndpoint)
        $content = $UdpClient.Receive([ref]$endpoint)
      }
      catch 
      {
        try 
        {
          $null = $UdpClient.Send($payload, $payload.length, $StunEndpoint)
          $content = $UdpClient.Receive([ref]$endpoint)
        }
        catch 
        {
          throw "Unable to receive data, check if firewall allows access to $($StunEndpoint.ToString())"
        }
      }
    }
    
    
    if (-not $content) 
    {
      throw  'Null response.'
    }
  
    [Byte[]]$messageType = $content[0..1]
    [Byte[]]$messageCookie = $content[4..7]
    [Byte[]]$TransactionId = $content[8..19]
    [Byte[]]$AttributeType = $content[20..21]
    [Byte[]]$AttributeLength = $content[22..23]

    if ([System.BitConverter]::IsLittleEndian) 
    {
      [Array]::Reverse($AttributeLength)
    }

    if ( -not ([BitConverter]::ToString($messageType)) -eq '01-01') 
    {
      throw  "Invalid message type: $([BitConverter]::ToString($messageType))"
    }
    if ( -not ([BitConverter]::ToString($messageCookie)) -eq '21-12-A4-42') 
    {
      throw  "Invalid message cookie: $([BitConverter]::ToString($messageCookie))"
    }
  
    if (-not  ([BitConverter]::ToString($TransactionId)) -eq [BitConverter]::ToString($LocalTransactionId) ) 
    {
      throw  "Invalid message id: $([BitConverter]::ToString($TransactionId))"
    }
    if (-not  ([BitConverter]::ToString($AttributeType)) -eq '00-20' ) 
    {
      throw  "Invalid Attribute Type: $([BitConverter]::ToString($AttributeType))"
    }
    $ProtocolByte = $content[25]
    if (-not (($ProtocolByte -eq 1) -or ($ProtocolByte -eq 2))) 
    {
      throw "Invalid Address Type: $([BitConverter]::ToString($ProtocolByte))"
    }
    $portArray = $content[26..27]
    if ([System.BitConverter]::IsLittleEndian) 
    {
      [Array]::Reverse($portArray)
    }

    $port = [Bitconverter]::ToUInt16($portArray, 0) -bxor 0x2112
          
    if ($ProtocolByte -eq 1) 
    {
      $IPbytes = $content[28..31]
      if ([System.BitConverter]::IsLittleEndian) 
      {
        [Array]::Reverse($IPbytes)
      }
      $IPByte = [System.BitConverter]::GetBytes(([Bitconverter]::ToUInt32($IPbytes, 0) -bxor 0x2112a442))
        
      if ([System.BitConverter]::IsLittleEndian) 
      {
        [Array]::Reverse($IPByte)
      }
      $IP = [ipaddress]::new($IPByte)
    }
    elseif ($ProtocolByte -eq 2) 
    {
      $IPbytes = $content[28..44]
      [Byte[]]$magic = $content[4..19]
      for ($i = 0; $i -lt $IPbytes.Count; $i ++) 
      {
        $IPbytes[$i] = $IPbytes[$i] -bxor $magic[$i]
      }
      $IP = [ipaddress]::new($IPbytes)
    }
    $ipendpoint = [IPEndpoint]::new($IP, $port)
    Ok
  }
  catch 
  {
    Fail
    Write-Warning "Failed to communicate with $($StunEndpoint.ToString()) with error: $_"
  }
  return $ipendpoint
}


$stunServer1Name = "stun.azure.com"

try
{
  Checking "DNS service"
  $stunDns = Resolve-DnsName $stunServer1Name -Type A -ea Stop
  $stunServer1 = [IPEndpoint]::new([ipaddress]::Parse($stunDns.IP4Address), 3478)
  Ok
}
catch
{
  Fail
  Write-Warning "DNS resolution of $stunServer1Name failed. This might be a temporary failure, or your firewall might restrict DNS queries.`nThe script will continue with a numeric IP instead.`nSee <fwlink here> for more information."
  $stunServer1 = [IPEndpoint]::new([ipaddress]::Parse('20.202.22.68'), 3478)
}

$stunServer2 = [IPEndpoint]::new([ipaddress]::Parse('13.107.17.41'), 3478)

$UdpClient = [Net.Sockets.UdpClient]::new([Net.Sockets.AddressFamily]::InterNetwork)

$ipendpoint1 = Test-StunEndpoint -UdpClient $UdpClient -StunEndpoint $stunServer1
$ipendpoint2 = Test-StunEndpoint -UdpClient $UdpClient -StunEndpoint $stunServer2

if (($null -eq $ipendpoint1) -or ($null -eq $ipendpoint2))
{
    Write-Host -Object "`n`nSTUN did not work properly.`nShortpath for public networks is very unlikely to work on this host.`nSee https://go.microsoft.com/fwlink/?linkid=2204021 for more information." -ForegroundColor Red
}
elseif ($ipendpoint1.Equals($ipendpoint2)) 
{
    Write-Host -Object "`n`nSTUN works and your NAT type appears to be 'cone shaped'.`nShortpath for public networks is likely to work on this host.`nSee https://go.microsoft.com/fwlink/?linkid=2204021 for more information." -ForegroundColor Green
}
else 
{
    Write-Host -Object "`n`nSTUN works, but your NAT type appears to be 'symmetric'.`nShortpath for public networks is very unlikely to work on this host.`nSee https://go.microsoft.com/fwlink/?linkid=2204021 for more information." -ForegroundColor Red
}


$UdpClient.Close()

