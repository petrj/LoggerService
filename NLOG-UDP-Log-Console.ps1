# PS script for listening NLOG messages when logging to UDP target using like this:
#   <target name="udp" xsi:type="NLogViewer" address="udp4://10.0.0.2:9999" layout="${longdate} ${uppercase:${level}}|${threadid}|${message}"/>
#
# all messages looks like this XML:
#   <log4j:event logger="DVBTTelevizor.MAUI.LoggerProvider" level="INFO" timestamp="1767031021989" thread="36"> 
#       <log4j:message>Device is already logged</log4j:message> 
#           <log4j:properties>
#               <log4j:data name="log4japp" value="DefaultDomain(6807)"/> 
#               <log4j:data name="log4jmachinename" value="localhost"/>
#           </log4j:properties> 
#   </log4j:event>

Param($Port, $IPFilter)

if ([String]::IsNullOrWhiteSpace($Port))
{
    Write-Host "Setting default port: 9999"
    $Port = 9999
} 

if (-not [String]::IsNullOrWhiteSpace($IPFilter))
{
    Write-Host "Filtering IP: $IPFilter"    
}

$udpClient = New-Object System.Net.Sockets.UdpClient($Port)
$endpoint = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)

Write-Host "Listening on UDP port $Port..."
Write-Host "Press CTRL + C for exit"

try 
{
    while ($true) 
    {
        $bytes = $udpClient.Receive([ref]$endpoint)
        $text  = [System.Text.Encoding]::UTF8.GetString($bytes)

        $sourceIP   = $endpoint.Address.ToString()

        if (-not [String]::IsNullOrWhiteSpace($IPFilter))
        {
            if ($sourceIP -ne $IPFilter)
            {
                continue
            }
        }

        # Inject missing namespace declaration
        $fixedXml = $text -replace '<log4j:event\b','<log4j:event xmlns:log4j="urn:log4j"'

        try 
        {
            $xml = [xml]$fixedXml
                        
            $time = [DateTimeOffset]::FromUnixTimeMilliseconds($xml.event.timestamp).LocalDateTime
            $time = $time.ToString("dd.MM.yyyy HH:mm:ss")            

            Write-Host  ("[" + $sourceIP + "] " + $time + " : " + $xml.event.message) 
        }
        catch 
        {        
            Write-Error $_.Exception
        }
    }
}
finally 
{
    $udpClient.Close()
}