# Build release APK y sube a Firebase App Distribution (monsters-app-2660c).
# Uso: .\scripts\distribute-android.ps1 -ReleaseNotes "TP v0.1.0"
#      .\scripts\distribute-android.ps1 -ReleaseNotes "Fix SBC" -Groups "beta"

param(
    [Parameter(Mandatory = $false)]
    [string] $ReleaseNotes = "Nueva build",

    [Parameter(Mandatory = $false)]
    [string] $Groups = ""
)

$ErrorActionPreference = "Stop"

$ProjectId = "monsters-app-2660c"
$FirebaseAppId = "1:1018920622215:android:05d27435de9b04b1404022"
$RepoRoot = Split-Path -Parent $PSScriptRoot

Push-Location $RepoRoot
try {
    if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
        Write-Error "Instalá Firebase CLI: npm install -g firebase-tools && firebase login"
    }

    Write-Host ">> flutter build apk --release"
    flutter build apk --release

    $apk = Join-Path $RepoRoot "build\app\outputs\flutter-apk\app-release.apk"
    if (-not (Test-Path $apk)) {
        Write-Error "No se encontró el APK en $apk"
    }

    $args = @(
        "appdistribution:distribute", $apk,
        "--app", $FirebaseAppId,
        "--project", $ProjectId,
        "--release-notes", $ReleaseNotes
    )
    if ($Groups.Trim().Length -gt 0) {
        $args += "--groups"
        $args += $Groups.Trim()
    }

    Write-Host ">> firebase $($args -join ' ')"
    & firebase @args

    Write-Host ""
    Write-Host "Listo. Testers con invite link verán la build en App Distribution."
    Write-Host "Invite link: Firebase Console > App Distribution > Invite links"
}
finally {
    Pop-Location
}
