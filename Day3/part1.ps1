

$in = Get-Content $PSScriptRoot\input.txt -Raw


$pattern = "(?<cap>mul\(\d+,\d+\))+?"
# Matches = Global search - return all results
$rx = [regex]::Matches($in, $pattern)


$multiplications = [System.Collections.ArrayList]::new()
$rx | ForEach-Object {
    [int]$x = $_.Value.Substring(4, $_.Value.Length - 5).Split(",")[0]
    [int]$y = $_.Value.Substring(4, $_.Value.Length - 5).Split(",")[1]

    $multiplications += [pscustomobject]@{
        x   = $x
        y   = $y
        mul = $x * $y
    }
}
$multiplications | Measure-Object -Sum mul