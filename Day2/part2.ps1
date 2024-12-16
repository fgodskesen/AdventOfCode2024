

$in = Get-Content $PSScriptRoot\input.txt


function Get-IsSafe ($parts) {
    if ($parts.Count -lt 2) {
        return $false
    }

    if ($parts[0] -eq $parts[1]) {
        return $false
    }

    $direction = ($parts[1] -gt $parts[0]) ? 1 : -1

    for ($x = 1; $x -lt $parts.Count; $x++) {
        $previous = $parts[$x - 1]
        $current = $parts[$x]

        $diff = ($current - $previous) * $direction
        if ($diff -gt 3 -or $diff -lt 1) {
            return $false
        }
    }
    return $true
}

$safeReports = 0
:reports foreach ($line in $in) {
    $parts = @()
    $parts += $line.Split(" ") | ForEach-Object { [int]$_ }

    if (Get-IsSafe $parts) {
        $safeReports++
        continue reports
    }

    # test until we find a safe report or run out of options
    $variations = @()
    $variations += $parts

    for ($x = 0; $x -lt $parts.Count; $x++) {
        $variation = @()
        for ($y = 0; $y -lt $parts.Count; $y++) {
            if ($y -ne $x) {
                $variation += $parts[$y]
            }
        }
        if (Get-IsSafe $variation) {
            $safeReports++
            continue reports
        }
    }
}

$safeReports