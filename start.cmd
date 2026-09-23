@echo off
set "COSMOS_ENGINE=%~dp0.tools\godot\Godot_v4.4.1-stable_win64.exe"
if defined GODOT_EXECUTABLE set "COSMOS_ENGINE=%GODOT_EXECUTABLE%"
if exist "%COSMOS_ENGINE%" (
  start "Pixel Cosmos Studio" "%COSMOS_ENGINE%" --path "%~dp0."
) else (
  where godot >nul 2>nul
  if errorlevel 1 (
    echo Install Godot 4.4.1 or later and open project.godot.
    echo Or set GODOT_EXECUTABLE to your Godot executable path.
    pause
  ) else (
    start "Pixel Cosmos Studio" godot --path "%~dp0."
  )
)
