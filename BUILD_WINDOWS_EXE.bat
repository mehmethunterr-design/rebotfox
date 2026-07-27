@echo off
chcp 65001 >nul
title Rebotfox Windows EXE Olusturucu

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\build_windows.ps1"

echo.
if errorlevel 1 (
  echo Derleme tamamlanamadi. Yukaridaki hata mesajini ChatGPT'ye gonder.
) else (
  echo Rebotfox Windows paketi hazir.
)
pause
