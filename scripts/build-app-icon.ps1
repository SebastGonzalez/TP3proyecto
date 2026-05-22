# Genera assets/icon/app_icon.png (cuadrado) desde LogoJuego.png sin deformar.
$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot
$srcPath = Join-Path $repo "assets\images\LogoJuego.png"
$outPath = Join-Path $repo "assets\icon\app_icon.png"
$size = 1024
$paddingFraction = 0.12

Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Image]::FromFile($srcPath)
$bmp = New-Object System.Drawing.Bitmap $size, $size
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.Clear([System.Drawing.Color]::FromArgb(255, 255, 255, 255))
$avail = $size * (1.0 - 2.0 * $paddingFraction)
$scale = [Math]::Min($avail / $src.Width, $avail / $src.Height)
$newW = [int]($src.Width * $scale)
$newH = [int]($src.Height * $scale)
$x = [int](($size - $newW) / 2)
$y = [int](($size - $newH) / 2)
$g.DrawImage($src, $x, $y, $newW, $newH)
New-Item -ItemType Directory -Force -Path (Split-Path $outPath) | Out-Null
$bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose(); $src.Dispose()
Write-Host "OK: $outPath"
