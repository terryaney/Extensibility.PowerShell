$DryRun = $true
$SourceRoot = "C:\btr\camelot"
$DestRoot   = "\\tca-xps\c$\btr\camelot"

Write-Host "Finding .git\config files in $SourceRoot and copying to $DestRoot..."
# Find all files named "config" inside any .git folder
$files = Get-ChildItem -Path $SourceRoot -Recurse -Filter "config" -File -Force |
         Where-Object { $_.FullName -match "\\.git\\" }

foreach ($file in $files) {

    # Compute the relative path under the source root
    $relativePath = $file.FullName.Substring($SourceRoot.Length).TrimStart('\')

    # Build the destination path
    $destPath = Join-Path $DestRoot $relativePath

    # Ensure the destination directory exists
    $destDir = Split-Path $destPath -Parent
    if (-not (Test-Path $destDir)) {
        if ($DryRun) {
            Write-Host "[DRY RUN] Would create $destDir"
        } else {
            Write-Host "Creating $destDir"
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
    }

    # Copy the file
    if ($DryRun) {
        Write-Host "[DRY RUN] Would copy $($file.FullName) -> $destPath"
    } else {
        Write-Host "Copying $($file.FullName) -> $destPath"
        Copy-Item -Path $file.FullName -Destination $destPath -Force
    }
}