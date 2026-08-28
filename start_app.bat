@echo off
title Siyaq App Server
echo ===================================================
echo           Starting Siyaq App Web Server...
echo ===================================================
echo.
echo Local URL:   http://localhost:8080
echo Network URL: http://192.168.8.81:8080
echo.
echo Press Ctrl+C anytime to stop the server.
echo ===================================================
echo.
npx -y http-server build/web -p 8080 -a 0.0.0.0 -c-1
pause
