

$in = Get-Content $PSScriptRoot\input.txt -Raw


$pattern = "(?<cap>(?:mul\(\d+,\d+\))|(?:do\(\))|(?:don't\(\)))+?"
# Matches = Global search - return all results
$rx = [regex]::Matches($in, $pattern)


$multiplications = [System.Collections.ArrayList]::new()
$on = $true
$rx | ForEach-Object {
    if ($_.Value -eq "don't()") {
        $on = $false
    }
    elseif ($_.Value -eq "do()") {
        $on = $true
    }
    else {
        [int]$x = $_.Value.Substring(4, $_.Value.Length - 5).Split(",")[0]
        [int]$y = $_.Value.Substring(4, $_.Value.Length - 5).Split(",")[1]
        if ($on) {
            $multiplications += [pscustomobject]@{
                x   = $x
                y   = $y
                mul = $x * $y
            }
        }
    }
}
$multiplications | Measure-Object -Sum mul