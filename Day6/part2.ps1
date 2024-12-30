
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
    [GuardHeading]$Heading
    [Grid]$Grid
    [bool]$IsInsideGrid = $true
    [bool]$Stuck = $false
    [System.Collections.Generic.HashSet[Cell]]$CellsVisited = [System.Collections.Generic.HashSet[Cell]]::new()
    [System.Collections.Generic.HashSet[string]]$Path = [System.Collections.Generic.HashSet[string]]::new()
    [Cell]$TemporaryObstacle

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

    [Cell] GetNextCell () {
        switch ([int]$this.Heading) {
            0 { return $this.Grid.GetCell($this.Position.Row - 1, $this.Position.Col); break }
            1 { return $this.Grid.GetCell($this.Position.Row, $this.Position.Col + 1); break }
            2 { return $this.Grid.GetCell($this.Position.Row + 1, $this.Position.Col); break }
            3 { return $this.Grid.GetCell($this.Position.Row, $this.Position.Col - 1); break }
            default { throw "NotImplemented"; break; }
        }
        return $null
    }

    Print ($height, $width) {
        # if height/width is odd number, topleft if pos - ((x-1)/2)
        # else its pos - (x/2)
        # this puts guard either in center or off by one to the right

        if ($height % 2 -eq 0) {
            $rowFrom = [math]::Max(0, $this.Position.Row - ($height / 2) - 1)
        }
        else {
            $rowFrom = [math]::Max(0, $this.Position.Row - (($height - 1) / 2) - 1)
        }

        if ($width % 2 -eq 0) {
            $colFrom = [math]::Max(0, $this.Position.Col - ($width / 2) - 1)
        }
        else {
            $colFrom = [math]::Max(0, $this.Position.Col - (($width - 1) / 2) - 1)
        }

        $lines = [System.Collections.ArrayList]::new()
        for ($r = $rowFrom; $r -lt [Math]::Min($this.Grid.TotalRows, $rowFrom + $height); $r++) {
            $sb = [System.Text.StringBuilder]::new()
            for ($c = $colFrom; $c -lt [Math]::Min($this.Grid.TotalColumns, $colFrom + $width); $c++) {
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
                elseif ($thisCell -eq $this.TemporaryObstacle) {
                    $sb.Append((Text "&lowast;" -ForegroundColor Red))
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
        $this.Grid = $g
    }

    Turn () {
        $this.Heading = (($this.Heading + 1) % 4)
    }

    TakeStep () {
        # Check for loop
        $idWithHeading = "{0}#{1}#{2}" -f $this.Position.Row, $this.Position.Col, [int]$this.Heading
        $nextCell = $this.GetNextCell()
        if ($null -eq $nextCell) {
            $this.IsInsideGrid = $false
        }
        else {
            if ($this.Path.Contains($idWithHeading)) {
                $this.Stuck = $true
                # ok we have been down this road before. Just stop walking.
            }
            elseif ($nextCell.Obstacle) {
                $this.Turn()
            }
            elseif ($nextCell.Id -eq $this.TemporaryObstacle.Id) {
                $this.Turn()
            }
            else {
                $this.CellsVisited.Add($this.Position)
                $null = $this.Path += "{0}#{1}#{2}" -f $this.Position.Row, $this.Position.Col, [int]$this.Heading
                # check if we are still inside the grid
                $this.Position = $nextCell
            }
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



# Starting Position is excluded from placing an obstacle
$startingPositionId = "{0}#{1}#{2}" -f $myGuard.Position.Row, $myGuard.Position.Col, [int]$myguard.Heading

# find all the possible locations we need to test placing one single obstacle
# these can be anywhere in the path of "an ordinary run"
$steps = 0
do {
    $steps++
    $myGuard.TakeStep()
    #if ($steps % 1 -eq 0 ) {
    #$myGuard.Print(40, 40)
    #Pause
    #}
} until (-not $myGuard.IsInsideGrid)


$cellsToTest = [System.Collections.Generic.HashSet[string]]::new()
$myGuard.Path.GetEnumerator() | ForEach-Object { $null = $cellsToTest += $_ }


# Go over all cells in the path and try placing a temporary obstacle in front of the guard
$CellsThatMakeHimGetStuck = [System.Collections.Generic.HashSet[Cell]]::new()
$p = 0

foreach ($pathEntry in ($cellsToTest | Select-Object -Skip 0)) {
    $p++
    $parts = $pathEntry.Split("#")

    # spawn a new guard at the current position in the path
    $newGuard = [Guard]::new($mygrid.GetCell($parts[0], $parts[1]), [GuardHeading]$parts[2], $myGrid)
    # magically summan an obstacle right in front of him
    $newGuard.TemporaryObstacle = $newGuard.GetNextCell()

    # but return the guard to the initial starting position to prevent him from magically being able to sometimes walk through walls
    $newGuard.Position = $mygrid.GetCell($startingPositionId.Split("#")[0], $startingPositionId.Split("#")[1])
    $newGuard.Heading = [GuardHeading]$startingPositionId.Split('#')[2]

    if ($newGuard.TemporaryObstacle.Id -eq $startingPositionId) {
        Write-Host "$($newGuard.TemporaryObstacle.Row)#$($newGuard.TemporaryObstacle.Col) : Cannot place obstacle at starting position." -ForegroundColor Yellow
    }
    else {
        $steps = 0
        while (-not $newGuard.Stuck -and $newGuard.IsInsideGrid) {
            #$newGuard.Print(30, 30)
            $steps++
            $newGuard.TakeStep()
        }
        if ($newGuard.Stuck) {
            Write-Host "$($newGuard.TemporaryObstacle.Row)#$($newGuard.TemporaryObstacle.Col) : Got stuck. $p of $($cellsToTest.Count)" -ForegroundColor Green
            $null = $CellsThatMakeHimGetStuck.Add($newGuard.TemporaryObstacle)
        }
        else {
            Write-Host "$($newGuard.TemporaryObstacle.Row)#$($newGuard.TemporaryObstacle.Col) : Left the building. $steps steps taken. $p of $($cellsToTest.Count)"
        }
    }
}
$timer.Elapsed.TotalSeconds