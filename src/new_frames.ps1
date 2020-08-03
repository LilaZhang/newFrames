$path = Read-Host "Enter directory path ->"
$count = 0
$ext = ".png"

# name of new directory to save frames to
$newDir = "tmp"
$frames = New-Object System.Collections.Generic.List[System.Object]
$check = New-Object System.Collections.Generic.List[System.Object]
$newIndex = 1
New-Item -Path $path -Name $newDir -ItemType "directory"

Get-ChildItem $path -Filter *.png |  # create list of only .png files 

Sort-Object |

ForEach-Object{
    $add = $_ -as [String]
    $frames.Add($add)
    $count++
}

$minFile = ""
$rmPos = 0

# extracts numerical index of frame name w/o path and ext
# problem now is need to also consider float decimal point names..
# returns indexed frame name as an int
function Get-IndexedName {
    Param($frame)
    $indexStr = [io.path]::GetFileNameWithoutExtension($frame)
    # if frame is not a decimal, convert it to int
    if($indexStr.indexOf('.') -lt 0) {
        $index = $indexStr -as [int]
    }
    else {
        $index = $indexStr -as [decimal]
    }
        
    return $index
}

# determines if the frame index name is a decimal or integer
# returns True if index is an integer
function Is-IntegerFrame {
    Param($frame)
    $index = [io.path]::GetFileNameWithoutExtension($frame)
    return ($index.indexOf('.') -lt 0)
}

# 'frame' is current full frame file name in iteration
# find frame with the smallest index value
$total = $frames.Count
while($total -gt 0) {
    while($check.Count -lt 2) {
        $pos = 0
        $min = 0
        foreach($frame in $frames) {
            # Write-Host $frame
            $indexedName = Get-IndexedName -frame $frame
            # Write-Host $indexedName
            if([decimal]$indexedName -le [decimal]$min -or $min -eq 0) {
                $minFile = $frame
                $min = $indexedName
                $rmPos = $pos
            }
            $pos++
        }
        if($frames.Count -gt 0) {
            $frames.RemoveAt($rmPos)
            Write-Host "Removed frame at pos "$rmPos" with name "$minFile
        }
        $check.Add($minFile)
    }

    $i0 = Get-IndexedName -frame $check[0]
    $i1 = Get-IndexedName -frame $check[1]
    $i0b = [Math]::Truncate($i0)
    $i1b = [Math]::Truncate($i1)
    $min = ($i0,$i1 | Measure -Min).Minimum
    $max = ($i0,$i1 | Measure -Max).Maximum
    Write-Host "min="$min" max="$max
    
    if($i0b -eq $i1b -and (-not($i0 -is [decimal]) -and -not($i0 -is [decimal]))) {
        # if base integer is the same and both aren't decimals, add the higher frame
        Write-Host "base ints are same"
        Move-Item -Path $path"/"$max".png" -Destination $path"/"$newDir"/"$newIndex$ext
        $addBack = "$min.png"
        Write-Host "Moved "$max".png as "$newIndex" to "$newDir
    }
    elseif(($i0b -ne $i1b) -or (($i0 -is [decimal]) -and ($i0 -is [decimal]))) {
        # else add the lower frame
        Write-Host "base ints are different"
        Move-Item -Path $path"/"$min".png" -Destination $path"/"$newDir"/"$newIndex$ext
        $addBack = "$max.png"
        Write-Host "Moved "$min".png as "$newIndex" to "$newDir
    }
    
    $frames.Add($addBack)
    $check.Clear()
    $newIndex++
    foreach($frame in $frames) {
        Write-Host $frame
    }
    $total--
}
