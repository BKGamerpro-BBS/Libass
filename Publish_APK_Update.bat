@echo off
echo ===================================================
echo      LIBASS APK AUTOMATIC BUILDER ^& UPDATER
echo ===================================================
echo.
echo Step 1: Navigating to the Flutter project folder...
cd /d "c:\Users\Acer\Desktop\PROJECTS\Libass 2.0\libass_app"

echo.
echo Step 2: Reading app version from pubspec.yaml...
set "APP_VERSION="
for /f "tokens=2 delims=: " %%A in ('findstr /b "version:" pubspec.yaml') do (
    set "FULL_VERSION=%%A"
)
rem Strip the +buildNumber suffix (e.g. 2.0.0+1 -> 2.0.0)
for /f "tokens=1 delims=+" %%V in ("%FULL_VERSION%") do (
    set "APP_VERSION=%%V"
)

if "%APP_VERSION%"=="" (
    echo [ERROR] Could not read version from pubspec.yaml.
    pause
    exit /b 1
)
echo    Detected version: %APP_VERSION%

echo.
echo Step 3: Building the DEBUG APK (for testing)...
call flutter build apk --debug

if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERROR] Flutter debug build failed. Please check the code for errors.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo Step 4: Building the RELEASE APK (for production)...
call flutter build apk --release

if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERROR] Flutter release build failed. Please check the code for errors.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo Step 5: Copying APKs to the Updates folder...
if not exist "..\Updates" mkdir "..\Updates"
copy /Y "build\app\outputs\flutter-apk\app-debug.apk" "..\Updates\Libass %APP_VERSION% - Testing.apk"
copy /Y "build\app\outputs\flutter-apk\app-release.apk" "..\Updates\Libass %APP_VERSION%.apk"

echo.
echo ===================================================
echo      UPDATE SUCCESSFUL! Both APKs are ready:
echo      - Libass %APP_VERSION% - Testing.apk  (debug)
echo      - Libass %APP_VERSION%.apk             (production)
echo ===================================================
pause
