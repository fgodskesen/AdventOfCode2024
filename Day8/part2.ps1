$ErrorActionPreference = "Stop"

Get-ChildItem $PSScriptRoot\..\Modules | ForEach-Object {
    Write-Host "Import module : $($_.Name)"
    Import-Module $_.FullName
}

<#
    Loads all ps1xml files for style/formatting of pscustomobjects
#>
Get-ChildItem "$PSScriptRoot\*.ps1xml" -Recurse | ForEach-Object {
    Update-FormatData $_.FullName
}


$in = Get-Content $PSScriptRoot\input.txt


class Grid {
    [Cell[, ]]$Cells

    [int]$TotalRows = 0
    [int]$TotalColumns = 0

    $FrequencyLookup = @{}


    [Cell] GetCell ([int]$r, [int]$c) {
        $ix = @($r, $c)
        return $this.Cells[$ix]
    }

    AddCell ([Cell]$Cell) {
        $ix = @($Cell.Row, $Cell.Col)
        $this.Cells[$ix] = $Cell

        if ($Cell.Frequency) {
            if (-not $this.FrequencyLookup.ContainsKey($Cell.Frequency)) {
                $this.FrequencyLookup[$Cell.Frequency] = @()
            }
            $this.FrequencyLookup[$Cell.Frequency] += $Cell
        }
    }

    Grid ($_TotalRows, $_TotalColumns) {
        $this.Cells = [Cell[, ]]::new($_TotalRows, $_TotalColumns)
        $this.TotalColumns = $_TotalColumns
        $this.TotalRows = $_TotalRows
    }


    GetAntinodes ([Cell]$firstCell, [Cell]$secondCell) {
        $out = @()

        # start at $firstCell. Apply vector in the negative direction
        $rowVector = $firstCell.Row - $secondCell.Row
        $colVector = $firstCell.Col - $secondCell.Col

        $currentRow = $firstCell.Row
        $currentCol = $firstCell.Col
        # Apply vector positively until out of bounds
        while (
            $currentRow -ge 0 -and $currentRow -lt $this.TotalRows -and
            $currentCol -ge 0 -and $currentCol -lt $this.TotalColumns
        ) {
            Write-Host "Antinode found at ($currentRow,$currentCol)"
            $this.GetCell($currentRow, $currentCol).Antinodes += $firstCell.Frequency
            $currentRow += $rowVector
            $currentCol += $colVector
        }

        # Apply vector negatively until out of bounds
        # Start at secondCell
        $currentRow = $secondCell.Row
        $currentCol = $secondCell.Col
        while (
            $currentRow -ge 0 -and $currentRow -lt $this.TotalRows -and
            $currentCol -ge 0 -and $currentCol -lt $this.TotalColumns
        ) {
            Write-Host "Antinode found at ($currentRow,$currentCol)"
            $this.GetCell($currentRow, $currentCol).Antinodes += $firstCell.Frequency
            $currentRow -= $rowVector
            $currentCol -= $colVector
        }
    }


    Print () {
        # if height/width is odd number, topleft if pos - ((x-1)/2)
        # else its pos - (x/2)
        # this puts guard either in center or off by one to the right

        $lines = [System.Collections.ArrayList]::new()
        for ($r = 0; $r -lt $this.TotalRows; $r++) {
            $sb = [System.Text.StringBuilder]::new()
            for ($c = 0; $c -lt $this.TotalColumns; $c++) {
                $thisCell = $this.GetCell($r, $c)
                $sb.Append(($thisCell.GetSymbol()))
            }
            $lines += $sb.ToString()
        }
        Clear-Host
        $lines | ForEach-Object { Write-Host $_ }
    }
}

class Cell {
    [int]$Row
    [int]$Col

    [char]$Frequency
    [char[]]$Antinodes

    [int[]] GetIndex() {
        return $($this.Row, $this.Col)
    }

    Cell ($r, $c, $f) {
        $this.Row = $r
        $this.Col = $c
        $this.Frequency = $f
    }

    Cell ($r, $c) {
        $this.Row = $r
        $this.Col = $c
    }

    [object] GetSymbol() {
        if ($this.Frequency) {
            if ($this.Antinodes) {
                return (Text $this.Frequency -ForegroundColor Red)
            }
            else {
                return (Text $this.Frequency -ForegroundColor Green)
            }
        }
        elseif ($this.Antinodes) {
            return (Text '#' -ForegroundColor Yellow)
        }
        else {
            return '.'
        }
    }
}


# Load data into grid
$myGrid = [Grid]::new($in.Count, $in[0].Length)
for ($r = 0; $r -lt $in.Count; $r++) {
    $line = $in[$r]
    for ($c = 0; $c -lt $line.Length; $c++) {
        if ($line[$c] -eq ".") {
            $myGrid.AddCell([Cell]::new($r, $c))
        }
        else {
            $myGrid.AddCell([Cell]::new($r, $c, $line[$c]))
        }
    }
}

$mygrid.Print()
Pause

# lets find antinodes
foreach ($frequency in $myGrid.FrequencyLookup.Keys) {
    $nodesToLoop = $myGrid.FrequencyLookup[$frequency]
    Write-Host "Frequency: $frequency; Nodes : $(($nodesToLoop | ForEach-Object {"($($_.Row),$($_.Col))"}) -join ";")" -ForegroundColor Red
    if ($nodesToLoop.Count -eq 1) {
        Write-Host "Only one antenna with frequency '$frequency'" -ForegroundColor Red
    }
    else {
        for ($x = 0; $x -lt $nodesToLoop.Count - 1 ; $x++) {
            $cell1 = $nodesToLoop[$x]
            for ($y = $x + 1; $y -lt $nodesToLoop.Count  ; $y++) {
                Write-Host "Find antinodes between cells ($($cell1.Row),$($cell1.Col)) and ($($cell2.Row),$($Cell2.Col))" -ForegroundColor Yellow
                $cell2 = $nodesToLoop[$y]
                $myGrid.GetAntinodes($cell1, $cell2)
            }
        }
    }
}


#

$mygrid.Print()
($myGrid.Cells | Where-Object { $_.Antinodes.Count }).Count