<#
.SYNOPSIS
Builds the CardTone apps using environment variables from a .env file.

.DESCRIPTION
This script safely injects Supabase credentials into the Flutter build process
using --dart-define without hardcoding them in the source.
It reads SUPABASE_URL and SUPABASE_ANON_KEY from the terminal environment or a .env file.

.USAGE
1. Create a .env file in the same directory:
   SUPABASE_URL="https://your-project.supabase.co"
   SUPABASE_ANON_KEY="your-anon-key-here"
2. Run this script:
   .\build_release.ps1 -App "kid"   # builds cardtone-kid
   .\build_release.ps1 -App "parent" # builds cardtone-parent
#>

param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("kid", "parent")]
    [string]$App,

    [switch]$Apk  # Use -Apk to build an APK instead of AppBundle (.aab)
)

$ErrorActionPreference = "Stop"

# 1. Load .env file if it exists
$envFile = Join-Path $PSScriptRoot ".env"
if (Test-Path $envFile) {
    Write-Host "Loading environment variables from .env" -ForegroundColor Cyan
    Get-Content $envFile | Where-Object { $_ -match "^[^#]*=" } | ForEach-Object {
        $name, $value = $_.Split('=', 2)
        $name = $name.Trim()
        $value = $value.Trim().Trim('"').Trim("'")
        [System.Environment]::SetEnvironmentVariable($name, $value)
    }
}

# 2. Verify variables exist
$url = [System.Environment]::GetEnvironmentVariable('SUPABASE_URL')
$key = [System.Environment]::GetEnvironmentVariable('SUPABASE_ANON_KEY')

if (-not $url -or -not $key) {
    Write-Host "ERROR: SUPABASE_URL or SUPABASE_ANON_KEY not found in environment or .env file." -ForegroundColor Red
    Write-Host "Please create a .env file with these variables." -ForegroundColor Yellow
    exit 1
}

# 3. Determine App Folder
$appFolder = if ($App -eq "kid") { "cardtone-kid" } else { "cardtone-parent" }
$projectPath = Join-Path $PSScriptRoot $appFolder

if (-not (Test-Path $projectPath)) {
    Write-Host "ERROR: Could not find app folder at $projectPath" -ForegroundColor Red
    exit 1
}

Push-Location $projectPath

# 4. Construct Build Command
$buildType = if ($Apk) { "apk" } else { "appbundle" }

Write-Host "Building $appFolder for release ($buildType)..." -ForegroundColor Green
Write-Host "Injecting SUPABASE_URL: $url" -ForegroundColor DarkGray

# We use the flutter command line to build
flutter build $buildType --release `
  --dart-define="SUPABASE_URL=$url" `
  --dart-define="SUPABASE_ANON_KEY=$key"

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Build Successful!" -ForegroundColor Green
    if ($Apk) {
        Write-Host "Output: $projectPath\build\app\outputs\flutter-apk\app-release.apk"
    } else {
        Write-Host "Output: $projectPath\build\app\outputs\bundle\release\app-release.aab"
    }
} else {
    Write-Host "`n❌ Build Failed." -ForegroundColor Red
}

Pop-Location
