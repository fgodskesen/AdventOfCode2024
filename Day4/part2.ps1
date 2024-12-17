

$in = Get-Content $PSScriptRoot\input.txt

$inCols = $in[0].Length
$inRows = $in.Count

$rows = $inRows + 8
$cols = $inCols + 8


# grid is an array of strings
# but we add a border of 4 .'s around the lines from input
# this simplifies array access as we will never be out of bounds
$grid = [System.Collections.ArrayList]::new()
(1..4) | ForEach-Object { $grid += "." * $cols }
foreach ($l in $in) {
    $grid += "...." + $l + "...."
}
(1..4) | ForEach-Object { $grid += "." * $cols }


$xmasCount = 0

# now loop through the grid, from row 4 to (rows - 4)
# if its an A, check diagonals for MAS
for ($r = 4; $r -lt $rows - 4; $r++) {
    for ($c = 4; $c -lt $cols - 4; $c++) {
        if ($grid[$r][$c] -eq 'A') {
            $slices = @()
            $slices += ($grid[$r - 1][$c - 1], $grid[$r][$c], $grid[$r + 1][$c + 1]) -join ""
            $slices += ($grid[$r - 1][$c + 1], $grid[$r][$c], $grid[$r + 1][$c - 1]) -join ""
            if (
                ($slices[0] -eq "MAS" -or $slices[0] -eq "SAM") -and
                ($slices[1] -eq "MAS" -or $slices[1] -eq "SAM")
            ) {
                $xmasCount++
            }
        }
    }
}

$xmasCount