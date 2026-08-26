Add-Type -AssemblyName System.Drawing

$green = [System.Drawing.Color]::FromArgb(255, 30, 122, 76)
$white = [System.Drawing.Color]::FromArgb(255, 255, 255, 255)
$root = Split-Path -Parent $PSScriptRoot

function New-Bars {
    param($size, $barColor, $background, $path, $scale = 1.0)

    $bmp = New-Object System.Drawing.Bitmap $size, $size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    if ($null -eq $background) {
        $g.Clear([System.Drawing.Color]::Transparent)
    } else {
        $g.Clear($background)
    }

    $brush = New-Object System.Drawing.SolidBrush $barColor
    $unit = ($size / 24.0) * $scale
    $height = $unit * 10
    $top = ($size - $height) / 2.0
    $widths = @(1, 2, 1, 3, 1, 1, 2, 1)
    $gap = $unit * 0.7
    $total = 0.0
    foreach ($w in $widths) { $total += ($unit * $w) + $gap }
    $total -= $gap
    $x = ($size - $total) / 2.0
    foreach ($w in $widths) {
        $barWidth = $unit * $w
        $g.FillRectangle($brush, $x, $top, $barWidth, $height)
        $x += $barWidth + $gap
    }

    $g.Dispose()
    $brush.Dispose()
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Output ("wrote {0} ({1} bytes)" -f $path, (Get-Item $path).Length)
}

New-Item -ItemType Directory -Force (Join-Path $root 'assets\icon') | Out-Null
New-Item -ItemType Directory -Force (Join-Path $root 'assets\splash') | Out-Null

New-Bars 1024 $white $green (Join-Path $root 'assets\icon\icon.png')
New-Bars 1024 $white $null (Join-Path $root 'assets\icon\icon_foreground.png')
New-Bars 1152 $green ([System.Drawing.Color]::White) (Join-Path $root 'assets\splash\splash.png') 0.75
