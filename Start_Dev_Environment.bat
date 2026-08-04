@echo off
title LIBASS Dev Swarm Launcher
cls
echo ===================================================
echo       LIBASS UNIFIED DEV SWARM LAUNCHER
echo ===================================================
echo.
echo [1/4] Verifying Python installation...

:: Try running python to check if it's in PATH
python --version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    :: Try py command
    py --version >nul 2>&1
    if %ERRORLEVEL% neq 0 (
        echo [ERROR] Python was not found on your system PATH.
        echo Please install Python 3.8+ and add it to your PATH.
        pause
        exit /b 1
    ) else (
        set "PYTHON_CMD=py"
    )
) else (
    set "PYTHON_CMD=python"
)
echo    Found Python command: %PYTHON_CMD%

echo.
echo [2/4] Verifying Flask dependencies...
cd /d "%~dp0drape"
:: Check if requirements are installed (run pip install)
echo    Installing/Checking requirements...
%PYTHON_CMD% -m pip install -r requirements.txt >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo    [Warning] Failed to verify/install requirements silently. Trying again with output...
    %PYTHON_CMD% -m pip install -r requirements.txt
) else (
    echo    All backend dependencies are verified and up-to-date!
)

echo.
echo [3/4] Launching Flask Backend (drape) on Port 5000...
:: Start the flask server minimized in a new command window
start "Libass Flask Backend" /min cmd /k "%PYTHON_CMD% app.py"

:: Wait a brief moment for the server to spin up
echo    Waiting for Flask server to initialize...
timeout /t 3 /nobreak >nul

echo.
echo [4/4] Starting Flutter Client...
cd /d "%~dp0libass_app"
call flutter run

echo.
echo ===================================================
echo       CLEANING UP DEV ENVIRONMENT
echo ===================================================
echo Stopping local Flask backend server running on port 5000...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :5000 ^| findstr LISTENING') do (
    taskkill /f /pid %%a >nul 2>&1
)
echo Backend server stopped successfully.
echo.
echo Thank you for developing with LIBASS!
echo ===================================================
pause
