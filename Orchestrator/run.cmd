@echo off
setlocal

REM Orchestrator needs admin rights (Hyper-V). Self-elevate via UAC if not already.
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

REM Build + run straight from source (dotnet run does an implicit build).
cd /d "%~dp0"
dotnet run --project "%~dp0Orchestrator.csproj"

echo.
echo Orchestrator exited.
pause
endlocal
