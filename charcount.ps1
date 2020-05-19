$file = Get-content C:\temp\CreateSnapshot.log
$file.count
$linesjoin = $file -join "'r"
$linesjoinUC = $linesjoin.ToUpper()
$linesjoinUC.GetEnumerator() | group -NoElement | sort count -Descending