
Start-Transcript -path $env:windir\Temp\Betatesting.log -force
#################################################################################################################################
#                               Add PowerCli Snapins
#################################################################################################################################
Add-PSSnapin VMware.VimAutomation.Core
Add-PSSnapin VMware.VimAutomation.Vds
#################################################################################################################################
#                               Connect to the ESX hosts
#################################################################################################################################
Connect-VIServer  –User 'root' –Password '' -Force -WarningAction SilentlyContinue
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
           if($OSFolders[$i] -eq $Revert.ResourcePool)
             {
               Write-Host("`nFound match " + $OSFolders[$i])
               $VM = Get-VM -Name $Revert.Name
               $VMName=$Revert.Name + ".ca.com"
               $password = convertto-securestring -String '<password>'-AsPlainText -Force
               $mycred = new-object -typename System.Management.Automation.PSCredential('Administrator', $password)
               $Dest1 = '\\' + $VMName + '\c$\windows\Temp'
               <#If((Test-Path T:))
                  {
                   Write-Host("Checking for Drive T: , Drive T Already exists so disconnecting the Drive`n")
                   Remove-PSDrive -Name T -Force
                  }#>
                   
                   Write-Host("Mapping the VM Drive " + $Dest1)
                   New-PSDrive -Name $(for($j=67;gdr($d=[char]$j++)2>0){}$d) -PSProvider FileSystem -Root $Dest1 -Credential $mycred -Persist
                   #New-psdrive -Name T -PsProvider FileSystem -root $Dest1 -Credential $mycred -persist                        
                   $FileSource = '\\lodivsa1nas1\CA_Rollups\SUVP_BetaTesting\BETA-TESTING\' + $OSFolders[$i] + '\' + '*'
                   Write-Host("`nFile source is " + $FileSource)

                      ###############################################################################################################################################################################
                      #
                      # Comparing the Resource pool Name in the CSV against the Foldername in the BETATESTING SHARE to ensure folder copying operations are performed on the applicable Machine only
                      #
                      ############################################################################################################################################################################### 
                                                                           
                      If($Revert.ResourcePool.Contains('Office'))
                        { 
                         $Dest = 'Directory_' + $Revert.ResourcePool
                        }
                      else
                      {
                      If($Revert.ResourcePool.Contains('x64'))
                        {
                         $Dest = 'Directory_' + $Revert.ResourcePool.Replace('x64','_x64')
                        }
                      else
                        {
                         $Dest = 'Directory_' + $Revert.ResourcePool + '_x86'
                        }
             }
                  
                    $CreateFolder = 'T:\' + $Dest
                    New-Item -ItemType directory -Path $CreateFolder -Force
                    Write-host("Folder to be created is " + $CreateFolder)                    
                    Copy-Item $FileSource $CreateFolder -recurse -Force
                   $Patch = Get-childitem -path $CreateFolder -include "*.msu","*.exe" -recurse -name
                   for($j=0;$j -lt $Patch.Length; $j++)
                    {
                      #$Execute = "c:\windows\temp\" + $Dest + "\" + $Patch[$j] + " /quiet /norestart"
                      $Execute = "c:\windows\temp\" + $Dest + "\" + $Patch[$j]
                      $a,$b,$c,$d,$BinaryName,$e,$f=$Execute.Split('\',7)
                      $Executing,$x,$y=$BinaryName.split('/',3)
                      $z,$KB,$bit,$ver=$Executing.split('-',4)
                      #write-host("`n$KB")
                      Invoke-vmscript -VM $VM -ScriptText "net start RemoteRegistry" -ScriptType Bat -HostUser 'root' -HostPassword 'interOP@123' -GuestUser 'administrator' -GuestPassword 'itrmbl4u@' -WarningAction SilentlyContinue
                      Invoke-vmscript -VM $VM -ScriptText "net start RpcLocator" -ScriptType Bat -HostUser 'root' -HostPassword 'interOP@123' -GuestUser 'administrator' -GuestPassword 'itrmbl4u@' -WarningAction SilentlyContinue

                        if($Executing -like "*Windows*.msu")
                          {
                             Invoke-vmscript -VM $VM -ScriptText "wusa.exe $Execute /quiet /norestart" -ScriptType Bat -HostUser 'root' -HostPassword 'interOP@123' -GuestUser 'administrator' -GuestPassword 'itrmbl4u@' -WarningAction SilentlyContinue
                             
                                
                                 ##########################################################################################################################################################################################################
                                 #  
                                 #                   CONNECTING TO THE REMOTE REGISTRY AND TRAVERSING THROUGH (HKLM) OF THE VIRTUAL MACHINE
                                 #
                                 ##########################################################################################################################################################################################################
                               
                                 $User = 'Administrator'
                                 $Password = 'itrmbl4u@'
                                 $MyCredentials = New-Object System.Management.Automation.PSCredential -ArgumentList $User, $($Password | ConvertTo-SecureString -AsPlainText -Force)
                                 $reg = Get-WmiObject -List -Namespace root\default -ComputerName $VMName -Credential $MyCredentials | Where-Object {$_.Name -eq "StdRegProv"}
                                 $HKLM = 2147483650
                                ##########################################################################################################################################################################################################
                                # 
                                #                    EXTRACTING THE MSU FILES TO GET THE XML FILE
                                #
                                ##########################################################################################################################################################################################################

                                  & expand -F:*.xml $CreateFolder\$Executing $CreateFolder\
                                  $BinaryNameArray = Get-ChildItem -Name $CreateFolder\*.xml
                                  $Flag = 0
                                  foreach($element in $BinaryNameArray)
                                   {
                                    [XML]$xmlfile = Get-Content $CreateFolder\$element
                                    $XmlValue=$xmlfile.unattend.servicing.package.assemblyIdentity.name + "~" +  $xmlfile.unattend.servicing.package.assemblyIdentity.publicKeyToken + "~" +  $xmlfile.unattend.servicing.package.assemblyIdentity.processorArchitecture + "~~" + $xmlfile.unattend.servicing.package.assemblyIdentity.version
                                    $CurrentState=$reg.GetDwordValue($HKLM,"SOFTWARE\\Microsoft\Windows\\CurrentVersion\\Component Based Servicing\\Packages\\$XmlValue","CurrentState").UValue
                                    $xmlkb=$xmlfile.unattend.servicing.package.source.location          
                                    IF(!([string]::IsNullOrEmpty($CurrentState)))
                                      { 
                                        If($xmlkb.contains($KB))
                                         {
                                          Write-Host("`nMachine: " + $VMName + "`nPatch Installed: " + "$Executing" + "`nPatch Validation: " + $XmlValue + "  CurrentState: " + $CurrentState)
                                          "`nMachine: $VMName","`n=============================","`nPatch Installed: $Executing","`n=====================================================", "`nPatch Validation: $XmlValue","`nCurrentState: $CurrentState", "`n`n" | out-file -FilePath C:\Temp\WinOSPV.txt -Append
                                         }
                                      }   
                                                
                                   } 
                        }
                        
                                   
                        elseIf($Executing -like "*fullfile*glb.exe")
                          {
                             write-host("========================================================================================================================================================`n")
                             write-host("`n`nPatch to be Executed: " + $Executing)
                             
                              $Returncode=Invoke-vmscript -VM $VM -ScriptText "$Execute /quiet /norestart" -ScriptType Bat -HostUser 'root' -HostPassword 'interOP@123' -GuestUser 'administrator' -GuestPassword 'itrmbl4u@' -WarningAction SilentlyContinue -ErrorAction SilentlyContinue                                      
                              
                              If((Test-Path T:\Extract))
                               {
                                 Remove-Item T:\Extract\* -Force -Recurse
                               }
                              else
                               {
                                 New-Item -Name Extract -ItemType directory  -Path 'T:\' -Force                          
                               }
                             If($Returncode.ExitCode -eq "0" -or $Returncode.ExitCode -eq "17025")
                               {
                                   Invoke-vmscript -VM $VM -ScriptText "$Execute /quiet /norestart /extract:C:\Windows\Temp\Extract" -ScriptType Bat -HostUser 'root' -HostPassword 'interOP@123' -GuestUser 'administrator' -GuestPassword 'itrmbl4u@' -WarningAction SilentlyContinue                                   
                                   $Package=Invoke-vmscript -VM $VM -ScriptText "DIR C:\Windows\Temp\Extract\*.msp" -ScriptType Bat -HostUser 'root' -HostPassword 'interOP@123' -GuestUser 'administrator' -GuestPassword 'itrmbl4u@' -WarningAction SilentlyContinue
                                   $Package  | out-file C:\Windows\Temp\MSPFILE.txt
                                   $MSPFILE=Get-Content C:\Windows\Temp\MSPFILE.txt                     
                     
                                   #Write-host($MSPFILE.count)
                                   [string]$PackageName = $null
                                   $New = $null
                                   foreach($line in $MSPFILE)
                                    {
                                      if($line.contains('msp'))
                                       {
                                         #Read from the last element of the array 
                                         for($k=$line.Length;$k -gt 0 ;$k--) 
                                          {
                                           if($line[$k] -ne " ")          
                                            {
                                              #Write-Host($line[$k])
                                              $New += $line[$k]
                                            }
                                           else
                                            {
                                             break
                                            }
                                          } 
                                        #Write-Host($New)
                                        for($m=$New.Length;$m -gt -1;$m--)
                                         {
                                          #Write-host($New[$m])     
                                          $PackageName = $PackageName + $New[$m]
                                         }
                                       }
                                    }                   
                                      #Write-Host($PackageName)
                                      $ValidationOffice=Invoke-vmscript -VM $VM -ScriptText "reg query HKLM\SOFTWARE\Classes\Installer\Patches /F $PackageName /s" -ScriptType Bat -HostUser 'root' -HostPassword 'interOP@123' -GuestUser 'administrator' -GuestPassword 'itrmbl4u@' -WarningAction SilentlyContinue
                                      $ValidationOffice | out-file C:\Windows\Temp\Office.txt
                                      $OfficePV=Get-Content C:\Windows\Temp\office.txt

                                     foreach($OfficePatchValidation in $OfficePV)
                                      {
                                       if($OfficePatchValidation.contains('HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Installer\Patches') -and  $OfficePatchValidation.EndsWith('SourceList'))
                                         {
                                          Write-Host("`nMachine: " + $VMName + "`nPatch Installed: " + "$Executing" + "`nPatch Validation: " + $OfficePatchValidation + "`n`n")
                                          "`nMachine: $VMName","`n===========================","`nPatch Installed: $Executing","`n=========================================================","`nPatch Validation: $OfficePatchValidation" , "`n`n" | Out-File -FilePath C:\Temp\OfficePV.txt -Append
                                         }
                                      }
                             }
                             else
                               { 
                                    Write-Host("Patch not applicable to this version of Office,extraction not Required.")                                
                               }

                             
                          }
                        elseIf($Executing -like "NDP*.exe")
                          {
                             Invoke-vmscript -VM $VM -ScriptText "$Execute /q /norestart" -ScriptType Bat -HostUser 'root' -HostPassword 'interOP@123' -GuestUser 'administrator' -GuestPassword 'itrmbl4u@' -WarningAction SilentlyContinue
                             $ValidationNDP=Invoke-vmscript -VM $VM -ScriptText "reg query HKLM\SOFTWARE\Microsoft\Updates /F $KB /s" -ScriptType Bat -HostUser 'root' -HostPassword 'interOP@123' -GuestUser 'administrator' -GuestPassword 'itrmbl4u@' -WarningAction SilentlyContinue
                             $ValidationNDP  | out-file C:\Windows\Temp\NETPV.txt
                             $NETPV=Get-Content C:\Windows\Temp\NETPV.txt

                             foreach($NDPPatchValidation in $NETPV)
                              {
                                if($NDPPatchValidation.Contains('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Updates') -and $NDPPatchValidation.EndsWith($KB)) 
                                  {
                                    Write-Host("`nMachine: " + $VMName + "`nPatch being Installed: " + "$Executing" + "`nPatch Validation: " + $NDPPatchValidation + "`n`n")
                                    "`nMachine: $VMName","`n==========================","`nPatch Installed: $Executing","`n=====================================","`nPatch Validation: $NDPPatchValidation" ,"`n`n" | Out-File -FilePath C:\Temp\NDPPV.txt -Append                        
                                  }
                              }
                          }

                        else
                          {
                             Write-Host("Unknown Patch")
                          }
             }

           }
           
         }
         
       }
 }
 
$Disconnect=Remove-PSDrive -Name T -Force
Write-host("`nDrive T has been disconnected")


#Disconnect from ESX Hosts

Disconnect-VIServer lodivsesx002.ca.com -Confirm:$false -Force 
Disconnect-VIServer lodivs104.ca.com -Confirm:$false -Force

Stop-Transcript
