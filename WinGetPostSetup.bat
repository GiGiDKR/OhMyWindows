@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: Définir la taille de la fenêtre
:: mode con: cols=80 lines=30

set "ligne1============================="
set "ligne2=         OhMyWindows        "
set "ligne3============================="

echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.

:: Vérifier si Winget est déjà installé
where winget >nul 2>&1
if %errorlevel% equ 0 (
    echo Winget est déjà installé sur votre système.
    echo Appuyez sur une touche pour continuer...
    pause >nul
    goto :winget_installed
)

:: Vérifier et modifier la politique d'exécution PowerShell si nécessaire
powershell -Command "& {$policy = Get-ExecutionPolicy; if ($policy -eq 'Restricted') {Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; Write-Host 'Modified'} else {Write-Host 'OK'}}" > "%TEMP%\policy_check.txt" 2>nul
set /p policy_status=<"%TEMP%\policy_check.txt"
del "%TEMP%\policy_check.txt" >nul 2>&1

if "%policy_status%"=="Modified" (
    echo Politique d'exécution PowerShell modifiée.
    echo.
) else (

    echo Politique d'exécution PowerShell correctement configurée.
    echo.
)

:: Vérifier les privilèges d'administrateur
net session >nul 2>&1
if %errorLevel% == 0 (
    goto :admin
) else (
    echo Redémarrage en tant qu'administrateur...
    powershell -Command "Start-Process '%~dpnx0' -Verb RunAs" >nul 2>&1
    exit /b
)

:admin
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Installation de Winget
echo.

:: Créer un dossier temporaire
set "tempFolder=%TEMP%\WinGetInstall"
if not exist "%tempFolder%" mkdir "%tempFolder%" >nul 2>&1

:: Télécharger les fichiers nécessaires avec bitsadmin
echo ■ Téléchargement des fichiers nécessaires
start /wait bitsadmin /transfer WinGetDownload /dynamic /priority high ^
    https://aka.ms/getwinget "%tempFolder%\winget.msixbundle" ^
    https://aka.ms/Microsoft.VCLibs.x86.14.00.Desktop.appx "%tempFolder%\vclibs_x86.appx" ^
    https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx "%tempFolder%\vclibs_x64.appx" ^
    https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.7.3 "%tempFolder%\xaml.zip" >nul 2>&1

:: Extraire le fichier XAML
echo - Extraction des fichiers
powershell -Command "& {Expand-Archive -Path '%tempFolder%\xaml.zip' -DestinationPath '%tempFolder%\xaml'}" >nul 2>&1

:: Trouver le fichier APPX XAML
for /f "delims=" %%i in ('powershell -Command "& {Get-ChildItem -Path '%tempFolder%\xaml' -Recurse -Filter '*.appx' | Where-Object { $_.Name -like '*x64*' } | Select-Object -First 1 -ExpandProperty FullName}" 2^>nul') do set "xamlAppxPath=%%i"

:: Installer les dépendances
echo ■ Installation des dépendances
powershell -Command "& {Add-AppxPackage -Path '%tempFolder%\vclibs_x86.appx'}" >nul 2>&1
powershell -Command "& {Add-AppxPackage -Path '%tempFolder%\vclibs_x64.appx'}" >nul 2>&1
if defined xamlAppxPath powershell -Command "& {Add-AppxPackage -Path '!xamlAppxPath!'}" >nul 2>&1

:: Installer WinGet
echo - Installation de WinGet
powershell -Command "& {Add-AppxPackage -Path '%tempFolder%\winget.msixbundle'}" >nul 2>&1

:: Nettoyer les fichiers temporaires
echo - Nettoyage des fichiers temporaires
rmdir /s /q "%tempFolder%" >nul 2>&1

echo.
echo ○ Winget a été installé avec succès !
echo.
echo ► Appuyez sur une touche pour continuer
pause >nul
goto :winget_installed

:winget_installed
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.  
echo ■ Installation des programmes
echo.

echo 1 - Installer la présélection de programmes
echo 2 - Sélectionner des programmes
echo 3 - Appliquer les paramètres Windows
echo 4 - Quitter
echo.
set /p choix=Sélectionner une option : 

if %choix%==1 goto :install_preselection
if %choix%==2 goto :install_programmes
if %choix%==3 goto :apply_windows_settings
if %choix%==4 goto :end_of_script

:install_preselection
winget import packages-winget.json --accept-source-agreements --accept-package-agreements
goto :winget_installed

