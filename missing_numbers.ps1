$missing = Get-Content C:\temp\number.txt 
$missing |%{$i=1}{while($i -lt $_){$i;$i++};$i++}