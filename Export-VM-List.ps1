<#
.SYNOPSIS
Exports various lists of VMs associated with a vCenter server, including details such as creation date, VR protection status, and SRM protection status.

.DESCRIPTION
Exports various lists of VMs associated with a vCenter server, including details such as creation date, VR protection status, and SRM protection status.

Current capabilities include:

- Displays and exports full list of all VMs, including power status, disk space, and creation date; filtering out SRM "placeholder" VMs.
- Displays and exports list of VMs protected by vSphere Replication, including RPO, quiescing, compression, encryption, and disk space.
- Displays and exports list of powered on VMs NOT protected by vSphere Replication, excluding SRM "placeholder" VMs.
- Displays and exports list of powered off VMs NOT protected by vSphere Replication, excluding SRM "placeholder" VMs.
- Displays and exports list of the last 5 successful replication sessions for each VM over the last 30 day period, including date stamp for each successful replication.
- Displays and exports list of the number of days elapsed since each successful replication for each VM.
- Displays and exports list of the size (in MB) of each of the last 5 replication sessions, including full syncs, incremental syncs, quiesced syncs, and crash-consistent syncs.
    - This reflects the amount of data transmitted across the WAN.
- Displays and exports list of list of all VR configured VMs in PAUSED or ERROR state (i.e. not replicating properly).  This typically happens when:
    - Someone manually paused replication.
    - Someone added a new VMDK to the VM, which pauses replication for the whole VM.
- Displays and exports list of all SRM "placeholder" VMs (in case of vCenter used as a recovery site for SRM).
- Displays and exports list of all VMs protected by SRM, along with name of SRM Protection Group and status of SRM Protection Group.
- Displays and exports list of SRM protected VMs that need to be re-configured due to missing/unresolved devices (CD-ROM with attached ISO image, etc.).
- Displays and exports list of SRM protected VMs that need to be re-configured due to VMDK(s) not being replicated properly (i.e. newly added VMDK).
- Displays and exports list of SRM configured VMs that have no protection (no placeholder VM) due to missing inventory mappings at the DR site (network mapping, folder mapping, etc.).
- Displays and exports list of SRM recovery plan(s) assigned to each VM.
- Displays and exports list of VMs with no SRM recovery plan assigned.
- Displays and exports list of all VMs that are being replicated by vSphere Replication but NOT protected by SRM.
- All of the above lists are displayed in table format as well as exported to CSV files.
- Supports SRM configured in shared recovery site configuration (multiple instances of SRM registered to a vCenter).
- Properly handles both FQDN and IP address of vCenter server and SRM server.

NOTE: VM creation date will show as 1/1/1970 for all VMs created on versions of vCenter/ESXi prior to 6.7.

Future enhancement ideas:

