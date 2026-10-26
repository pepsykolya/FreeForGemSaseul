@echo off
rem FreeForGemSaseul (ffgs) - SASEUL (SL) GPU miner on saseulpool.com (NATS, nats://nats.saseulpool.com:4222).
rem Put your SASEUL address (44 hex chars) below, save, double-click this file.
rem The pool answers no single share: "delivered" shares reached its server; what it credited is in the "pool" line.
cd /d "%~dp0"
set WALLET=YOUR_SASEUL_ADDRESS
rem Worker name shown on saseulpool.com (empty = this computer's name)
set WORKER=
rem GPUs to use, numbered as in nvidia-smi (empty = all), e.g. 0,1
set DEVICES=
rem Fee 2% = 1% ffgs dev + 1% referral. REFERRER = the SASEUL address of who recommended ffgs to you:
rem they get the 1% referral minute. Put your own wallet here to pay only 1% in total.
rem Empty = the referral minute goes to the ffgs dev.
set REFERRER=

rem ---- Optional GPU clock control (empty = leave as is). Needs Administrator (see AUTO_ELEVATE below).
rem One value for all GPUs, or a comma list in DEVICES order (empty entry or 0 = leave that GPU alone),
rem e.g. LOCK_CCLOCK=1400,,1500. Everything is put back when ffgs exits. RTX 3070: 1400 / 810 / 225 (README).
rem Core clock lock, MHz:
set LOCK_CCLOCK=
rem Memory clock lock, MHz (810 = lowest; SL needs no memory bandwidth):
set LOCK_MCLOCK=
rem Core clock V/F offset, MHz = undervolt at the locked clock:
set COFFSET=
rem Memory clock offset, MHz, may be negative (NVIDIA driver 555+):
set MOFFSET=
rem Power limit, W:
set PLIMIT=
rem 1 = undervolt auto-tuner (--auto-uv): finds the highest stable core offset itself, at a locked core clock
rem (set LOCK_CCLOCK). The first start tunes ~10-15 min before mining, later starts reuse the saved result.
set AUTO_UV=
rem 1 = when clock settings are set and this window is not elevated, ask Windows to reopen it as Administrator
set AUTO_ELEVATE=1

rem Extra arguments, e.g. --eco
set EXTRA=

set ARGS=--pool saseulpool --wallet %WALLET%
if not "%REFERRER%"=="" set ARGS=%ARGS% --referrer %REFERRER%
if not "%WORKER%"=="" set ARGS=%ARGS% --worker %WORKER%
if not "%DEVICES%"=="" set ARGS=%ARGS% --devices %DEVICES%
if not "%LOCK_CCLOCK%"=="" set ARGS=%ARGS% --lock-cclock %LOCK_CCLOCK%
if not "%LOCK_MCLOCK%"=="" set ARGS=%ARGS% --lock-mclock %LOCK_MCLOCK%
if not "%COFFSET%"=="" set ARGS=%ARGS% --coffset %COFFSET%
if not "%MOFFSET%"=="" set ARGS=%ARGS% --moffset %MOFFSET%
if not "%PLIMIT%"=="" set ARGS=%ARGS% --plimit %PLIMIT%
if "%AUTO_UV%"=="1" set ARGS=%ARGS% --auto-uv
set OC=%LOCK_CCLOCK%%LOCK_MCLOCK%%COFFSET%%MOFFSET%%PLIMIT%%AUTO_UV%
if "%OC%"=="" goto run
net session >nul 2>&1
if not errorlevel 1 goto run
echo GPU clock settings need Administrator rights.
if not "%AUTO_ELEVATE%"=="1" goto noadmin
echo Asking Windows to reopen this window as Administrator...
powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs" >nul 2>&1 && exit /b
:noadmin
echo Not elevated: ffgs mines at the current clocks. Right-click start-saseulpool.bat, Run as administrator.

:run
if not exist "%~dp0logs" mkdir "%~dp0logs"
:loop
rem the console shows colors; logs\ffgs.log gets the same lines as plain text
"%~dp0ffgs.exe" %ARGS% %EXTRA% --log "%~dp0logs\ffgs.log"
echo ffgs exited with code %ERRORLEVEL%, restarting in 10 s (Ctrl+C to stop)
timeout /t 10 /nobreak >nul
goto loop
