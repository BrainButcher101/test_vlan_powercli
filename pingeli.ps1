# Define the list of IPs and metadata
$ipList = @(
    @{ VMName = "VLAN-Test1"; Cluster = "WIN-PROD"; Vlan = "pg_vm.2400_PRO_WIN.ds_WIN-PROD"; IP = "10.76.32.250"; SubnetMask = "255.255.255.0"; Gateway = "10.76.32.1"; Prefix = "24" },
    @{ VMName = "VLAN-Test2"; Cluster = "LNX-PROD"; Vlan = "pg_vm.2405_PRO_LNX.ds_LNX-PROD"; IP = "10.76.34.125"; SubnetMask = "255.255.255.128"; Gateway = "10.76.34.1"; Prefix = "28" },
    @{ VMName = "VLAN-Test3"; Cluster = "SAP"; Vlan = "pg_vm.2410_PRO_SAP_APP.ds_SAP"; IP = "10.76.35.29"; SubnetMask = "255.255.255.224"; Gateway = "10.76.35.1"; Prefix = "28" },
    @{ VMName = "VLAN-Test4"; Cluster = "SAP"; Vlan = "pg_vm.2415_PRO_SAP_ARC_APP.ds_SAP"; IP = "10.76.35.45"; SubnetMask = "255.255.255.240"; Gateway = "10.76.35.33"; Prefix = "24" },
    @{ VMName = "VLAN-Test5"; Cluster = "MSQ-PROD"; Vlan = "pg_vm.2420_PRO_DB_MSQ.ds_MSQ-PROD"; IP = "10.76.36.61"; SubnetMask = "255.255.255.192"; Gateway = "10.76.36.1"; Prefix = "24" },
    @{ VMName = "VLAN-Test6"; Cluster = "SAP"; Vlan = "pg_vm.2430_PRO_SAP_HANA.ds_SAP"; IP = "10.76.36.220"; SubnetMask = "255.255.255.224"; Gateway = "10.76.36.193"; Prefix = "24" },
    @{ VMName = "VLAN-Test7"; Cluster = "WIN-NPROD"; Vlan = "pg_vm.2440_TST_WIN.ds_WIN-NPROD"; IP = "10.76.40.250"; SubnetMask = "255.255.255.0"; Gateway = "10.76.40.1"; Prefix = "24" },
    @{ VMName = "VLAN-Test8"; Cluster = "LNX-NPROD"; Vlan = "pg_vm.2445_TST_LNX.ds_LNX-NPROD"; IP = "10.76.42.125"; SubnetMask = "255.255.255.128"; Gateway = "10.76.42.1"; Prefix = "24" },
    @{ VMName = "VLAN-Test9"; Cluster = "SAP"; Vlan = "pg_vm.2650_TST_SAP_APP.ds_SAP"; IP = "10.76.43.29"; SubnetMask = "255.255.255.224"; Gateway = "10.76.43.1"; Prefix = "24" },
    @{ VMName = "VLAN-Test10"; Cluster = "MSQ-PROD"; Vlan = "pg_vm.2455_TST_DB_MSQ.ds_MSQ-NPROD"; IP = "10.76.44.61"; SubnetMask = "255.255.255.192"; Gateway = "10.76.44.1"; Prefix = "24" },
    @{ VMName = "VLAN-Test11"; Cluster = "SAP"; Vlan = "pg_vm.2465_TST_SAP_HANA.ds_SAP"; IP = "10.76.44.220"; SubnetMask = "255.255.255.224"; Gateway = "10.76.44.193"; Prefix = "24" },
    @{ VMName = "VLAN-Test12"; Cluster = "WIN-NPROD"; Vlan = "pg_vm.2470_DEV_WIN.ds_WIN-NPROD"; IP = "10.76.47.60"; SubnetMask = "255.255.255.192"; Gateway = "10.76.47.1"; Prefix = "24" },
    @{ VMName = "VLAN-Test13"; Cluster = "LNX-NPROD"; Vlan = "pg_vm.2475_DEV_LNX.ds_LNX-NPROD"; IP = "10.76.48.60"; SubnetMask = "255.255.255.192"; Gateway = "10.76.48.1"; Prefix = "24" },
    @{ VMName = "VLAN-Test14"; Cluster = "SAP"; Vlan = "pg_vm.2480_DEV_SAP_APP.ds_SAP"; IP = "10.76.48.220"; SubnetMask = "255.255.255.224"; Gateway = "10.76.48.193"; Prefix = "24" },
    @{ VMName = "VLAN-Test15"; Cluster = "MSQ-NPROD"; Vlan = "pg_vm.2485_DEV_DB_MSQ.ds_MSQ-NPROD"; IP = "10.76.49.60"; SubnetMask = "255.255.255.192"; Gateway = "10.76.48.1"; Prefix = "24" },
    @{ VMName = "VLAN-Test16"; Cluster = "SAP"; Vlan = "pg_vm.2495_DEV_SAP_HANA.ds_SAP"; IP = "10.76.49.220"; SubnetMask = "255.255.255.224"; Gateway = "10.76.48.193"; Prefix = "24" },
    @{ VMName = "VLAN-Test17"; Cluster = "LNX-PROD"; Vlan = "pg_vm.2535_DMZ_OB_APP_LNX.ds_LNX-PROD"; IP = "10.76.56.93"; SubnetMask = "255.255.255.224"; Gateway = "10.76.56.65"; Prefix = "24" },
    @{ VMName = "VLAN-Test18"; Cluster = "WIN-PROD"; Vlan = "pg_vm.2540_DMZ_OB_INF_WIN.ds_WIN-PROD"; IP = "10.76.56.157"; SubnetMask = "255.255.255.224"; Gateway = "10.76.56.129"; Prefix = "24" },
    @{ VMName = "VLAN-Test19"; Cluster = "LNX-PROD"; Vlan = "pg_vm.2545_DMZ_OB_INF_LNX.ds_LNX-PROD"; IP = "10.76.56.220"; SubnetMask = "255.255.255.224"; Gateway = "10.76.56.193"; Prefix = "24" }
)

# Initialize an empty array for storing the ping results
$pingResults = @()

# Loop through each entry in the IP list
foreach ($entry in $ipList) {
    $destinationIP = $entry.IP
    $sourceIP = (Test-Connection -ComputerName $destinationIP -Count 1 -Quiet) # Pinging the IP address
    if ($sourceIP) {
        $pingResult = "Success"
    } else {
        $pingResult = "Failure"
    }

    # Append the results to the array
    $pingResults += [PSCustomObject]@{
        SourceIP = $env:COMPUTERNAME
        DestinationIP = $destinationIP
        PingResult = $pingResult
    }
}

# Export the ping results to a CSV file in Administrator/Documents
$path = "C:\Users\Administrator\Documents\PingResults.csv"
$pingResults | Export-Csv -Path $path -NoTypeInformation

Write-Host "Ping results have been saved to $path."