:install_programmes
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Sélection des programmes à installer
echo.

set "counter=1"
for /f "tokens=1,2 delims=|" %%a in (packages.txt) do (
    set "program[!counter!]=%%a|%%b"
    echo ◘ !counter! - %%a
    set /a "counter+=1"
)

set /a "total_programs=counter - 1"
echo.
echo Nombre total de programmes trouvés : %total_programs%
echo.
echo ◘ 0 - Retour au menu précédent
echo.
set /p choix=Sélectionnez les numéros des programmes à installer (séparés par des espaces) ou 0 pour revenir : 

if "%choix%"=="0" goto :winget_installed

for %%i in (%choix%) do (
    if defined program[%%i] (
        for /f "tokens=1,2 delims=|" %%a in ("!program[%%i]!") do (
            set "name=%%a"
            set "id=%%b"
        )
        echo Installation de !name!...
        winget install !id! --silent --accept-source-agreements --accept-package-agreements
        if !errorlevel! equ 0 (
            echo Installation de !name! réussie.
        ) else (
            echo Échec de l'installation de !name!.
        )
    ) else (
        echo Le programme numéro %%i n'existe pas dans la liste.
    )
)

echo.
echo Toutes les installations sont terminées.
echo Appuyez sur une touche pour revenir au menu...
pause >nul
goto :install_programmes

:apply_windows_settings
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Application des paramètres Windows
echo.
echo ► Appuyez sur une touche pour continuer
pause >nul

:: Vérifier si Blank.ico existe dans le dossier du script
if exist "%~dp0Blank.ico" (
    copy "%~dp0Blank.ico" "C:\Windows\Blank.ico" /Y
    set "shellIconValue=%%SystemRoot%%\Blank.ico,0"
) else (
    set "shellIconValue=%%windir%%\System32\imageres.dll,-17"
)

:: Créer le fichier .reg
(
echo Windows Registry Editor Version 5.00
echo.
echo ;Dark Mode
echo [HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize]
echo "AppsUseLightTheme"=dword:00000000
echo "SystemUsesLightTheme"=dword:00000000
echo "EnableTransparency"=dword:00000001
echo.
echo [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\History]
echo "AutoColor"=dword:00000001
echo.
echo ;Set Explore This PC
echo [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced]
echo "LaunchTo"=dword:00000001
echo.
echo ;Compact Mode 
echo [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced]
echo "UseCompactMode"=dword:00000001
echo.
echo ;Menu animation
echo [HKEY_CURRENT_USER\Control Panel\Desktop]
echo "MenuShowDelay"="50"
echo.
echo ;Wallpaper Quality Max
echo "JPEGImportQuality"=dword:00000064
echo.
echo ;Shortcut
echo [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer]
echo "link"=hex:00,00,00,00
echo.
echo [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons]
echo "29"="%shellIconValue%"
echo.
echo ;Show Copy More Details
echo [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager]
echo "EnthusiastMode"=dword:00000001
echo.
echo ;Start
echo [HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Explorer]
echo "HideRecentlyAddedApps"=dword:00000001
echo "ShowOrHideMostUsedApps"=dword:00000002
echo.
echo [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer]
echo "NoRecentDocsHistory"=dword:00000001
echo.
echo [HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced]
echo "Start_TrackDocs"=dword:00000000
echo.
echo [HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager]
echo "SubscribedContent-338388Enabled"=dword:00000000
echo.
echo ;Offline Maps
echo [HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Maps]
echo "AutoDownloadAndUpdateMapData"=dword:00000000
echo.
echo ;Disable Edge Desktop Icon
echo [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer]
echo "DisableEdgeDesktopShortcutCreation"=dword:00000001
echo.
echo ;Mouse acceleration
echo [HKEY_CURRENT_USER\Control Panel\Mouse]
echo "MouseSpeed"="1"
echo "MouseThreshold1"="6"
echo "MouseThreshold2"="10"
) > "%TEMP%\Windows_Settings.reg"

regedit /s "%TEMP%\Windows_Settings.reg"
del "%TEMP%\Windows_Settings.reg"

cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Redémarrage de l'explorateur
echo.
echo ► Appuyez sur une touche pour continuer
pause >nul

taskkill /F /IM explorer.exe
start explorer.exe
goto :end_of_script

:end_of_script
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ☺ Script terminé !
echo.
echo ► Appuyez sur une touche pour quitter
pause >nul

endlocal