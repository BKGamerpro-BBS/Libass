@echo off
title LIBASS Backend Keep-Alive Service
cls
echo ===================================================
echo     LIBASS BACKEND 24/7 KEEP-ALIVE SERVICE
echo ===================================================
echo.
echo This script pings your hosted Render backend every 10 minutes
echo to prevent Render's Free Tier from spinning down / sleeping.
echo.
echo Target URL: https://libass-backend.onrender.com
echo.
echo [Control + C] to terminate this loop at any time.
echo ===================================================
echo.

:loop
echo [%time%] Sending keep-awake ping to https://libass-backend.onrender.com ...
powershell -Command "try { $res = Invoke-WebRequest -Uri 'https://libass-backend.onrender.com/' -UseBasicParsing -TimeoutSec 15; Write-Host '   Ping Success! Status Code:' $res.StatusCode -ForegroundColor Green } catch { Write-Host '   Ping Failed or Timed Out (the server might be cold-booting...)' -ForegroundColor Yellow }"
echo [%time%] Sleeping for 10 minutes...
timeout /t 600 /nobreak
goto loop
