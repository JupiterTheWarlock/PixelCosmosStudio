param([string]$GodotPath = '.tools/godot/Godot_v4.4.1-stable_win64_console.exe')
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$originalPath = $env:PATH
$env:PATH = (Join-Path $projectRoot '.tools/rcedit') + ';' + $env:PATH
Push-Location -LiteralPath $projectRoot
try {
    $enginePath = (Resolve-Path -LiteralPath $GodotPath).Path
    New-Item -ItemType Directory -Force -Path dist/web,dist/windows,dist/licenses | Out-Null
    New-Item -ItemType File -Force -Path dist/.gdignore | Out-Null
    & $enginePath --headless --path $projectRoot --editor --import --quit *> dist/import.log
    if ($LASTEXITCODE -ne 0) { throw 'Godot import failed. See dist/import.log.' }
    & $enginePath --headless --path $projectRoot --script res://tools/runtime_notices.gd *> dist/licenses.log
    if ($LASTEXITCODE -ne 0) { throw 'License export failed. See dist/licenses.log.' }
    & $enginePath --headless --path $projectRoot --export-release Web dist/web/index.html *> dist/web-build.log
    if ($LASTEXITCODE -ne 0) { throw 'Web export failed. See dist/web-build.log.' }
    & $enginePath --headless --path $projectRoot --export-release Windows dist/windows/PixelCosmosStudio.exe *> dist/windows-build.log
    if ($LASTEXITCODE -ne 0) { throw 'Windows export failed. See dist/windows-build.log.' }
    foreach ($required in @('dist/web/index.html','dist/web/index.pck','dist/web/index.wasm','dist/windows/PixelCosmosStudio.exe','dist/windows/PixelCosmosStudio.pck')) {
        if (!(Test-Path -LiteralPath $required) -or (Get-Item -LiteralPath $required).Length -eq 0) { throw "Missing release file: $required" }
    }
    Copy-Item -LiteralPath docs/RELEASE_README.txt -Destination dist/windows/README.txt
    foreach ($platform in @('web','windows')) {
        Copy-Item -LiteralPath THIRD_PARTY_NOTICES.md -Destination "dist/$platform/THIRD_PARTY_NOTICES.md"
        New-Item -ItemType Directory -Force -Path "dist/$platform/licenses" | Out-Null
        Copy-Item -Path dist/licenses/* -Destination "dist/$platform/licenses"
        Copy-Item -Path assets/ui/OFL-*.txt -Destination "dist/$platform/licenses"
        if (Test-Path -LiteralPath LICENSE) { Copy-Item -LiteralPath LICENSE -Destination "dist/$platform/LICENSE" }
    }
    $webFiles = @(Get-ChildItem -LiteralPath dist/web -File | Where-Object { $_.Name -like 'index.*' -or $_.Name -eq 'THIRD_PARTY_NOTICES.md' -or $_.Name -eq 'LICENSE' })
    $webAll = @($webFiles) + @(Get-ChildItem -LiteralPath dist/web/licenses -File)
    if ($webAll.Count -gt 1000 -or ($webAll | Measure-Object Length -Sum).Sum -gt 500MB -or ($webAll | Where-Object { $_.Length -gt 200MB })) { throw 'Web build exceeds itch HTML5 limits.' }
    Compress-Archive -Path ($webFiles.FullName + @((Join-Path $projectRoot 'dist/web/licenses'))) -DestinationPath dist/PixelCosmosStudio-web.zip -Force
    $windowsFiles = @('dist/windows/PixelCosmosStudio.exe','dist/windows/PixelCosmosStudio.pck','dist/windows/README.txt','dist/windows/THIRD_PARTY_NOTICES.md','dist/windows/licenses')
    if (Test-Path -LiteralPath dist/windows/LICENSE) { $windowsFiles += 'dist/windows/LICENSE' }
    Compress-Archive -Path $windowsFiles -DestinationPath dist/PixelCosmosStudio-windows.zip -Force
    Get-Item -LiteralPath dist/PixelCosmosStudio-web.zip,dist/PixelCosmosStudio-windows.zip | Select-Object Name,Length
} finally { $env:PATH = $originalPath; Pop-Location }
