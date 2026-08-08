Add-Type -AssemblyName System.Drawing

$srcPath = 'a:\Hashzone\WhatsApp Image 2026-07-24 at 11.35.24 AM gg.jpeg'
$outDir  = 'a:\Hashzone\_favicon_gen'

if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

$img = [System.Drawing.Image]::FromFile($srcPath)

$sizes = @(16, 32, 48, 72, 96, 144, 192, 256, 384, 512)

foreach ($sz in $sizes) {
    $bmp = New-Object System.Drawing.Bitmap($sz, $sz)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode   = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode       = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode     = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality  = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.Clear([System.Drawing.Color]::White)
    $g.DrawImage($img, 0, 0, $sz, $sz)
    $g.Dispose()
    $outPath = "$outDir\favicon_${sz}.png"
    $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "Generated: $outPath"
}

$img.Dispose()
Write-Host "All favicons generated."
