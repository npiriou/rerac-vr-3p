[CmdletBinding()]
param([Parameter(Mandatory = $true)][ValidatePattern('^v?[0-9]+\.[0-9]+\.[0-9]+$')][string]$Version,
    [switch]$NoBuild)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$Root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$Name = "RatchetVR-3P-$Version"
$Dist = Join-Path $Root 'work/vr/dist'
$Out = Join-Path $Dist $Name
$Zip = Join-Path $Dist "$Name.zip"
$Target = Join-Path $Root 'target/release'
$OldRustFlags = $env:RUSTFLAGS
Push-Location $Root
try {
    if (-not $NoBuild) {
        $env:RUSTFLAGS = ''
        & (Join-Path $PSScriptRoot 'Build.ps1') -Release
        $PreviousPreference = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            & cargo build --release --locked -p rc-extract --bin rerac-extract 2>&1 | Out-Host
            $Code = $LASTEXITCODE
        } finally { $ErrorActionPreference = $PreviousPreference }
        if ($Code -ne 0) { throw "Extractor build failed (exit $Code)." }
    }

    $Binaries = @('rerac.exe', 'ratchet-vr-3p.exe', 'rerac-extract.exe')
    foreach ($Binary in $Binaries) {
        if (-not (Test-Path -LiteralPath (Join-Path $Target $Binary) -PathType Leaf)) {
            throw "Missing target/release/$Binary. Build the Release profile first."
        }
    }
    $Record = Join-Path $Root 'work/vr/last-build-release.json'
    if (-not (Test-Path -LiteralPath $Record -PathType Leaf)) { throw 'Missing successful Release build record.' }
    $State = Get-Content -LiteralPath $Record -Raw | ConvertFrom-Json
    if ($State.executable_sha256 -ne (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $Target 'rerac.exe')).Hash) {
        throw 'The game executable does not match its successful Release build record.'
    }
    if ((Test-Path -LiteralPath $Out) -or (Test-Path -LiteralPath $Zip)) {
        throw "Release output already exists: $Name. Choose another version."
    }

    [IO.Directory]::CreateDirectory($Out) | Out-Null
    Copy-Item -LiteralPath (Join-Path $Target 'ratchet-vr-3p.exe') -Destination (Join-Path $Out 'RatchetVR-3P.exe')
    Copy-Item -LiteralPath (Join-Path $Target 'rerac.exe') -Destination $Out
    Copy-Item -LiteralPath (Join-Path $Target 'rerac-extract.exe') -Destination $Out

    $VsWhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
    if (-not (Test-Path -LiteralPath $VsWhere)) { throw 'Visual Studio redistributable lookup is missing.' }
    $Crt = @(& $VsWhere -products '*' -find 'VC\Redist\MSVC\*\x64\Microsoft.VC14*.CRT' |
        Where-Object { Test-Path -LiteralPath (Join-Path $_ 'vcruntime140_1.dll') } |
        Sort-Object {[version](Split-Path (Split-Path (Split-Path $_ -Parent) -Parent) -Leaf)} -Descending)
    if (-not $Crt) { throw 'No Visual C++ redistributable CRT folder found.' }
    foreach ($Dll in @('vcruntime140.dll', 'vcruntime140_1.dll', 'msvcp140.dll')) {
        Copy-Item -LiteralPath (Join-Path $Crt[0] $Dll) -Destination $Out
    }

    $Shaders = Join-Path $Out 'assets/shaders'
    [IO.Directory]::CreateDirectory($Shaders) | Out-Null
    Get-ChildItem -LiteralPath (Join-Path $Root 'crates/rc-engine/assets/shaders') -Filter '*.wgsl' -File |
        Copy-Item -Destination $Shaders
    Copy-Item -LiteralPath (Join-Path $Root 'LICENSE') -Destination (Join-Path $Out 'LICENSE.txt')
    $Readme = @"
Ratchet & Clank VR: Third Person $Version

1. Turn on your headset and start SteamVR.
2. Double-click RatchetVR-3P.exe.
3. On the first launch, choose your own Ratchet & Clank PS2 disc image (.iso, US SCUS-97199).
   The game is copied into the data folder once; allow a few minutes and about 5 GB.

Play with a normal PC gamepad. Move Ratchet with the left stick, move the original camera with the right stick,
and look around with your headset. VR motion controllers are not needed. Press F8 on the keyboard to recenter.

Your progress is stored in the saves folder. Keep the game in a writable location such as Desktop or Documents.
For controls and help: https://github.com/npiriou/rerac-vr-3p

Fan project built on ReRAC (https://github.com/re-rac/rerac). No game data is included.
"@
    [IO.File]::WriteAllText((Join-Path $Out 'README.txt'), ($Readme -replace "`r?`n", "`r`n"), (New-Object Text.UTF8Encoding($false)))
    $Allowed = '^(RatchetVR-3P\.exe|rerac\.exe|rerac-extract\.exe|vcruntime140\.dll|vcruntime140_1\.dll|msvcp140\.dll|README\.txt|LICENSE\.txt|assets\\shaders\\[^\\]+\.wgsl)$'
    $Unexpected = @(Get-ChildItem -LiteralPath $Out -Recurse -Force -File |
        ForEach-Object { $_.FullName.Substring($Out.Length + 1) } | Where-Object { $_ -notmatch $Allowed })
    if ($Unexpected) { throw "Unexpected files in the Release folder: $($Unexpected -join ', ')" }
    Compress-Archive -LiteralPath $Out -DestinationPath $Zip
    Write-Host "Release zip: $Zip"
} finally {
    $env:RUSTFLAGS = $OldRustFlags
    Pop-Location
}
