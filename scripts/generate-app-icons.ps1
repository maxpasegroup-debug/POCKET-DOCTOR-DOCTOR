$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$sourcePath = Join-Path $projectRoot 'assets/branding/doctor-app-icon.png'
$source = [Drawing.Bitmap]::FromFile($sourcePath)
try {
    function Write-LauncherIcon([string]$relativePath, [int]$size) {
        # Preserve the supplied artwork's aspect ratio, including all lettering.
        # Native icons require square opaque canvases; extend edge colours into
        # the narrow padding rather than cropping or stretching the source.
        $bitmap = New-Object Drawing.Bitmap($size, $size, [Drawing.Imaging.PixelFormat]::Format24bppRgb)
        $graphics = [Drawing.Graphics]::FromImage($bitmap)
        try {
            $graphics.Clear($source.GetPixel(0, 0))
            $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $scale = [Math]::Min($size / $source.Width, $size / $source.Height)
            $width = [single]($source.Width * $scale)
            $height = [single]($source.Height * $scale)
            $left = [single](($size - $width) / 2)
            $top = [single](($size - $height) / 2)
            # Replicate the original top/bottom edge pixels into square padding.
            if ($top -gt 0) {
                $graphics.DrawImage($source, [Drawing.RectangleF]::new(0, 0, $size, $top + 1), [Drawing.RectangleF]::new(0, 0, $source.Width, 1), [Drawing.GraphicsUnit]::Pixel)
                $graphics.DrawImage($source, [Drawing.RectangleF]::new(0, $top + $height - 1, $size, $size - $top - $height + 1), [Drawing.RectangleF]::new(0, $source.Height - 1, $source.Width, 1), [Drawing.GraphicsUnit]::Pixel)
            }
            $attributes = New-Object Drawing.Imaging.ImageAttributes
            try {
                $attributes.SetWrapMode([Drawing.Drawing2D.WrapMode]::TileFlipXY)
                $rectangle = [Drawing.Rectangle]::new([int]$left, [int]$top, [int]$width, [int]$height)
                $graphics.DrawImage($source, $rectangle, 0, 0, $source.Width, $source.Height, [Drawing.GraphicsUnit]::Pixel, $attributes)
            } finally { $attributes.Dispose() }
            # Copy final rendered edge pixels into padding without interpolation seams.
            for ($x = 0; $x -lt $size; $x++) {
                $topColor = $bitmap.GetPixel($x, $rectangle.Top)
                $bottomColor = $bitmap.GetPixel($x, $rectangle.Bottom - 1)
                for ($y = 0; $y -lt $rectangle.Top; $y++) { $bitmap.SetPixel($x, $y, $topColor) }
                for ($y = $rectangle.Bottom; $y -lt $size; $y++) { $bitmap.SetPixel($x, $y, $bottomColor) }
            }
            $bitmap.Save((Join-Path $projectRoot $relativePath), [Drawing.Imaging.ImageFormat]::Png)
        } finally { $graphics.Dispose(); $bitmap.Dispose() }
    }
    foreach ($entry in @{mdpi=48; hdpi=72; xhdpi=96; xxhdpi=144; xxxhdpi=192}.GetEnumerator()) {
        Write-LauncherIcon "android/app/src/main/res/mipmap-$($entry.Key)/ic_launcher.png" $entry.Value
    }
    $catalog = Get-Content (Join-Path $projectRoot 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json') -Raw | ConvertFrom-Json
    foreach ($entry in $catalog.images | Sort-Object filename -Unique) {
        $points = [double]::Parse($entry.size.Split('x')[0], [Globalization.CultureInfo]::InvariantCulture)
        $scale = [int]$entry.scale.TrimEnd('x')
        Write-LauncherIcon "ios/Runner/Assets.xcassets/AppIcon.appiconset/$($entry.filename)" ([int]($points * $scale))
    }
    Write-Output 'Generated 5 Android and 15 iOS icon files from the supplied artwork.'
} finally { $source.Dispose() }

