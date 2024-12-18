

$in = Get-Content $PSScriptRoot\input.txt

class ManualPage {
    [System.Collections.Generic.List[ManualPage]]$Children
    [System.Collections.Generic.List[ManualPage]]$Parents
    [int]$PageNum

    ManualPage ([int]$p) {
        $this.PageNum = $p
    }

    Print () {
        Write-Host "$($this.Parents.PageNum -join ',') ---- $($this.PageNum) ---- $($this.Children.PageNum -join ',')"
    }
}

class Book {
    [hashtable]$Pages = @{}

    [ManualPage] GetOrCreatePage ($p) {
        if (-not $this.Pages.ContainsKey($p)) {
            $this.Pages.Add($p, [ManualPage]::New($p))
        }
        return ($this.Pages[$p])
    }

    Print () {
        $this.Pages.Values | ForEach-Object { $_.Print() }
    }
}


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
        $newObj = [pscustomobject]@{
            Parts       = ($l.Split(",") | ForEach-Object { [int]$_ })
            Count       = 0
            SortedParts = @()
            IsValid     = $null
        }
        $newObj.Count = $newObj.Parts.Count
        $updates += $newObj
    }
}




function Switch-Elements ([array]$arr, [int]$posA, [int]$posB) {
    $temp = $arr[$posA]
    $arr[$posA] = $arr[$posB]
    $arr[$posB] = $temp
}

function Add-ElementAtPos ([array]$arr, [object]$Element, [int]$pos) {
    for ($x = $arr.Count - 1; $x -ge $pos; $x--) {
        $arr[$x] = $arr[$x - 1]
    }
    $arr[$pos] = $Element
    return $arr
}




# Validate as per part 1
:eachupdate foreach ($update in $updates) {
    $update.IsValid = $true
    # Start at 2nd char and move right.
    # Validate that all rules matching thisNum against all numbers to the left of thisNum are not in the rules
    for ($x = 1; $x -le $update.Count - 1; $x++) {
        $thisNum = $update.Parts[$x]
        for ($y = 0; $y -le $x - 1; $y++) {
            $thatNum = $update.Parts[$y]
            if ($rules[$thisNum] -contains $thatNum) {
                $update.IsValid = $false
                continue eachupdate
            }
        }
    }
}







# Do Bubble sort... sort of.. on the invalid updates
$medianSum = 0
foreach ($update in $updates | Where-Object { -not $_.IsValid }) {
    $pagesInThisUpdate = $update.Parts

    # Create new ruleset only with pages that appear in this update
    $newRules = @{}
    foreach ($k in ($rules.Keys | Where-Object { $_ -in $pagesInThisUpdate } )) {
        $gt = [System.Collections.Generic.HashSet[int]]::new()

        $nodesToAdd = [System.Collections.Generic.HashSet[int]]::new()
        $rules[$k] | Where-Object { $_ -in $pagesInThisUpdate } | ForEach-Object { $null = $nodesToAdd.Add($_) }

        while ($nodesToAdd.Count) {
            $n = $nodesToAdd.GetEnumerator() | Select-Object -First 1
            $null = $gt.Add($n)
            $rules[$n] | Where-Object { $_ -and $_ -notin $gt } | ForEach-Object { $null = $nodesToAdd.Add($_) }
            $null = $nodesToAdd.Remove($n)
        }
        $newRules[$k] = $gt.GetEnumerator() | ForEach-Object { $_ }
    }

    # x contains num of sorted elements to the lhs
    $update.SortedParts = $update.Parts.Clone()
    #$update.Parts | ForEach-Object { $update.SortedParts += $_ }
    for ($x = 0; $x -lt $update.Count - 2 ; $x++) {
        # y is looped in consequtively smaller loops
        for ($y = $update.Count - 1; $y -gt $x; $y--) {
            $thisPosValue = $update.SortedParts[$y]
            $leftPosValue = $update.SortedParts[$y - 1]
            if ($newRules[$thisPosValue] -contains $leftPosValue) {
                Switch-Elements $update.SortedParts $y ($y - 1)
            }
        }
    }

    $median = $update.SortedParts[(($update.Count - 1) / 2)]
    $medianSum += $median
}

$medianSum














<#

foreach ($update in $updates) {
    # pick an element to position
    $update.SortedParts = $update.Parts.Clone()
    for ($x = 0; $x -lt $update.Count - 2; $x++) {
        $element = $update.Parts[$x]
        $highwaterMark = $x
        for ($y = $x + 1; $y -lt $update.Count - 1; $y++) {
            if ($rules[$update.SortedParts[$y]] -contains $element) {
                $highwaterMark = $y
            }
        }
        if ($highwaterMark -ne $x) {
            $x--
            Switch-Elements $update.SortedParts $x $y
        }
    }
}
$update | ConvertTo-Json
#>


<#

$b = [Book]::new()
foreach ($key in $rules.Keys) {
    $page = $b.GetOrCreatePage($key)
    foreach ($child in $rules[$key]) {
        $c = $b.GetOrCreatePage($child)
        $c.Parents += $page
        $page.Children += $c
    }
}

#$b.Print()


foreach ($x in $b.Pages.Keys) {
    # Remove Children if they are accessible through a longer path
    $thisPage = $b.Pages[$x]


    foreach ($p in $thisPage.Children.PageNum) {
        $pageToInspect = $b.Pages[$p]
        $pagesToVisit = [System.Collections.Generic.HashSet[int]]::new()
        $thisPage.Children | Where-Object { $_ -ne $p } | ForEach-Object { $null = $pagesToVisit.Add($_.PageNum) }
        $pagesAlreadyVisited = [System.Collections.Generic.HashSet[int]]::new()
        $null = $pagesAlreadyVisited.Add($p)

        while ($pagesToVisit.Count) {
            $nextPage = $pagesToVisit | Select-Object -First 1 | ForEach-Object { $b.Pages[$_] }

            if ($nextPage.Children.PageNum -contains $p) {
                $null = $pageToInspect.Parents.Remove($thisPage)
                $null = $thisPage.Children.Remove($pageToInspect)
                break
            }

            $nextPage.Children | Where-Object { $_ -notin $pagesAlreadyVisited } | ForEach-Object { $null = $pagesToVisit.Add($_.PageNum) }

            $null = $pagesToVisit.Remove($nextPage.PageNum)
            $null = $pagesAlreadyVisited.Add($nextPage.PageNum)
        }
    }
}
$b.Print()

#>