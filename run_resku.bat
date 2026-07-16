@echo off
title Resku Launcher
:start
cls
echo ===================================================
echo               RESKU APPLICATION LAUNCHER           
echo ===================================================
echo.
echo Silakan pilih platform untuk menjalankan aplikasi:
echo [1] Windows (Desktop Native)
echo [2] Web (Google Chrome - Port 3001)
echo [3] Web (Microsoft Edge - Port 3001)
echo [4] Keluar
echo.
set /p pilihan="Masukkan pilihan Anda [1-4]: "

if "%pilihan%"=="1" goto windows
if "%pilihan%"=="2" goto chrome
if "%pilihan%"=="3" goto edge
if "%pilihan%"=="4" goto exit

echo Pilihan tidak valid. Silakan pilih antara 1 sampai 4.
pause
goto start

:windows
echo.
echo Menjalankan Resku di Windows Desktop...
flutter run -d windows
goto end

:chrome
echo.
echo Menjalankan Resku di Google Chrome (Port 3001)...
flutter run -d chrome --web-port 3001
goto end

:edge
echo.
echo Menjalankan Resku di Microsoft Edge (Port 3001)...
flutter run -d edge --web-port 3001
goto end

:exit
echo Keluar dari launcher.
exit /b

:end
pause
goto start
