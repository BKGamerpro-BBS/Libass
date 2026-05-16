@echo off
echo ===================================================
echo      LIBASS APK AUTOMATIC BUILDER & UPDATER
echo ===================================================
echo.
echo Step 1: Navigating to the Flutter project folder...
cd /d "c:\Users\Acer\Desktop\PROJECTS\Libass 2.0\libass_app"

echo.
echo Step 2: Building the Release APK (This may take a minute)...
call flutter build apk --release

if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERROR] Flutter build failed. Please check the code for errors.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo Step 3: Copying and replacing the APK in the Updates folder...
copy /Y "build\app\outputs\flutter-apk\app-release.apk" "..\Updates\libass 2.0.0.apk"

echo.
echo ===================================================
echo      UPDATE SUCCESSFUL! The APK has been replaced.
echo ===================================================
pause
