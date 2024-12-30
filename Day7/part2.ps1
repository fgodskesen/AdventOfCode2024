$ErrorActionPreference = "Stop"

$in = Get-Content $PSScriptRoot\input.txt

$calibrations = [System.Collections.ArrayList]::new()
foreach ($line in $in) {
    $temp = $line.Substring(0, $line.IndexOf(':'))
    $parts = $line.Substring($line.IndexOf(':') + 2) -split " " | ForEach-Object { [long]$_ }
    $calibrations += [pscustomobject]@{
        Total = [long]$temp
        Parts = $parts
    }
}





function Get-Combination ([long]$total, $parts, [string]$representation) {
    # extract data
    $num1 = $parts[0]
    $num2 = $parts[1]
    $newParts = ($parts.Count -gt 2) ? $parts[2..($parts.Count - 1)] : @()

    # SUM
    $newRep = $representation + " + $num2"
    $sum = $num1 + $num2
    if ($newParts.Count) {
        # not done yet.
        if ($sum -gt $total) {
            $outObj = [pscustomobject]@{
                Total   = $total
                Result  = $sum
                Success = $false
                Eq      = ">"
                Txt     = $newRep + ($newParts -join " ? ")
            }
            Write-Output $outObj
        }
        else {
            Get-Combination $total (@($sum) + $newParts) $newRep
        }
    }
    else {
        if ($sum -eq $total) {
            $outObj = [pscustomobject]@{
                Total   = $total
                Result  = $sum
                Success = $true
                Eq      = "="
                Txt     = $newRep
            }
            Write-Output $outObj
        }
        elseif ($sum -gt $total) {
            $outObj = [pscustomobject]@{
                Total   = $total
                Result  = $sum
                Success = $false
                Eq      = ">"
                Txt     = $newRep
            }
            Write-Output $outObj
        }
        else {
            $outObj = [pscustomobject]@{
                Total   = $total
                Result  = $sum
                Success = $false
                Eq      = "<"
                Txt     = $newRep
            }
            Write-Output $outObj
        }
    }


    # PRODUCT
    $newRep = $representation + " * $num2"
    $prod = $num1 * $num2
    if ($newParts.Count) {
        # not done yet.
        if ($prod -gt $total) {
            $outObj = [pscustomobject]@{
                Total   = $total
                Result  = $prod
                Success = $false
                Eq      = ">"
                Txt     = $newRep + " ? " + ($newParts -join " ? ")
            }
            Write-Output $outObj
        }
        else {
            Get-Combination $total (@($prod) + $newParts) $newRep
        }
    }
    else {
        if ($prod -eq $total) {
            $outObj = [pscustomobject]@{
                Total   = $total
                Result  = $prod
                Success = $true
                Eq      = "="
                Txt     = $newRep
            }
            Write-Output $outObj
        }
        elseif ($prod -gt $total) {
            $outObj = [pscustomobject]@{
                Total   = $total
                Result  = $prod
                Success = $false
                Eq      = ">"
                Txt     = $newRep
            }
            Write-Output $outObj
        }
        else {
            $outObj = [pscustomobject]@{
                Total   = $total
                Result  = $prod
                Success = $false
                Eq      = "<"
                Txt     = $newRep
            }
            Write-Output $outObj
        }
    }



    # CONCATENATION
    $newRep = $representation + " || $num2"
    $concat = [long]("$num1$num2")
    if ($newParts.Count) {
        # not done yet.
        if ($concat -gt $total) {
            $outObj = [pscustomobject]@{
                Total   = $total
                Result  = $concat
                Success = $false
                Eq      = ">"
                Txt     = $newRep + " ? " + ($newParts -join " ? ")
            }
            Write-Output $outObj
        }
        else {
            Get-Combination $total (@($concat) + $newParts) $newRep
        }
    }
    else {
        if ($concat -eq $total) {
            $outObj = [pscustomobject]@{
                Total   = $total
                Result  = $concat
                Success = $true
                Eq      = "="
                Txt     = $newRep
            }
            Write-Output $outObj
        }
        elseif ($concat -gt $total) {
            $outObj = [pscustomobject]@{
                Total   = $total
                Result  = $concat
                Success = $false
                Eq      = ">"
                Txt     = $newRep
            }
            Write-Output $outObj
        }
        else {
            $outObj = [pscustomobject]@{
                Total   = $total
                Result  = $concat
                Success = $false
                Eq      = "<"
                Txt     = $newRep
            }
            Write-Output $outObj
        }
    }

}



$sumOfTestValues = 0
$calibrations | ForEach-Object {
    Get-Combination $_.Total $_.Parts ($_.Parts[0]) | Where-Object { $_.Success } | Select-Object -First 1 | ForEach-Object {
        $sumOfTestValues += $_.Total
        $_
    }
} | ft

Write-Host "SumOfTestValues : $sumOfTestValues"


#Get-Combination $calibrations[4].Total $calibrations[4].Parts $calibrations[4].Parts[0]