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
$vmCpu = 2
$vmMemoryMB = 4096
$vmDiskGB = 40
$vmGuestOS = "windows9Server64Guest"  # Replace with appropriate guest OS ID

# Function to create a VM from scratch
function Create-VM {
    param (
        [string]$vmName,
        [string]$networkName
    )

    # Create a new VM
    New-VM -Name $vmName `
           -ResourcePool (Get-Cluster $clusterName | Get-ResourcePool | Where-Object { $_.Name -eq 'Resources' }) `
           -Datastore $datastoreName `
           -DiskGB $vmDiskGB `
           -MemoryMB $vmMemoryMB `
           -NumCpu $vmCpu `
           -NetworkName $networkName `
           -GuestId $vmGuestOS `
           -Datacenter $datacenterName `
           -CD  -Confirm:$false -RunAsync
}

# Create the test server in the specified VLAN
Write-Host "Creating Test Server in VLAN Test Server..."
$testServer = Create-VM -vmName $vmNameTestServer -networkName $networkNameTestServer

# Wait for the test server to be created
Start-Sleep -Seconds 120

# Get the IP Address of the Test Server
$testServerIp = (Get-VM $vmNameTestServer | Get-VMGuest).IPAddress[0]

# Create VMs in each of the other VLANs and ping from the Test Server
foreach ($vlan in $vlans) {
    $vmName = "TestVM-$vlan"
    Write-Host "Creating VM in $vlan..."
    $vm = Create-VM -vmName $vmName -networkName $vlan

    # Wait for the VM to be created
    Start-Sleep -Seconds 120

    # Get IP Address of the VM
    $vmIp = (Get-VM $vmName | Get-VMGuest).IPAddress[0]

    # Perform Ping Test
    function Test-Ping {
        param (
            [string]$sourceVmIp,
            [string]$targetVmIp
        )

        Write-Host "Pinging from $sourceVmIp to $targetVmIp..."
        Test-Connection -Source $sourceVmIp -ComputerName $targetVmIp -Count 4 -Quiet
    }

    # Ping from Test Server to the VM
    if (Test-Ping -sourceVmIp $testServerIp -targetVmIp $vmIp) {
        Write-Host "Ping from Test Server ($testServerIp) to VM ($vmIp) in $vlan succeeded."
    } else {
        Write-Host "Ping from Test Server ($testServerIp) to VM ($vmIp) in $vlan failed."
    }
}

# Disconnect from vCenter
Disconnect-VIServer -Server $vcenterServer -Confirm:$false
