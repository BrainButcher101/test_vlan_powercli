# Define the list of IPs and metadata
$ipList = @(
    @{ VMName = "VLAN-Test1"; Cluster = "WIN-PROD"; Vlan = "pg_vm.2400_PRO_WIN.ds_WIN-PROD"; IP = "10.76.32.250"; SubnetMask = "255.255.255.0"; Gateway = "10.76.32.1"; Prefix = "24" },
    @{ VMName = "VLAN-Test2"; Cluster = "LNX-PROD"; Vlan = "pg_vm.2405_PRO_LNX.ds_LNX-PROD"; IP = "10.76.34.125"; SubnetMask = "255.255.255.128"; Gateway = "10.76.34.1"; Prefix = "28" },
    @{ VMName = "VLAN-Test3"; Cluster = "SAP"; Vlan = "pg_vm.2410_PRO_SAP_APP.ds_SAP"; IP = "10.76.35.29"; SubnetMask = "255.255.255.224"; Gateway = "10.76.35.1"; Prefix = "28" }
    # Add more entries as needed...
)

# Initialize an array list for storing the ping results
$pingResults = New-Object System.Collections.ArrayList

# Function to ping a host using the normal ping command
function Ping-Host {
    param (
        [string]$DestinationIP,
        [string]$VMName,
        [string]$Cluster
    )

    # Run the ping command and capture the output as a string array
    $pingOutput = ping $DestinationIP -n 4

    # Parse the ping command output
    foreach ($line in $pingOutput) {
        if ($line -match "Reply from (\d+\.\d+\.\d+\.\d+): bytes=\d+ time=(\d+)ms TTL=\d+") {
            $responseTime = $matches[2]
            $pingResults.Add([PSCustomObject]@{
                SourceIP = $env:COMPUTERNAME
                DestinationIP = $DestinationIP
                PingResult = "Success"
                ResponseTime = $responseTime
                VMName = $VMName
                Cluster = $Cluster
            }) | Out-Null
        } elseif ($line -match "Request timed out.") {
            $pingResults.Add([PSCustomObject]@{
                SourceIP = $env:COMPUTERNAME
                DestinationIP = $DestinationIP
                PingResult = "Timeout"
                ResponseTime = "N/A"
                VMName = $VMName
                Cluster = $Cluster
            }) | Out-Null
        } elseif ($line -match "Ping request could not find host") {
            $pingResults.Add([PSCustomObject]@{
                SourceIP = $env:COMPUTERNAME
                DestinationIP = $DestinationIP
                PingResult = "Failed"
                ResponseTime = "N/A"
                VMName = $VMName
                Cluster = $Cluster
            }) | Out-Null
        }
    }
}

# Loop through each entry in the IP list and perform the ping
foreach ($entry in $ipList) {
    Ping-Host -DestinationIP $entry.IP -VMName $entry.VMName -Cluster $entry.Cluster
    # Sleep for 2 seconds to avoid resource overload
    Start-Sleep -Seconds 2
}

# Convert the ArrayList to an array and export the ping results to a CSV file with headers in Administrator/Documents
$pingResultsArray = $pingResults.ToArray()
$path = "C:\Users\Administrator\Documents\PingResults.csv"
$pingResultsArray | Export-Csv -Path $path -NoTypeInformation

Write-Host "Ping results have been saved to $path."
