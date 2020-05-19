Start-Transcript -path C:\temp\GenerateVMList.log -Force

######################
# Add PowerCli Snapins
######################

  if(-not (Get-PSSnapin VMware.VimAutomation.Core))
       {
           Add-PSSnapin VMware.VimAutomation.Core
       }
        

   if(-not (Get-PSSnapin VMware.VimAutomation.Vds))
       {
           Add-PSSnapin VMware.VimAutomation.Vds
       }
      
######################
# Create c:\temp if it does not exist
######################

$TARGETDIR = 'c:\temp\'
if(-Not(Test-Path -Path $TARGETDIR ))
{
   New-Item -ItemType directory -Path $TARGETDIR
}

######################
#Connect to the ESX hosts
######################

#Connect-VIServer lodivsesx002.ca.com –User 'root' –Password 'interOP@123' -Force -WarningAction SilentlyContinue


 #Connect-VIServer LOD-PRPOOLVC.lod.ca.lab
 #Connect-VIServer vcenterhcl.dev.fco
 Connect-VIServer vcentercho.dev.fco


######################
# Get VmwareTools Status in a seperate file
######################

Get-VM | Get-View | Select-Object @{N=”VM Name”;E={$_.Name}},@{Name=”VMware Tools”;E={$_.Guest.ToolsStatus}} | Export-CSV c:\temp\VMwareToolsStatus.csv

######################
# Get list of VMS and ResourcePool
######################
Get-VM | Select-Object –Property ResourcePool,Name,VMhost | sort ResourcePool | Export-CSV –Path c:\temp\VMs.csv –UseCulture -NoTypeInformation


######################
#Add additional columns Revert,DSMServer, SnapshotName, DSMGroup and Assign default values.
######################
Import-Csv “c:\temp\VMs.csv" | Select-Object *,@{Name='Revert';Expression={'No'}},@{Name='SnapshotName';Expression={'Last'}}, @{Name = "CPU"; Expression = {($_.PercentProcessorTime/$cores)}}, @{Name = "PID"; Expression = {$_.IDProcess}}, @{"Name" = "Memory(MB)"; Expression = {[int]($_.WorkingSetPrivate/1mb)}} |  Export-Csv “c:\temp\VMInventory.csv" -NoTypeInformation -Force

Write-Host("Please start working on the generated c:\temp\VMInventory.csv file")

Remove-Item 'c:\temp\VMs.csv' -Force

#######################
#Disconnect from ESX Hosts
######################
#Disconnect-VIServer lodivsesx002.ca.com -Confirm:$false -Force 
Stop-Transcript



