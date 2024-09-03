# Import the VMware PowerCLI module
Import-Module VMware.VimAutomation.Core

# Connect to the vCenter Server
$vcenterServer = "vcenter.yourdomain.com"
$vcUsername = "administrator@vsphere.local"
$vcPassword = "YourPassword"
Connect-VIServer -Server $vcenterServer -User $vcUsername -Password $vcPassword

# Parameters
$datacenterName = "YourDatacenter"
$clusterName = "YourCluster"
$datastoreName = "YourDatastore"
$sourceVMName = "sourceVM"  # Use a neutral name
$vlans = @("VLAN1-PortGroup", "VLAN2-PortGroup", "VLAN3-PortGroup", "VLAN4-PortGroup", "VLAN5-PortGroup", "VLAN6-PortGroup", "VLAN7-PortGroup", "VLAN8-PortGroup", "VLAN9-PortGroup", "VLAN10-PortGroup", "VLAN11-PortGroup", "VLAN12-PortGroup", "VLAN13-PortGroup", "VLAN14-PortGroup", "VLAN15-PortGroup", "VLAN16-PortGroup", "VLAN17-PortGroup", "VLAN18-PortGroup", "VLAN19-PortGroup", "VLAN20-PortGroup")
$staticIPs = @("192.168.1.10", "192.168.2.10", "192.168.3.10", "192.168.4.10", "192.168.5.10", "192.168.6.10", "192.168.7.10", "192.168.8.10", "192.168.9.10", "192.168.10.10", "192.168.11.10", "192.168.12.10", "192.168.13.10", "192.168.14.10", "192.168.15.10", "192.168.16.10", "192.168.17.10", "192.168.18.10", "192.168.19.10", "192.168.20.10")
$vmCpu = 2
$vmMemoryMB = 4096
$subnetMask = "255.255.255.0"
$gateway = "192.168.1.1"  # Replace with the appropriate gateway
$dnsServer = "8.8.8.8"  # Replace with your DNS server

# CSV output file
$outputCsv = "PingResults.csv"

# Initialize CSV file
"SourceVM,SourceIP,DestinationVM,DestinationIP,PingResult" | Out-File -FilePath $outputCsv

# Function to clone a VM and reconfigure it
function Clone-VM {
    param (
        [string]$vmName,
        [string]$networkName,
        [string]$staticIP
    )

    try {
        # Clone the existing VM
        $clonedVM = New-VM -Name $vmName `
            -VM $sourceVMName `
            -Datastore $datastoreName `
            -ResourcePool (Get-Cluster $clusterName | Get-ResourcePool | Where-Object { $_.Name -eq 'Resources' }) `
            -NetworkName $networkName `
            -NumCpu $vmCpu `
            -MemoryMB $vmMemoryMB `
            -RunAsync

        # Wait for VM to be cloned
        Start-Sleep -Seconds 120

        # Configure network settings with static IP
        $adapter = Get-NetworkAdapter -VM $clonedVM
        Set-VMGuestNetworkInterface -IPPolicy static -Gateway $gateway -Netmask $subnetMask -IPAddress $staticIP -NetworkAdapter $adapter -VM $clonedVM -Dns $dnsServer -Confirm:$false
    } catch {
        Write-Warning "Error cloning or configuring VM: $_"
    }
}

# Clone VMs in each of the VLANs and assign static IPs
$vmDetails = @()  # To store VM names and IPs
for ($i = 0; $i -lt $vlans.Count; $i++) {
    $vlan = $vlans[$i]
    $staticIP = $staticIPs[$i]
    $vmName = "ClonedVM-$i"
    Write-Host "Cloning VM for $vlan with IP $staticIP..."
    Clone-VM -vmName $vmName -networkName $vlan -staticIP $staticIP

    # Store VM name and IP for later ping tests
    $vmDetails += [PSCustomObject]@{ VMName = $vmName; IPAddress = $staticIP }
}

# Perform ping tests between all VMs and save results to CSV
foreach ($sourceVM in $vmDetails) {
    foreach ($targetVM in $vmDetails) {
        if ($sourceVM.IPAddress -ne $targetVM.IPAddress) {  # Avoid pinging itself
            Write-Host "Pinging from $($sourceVM.VMName) ($($sourceVM.IPAddress)) to $($targetVM.VMName) ($($targetVM.IPAddress))..."
            $pingResult = if (Test-Connection -Source $sourceVM.IPAddress -ComputerName $targetVM.IPAddress -Count 4 -Quiet) {
                "Success"
            } else {
                "Failed"
            }

            # Write result to CSV
            "$($sourceVM.VMName),$($sourceVM.IPAddress),$($targetVM.VMName),$($targetVM.IPAddress),$pingResult" | Out-File -FilePath $outputCsv -Append
        }
    }
}

# Disconnect from vCenter
Disconnect-VIServer -Server $vcenterServer -Confirm:$false

Write-Host "Ping tests completed. Results saved to $outputCsv"
