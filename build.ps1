# Exports the web build that serve.ps1 serves. Godot's progress lines are filtered out.
$godot = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe"
New-Item -ItemType Directory -Force "$PSScriptRoot\build\web" | Out-Null
& $godot --headless --path $PSScriptRoot --export-release "Web" build/web/index.html 2>&1 |
    Select-String -NotMatch "first_scan|loading_editor|savepack|^\s*$"
