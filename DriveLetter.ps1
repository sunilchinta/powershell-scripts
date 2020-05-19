$password = convertto-securestring -String 'Windows7ent'-AsPlainText -Force
$mycred = new-object -typename System.Management.Automation.PSCredential('tant-a01\chisu11', $password)
New-PSDrive -Name $(for($j=67;gdr($d=[char]$j++)2>0){}$d) -PSProvider FileSystem -Root \\lodivsa1nas1\CA_Rollups -Credential $mycred -Persist