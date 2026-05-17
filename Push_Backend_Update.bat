@echo off
echo ===================================================
echo      LIBASS BACKEND - PUSH TO GITHUB ^& DEPLOY
echo ===================================================
echo.

cd /d "c:\Users\Acer\Desktop\PROJECTS\Libass 2.0"

echo Step 1: Checking for changes...
git status --short
echo.

set "HAS_CHANGES=0"
for /f %%i in ('git status --porcelain') do set "HAS_CHANGES=1"

if "%HAS_CHANGES%"=="0" (
    echo    No changes detected. Nothing to push.
    echo.
    pause
    exit /b 0
)

echo Step 2: Enter a short description of what you changed:
set /p COMMIT_MSG=">> "

if "%COMMIT_MSG%"=="" (
    set "COMMIT_MSG=Backend update"
)

echo.
echo Step 3: Staging all changes...
git add -A

echo.
echo Step 4: Committing with message: "%COMMIT_MSG%"
git commit -m "%COMMIT_MSG%"

if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERROR] Git commit failed.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo Step 5: Pushing to GitHub...
git push

if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERROR] Git push failed. Check your internet connection.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo ===================================================
echo      PUSH SUCCESSFUL!
echo      Render will now auto-deploy your backend.
echo      Check: https://dashboard.render.com
echo ===================================================
pause
