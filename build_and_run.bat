@echo off
title Siyaq App - Build and Run
echo ===================================================
echo           Building Siyaq App (Flutter Web)...
echo ===================================================
echo.
call flutter build web --release
echo.
echo ===================================================
echo           Starting Web Server...
echo ===================================================
echo.
echo Local URL:   http://localhost:8080
echo Network URL: http://192.168.8.81:8080
echo.
npx -y http-server build/web -p 8080 -a 0.0.0.0 -c-1
pause
