
$in = Get-Content $PSScriptRoot\input.txt
Import-Module $PSScriptRoot\..\Modules\Pansies


class Grid {
    [hashtable]$Cells = @{}

    [int]$TotalRows = 0
    [int]$TotalColumns = 0


    [Cell] GetCell ([int]$r, [int]$c) {
        $id = "$r#$c"
        return $this.Cells[$id]
    }

    [Cell[]] GetRowOfCells ($r) {
        $ids = $()
        for ($temp = 0; $temp -lt $this.TotalColumns - 1; $temp++) {

        }
        return $this.Cells[$ids]
    }

    AddCell ([Cell]$Cell) {
        $id = "$($Cell.Row)#$($Cell.Col)"
        $this.Cells[$id] = $Cell
    }

    Grid ($_TotalRows, $_TotalColumns) {
        $this.TotalColumns = $_TotalColumns
        $this.TotalRows = $_TotalRows
    }
}

class Cell {
    [int]$Row
    [int]$Col
    [bool]$Obstacle
    [string]$Id

    Cell ($r, $c, $o) {
        $this.Row = $r
        $this.Col = $c
        $this.Obstacle = $o
        $this.Id = "$r#$c"
    }
}


enum GuardHeading {
    North
    East
    South
    West
}

Class Guard {
    [Cell]$Position
    [Cell]$NextCell
    [GuardHeading]$Heading
    [Grid]$Grid
    [bool]$IsInsideGrid = $true
    [System.Collections.Generic.HashSet[Cell]]$CellsVisited = [System.Collections.Generic.HashSet[Cell]]::new()

    [object] GetSymbol () {
        $index = [int]$this.Heading
        $array = @(
            (Text "&uarr;" -ForegroundColor Red),
            (Text "&rarr;" -ForegroundColor Red),
            (Text "&darr;" -ForegroundColor Red),
            (Text "&larr;" -ForegroundColor Red)
        )
        return $array[$index]
    }

    Print ($height, $width) {
        # if height/width is odd number, topleft if pos - ((x-1)/2)
        # else its pos - (x/2)
        # this puts guard either in center or off by one to the right

        if ($height % 2 -eq 0) {
            $rowFrom = [math]::Max(0, $this.Position.Row - ($height / 2))
        }
        else {
            $rowFrom = [math]::Max(0, $this.Position.Row - (($height - 1) / 2))
        }

        if ($width % 2 -eq 0) {
            $colFrom = [math]::Max(0, $this.Position.Col - ($width / 2))
        }
        else {
            $colFrom = [math]::Max(0, $this.Position.Col - (($width - 1) / 2))
        }

        $lines = [System.Collections.ArrayList]::new()
        for ($r = $rowFrom; $r -le [Math]::Min($this.Grid.TotalRows, $rowFrom + $height); $r++) {
            $sb = [System.Text.StringBuilder]::new()
            for ($c = $colFrom; $c -le [Math]::Min($this.Grid.TotalColumns, $colFrom + $width); $c++) {
                $thisCell = $this.Grid.GetCell($r, $c)
                if ($this.Position -eq $thisCell) {
                    $sb.Append(($this.GetSymbol()))
                }
                elseif ($thisCell -in $this.CellsVisited) {
                    #$sb.Append((Text "&loz;" -ForegroundColor Green))
                    $sb.Append((Text "&bull;" -ForegroundColor Green))
                }
                elseif ($thisCell.Obstacle) {
                    $sb.Append((Text "&lowast;" -ForegroundColor Yellow))
                    #$sb.Append('#')
                }
                else {
                    #$sb.Append((Text "&bull;"))
                    $sb.Append(".")
                }
            }
            $lines += $sb.ToString()
        }
        Clear-Host
        $lines | ForEach-Object { Write-Host $_ }
    }


    Guard ([Cell]$p, [GuardHeading]$h, [Grid]$g) {
        $this.Position = $p
        $this.Heading = $h
        $null = $this.CellsVisited.Add($p)
        $this.Grid = $g
    }

    Turn () {
        $this.Heading = (($this.Heading + 1) % 4)
    }

    TakeStep () {
        switch ([int]$this.Heading) {
            0 { $this.NextCell = $this.Grid.GetCell($this.Position.Row - 1, $this.Position.Col); break }
            1 { $this.NextCell = $this.Grid.GetCell($this.Position.Row, $this.Position.Col + 1); break }
            2 { $this.NextCell = $this.Grid.GetCell($this.Position.Row + 1, $this.Position.Col); break }
            3 { $this.NextCell = $this.Grid.GetCell($this.Position.Row, $this.Position.Col - 1); break }
            default { throw "NotImplemented"; break }
        }

        if ($null -eq $this.NextCell) {
            #oops. left the area.
            $this.IsInsideGrid = $false
            $null = $this.CellsVisited.Add($this.Position)
            $this.Position = $null
        }
        elseif ($this.NextCell.Obstacle) {
            $this.Turn()
        }
        else {
            $this.CellsVisited.Add($this.Position)
            $this.Position = $this.NextCell
            $this.NextCell = $null
        }
    }
}


# Load data into grid
$myGrid = [Grid]::new($in.Count, $in[0].Length)
for ($r = 0; $r -lt $in.Count; $r++) {
    $line = $in[$r]
    for ($c = 0; $c -lt $line.Length; $c++) {
        switch ($line[$c]) {
            "#" {
                $myGrid.AddCell([Cell]::new($r, $c, $true))
                break
            }
            "^" {
                $cell = [Cell]::new($r, $c, $false)
                $myGuard = [Guard]::new($cell, [GuardHeading]::North, $myGrid)
                $myGrid.AddCell($cell)
                break
            }
            ">" {
                $cell = [Cell]::new($r, $c, $false)
                $myGuard = [Guard]::new($cell, [GuardHeading]::East, $myGrid)
                $myGrid.AddCell($cell)
                break
            }
            "v" {
                $cell = [Cell]::new($r, $c, $false)
                $myGuard = [Guard]::new($cell, [GuardHeading]::South, $myGrid)
                $myGrid.AddCell($cell)
                break
            }
            "<" {
                $cell = [Cell]::new($r, $c, $false)
                $myGuard = [Guard]::new($cell, [GuardHeading]::West, $myGrid)
                $myGrid.AddCell($cell)
                break
            }
            "." {
                $cell = [Cell]::new($r, $c, $false)
                $myGrid.AddCell($cell)
                break
            }
            default {
                $cell = [Cell]::new($r, $c, $false)
                $myGrid.AddCell($cell)
                break
            }
        }
    }
}


do {
    $myGuard.TakeStep()
} while ($myGuard.IsInsideGrid)

$myguard.CellsVisited.Count





