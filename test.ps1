# Import the VMware PowerCLI module
Import-Module VMware.VimAutomation.Core

# Connect to the vCenter Server
$vcenterServer = "vcenter.yourdomain.com"
$vcUsername = "administrator@vsphere.local"
$vcPassword = "YourPassword"
Connect-VIServer -Server $vcenterServer -User $vcUsername -Password $vcPassword

# Parameters: Cluster, VLAN, IP, Subnet Mask, and Gateway combinations
$vmConfigurations = @(
    @{ VMName = "TestVM-1"; Cluster = "Cluster1"; Vlan = "VLAN1-PortGroup"; IP = "192.168.1.10"; SubnetMask = "255.255.255.0"; Gateway = "192.168.1.1" },
    @{ VMName = "TestVM-2"; Cluster = "Cluster2"; Vlan = "VLAN2-PortGroup"; IP = "192.168.2.10"; SubnetMask = "255.255.255.0"; Gateway = "192.168.2.1" },
    @{ VMName = "TestVM-3"; Cluster = "Cluster3"; Vlan = "VLAN3-PortGroup"; IP = "192.168.3.10"; SubnetMask = "255.255.255.0"; Gateway = "192.168.3.1" },
    @{ VMName = "TestVM-4"; Cluster = "Cluster4"; Vlan = "VLAN4-PortGroup"; IP = "192.168.4.10"; SubnetMask = "255.255.255.128"; Gateway = "192.168.4.1" }
)

$vmCpu = 2
$vmMemoryMB = 4096
$dnsServer = "8.8.8.8"  # Replace with your DNS server
$sourceVMName = "schlampe"  # The existing VM to clone

# CSV output file
$outputCsv = "PingResults.csv"

# Initialize CSV file
"SourceVM,SourceIP,DestinationVM,DestinationIP,PingResult" | Out-File -FilePath $outputCsv

# Function to clone a VM, configure its network, and place it in a specific cluster and VLAN
function Clone-VM {
    param (
        [string]$vmName,
        [string]$clusterName,
        [string]$networkName,
        [string]$staticIP,
        [string]$subnetMask,
        [string]$gateway
    )

    # Clone the existing VM
    $clonedVM = New-VM -Name $vmName `
                       -VM $sourceVMName `
                       -Datastore (Get-Cluster $clusterName | Get-Datastore | Select-Object -First 1) `
                       -ResourcePool (Get-Cluster $clusterName | Get-ResourcePool | Where-Object { $_.Name -eq 'Resources' }) `
                       -NetworkName $networkName `
                       -NumCpu $vmCpu `
                       -MemoryMB $vmMemoryMB `
                       -RunAsync

    # Wait for VM to be cloned
    Start-Sleep -Seconds 120

    # Configure network settings with static IP, gateway, and subnet mask
    $adapter = Get-NetworkAdapter -VM $clonedVM
    Set-VMGuestNetworkInterface -IPPolicy static -Gateway $gateway -Netmask $subnetMask -IPAddress $staticIP -NetworkAdapter $adapter -VM $clonedVM -Dns $dnsServer -Confirm:$false
}

# Clone VMs and assign static IPs, subnet masks, and gateways based on the configurations
$vmDetails = @()  # To store VM names and IPs
for ($i = 0; $i -lt $vmConfigurations.Count; $i++) {
    $config = $vmConfigurations[$i]
    $vmName = $config.VMName  # Use the custom VM name from the configuration
    Write-Host "Cloning VM $vmName for Cluster $($config.Cluster), VLAN $($config.Vlan), IP $($config.IP), Subnet Mask $($config.SubnetMask), and Gateway $($config.Gateway)..."
    Clone-VM -vmName $vmName -clusterName $config.Cluster -networkName $config.Vlan -staticIP $config.IP -subnetMask $config.SubnetMask -gateway $config.Gateway

    # Store VM name and IP for later ping tests
    $vmDetails += [PSCustomObject]@{ VMName = $vmName; IPAddress = $config.IP }
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
