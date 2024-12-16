

$in = Get-Content $PSScriptRoot\input.txt



$reports = [System.Collections.ArrayList]::new()
foreach ($line in $in) {
    $parts = @()
    $parts += $line.Split(" ") | ForEach-Object { [int]$_ }

    $direction = 0
    $isSafe = $true
    for ($x = 1; $x -lt $parts.Count; $x++) {
        $previous = $parts[$x - 1]
        $current = $parts[$x]

        if (-not $direction) {
            if ($current -gt $previous) {
                $direction = 1
            }
            elseif ($current -lt $previous) {
                $direction = -1
            }
            else {
                $isSafe = $false
                break
            }
        }

        $diff = ($current - $previous) * $direction
        if ($diff -gt 3 -or $diff -lt 1) {
            $isSafe = $false
        }
    }

    $reports += [pscustomobject]@{
        Line      = $line
        Parts     = $parts
        Direction = $direction
        IsSafe    = $isSafe
    }
}
($reports | Where-Object { $_.IsSafe }).Count