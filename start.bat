@echo off
REM NTSC Cam launcher — serves ntsc.html on http://localhost:9395 and opens it.
REM Requires Python 3 in PATH (Microsoft Store: "python" → install).

setlocal
set PORT=9395
cd /d "%~dp0"

where python >nul 2>nul
if errorlevel 1 (
  where py >nul 2>nul
  if errorlevel 1 (
    echo Python not found. Install from the Microsoft Store: search "Python".
    pause
    exit /b 1
  )
  set PYEXE=py
) else (
  set PYEXE=python
)

echo Starting NTSC Cam on http://localhost:%PORT%/ntsc.html
echo Press Ctrl+C in this window to stop.
echo.

start "" "http://localhost:%PORT%/ntsc.html?src=phonelink&size=1080x1920&preset=vhs"
%PYEXE% -m http.server %PORT%
