@echo off
cd /d "%~dp0"
echo ============================================
echo   Iraq Pharma Guide - Release Build (AAB)
echo ============================================
echo.
echo [1/3] Cleaning previous build...
call flutter clean
echo.
echo [2/3] Getting dependencies...
call flutter pub get
echo.
echo [3/3] Building signed App Bundle (release)...
call flutter build appbundle --release
echo.
if exist "build\app\outputs\bundle\release\app-release.aab" (
    echo ============================================
    echo   SUCCESS - AAB file ready at:
    echo   %cd%\build\app\outputs\bundle\release\app-release.aab
    echo ============================================
) else (
    echo ============================================
    echo   BUILD FAILED - check the errors printed above
    echo   and send them back for troubleshooting.
    echo ============================================
)
echo.
pause
