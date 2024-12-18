

$in = Get-Content $PSScriptRoot\input.txt


$rules = @{}
$updates = [System.Collections.ArrayList]::new()

$inFirstHalf = $true
foreach ($l in $in) {
    if ($inFirstHalf) {
        if ($l -eq "") {
            $inFirstHalf = $false
        }
        else {
            $lhs = [int]$l.Split('|')[0]
            $rhs = [int]$l.Split('|')[1]
            if (-not $rules.ContainsKey($lhs)) {
                $rules[$lhs] = @()
            }
            $rules[$lhs] += $rhs
        }
    }
    else {
        $updates += , ($l.Split(",") | ForEach-Object { [int]$_ })
    }
}

$middlePageNumSum = 0


$output = [System.Collections.ArrayList]::new()
:eachupdate foreach ($update in $updates) {
    $isValid = $true
    # Start at 2nd char and move right.
    # Validate that all rules matching thisNum against all numbers to the left of thisNum are not in the rules
    for ($x = 1; $x -le $update.Count - 1; $x++) {
        $thisNum = $update[$x]
        for ($y = 0; $y -le $x - 1; $y++) {
            $thatNum = $update[$y]
            if ($rules[$thisNum] -contains $thatNum) {
                $isValid = $false
            }
        }
    }
    $output += [pscustomobject]@{
        Update  = $update -join ","
        Array   = $update
        IsValid = $isValid
    }
}

$medianSum = 0
$output | Where-Object { $_.IsValid } | ForEach-Object {
    $median = $_.Array[(($_.Array.Count - 1) / 2)]
    $medianSum += $median
}

$medianSum