- Display last time Recovery Plan was tested (i.e. the last time a DR test was performed).
- E-mail CSV output to e-mail address.
- Exclude VMs with vCenter tag "No VR Protect" from list.
- Exclude VMs with vCenter tag "No SRM Protect" from list.
- Report on VMs with Tag Name "Backup" and Category "Backup" (these are Avamar protected VMs).
- Automatically protect VMs with VR based on vCenter tag.
- Automatically protect VMs with SRM based on vCenter tag.
- Report on VMs experiencing RRO violations (Joe Williams' script).


.PARAMETER VIServer
Specifies the vCenter Server FQDN or IP address.  If using SRM, this should be the vCenter paired with the SRM server below.

.PARAMETER SRMServer
Specifies the SRM Server FQDN or IP address.  This should be the SRM server paired with the vCenter above.

.PARAMETER SRMAppliance
If using the Windows version of SRM, this can be ignored.  If using the PhotonOS (appliance) version of SRM, specify "1" for this parameter.

.NOTES
Author: Bill Oyler

vSphere Replication status code from Ben Meadowcroft
(https://github.com/vmware/PowerCLI-Example-Scripts/blob/master/Modules/SRM/Meadowcroft.Srm.psm1)

SRM protection status code from Phyoe Wai Paing (https://sysadminplus.blogspot.com/2016/12/list-all-vmware-srm-protected-vms-with.html) and piercj2 (https://communities.vmware.com/thread/569921)

vSphere Replication status code adapted from Neale (https://enlow.co.uk/powershell/reporting-on-vsphere-replication-transfer-sizes/)

Structure of PowerShell script thanks to Mark Wolfe and Scott Haas (https://github.com/ScottHaas/vcenter-migration-scripts)

Changelog:
2019-10-08
 * Properly handles IP address input for vCenter and SRM FQDN.
 * Displays last 5 replication sessions (and corresponding transfer size) for each VM configured for vSphere Replication over the last 30 days.
 * Displays list of vSphere Replication configured VMs that are currently in "PAUSED" or "ERROR" state (i.e. not replicating).
 * Displays SRM protection status for each VM, including all issues that require re-configuration.
 * Displays SRM recovery plan status for each VM.
2019-09-26
 * Excludes SRM placeholder VMs, filters out Powered Off VMs, displays RPO, quiesce, encryption, and compression status.
2019-09-03
 * Initial version.

 
.EXAMPLE
Export lists of VMs and VR/SRM protection status from vCenter prod-vcenter.domain.com and its associated SRM server prod-srm.domain.com, which is a PhotonOS SRM virtual appliance:

PS> Export-VM-List.ps1 prod-vcenter.domain.com prod-srm.domain.com 1

.LINK
Reference: https://gitlab.presidio.com/tmmiller/powercli-scripts/tree/master/vCenter-Info
#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateNotNullOrEmpty()]
    [string]$VIServer,
    [Parameter(Mandatory=$false, Position=1)]
    [string]$SRMServer,
    [Parameter(Mandatory=$false, Position=2)]
    [int]$SRMAppliance
)


# Ignore invalid / self-signed SSL certificates.
Set-PowerCLIConfiguration -InvalidCertificateAction ignore -confirm:$false | out-null


# If previous vCenter server connection(s) exist, disconnect existing vCenter connection(s).
if ($global:defaultviservers){
    Write-Host "Disconnecting from existing vCenter server connection(s)..."
    Disconnect-VIServer * -Confirm:$false -ErrorAction:SilentlyContinue
}


# If previous SRM server connection(s) exist, disconnect existing SRM connection(s).
if ($global:DefaultSrmServers){
    Write-Host "Disconnecting from existing SRM server connection(s)..."
    Disconnect-SrmServer * -Confirm:$false -ErrorAction:SilentlyContinue
}


# Request credentials to connect to vCenter server (and SRM server).
Write-Host "`n`nConnecting to vCenter Server $VIServer...`n`n"
$username = "administrator@vsphere.local"
$password = "passwordhere"
$secureStringPwd = $password | ConvertTo-SecureString -AsPlainText -Force 
$Credential = New-Object System.Management.Automation.PSCredential -ArgumentList ($username, $secureStringPwd)


# Connect to vCenter server.
Connect-VIServer -Server $VIServer -Credential $credential -ErrorAction Stop | out-null
# Determine whether we have FQDN or IP address, for purpose of displaying "short name" in case of long FQDN.
$isIPAddress = ($VIServer -AS [IPAddress]) -as [Bool]
if ($isIPAddress -ne "TRUE") {
    $VIServerShortName = $VIServer.Split(".")[0]
} else {
    $VIServerShortName = $VIServer
}


# Connect to SRM server (if SRM server name was provided).
if ($SRMServer) {
    Write-Host "`n`nConnecting to SRM server $SRMServer using same credentials as vCenter Server...`n`n"
    if ($SRMAppliance) {
        $srm = Connect-SrmServer -SrmServerAddress $SRMServer -Port 443 -Credential $credential -RemoteCredential $credential -IgnoreCertificateErrors
    }
    else {
        $srm = Connect-SrmServer -SrmServerAddress $SRMServer -Credential $credential -RemoteCredential $credential -IgnoreCertificateErrors
    }

    # Determine whether we have FQDN or IP address, for purpose of displaying "short name" in case of long FQDN.
    $isIPAddress = ($SRMServer -AS [IPAddress]) -as [Bool]
    if ($isIPAddress -ne "TRUE") {
        $SRMServerShortName = $SRMServer.Split(".")[0]
    } else {
        $SRMServerShortName = $SRMServer
    }
}


# Display list of all VMs registered to vCenter (except for SRM placeholder VMs and VRAs).
Write-Host "===================================================================================================`nFull list of all VMs on vCenter $VIServerShortName (excluding SRM placeholder VMs and VRAs) ...`n==================================================================================================="
$VMList = Get-VM | Where-Object {!$_.ExtensionData.Config.ManagedBy.Type -ieq 'placeholderVm'} | Select Name,PowerState,@{n="ProvisionedSpace(GB)"; E={[math]::round($_.ProvisionedSpaceGB)}},@{n="UsedSpace(GB)"; E={[math]::round($_.UsedSpaceGB)}},@{N="Creation Date";E={$_.ExtensionData.Config.createDate}}
$VMList | ft -AutoSize

# Export to CSV file.
$VMFilename = "VM.Full-List.csv"
Write-Host ">>>> EXPORTING TO CSV FILE: $VMFilename ...`n`n"
$VMList | Export-Csv $VMFilename -NoTypeInformation -UseCulture


# Display list of all VMs configured for vSphere Replication.
Write-Host "===================================================================================================`nAll VMs configured for vSphere Replication (VR) on vCenter $VIServerShortName ...`n==================================================================================================="
$VMList = Get-VM | Where-Object {($_.ExtensionData.Config.ExtraConfig | Where-Object { $_.Key -eq 'hbr_filter.destination' -and $_.Value } )} | Select Name,PowerState,@{N="RPO Minutes";E={($_.ExtensionData.Config.ExtraConfig | where {$_.Key -like 'hbr_filter.rpo'}).Value}},@{N="Quiesced?";E={($_.ExtensionData.Config.ExtraConfig | where {$_.Key -like 'hbr_filter.quiesce'}).Value}},@{N="WAN Compressed?";E={($_.ExtensionData.Config.ExtraConfig | where {$_.Key -like 'hbr_filter.netCompression'}).Value}},@{N="WAN Encrypted?";E={($_.ExtensionData.Config.ExtraConfig | where {$_.Key -like 'hbr_filter.netEncryption'}).Value}},@{n="ProvisionedSpace(GB)"; E={[math]::round($_.ProvisionedSpaceGB)}},@{n="UsedSpace(GB)"; E={[math]::round($_.UsedSpaceGB)}},@{N="Creation Date";E={$_.ExtensionData.Config.createDate}}
$VMList | ft -AutoSize

# Export to CSV file.
$VMFilename = "VR-Configured.csv"
Write-Host ">>>> EXPORTING TO CSV FILE: $VMFilename ...`n`n"
$VMList | Export-Csv $VMFilename -NoTypeInformation -UseCulture


# Display list of the last 5 successful vSphere Replication transfers (including transfer size in MB) over the last 30 days for all VMs configured for vSphere Replication.
# The following types of synchronizations are reported:
# hbr.primary.DeltaCompletedEvent = Crash consistent sync completed
# hbr.primary.SyncCompletedEvent = Full-sync completed
# hbr.primary.AppQuiescedDeltaCompletedEvent = Application consistent sync completed
# hbr.primary.FSQuiescedDeltaCompletedEvent	= File-system consistent sync completed
Write-Host "===================================================================================================`nLast 5 successful vSphere Replication sessions in last 30 days for all VR protected VMs on vCenter $VIServerShortName ...`n==================================================================================================="
$DateRangeStart = $(Get-Date).AddDays(-30)
$DateRangeEnd = Get-Date
foreach ($_ in $VMList) {
    # Size of replication session in MB, rounded to nearest two decimal places and then formatted without decimal places.
    $ReplSize = @{L="Size of Replication Transfer (MB)";E={ [string]::Format('{0:N0}',([math]::Round($_.Arguments.Value/1MB, 2)))} }
    # Number of days that have elapsed since each replication session to today's date.
    $ReplDays = @{L="Days Since Replication";E={ (New-TimeSpan -Start $_.CreatedTime -End $DateRangeEnd).Days} }
    $ReplSessionList += Get-VIEvent -Entity $_.Name  -MaxSamples ([int]::MaxValue) -Start $DateRangeStart -Finish $DateRangeEnd | Where-Object { $_.EventTypeId -eq "hbr.primary.DeltaCompletedEvent" -or $_.EventTypeId -eq "hbr.primary.SyncCompletedEvent" -or $_.EventTypeId -eq "hbr.primary.AppQuiescedDeltaCompletedEvent" -or $_.EventTypeId -eq "hbr.primary.FSQuiescedDeltaCompletedEvent" } | Select -First 5 @{Name="Name";Expression={$_.Vm.Name}}, @{n="Last 5 Successful Replications"; E={$_.CreatedTime}}, $ReplSize, $ReplDays
}
$ReplSessionList | ft -AutoSize

# Export to CSV file.
$VMFilename = "VR-Repl-History.csv"
Write-Host ">>>> EXPORTING TO CSV FILE: $VMFilename ...`n`n"
$ReplSessionList | Export-Csv $VMFilename -NoTypeInformation -UseCulture


# Display list of all VR configured VMs in PAUSED or ERROR state.
Write-Host "===================================================================================================`nAll VR configured VMs in PAUSED or ERROR state (i.e. not replicating properly) on vCenter $VIServerShortName ...`n==================================================================================================="
$ErrorState = "PAUSED or ERROR"
$VMList = Get-VM | Where-Object {($_.ExtensionData.Config.ExtraConfig | Where-Object { $_.Key -eq 'hbr_filter.pause' } )} | Select Name,PowerState,@{N="Replication Status";E={$ErrorState}},@{n="ProvisionedSpace(GB)"; E={[math]::round($_.ProvisionedSpaceGB)}},@{n="UsedSpace(GB)"; E={[math]::round($_.UsedSpaceGB)}},@{N="Creation Date";E={$_.ExtensionData.Config.createDate}}
$VMList | ft -AutoSize

# Export to CSV file.
$VMFilename = "VR-Error-Paused.csv"
Write-Host ">>>> EXPORTING TO CSV FILE: $VMFilename ...`n`n"
$VMList | Export-Csv $VMFilename -NoTypeInformation -UseCulture


# Display list of all powered on VMs NOT configured for vSphere Replication.
Write-Host "===================================================================================================`nAll powered on VMs NOT configured for vSphere Replication (VR) on vCenter $VIServerShortName ...`n==================================================================================================="
$VMList = Get-VM | Where-Object {!($_.ExtensionData.Config.ExtraConfig | Where-Object { $_.Key -match 'hbr_filter.destination' -and $_.Value } )} | Where-Object {!$_.ExtensionData.Config.ManagedBy.Type -ieq 'placeholderVm'} | Where-Object {$_.PowerState -eq "PoweredOn"} | Select Name,PowerState,@{n="ProvisionedSpace(GB)"; E={[math]::round($_.ProvisionedSpaceGB)}},@{n="UsedSpace(GB)"; E={[math]::round($_.UsedSpaceGB)}},@{N="Creation Date";E={$_.ExtensionData.Config.createDate}}
$VMList | ft -AutoSize

# Export to CSV file.
$VMFilename = "VR-Not-Configured-PoweredOn.csv"
Write-Host ">>>> EXPORTING TO CSV FILE: $VMFilename ...`n`n"
$VMList | Export-Csv $VMFilename -NoTypeInformation -UseCulture


# Display list of all powered off VMs NOT configured for vSphere Replication.
Write-Host "===================================================================================================`nAll powered off VMs NOT configured for vSphere Replication (VR) on vCenter $VIServerShortName ...`n==================================================================================================="
$VMList = Get-VM | Where-Object {!($_.ExtensionData.Config.ExtraConfig | Where-Object { $_.Key -match 'hbr_filter.destination' -and $_.Value } )} | Where-Object {!$_.ExtensionData.Config.ManagedBy.Type -ieq 'placeholderVm'} | Where-Object {$_.PowerState -eq "PoweredOff"} | Select Name,PowerState,@{n="ProvisionedSpace(GB)"; E={[math]::round($_.ProvisionedSpaceGB)}},@{n="UsedSpace(GB)"; E={[math]::round($_.UsedSpaceGB)}},@{N="Creation Date";E={$_.ExtensionData.Config.createDate}}
$VMList | ft -AutoSize

# Export to CSV file.
$VMFilename = "VR-Not-Configured-PoweredOff.csv"
Write-Host ">>>> EXPORTING TO CSV FILE: $VMFilename ...`n`n"
$VMList | Export-Csv $VMFilename -NoTypeInformation -UseCulture


# Display list of all SRM placeholder VMs (zero bytes, powered off).
Write-Host "===================================================================================================`nAll SRM placeholder VMs on vCenter $VIServerShortName (used for DR testing and failover only)...`n==================================================================================================="
$VMList = Get-VM | Where-Object {$_.ExtensionData.Config.ManagedBy.Type -ieq 'placeholderVm'} | Select Name,PowerState,@{n="UsedSpace(GB)"; E={[math]::round($_.UsedSpaceGB)}},@{N="Creation Date";E={$_.ExtensionData.Config.createDate}}
$VMList | ft -AutoSize

# Export to CSV file.
$VMFilename = "SRM-Placeholders.csv"
Write-Host ">>>> EXPORTING TO CSV FILE: $VMFilename ...`n`n"
$VMList | Export-Csv $VMFilename -NoTypeInformation -UseCulture


# The following lists are generated only when an SRM server is connected.
if ($SRMServer) {
    # Display list of all VMs protected by SRM and their associated protection groups and recovery plans.
    Write-Host "===================================================================================================`nAll VMs on vCenter $VIServerShortName protected by SRM server $SRMServerShortName ...`n==================================================================================================="
    $protectionGroups = $srm.ExtensionData.Protection.ListProtectionGroups() | Where-Object {$_.ProtectionGroupGetOperationalLocation() -eq "inProtectedSite"}

    $VMList = $protectionGroups | where {$_.GetProtectionState() -ne "Shadowing" } | % {    # List only VMs at the Protection Site (not the Recovery Site)
        $protectionGroup = $_
        $protectionGroupInfo = $protectionGroup.GetInfo()
        $protectionGroupState = $protectionGroup.GetProtectionState()
        $RecoveryPlan = ""
        $RecoveryPlan = $protectionGroup.ListRecoveryPlans()
        if ($RecoveryPlan) {
            $SRMRecoveryPlan = $RecoveryPlan.GetInfo().Name -join ', '  # Protection group may exist in more than one Recovery Plan
        } else {
            $SRMRecoveryPlan = "** NO RECOVERY PLAN ASSIGNED! **"
        }
        
        # Associated VMs are all vSphere Replication protected VMs that have been added to an SRM Protection Group (may or may not be fully protected, however).
        $associatedVms = Get-VM -id $($protectionGroup.ListAssociatedVms().MoRef)

        # Protected VMs are all VMs in an SRM Protection Group that are protected at the Recovery Site (i.e. Placeholder VM has been created).
        $protectedVms = $protectionGroup.ListProtectedVms() # Returns an array of "ProtectedVm" data objects.
        $protectedVms | % { $_.VM = Get-View -id $_.vm.moref }  # The "ProtectedVm" object contains a "Vm" object which contains a "MoRef" which can be used to get the actual VM.
        
        foreach ($vm in $associatedVms) {   # For each vSphere Replication protected VM in an SRM Protection Group
            # By default, assume that each associated VM is NOT properly protected unless we find out otherwise
            $SRMNeedsConfig = "** NOT PROTECTED! **"
            $SRMFaults = "** NOT PROTECTED! **"
            $SRMVMState = "** NOT PROTECTED! **"
            $SRMPeerState = "** NOT PROTECTED! **"

            foreach ($protectedVM in $protectedVms) {   # For each VM being properly protected in the Protection Group (i.e. placeholder VM exists at DR site)
                if ($protectedVM.vm.Name -eq $vm.Name) {
                    if ($protectedVM.needsconfiguration) {
                        $SRMNeedsConfig = "** NEEDS RECONFIGURATION! **"    # VM is protected, but need minor re-configuration (such as disconnect a CD-ROM ISO)
                    } else {
                        $SRMNeedsConfig = "OK"  # VM is fully protected
                    }
                    $SRMFaults = $protectedVM.faults
                    $SRMVMState = $protectedVM.state
                    $SRMPeerState = $protectedVM.peerState
                }
            } # end for each protected VM

            $output = "" | select Name, ProtectionGroupName, ConfigurationStatus, Faults, ProtectionGroupState, VMState, PeerState, RecoveryPlans, CreationDate
            $output.Name = $vm.Name
            $output.ConfigurationStatus = $SRMNeedsConfig
            $output.Faults = $SRMFaults
            $output.VMState = $SRMVMState
            $output.PeerState = $SRMPeerState
            $output.ProtectionGroupName = $protectionGroupInfo.Name
            $output.ProtectionGroupState = $protectionGroupState
            $output.RecoveryPlans = $SRMRecoveryPlan
            $output.CreationDate = $vm.ExtensionData.Config.createDate
            $output
        } # end for each associated VM
    } 

    $VMList | ft -AutoSize

    # Export to CSV file.
    $VMFilename = "SRM-Configured-$SRMServerShortName.csv"
    Write-Host ">>>> EXPORTING TO CSV FILE: $VMFilename ...`n`n"
    $VMList | Export-Csv $VMFilename -NoTypeInformation -UseCulture

    
    # Display list of all VMs being replicated by VR but NOT protected by SRM.
    Write-Host "===================================================================================================`nAll vSphere Replicated VMs on vCenter $VIServerShortName NOT protected by SRM ...`n==================================================================================================="
    $VMList = $srm.ExtensionData.Protection.ListUnassignedReplicatedVms("vr") | ForEach-Object { Get-VM -id $($_.MoRef) } | Select Name,PowerState,@{n="ProvisionedSpace(GB)"; E={[math]::round($_.ProvisionedSpaceGB)}},@{n="UsedSpace(GB)"; E={[math]::round($_.UsedSpaceGB)}},@{N="Creation Date";E={$_.ExtensionData.Config.createDate}}
    $VMList | ft -AutoSize

    # Export to CSV file.
    $VMFilename = "SRM-Not-Configured-$SRMServerShortName.csv"
    Write-Host ">>>> EXPORTING TO CSV FILE: $VMFilename ...`n`n"
    $VMList | Export-Csv $VMFilename -NoTypeInformation -UseCulture
}


# Clean up and disconnect vCenter server connection.
Write-Host "Disconnecting from vCenter Server $VIServer ..."
Disconnect-VIServer -Server $VIServer -Confirm:$False

# Disconnect SRM server connection.
if ($SRMServer) {
    Write-Host "`nDisconnecting from SRM server $SRMServer ..."
    Disconnect-SrmServer * -Confirm:$False
}
