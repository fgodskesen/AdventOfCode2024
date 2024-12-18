

$in = Get-Content $PSScriptRoot\input.txt

class ManualPage {
    [hashtable]$Children = @{}
    [hashtable]$Parents = @{}
    [int]$PageNum

    ManualPage ([int]$p) {
        $this.PageNum = $p
    }

    Print () {
        Write-Host "$($this.Parents.Keys -join ',') --> " -NoNewline
        Write-Host $($this.PageNum) -ForegroundColor Green -NoNewline
        Write-Host " --> $($this.Children.Keys -join ',')"
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
        Write-Host "-------------------------------------"
        $this.Pages.Values | ForEach-Object { $_.Print() }
    }

    RemovePage ($p) {
        $pageToRemove = $this.Pages[$p]
        # Remove the references
        foreach ($parentID in $pageToRemove.Parents.Keys) {
            $this.Pages[$parentID].Children.Remove($p)
        }
        foreach ($childID in $pageToRemove.Children.Keys) {
            $this.Pages[$childID].Parents.Remove($p)
        }
        $this.Pages.Remove($p)
    }

    [Book] Clone () {
        $newBook = [Book]::new()
        foreach ($oldPage in $this.Pages.Values) {
            $newPage = $newBook.GetOrCreatePage($oldPage.PageNum)
            foreach ($child in $oldPage.Children.Values) {
                $newChild = $newBook.GetOrCreatePage($child.PageNum)
                $newChild.Parents[$newPage.PageNum] = $newPage
                $newPage.Children[$newChild.PageNum] = $newChild
            }
        }
        return $newBook
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
            IsValid     = $true
        }
        $newObj.Count = $newObj.Parts.Count
        $updates += $newObj
    }
}




# Validate as per part 1
:eachupdate foreach ($update in $updates) {
    # Start at 2nd char and move right
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



# create full book of all manpages
$b = [Book]::new()
foreach ($key in $rules.Keys) {
    $page = $b.GetOrCreatePage($key)
    foreach ($childPageNum in $rules[$key]) {
        $childPage = $b.GetOrCreatePage($childPageNum)
        $childPage.Parents[$page.PageNum] = $page
        $page.Children[$childPageNum] += $childPage
    }
}


$medianCount = 0
foreach ($update in ($updates | Where-Object { -not $_.IsValid })) {
    # create a clone of the book
    $b2 = $b.Clone()
    #$b2.Print()
    # strip pages from the clone until we only include pages/nodes contained in the update
    $toRemove = $b2.Pages.Keys | Where-Object { $_ -notin $update.Parts }
    $toRemove | ForEach-Object { $b2.RemovePage($_) }

    #$b2.Print()
    # Where do we start... well... with any page that has no parents. As we progress, we remove those pages from our b2 book as we know they are placed correctly in the beginning of the string
    # Grandparents can be in any order between themselves, so we will just take them one at a time and add to SortedParts
    while ($b2.Pages.Count) {
        $grandParents = $b2.Pages.Values | Where-Object { $_.Parents.Count -eq 0 } | Select-Object -ExpandProperty PageNum
        $grandParents | ForEach-Object {
            $update.SortedParts += $_
            $b2.RemovePage($_)
            #$b2.Print()
        }
    }

    Write-Host "From   : $($update.Parts -join ',')"
    Write-Host "To     : $($update.SortedParts -join ',')"
    $median = $update.SortedParts[ (($update.Count - 1) / 2) ]
    Write-Host "Median : $median"
    $medianCount += $median
}
Write-Host "---"
Write-Host "Total sum of Medians: $medianCount" -ForegroundColor Green

#$b.Print()

<#
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