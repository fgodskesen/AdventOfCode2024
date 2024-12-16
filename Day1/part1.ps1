

$in = Get-Content $PSScriptRoot\input.txt



$left = [System.Collections.ArrayList]::new()
$right = [System.Collections.ArrayList]::new()

foreach ($n in $in) {
    $split = $n.Split(" ") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
    $left += [int]$split[0]
    $right += [int]$split[1]
}

$lsort = $left | Sort-Object
$rsort = $right | Sort-Object

$outTotal = 0

for ($x = 0; $x -lt $in.Count; $x++) {
    $outTotal += [math]::Abs($lsort[$x] - $rsort[$x])
}

Write-Host "Total : $outTotal"