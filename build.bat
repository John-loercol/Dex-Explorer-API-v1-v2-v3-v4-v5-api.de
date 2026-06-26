@echo off
echo ========================================
echo   Startup Alert - Build Script
echo ========================================
echo.

echo [1/2] Installing PyInstaller...
pip install pyinstaller
echo.

echo [2/2] Building StartupAlert.exe...
pyinstaller --onefile --noconsole --name "StartupAlert" main.py
echo.

if exist "dist\StartupAlert.exe" (
    echo ✅ Build successful!
    echo    File: dist\StartupAlert.exe
) else (
    echo ❌ Build failed. Please check errors above.
)

echo.
pause
