@echo off
title SENTINEL DEPLOY

echo.
echo ==========================================
echo   SENTINEL OPS - GitHub Deploy Tool
echo ==========================================
echo.

git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERREUR: Git non installe
    pause
    exit /b 1
)

if not exist ".git" (
    echo ERREUR: Pas de repo Git ici
    pause
    exit /b 1
)

for /f %%i in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set BRANCH=%%i
for /f %%i in ('git remote get-url origin 2^>nul') do set REMOTE=%%i

echo Branche : %BRANCH%
echo Remote  : %REMOTE%
echo.

set COMMITMSG=update SENTINEL %date% %time:~0,5%
if not "%~1"=="" set COMMITMSG=%~1

echo Message : %COMMITMSG%
echo.

echo [1/4] Pull...
git pull origin %BRANCH% >nul 2>&1
echo OK

echo [2/4] Add...
git add -A
git diff --cached --quiet
if %errorlevel% equ 0 (
    echo Aucun changement a deployer.
    pause
    exit /b 0
)
git diff --cached --name-only

echo.
echo [3/4] Commit...
git commit -m "%COMMITMSG%"
if %errorlevel% neq 0 (
    echo ERREUR: Commit echoue
    pause
    exit /b 1
)

echo.
echo [4/4] Push vers GitHub...
git push origin %BRANCH%
if %errorlevel% neq 0 (
    echo ERREUR: Push echoue
    pause
    exit /b 1
)

echo.
echo ==========================================
echo DEPLOY REUSSI !
echo ==========================================
echo Commit : %COMMITMSG%
echo Remote : %REMOTE%
echo.
pause
