# A local custom settings.json is copied into Fragments, but not all
# settings work there. This script installs the rest into the main settings.json


# the bash profile from our local settings.json
$defaultProfileGuid = "{b13093d2-b61f-48a8-a561-558afd31b91c}"

# Win + ` to toggle show/hide terminal
$bindingMarker = "User.globalSummon.51A3D78C"
$binding = @'
        {
            "id": "User.globalSummon.51A3D78C",
            "keys": "win+`"
        },
'@

# dark mode, font size, starting dir
$profileDefaults = @'
    "defaults": {
        "colorScheme": "Dark+",
        "bellStyle": "none",
        "font": {
        "size": 11,
        "weight": "semi-light"
        },
        "startingDirectory": "%USERPROFILE%"
    },
'@

$initialCols = 140
$initialRows = 60

$installedAny = $false


# read main settings file
$settingsPath = Get-ChildItem "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_*\LocalState\settings.json" `
    -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName

if (-not $settingsPath) {
    Write-Error "Windows Terminal settings.json not found"
    exit 1
}

$content = Get-Content $settingsPath -Raw


# set default profile to bash
$newDefaultProfileContent = "`"defaultProfile`": `"$defaultProfileGuid`""
if ($content -notmatch [regex]::Escape($newDefaultProfileContent))
{
    if ($content -notmatch '"defaultProfile"\s*:\s*"\{[0-9a-fA-F-]+\}"') {`
        Write-Error "Couldn't find defaultProfile to replace. Add one manually first."
        exit 1
    }
    $content = $content -replace '"defaultProfile"\s*:\s*"\{[0-9a-fA-F-]+\}"', $newDefaultProfileContent
    Write-Host "Set Terminal defaultProfile: $defaultProfileGuid"
    $installedAny = $true
}


# initial cols/rows
if ($content -notmatch 'initialRows') {
    $content = $content -replace '("defaultProfile":.*)', "`$1`n    `"initialRows`": $initialRows,"
    Write-Host "Set Terminal initialRows: $initialRows"
    $installedAny = $true
}
if ($content -notmatch 'initialCols') {
    $content = $content -replace '("defaultProfile":.*)', "`$1`n    `"initialCols`": $initialCols,"
    Write-Host "Set Terminal initialCols: $initialCols"
    $installedAny = $true
}


# add global summon keybinding
if ($content -notmatch [regex]::Escape($bindingMarker))
{
    if ($content -notmatch '"keybindings"\s*:\s*\[') {
        Write-Error "Couldn't find an 'keybindings' array to inject into. Add one manually first."
        exit 1
    }
    $content = $content -replace '("keybindings"\s*:\s*\[)', "`$1`n$binding"

    Write-Host "Set Terminal global summon keybind"
    $installedAny = $true
}


# add profile defaults
if ($content -notmatch 'Dark\+')
{
    if ($content -notmatch '"profiles"\s*:\s*\{') {
        Write-Error "Couldn't find an 'profiles' array to inject into. Add one manually first."
        exit 1
    }
    $content = $content -replace '("defaults"\s*:\s*\{\}),', "" # remove empty defaults
    $content = $content -replace '("profiles"\s*:\s*\{)', "`$1`n$profileDefaults"

    Write-Host "Set Terminal default profile prefs"
    $installedAny = $true
}

if (-not $installedAny)
{
    Write-Host "Terminal prefs already installed"
    exit 0
}

# write new settings
Set-Content -Path $settingsPath -Value $content -Encoding UTF8
