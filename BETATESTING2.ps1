Start-Transcript -path $env:windir\Temp\logging1.log -force
# Add PowerCli Snapins
Add-PSSnapin VMware.VimAutomation.Core
Add-PSSnapin VMware.VimAutomation.Vds

#Connect to the ESX hosts
Connect-VIServer lodivsesx002.ca.com –User 'root' –Password 'interOP@123' -Force -WarningAction SilentlyContinue
Connect-VIServer lodivs104.ca.com –User 'root' –Password 'interOP@123' -Force -WarningAction SilentlyContinue

$source = "\\lodivsa1nas1\CA_Rollups\SUVP_BetaTesting\BETA-TESTING"
$OSFolders = Get-ChildItem $source -Name

$csvData = import-Csv “c:\temp\VMInventory.csv"
ForEach ($Revert in $csvData)
 {
    If($Revert.Revert.Contains('Yes'))
        {

        for($i=0;$i -lt $OSFolders.Length;$i++)
          {
               #Write-host($OSFolders[$i])

             #Write-Host($Revert.ResourcePool + " is being compared to " + $OSFolders[$i])


            if($OSFolders[$i] -eq $Revert.ResourcePool)
                {
                   Write-Host("`nFound match " + $OSFolders[$i])
                   $VM = Get-VM -Name $Revert.Name
                   $VMName=$Revert.Name + ".ca.com"
                   $password = convertto-securestring -String 'itrmbl4u@'-AsPlainText -Force
                   $mycred = new-object -typename System.Management.Automation.PSCredential('Administrator', $password)
                   $Dest1 = '\\' + $VMName + '\c$\windows\Temp'
                If ((Test-Path T:))
                    {
                        Write-Host("Checking for Drive T: , Drive T Already exists so disconnecting the Drive`n")
                        Remove-PSDrive -Name T -Force
                        
                    }

                        Write-Host("Mapping the VM Drive " + $Dest1)
                        New-psdrive -Name T -PsProvider FileSystem -root $Dest1 -Credential $mycred -persist                        
                
                    $FileSource = '\\lodivsa1nas1\CA_Rollups\SUVP_BetaTesting\BETA-TESTING\' + $OSFolders[$i] + '\' + '*'
                     Write-Host("`nFile source is " + $FileSource)
                
                # Comparing the Resource pool Name in the CSV against the Foldername in the BETATESTING SHARE to ensure folder copying operations are performed on the applicable Machine only
                                                      
                    If($Revert.ResourcePool.Contains('Office'))
                        { 
                            $Dest = 'OS_' + $Revert.ResourcePool
                    
                        }
                    else
                       {
                        If($Revert.ResourcePool.Contains('x64'))
                          {
                                 $Dest = 'OS_' + $Revert.ResourcePool.Replace('x64','_x64')
                                              
                          }
                        else
                         {
                            $Dest = 'OS_' + $Revert.ResourcePool + '_x86'
                         }
                      }
                  
                $CreateFolder = 'T:\' + $Dest
                New-Item -ItemType directory -Path $CreateFolder -Force
                Write-host("Folder to be created is " + $CreateFolder)
                Copy-Item $FileSource $CreateFolder -recurse -Force

                $Patch = Get-childitem -path $CreateFolder -Filter *.msu -recurse -name
                for($j=0;$j -lt $Patch.length; $j++)
                {
                  $Execute = "c:\windows\temp\" + $Dest + "\" + $Patch[$j] + " /quiet /norestart"
                  Write-Host("`nPatch to be executed " + $Execute)
                  #$a,$b,$c,$d,$PatchSplit=$Execute.split("\",5)
                  #Write-Host("`n$PatchSplit")                  
                  #Write-Host "$wusa"
                  Invoke-vmscript  -VM $VM -ScriptText "wusa.exe $Execute" -ScriptType Bat -HostUser 'root' -HostPassword 'interOP@123' -GuestUser 'administrator' -GuestPassword 'itrmbl4u@' -WarningAction SilentlyContinue
                  
                  # EXTRACTING THE MSU FILES TO GET THE XML FILE

                  & expand -F:*.xml $CreateFolder\*.msu $CreateFolder\

                  # CONNECTING TO THE REMOTE REGISTRY AND TRAVERSING THROUGH (HKLM) OF THE VIRTUAL MACHINE

                  $User = 'Administrator'
                  $Password = 'itrmbl4u@'
                  $MyCredentials = New-Object System.Management.Automation.PSCredential -ArgumentList $User, $($Password | ConvertTo-SecureString -AsPlainText -Force)
                  $reg = Get-WmiObject -List -Namespace root\default -ComputerName $VMName -Credential $MyCredentials | Where-Object {$_.Name -eq "StdRegProv"}
                  $HKLM = 2147483650
                  
                  $BinaryNameArray = Get-ChildItem -Name $CreateFolder\*.xml
                  $Flag = 0
                  foreach($element in $BinaryNameArray)
                    {
                      [XML]$xmlfile = Get-Content $CreateFolder\$element
                      $XmlValue=$xmlfile.unattend.servicing.package.assemblyIdentity.name + "~" +  $xmlfile.unattend.servicing.package.assemblyIdentity.publicKeyToken + "~" +  $xmlfile.unattend.servicing.package.assemblyIdentity.processorArchitecture + "~~" + $xmlfile.unattend.servicing.package.assemblyIdentity.version
                      $CurrentState=$reg.GetDwordValue($HKLM,"SOFTWARE\\Microsoft\Windows\\CurrentVersion\\Component Based Servicing\\Packages\\$XmlValue","CurrentState").UValue                      
                      #Write-Host("Current State value for: " + $XmlValue + " on Machine " + $VMName + " is " + $CurrentState)
                      Write-Host("Machine: " + $VMName + " PV: " + $XmlValue + " CurrentState: " + $CurrentState)

                      Add-Content C:\Temp\PV.txt $VMName, $XmlValue
                      #Out-file -filepath C:\Temp\PV.txt -inputobject $XmlValue -Append                  
                    }
                  
               } 
                         
             }

           }
           
         }
         
       }
Get-Content C:\Temp\PV.txt | sort-object -unique | Out-File c:\temp\PVFinal.txt
Remove-Item C:\Temp\PV.txt -Force
#Disconnect from ESX Hosts
Disconnect-VIServer lodivsesx002.ca.com -Confirm:$false -Force 
Disconnect-VIServer lodivs104.ca.com -Confirm:$false -Force
Stop-Transcript 