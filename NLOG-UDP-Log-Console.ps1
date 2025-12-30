# PS script for listening NLOG messages when logging to UDP target using like this:
#   <target name="udp" xsi:type="Network" address="udp4://10.0.0.2:9999" layout="${longdate} ${uppercase:${level}}|${threadid}|${message}"/>
#
# XML:
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

        # when using <target name="udp" xsi:type="Network" .... all messages are plain text

        # when using <target name="udp" xsi:type="NLogViewer" .... all messages are XML

        try 
        {
            # Inject missing namespace declaration
            $fixedXml = $text -replace '<log4j:event\b','<log4j:event xmlns:log4j="urn:log4j"'

            $xml = New-Object System.Xml.XmlDocument
            $xml.LoadXml($fixedXml)

            $time = [DateTimeOffset]::FromUnixTimeMilliseconds($xml.event.timestamp).LocalDateTime
            $time = $time.ToString("yyyy-MM-dd HH:mm:ss.ffff")

            Write-Host  ($sourceIP + ":" + $time + " INFO|?|" + $xml.event.message)
        }
        catch [System.Xml.XmlException] 
        {
            # NOT xml
            Write-Host ($sourceIP + ":" + $text);
        }         
    }
}
finally 
{
    $udpClient.Close()
}