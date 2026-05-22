# Build release APK, sube a Firebase App Distribution y deja lista la próxima versión.
#
# Primera subida (APK = 1.0.0+1):
#   .\scripts\distribute-android.ps1 -ReleaseNotes "Walkmons 1.0 — primera build"
#
# Siguientes (auto 1.1, 1.2, … después de cada éxito):
#   .\scripts\distribute-android.ps1 -ReleaseNotes "Fix gatcha"
#
# Sin auto-versionado:
#   .\scripts\distribute-android.ps1 -NoVersionBump -ReleaseNotes "..."
#
# Con grupo de testers (invite link atado al grupo "beta"):
#   .\scripts\distribute-android.ps1 -Groups "beta"

param(
    [Parameter(Mandatory = $false)]
    [string] $ReleaseNotes = "",

    [Parameter(Mandatory = $false)]
    [string] $Groups = "",

    [switch] $NoVersionBump
)

$ErrorActionPreference = "Stop"

$ProjectId = "monsters-app-2660c"
$FirebaseAppId = "1:1018920622215:android:05d27435de9b04b1404022"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$PubspecPath = Join-Path $RepoRoot "pubspec.yaml"

function Get-PubspecVersion {
    $line = (Get-Content $PubspecPath -Raw) -match 'version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)'
    if (-not $Matches) {
        throw "pubspec.yaml: no se encontró version: X.Y.Z+N"
    }
    return @{
        Major = [int]$Matches[1]
        Minor = [int]$Matches[2]
        Patch = [int]$Matches[3]
        Build = [int]$Matches[4]
        Name = "$($Matches[1]).$($Matches[2]).$($Matches[3])"
        Full = "$($Matches[1]).$($Matches[2]).$($Matches[3])+$($Matches[4])"
    }
}

function Set-PubspecVersion($major, $minor, $patch, $build) {
    $newLine = "version: $major.$minor.$patch+$build"
    $content = Get-Content $PubspecPath -Raw
    $updated = $content -replace 'version:\s*\d+\.\d+\.\d+\+\d+', $newLine
    if ($updated -eq $content) { throw "No se pudo actualizar version en pubspec.yaml" }
    Set-Content -Path $PubspecPath -Value $updated -NoNewline
}

function Get-NextPubspecVersion($v) {
    @{
        Major = $v.Major
        Minor = $v.Minor + 1
        Patch = 0
        Build = $v.Build + 1
        Name = "$($v.Major).$($v.Minor + 1).0"
        Full = "$($v.Major).$($v.Minor + 1).0+$($v.Build + 1)"
    }
}

Push-Location $RepoRoot
try {
    if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
        Write-Error "Instalá Firebase CLI: npm install -g firebase-tools && firebase login"
    }
    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
        Write-Error "Flutter no está en el PATH."
    }

    $current = Get-PubspecVersion
    $displayVersion = "$($current.Major).$($current.Minor)"
    if ($ReleaseNotes.Trim().Length -eq 0) {
        $ReleaseNotes = "Walkmons $displayVersion (build $($current.Build))"
    }

    Write-Host ">> Versión de esta build: $($current.Full)  (visible: $displayVersion)" -ForegroundColor Cyan

    Write-Host ">> flutter build apk --release"
    flutter build apk --release

    $apk = Join-Path $RepoRoot "build\app\outputs\flutter-apk\app-release.apk"
    if (-not (Test-Path $apk)) {
        Write-Error "No se encontró el APK en $apk"
    }

    $firebaseArgs = @(
        "appdistribution:distribute", $apk,
        "--app", $FirebaseAppId,
        "--project", $ProjectId,
        "--release-notes", $ReleaseNotes
    )
    if ($Groups.Trim().Length -gt 0) {
        $firebaseArgs += "--groups"
        $firebaseArgs += $Groups.Trim()
    }

    Write-Host ">> firebase appdistribution:distribute ..."
    & firebase @firebaseArgs

    if (-not $NoVersionBump) {
        $next = Get-NextPubspecVersion $current
        Set-PubspecVersion $next.Major $next.Minor $next.Patch $next.Build
        $nextDisplay = "$($next.Major).$($next.Minor)"
        Write-Host ""
        Write-Host "Próxima build en pubspec.yaml: $($next.Full)  (visible: $nextDisplay)" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "Listo. Testers del invite link reciben esta versión en App Distribution."
}
finally {
    Pop-Location
}
