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


    [Cell[]] GetAntinodes ([Cell]$firstCell, [Cell]$secondCell) {
        if ($firstCell -eq $secondCell) {
            throw "Cannot get antinodes with myself"
            return $null
        }

        $out = @()
        $an1Row = $firstCell.Row * 2 - $secondCell.Row
        $an1Col = $firstCell.Col * 2 - $secondCell.Col
        if (
            $an1Row -ge 0 -and
            $an1Row -lt $this.TotalRows -and
            $an1Col -ge 0 -and
            $an1Col -lt $this.TotalColumns
        ) {
            Write-Host "Found antinode 1 at ($an1Row,$an1Col)" -ForegroundColor Green
            $out += $this.GetCell($an1Row, $an1Col)
        }
        else {
            Write-Host "Antinode 1 is outside the grid ($an1Row,$an1Col)" -ForegroundColor Red
        }

        $an2Row = $secondCell.Row * 2 - $firstCell.Row
        $an2Col = $secondCell.Col * 2 - $firstCell.Col
        if (
            $an2Row -ge 0 -and
            $an2Row -lt $this.TotalRows -and
            $an2Col -ge 0 -and
            $an2Col -lt $this.TotalColumns
        ) {
            Write-Host "Found antinode 2 at ($an2Row,$an2Col)" -ForegroundColor Green
            $out += $this.GetCell($an2Row, $an2Col)
        }
        else {
            Write-Host "Antinode 2 is outside the grid ($an2Row,$an2Col)" -ForegroundColor Red
        }
        return $out
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
                $myGrid.GetAntinodes($cell1, $cell2) | ForEach-Object {
                    $_.Antinodes += $frequency
                }
            }
        }
    }
}

#($myGrid.Cells | Where-Object { $_.Antinodes.Count }).Count
#$mygrid.Print()