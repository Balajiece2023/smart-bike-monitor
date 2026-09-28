Add-Type -AssemblyName System.Drawing
$srcPath = "C:\Users\bala1\.gemini\antigravity-ide\brain\52fb58cf-72c8-4c11-ad6c-b16f17e3b818\app_logo_icon_1790387842615.jpg"
$srcImg = [System.Drawing.Image]::FromFile($srcPath)

$assetPng = "E:\CProj_01\assets\images\app_logo.png"
$srcImg.Save($assetPng, [System.Drawing.Imaging.ImageFormat]::Png)
Write-Host "Saved asset: $assetPng"

$sizes = @{
    "mipmap-mdpi" = 48
    "mipmap-hdpi" = 72
    "mipmap-xhdpi" = 96
    "mipmap-xxhdpi" = 144
    "mipmap-xxxhdpi" = 192
}

foreach ($item in $sizes.GetEnumerator()) {
    $folder = $item.Key
    $sz = $item.Value
    $targetDir = "E:\CProj_01\android\app\src\main\res\$folder"
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
    $bmp = New-Object System.Drawing.Bitmap $sz, $sz
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.DrawImage($srcImg, 0, 0, $sz, $sz)
    $targetFile = "$targetDir\ic_launcher.png"
    $bmp.Save($targetFile, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
    Write-Host "Created $targetFile ($sz x $sz)"
}

$srcImg.Dispose()
Write-Host "All icons generated successfully!"
