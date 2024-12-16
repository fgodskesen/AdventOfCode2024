

$in = Get-Content $PSScriptRoot\input.txt



$left = [System.Collections.ArrayList]::new()
$right = @{}

foreach ($n in $in) {
    [int]$l = $n.SubString(0, $n.IndexOf(" "))
    [int]$r = $n.SubString($n.IndexOf(" "))

    $left += $l
    if ($right.ContainsKey($r)) {
        $right[$r]++
    }
    else {
        $right[$r] = 1
    }
}


$similarityScore = 0
# if key does not exist in right, there are 0 occurrences which does not contribute to score
# hence we only have to process right.Keys
foreach ($key in $left) {
    $similarityScore += $key * ($right[$key] ?? 0)
}

Write-Host "Similarity score : $similarityScore"