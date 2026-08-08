# Create a proper multi-size favicon.ico from generated PNG files
# ICO format supports embedded PNG (Vista+ ICO) for 16, 32, 48 pixel sizes
# Google crawler specifically fetches /favicon.ico at the root domain

$pngDir = 'a:\Hashzone\_favicon_gen'
$outIco = 'a:\Hashzone\web\favicon.ico'

# Read the three PNG files as raw bytes
$png16  = [System.IO.File]::ReadAllBytes("$pngDir\favicon_16.png")
$png32  = [System.IO.File]::ReadAllBytes("$pngDir\favicon_32.png")
$png48  = [System.IO.File]::ReadAllBytes("$pngDir\favicon_48.png")

$count = 3  # number of images

# ICO header: 6 bytes
# WORD Reserved (0), WORD Type (1=ICO), WORD Count
$header = [byte[]](0,0, 1,0, $count,0)

# Each directory entry: 16 bytes
# BYTE Width, BYTE Height, BYTE ColorCount, BYTE Reserved,
# WORD Planes, WORD BitCount, DWORD BytesInRes, DWORD ImageOffset

$dirEntrySize = 16
$headerSize   = 6
$dirSize      = $dirEntrySize * $count
$dataOffset   = $headerSize + $dirSize  # where image data starts

function Make-IcoDirEntry([int]$w, [int]$h, [byte[]]$data, [int]$offset) {
    $size = $data.Length
    $entry = [byte[]](
        [byte]$w,          # width  (0 means 256)
        [byte]$h,          # height (0 means 256)
        0,                 # color count (0 = more than 256)
        0,                 # reserved
        1, 0,              # planes = 1
        32, 0,             # bit count = 32 (RGBA)
        # size as 4-byte LE
        [byte]($size -band 0xFF),
        [byte](($size -shr 8) -band 0xFF),
        [byte](($size -shr 16) -band 0xFF),
        [byte](($size -shr 24) -band 0xFF),
        # offset as 4-byte LE
        [byte]($offset -band 0xFF),
        [byte](($offset -shr 8) -band 0xFF),
        [byte](($offset -shr 16) -band 0xFF),
        [byte](($offset -shr 24) -band 0xFF)
    )
    return $entry
}

$offset16 = $dataOffset
$offset32 = $offset16 + $png16.Length
$offset48 = $offset32 + $png32.Length

$dir16 = Make-IcoDirEntry 16 16 $png16 $offset16
$dir32 = Make-IcoDirEntry 32 32 $png32 $offset32
$dir48 = Make-IcoDirEntry 48 48 $png48 $offset48

# Concatenate everything
$ico = [System.IO.MemoryStream]::new()
$ico.Write($header, 0, $header.Length)
$ico.Write($dir16,  0, $dir16.Length)
$ico.Write($dir32,  0, $dir32.Length)
$ico.Write($dir48,  0, $dir48.Length)
$ico.Write($png16,  0, $png16.Length)
$ico.Write($png32,  0, $png32.Length)
$ico.Write($png48,  0, $png48.Length)

[System.IO.File]::WriteAllBytes($outIco, $ico.ToArray())
$ico.Dispose()

$size = (Get-Item $outIco).Length
Write-Host "Created $outIco ($size bytes) with 16x16 + 32x32 + 48x48 embedded PNGs."
