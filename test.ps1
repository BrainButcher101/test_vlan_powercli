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
$networkNameTestServer = "VLAN-TestServer-PortGroup"  # VLAN where the test server will be
$vmNameTestServer = "TestServer"
$vlans = @("VLAN1-PortGroup", "VLAN2-PortGroup", "VLAN3-PortGroup", "VLAN4-PortGroup", "VLAN5-PortGroup", "VLAN6-PortGroup", "VLAN7-PortGroup", "VLAN8-PortGroup", "VLAN9-PortGroup", "VLAN10-PortGroup", "VLAN11-PortGroup", "VLAN12-PortGroup", "VLAN13-PortGroup", "VLAN14-PortGroup", "VLAN15-PortGroup", "VLAN16-PortGroup", "VLAN17-PortGroup", "VLAN18-PortGroup", "VLAN19-PortGroup", "VLAN20-PortGroup")
$staticIPs = @("192.168.1.10", "192.168.2.10", "192.168.3.10", "192.168.4.10", "192.168.5.10", "192.168.6.10", "192.168.7.10", "192.168.8.10", "192.168.9.10", "192.168.10.10", "192.168.11.10", "192.168.12.10", "192.168.13.10", "192.168.14.10", "192.168.15.10", "192.168.16.10", "192.168.17.10", "192.168.18.10", "192.168.19.10", "192.168.20.10")
$vmCpu = 2
$vmMemoryMB = 4096
$vmDiskGB = 40
$vmGuestOS = "windows9Server64Guest"  # Replace with appropriate guest OS ID
$subnetMask = "255.255.255.0"
$gateway = "192.168.1.1"  # Replace with the appropriate gateway
$dnsServer = "8.8.8.8"  # Replace with your DNS server

# Function to create a VM from scratch and assign a static IP
function Create-VM {
    param (
        [string]$vmName,
        [string]$networkName,
        [string]$staticIP
    )

    # Create a new VM
    $vm = New-VM -Name $vmName `
                 -ResourcePool (Get-Cluster $clusterName | Get-ResourcePool | Where-Object { $_.Name -eq 'Resources' }) `
                 -Datastore $datastoreName `
                 -DiskGB $vmDiskGB `
                 -MemoryMB $vmMemoryMB `
                 -NumCpu $vmCpu `
                 -NetworkName $networkName `
                 -GuestId $vmGuestOS `
                 -Datacenter $datacenterName `
                 -CD  -Confirm:$false -RunAsync

    # Wait for VM creation
    Start-Sleep -Seconds 120

    # Configure network settings with static IP
    $adapter = Get-NetworkAdapter -VM $vm
    Set-VMGuestNetworkInterface -IPPolicy static -Gateway $gateway -Netmask $subnetMask -IPAddress $staticIP -NetworkAdapter $adapter -VM $vm -Dns $dnsServer -Confirm:$false
}

# Create the test server in the specified VLAN and assign a static IP
$testServerIp = "192.168.1.100"  # Specify the IP for the test server
Write-Host "Creating Test Server in VLAN Test Server..."
$testServer = Create-VM -vmName $vmNameTestServer -networkName $networkNameTestServer -staticIP $testServerIp

# Create VMs in each of the other VLANs and assign static IPs
for ($i = 0; $i -lt $vlans.Count; $i++) {
    $vlan = $vlans[$i]
    $staticIP = $staticIPs[$i]
    $vmName = "TestVM-$vlan"
    Write-Host "Creating VM in $vlan with IP $staticIP..."
    Create-VM -vmName $vmName -networkName $vlan -staticIP $staticIP
}

# Perform ping tests from the Test Server to each VM
foreach ($ip in $staticIPs) {
    Write-Host "Pinging from Test Server ($testServerIp) to VM ($ip)..."
    if (Test-Connection -Source $testServerIp -ComputerName $ip -Count 4 -Quiet) {
        Write-Host "Ping to VM ($ip) succeeded."
    } else {
        Write-Host "Ping to VM ($ip) failed."
    }
}

# Disconnect from vCenter
Disconnect-VIServer -Server $vcenterServer -Confirm:$false
