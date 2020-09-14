2
43
#
# PowerCLI to create VMs from existing vSphere VM
# Version 1.0
# Magnus Andersson RTS
#
# Specify vCenter Server, vCenter Server username and vCenter Server user password
$vCenter=""
$vCenterUser=""
$vCenterUserPassword=""
#
# Specify number of VMs you want to create
$vm_count = "3"
#
# Specify the VM you want to clone
$clone = "Template_CentOS_7.0_x64-Systems"
#
# Specify the Customization Specification to use
$customspecification="VCDX56-customization"
#
# Specify the datastore or datastore cluster placement
$ds = "lvnlntxfb1d.lvn.broadcom.net"
#
# Specify vCenter Server Virtual Machine & Templates folder
$Folder = "UIM"
#
# Specify the vSphere Cluster
$Cluster = "LVNLVCLF"
#
# Specify the VM name to the left of the - sign
$VM_prefix = "sc645393-"
#
# End of user input parameters
#_______________________________________________________
#
write-host "Connecting to vCenter Server $vCenter" -foreground green
Connect-viserver $vCenter -user $vCenterUser -password $vCenterUserPassword -WarningAction 0
1..$vm_count | foreach {
$y="{0:D1}" -f + $_
$VM_name= $VM_prefix + $y
$ESXi=Get-Cluster $Cluster | Get-VMHost -state connected | Get-Random
write-host "Creation of VM $VM_name initiated" -foreground green
New-VM -Name $VM_Name -VM $clone -VMHost $ESXi -Datastore $ds -Location $Folder -OSCustomizationSpec $customspecification -RunAsync
}
