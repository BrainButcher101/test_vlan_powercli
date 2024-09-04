# Define the list of IPs and metadata
$ipList = @(
    @{ VMName = "VLAN-Test1"; Cluster = "WIN-PROD"; Vlan = "pg_vm.2400_PRO_WIN.ds_WIN-PROD"; IP = "10.76.32.250"; SubnetMask = "255.255.255.0"; Gateway = "10.76.32.1"; Prefix = "24" },
    @{ VMName = "VLAN-Test2"; Cluster = "LNX-PROD"; Vlan = "pg_vm.2405_PRO_LNX.ds_LNX-PROD"; IP = "10.76.34.125"; SubnetMask = "255.255.255.128"; Gateway = "10.76.34.1"; Prefix = "28" },
    @{ VMName = "VLAN-Test3"; Cluster = "SAP"; Vlan = "pg_vm.2410_PRO_SAP_APP.ds_SAP"; IP = "10.76.35.29"; SubnetMask = "255.255.255.224"; Gateway = "10.76.35.1"; Prefix = "28" }
    # Add more entries as needed...
)

# Define the output file path
$outputFilePath = "C:\Users\Administrator\Documents\PingResult.txt"

# Clear or create the output file
Set-Content -Path $outputFilePath -Value ""

# Function to ping a host and save the output to a text file
function Ping-Host {
    param (
        [string]$DestinationIP,
        [string]$VMName,
        [string]$Cluster
    )

    # Run the ping command and capture the output
    $pingOutput = ping $DestinationIP -n 4 | Out-String

    # Append the output to the text file with VM and cluster info
    Add-Content -Path $outputFilePath -Value "Pinging $DestinationIP (VM: $VMName, Cluster: $Cluster)"
    Add-Content -Path $outputFilePath -Value $pingOutput
    Add-Content -Path $outputFilePath -Value "`n"  # Add a new line for separation
}

# Loop through each entry in the IP list and perform the ping
foreach ($entry in $ipList) {
    Ping-Host -DestinationIP $entry.IP -VMName $entry.VMName -Cluster $entry.Cluster
    Start-Sleep -Seconds 2  # Sleep to avoid resource overload
}

Write-Host "Ping results have been saved to $outputFilePath."
