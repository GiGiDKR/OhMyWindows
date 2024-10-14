@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "ligne1=============================================="
set "ligne2=               OhMyWindows                 "
set "ligne3=============================================="

:: Sauvegarder le chemin d'origine
if not defined ORIGINAL_PATH set "ORIGINAL_PATH=%~dp0"


:: Vérifier les privilèges administrateur et relancer si nécessaire
net session >nul 2>&1
if %errorLevel% == 0 (
    goto :admin_ok
) else (
    cls
    echo %ligne1%
    echo %ligne2%
    echo %ligne3%
    echo.
    echo Redémarrage en tant qu'administrateur
    powershell -Command "Start-Process '%~dpnx0' -Verb RunAs -ArgumentList '-ORIGINAL_PATH:%ORIGINAL_PATH%'" >nul 2>&1
    exit /b
)

:admin_ok
powershell -Command "& {$policy = Get-ExecutionPolicy; if ($policy -eq 'Restricted') {Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; Write-Host 'Modified'} else {Write-Host 'OK'}}" > "%TEMP%\policy_check.txt" 2>nul
set /p policy_status=<"%TEMP%\policy_check.txt"
del "%TEMP%\policy_check.txt" >nul 2>&1

if "%policy_status%"=="Modified" (
    echo Politique d'exécution PowerShell modifiée
    echo.
) else (

    echo Politique d'exécution PowerShell correctement configurée
    echo.
)

:: Définir la taille de la fenêtre
:: mode con: cols=80 lines=30

cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.

:version_winget
where winget >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=*" %%i in ('winget -v') do set "winget_version=%%i"
    echo ► Version de Winget : %winget_version%
    goto :check_windows_terminal
) else (
    echo x Winget n'est pas installé sur votre système
    goto :install_winget
)

:check_windows_terminal
if "%WT_SESSION%"=="" (
    where wt >nul 2>&1
    if %errorlevel% equ 0 (
        echo Windows Terminal est déjà installé
        echo Redémarrage du script dans Windows Terminal
        start wt "%~dpnx0"
        exit /b
    ) else (
        goto :install_windows_terminal
    )
)
goto :main_menu

:install_winget
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Installation de Winget
echo.

set "tempFolder=%TEMP%\WinGetInstall"
if not exist "%tempFolder%" mkdir "%tempFolder%" >nul 2>&1

echo - Téléchargement des fichiers nécessaires
start /wait bitsadmin /transfer WinGetDownload /dynamic /priority high ^
    https://aka.ms/getwinget "%tempFolder%\winget.msixbundle" ^
    https://aka.ms/Microsoft.VCLibs.x86.14.00.Desktop.appx "%tempFolder%\vclibs_x86.appx" ^
    https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx "%tempFolder%\vclibs_x64.appx" ^
    https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.7.3 "%tempFolder%\xaml.zip" >nul 2>&1

echo - Extraction des fichiers
powershell -Command "& {Expand-Archive -Path '%tempFolder%\xaml.zip' -DestinationPath '%tempFolder%\xaml'}" >nul 2>&1

for /f "delims=" %%i in ('powershell -Command "& {Get-ChildItem -Path '%tempFolder%\xaml' -Recurse -Filter '*.appx' | Where-Object { $_.Name -like '*x64*' } | Select-Object -First 1 -ExpandProperty FullName}" 2^>nul') do set "xamlAppxPath=%%i"

echo - Installation des dépendances
powershell -Command "& {Add-AppxPackage -Path '%tempFolder%\vclibs_x86.appx'}" >nul 2>&1
powershell -Command "& {Add-AppxPackage -Path '%tempFolder%\vclibs_x64.appx'}" >nul 2>&1
if defined xamlAppxPath powershell -Command "& {Add-AppxPackage -Path '!xamlAppxPath!'}" >nul 2>&1

echo - Installation de WinGet
powershell -Command "& {Add-AppxPackage -Path '%tempFolder%\winget.msixbundle'}" >nul 2>&1

echo - Nettoyage des fichiers temporaires
rmdir /s /q "%tempFolder%" >nul 2>&1

echo.
echo ► Winget a été installé avec succès !
call :version_winget
echo.
pause
goto :install_windows_terminal

:install_windows_terminal
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Installation de Windows Terminal
echo.
winget install Microsoft.WindowsTerminal --accept-source-agreements --accept-package-agreements
if %errorlevel% equ 0 (
    echo.
    echo ► Windows Terminal a été installé avec succès !
    echo Redémarrage du script dans Windows Terminal
    timeout /t 3 >nul
    start wt "%~dpnx0"
    exit /b
) else (
    echo.
    echo x Échec de l'installation de Windows Terminal
    echo Poursuite du script dans la fenêtre actuelle
    timeout /t 3 >nul
)

:main_menu
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.  
echo ■ Menu principal
echo.

echo 1 - Installation de programmes
echo 2 - Installation de Microsoft Store
echo 3 - Installation Microsoft Office
echo 4 - Fonctionnalités Windows
echo 5 - Activation de Windows / Office
echo 6 - WinUtil
echo 7 - Paramètres Windows
echo 8 - Nettoyage de Windows
echo 9 - Installer la police Meslo LGL Nerd
echo 10 - Configuration du profil PowerShell
echo.
echo 0 - Quitter
echo.
echo %ligne1%
echo.
set /p choix=■ Sélectionner une option : 

if "%choix%"=="1" goto :install_programmes
if "%choix%"=="2" goto :install_microsoft_store
if "%choix%"=="3" goto :install_microsoft_office
if "%choix%"=="4" goto :windows_features
if "%choix%"=="5" goto :activate_windows
if "%choix%"=="6" goto :winutil_menu
if "%choix%"=="7" goto :windows_settings_menu
if "%choix%"=="8" goto :clean_windows
if "%choix%"=="9" goto :install_fonts
if "%choix%"=="10" goto :configure_powershell_profile
if "%choix%"=="0" goto :end_of_script

echo.
echo Option invalide. Veuillez réessayer.
pause
goto :main_menu

:winutil_menu
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ WinUtil
echo.
echo 1 - Exécuter WinUtil
echo 2 - Installer WinUtil
echo.
echo 0 - Retour au menu principal
echo.
set /p winutil_choice=■ Sélectionner une option : 

if "%winutil_choice%"=="0" goto :main_menu
if "%winutil_choice%"=="1" goto :run_winutil
if "%winutil_choice%"=="2" goto :install_winutil

echo.
echo Option invalide. Veuillez réessayer.
pause
goto :winutil_menu

:run_winutil
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Exécution de WinUtil
echo.
powershell -Command "irm https://christitus.com/win | iex"
echo.
pause
goto :main_menu

:install_winutil
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Installation de WinUtil
echo.
call :create_winutil_shortcut
echo.
pause
goto :main_menu

:create_winutil_shortcut
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { $desktopPath = [Environment]::GetFolderPath('Desktop'); $shortcutPath = Join-Path $desktopPath 'winutil.lnk'; $shell = New-Object -ComObject WScript.Shell; $shortcut = $shell.CreateShortcut($shortcutPath); $shortcut.TargetPath = 'powershell.exe'; $shortcut.Arguments = '-NoProfile -ExecutionPolicy Bypass -Command ""irm https://christitus.com/win | iex""'; $shortcut.WorkingDirectory = $env:USERPROFILE; $winutilDir = Join-Path $env:LOCALAPPDATA 'WinUtil'; $iconPath = Join-Path $winutilDir 'cttlogo.ico'; if (-not (Test-Path $iconPath)) { New-Item -ItemType Directory -Force -Path $winutilDir | Out-Null; Invoke-WebRequest -Uri 'https://christitus.com/images/logo-full.ico' -OutFile $iconPath }; if (Test-Path $iconPath) { $shortcut.IconLocation = $iconPath }; $shortcut.Save(); $bytes = [System.IO.File]::ReadAllBytes($shortcutPath); $bytes[0x15] = $bytes[0x15] -bor 0x20; [System.IO.File]::WriteAllBytes($shortcutPath, $bytes)}"
if %errorlevel% equ 0 (
    echo ► Raccourci WinUtil créé sur le bureau
) else (
    echo x Échec de la création du raccourci WinUtil
)
goto :eof

:clean_windows
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Nettoyage de Windows
echo.

echo - Nettoyage des fichiers temporaires
del /q /f /s %TEMP%\* >nul 2>&1
del /q /f /s C:\Windows\Temp\* >nul 2>&1

echo - Exécution de Dism.exe
Dism.exe /online /Cleanup-Image /StartComponentCleanup >nul 2>&1

echo - Exécution de cleanmgr
start /wait cleanmgr /sagerun:1 >nul 2>&1

echo.
echo ► Nettoyage terminé
pause
goto :main_menu

:windows_settings_menu
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Paramètres Windows
echo.
echo 1 - Registre Windows
echo 2 - Fonds d'écran
echo.
echo 0 - Retour au menu principal
echo.
set /p settings_choice=■ Sélectionner une option : 

if "%settings_choice%"=="0" goto :main_menu
if "%settings_choice%"=="1" goto :apply_windows_settings
if "%settings_choice%"=="2" goto :wallpaper_dl

echo.
echo Option invalide. Veuillez réessayer
pause
goto :windows_settings_menu

:windows_features
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Fonctionnalités Windows
echo.
echo 1 - Hyper-V
echo 2 - Sandbox
echo 3 - .NET Framework 3.5
echo.
echo 0 - Retour au menu principal
echo.
set /p feature_choice=■ Sélectionner une option : 

if "%feature_choice%"=="0" goto :main_menu
if "%feature_choice%"=="1" goto :enable_hyperv
if "%feature_choice%"=="2" goto :enable_sandbox
if "%feature_choice%"=="3" goto :enable_dotnet35

echo.
echo Option invalide. Veuillez réessayer
pause
goto :windows_features

:enable_hyperv
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Installation de Hyper-V
DISM /Online /Enable-Feature /All /FeatureName:Microsoft-Hyper-V /NoRestart
if %errorlevel% equ 0 (
    echo.
    echo ► Hyper-V a été installé avec succès
    echo.
    echo Un redémarrage sera nécessaire pour finaliser l'installation
) else if %errorlevel% equ 3010 (
    echo.
    echo ► Hyper-V a été installé avec succès
    echo.
    echo Un redémarrage sera nécessaire pour finaliser l'installation
) else (
    echo.
    echo x Échec de l'installation de Hyper-V
)
echo.
pause
goto :windows_features

:enable_sandbox
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Installation de Windows Sandbox
DISM /Online /Enable-Feature /FeatureName:"Containers-DisposableClientVM" /All /NoRestart
if %errorlevel% equ 0 (
    echo ► Windows Sandbox a été installé avec succès
    echo.
    echo Un redémarrage sera nécessaire pour finaliser l'installation
) elseif %errorlevel% equ 3010 (
    echo ► Windows Sandbox a été installé avec succès
    echo.
    echo Un redémarrage sera nécessaire pour finaliser l'installation
) else (
    echo x Échec de l'installation de Windows Sandbox
)
echo.
pause
goto :windows_features

:enable_dotnet35
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Installation de .NET Framework 3.5
DISM /Online /Enable-Feature /FeatureName:NetFx3 /All /NoRestart
if %errorlevel% equ 0 (
    echo ► .NET Framework 3.5 a été installé avec succès
    echo.
    echo Un redémarrage peut être nécessaire pour finaliser l'installation
) else if %errorlevel% equ 3010 (
    echo ► .NET Framework 3.5 a été installé avec succès
    echo.
    echo Un redémarrage sera nécessaire pour finaliser l'installation
) else (
    echo x Échec de l'installation de .NET Framework 3.5
)
echo.
pause
goto :windows_features

:activate_windows
powershell -Command "irm https://get.activated.win | iex"
goto :main_menu

:install_programmes
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Sélection des programmes à installer
echo.

if not exist "%ORIGINAL_PATH%packages.txt" (
    powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/GiGiDKR/OhMyWindows/refs/heads/0.2.0/files/packages.txt' -OutFile '%ORIGINAL_PATH%packages.txt'"
)

set "counter=1"
for /f "tokens=1,2 delims=|" %%a in (%ORIGINAL_PATH%packages.txt) do (
    set "program[!counter!]=%%a|%%b"
    echo !counter! - %%a
    set /a "counter+=1"
)

set "program[!counter!]=Cleanmgr+|CUSTOM"
echo !counter! - Cleanmgr+

set /a "total_programs=counter"
echo.
echo 0 - Retour au menu principal
echo A - Installer tous les programmes
echo.
echo %ligne1%
echo.
set /p choix=■ Saisir les numéros (séparés par des espaces) : 

if "%choix%"=="0" goto :main_menu
if /i "%choix%"=="A" goto :install_all_programs

for %%i in (%choix%) do (
    if defined program[%%i] (
        for /f "tokens=1,2 delims=|" %%a in ("!program[%%i]!") do (
            set "name=%%a"
            set "id=%%b"
        )
        if "!id!"=="CUSTOM" (
            if "!name!"=="Cleanmgr+" (
                cls
                echo %ligne1%
                echo %ligne2%
                echo %ligne3%
                echo.
                echo - Installation de Cleanmgr+
                powershell -Command "& {$tempFile = [System.IO.Path]::GetTempFileName() + '.zip'; Invoke-WebRequest -Uri 'https://github.com/builtbybel/CleanmgrPlus/releases/download/1.50.1300/cleanmgrplus.zip' -OutFile $tempFile -ErrorAction SilentlyContinue | Out-Null; New-Item -ItemType Directory -Path 'C:\Program Files\Cleanmgr+' -Force -ErrorAction SilentlyContinue | Out-Null; Expand-Archive -Path $tempFile -DestinationPath 'C:\Program Files\Cleanmgr+' -Force -ErrorAction SilentlyContinue | Out-Null; $WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut([System.IO.Path]::Combine($env:USERPROFILE, 'Desktop', 'Cleanmgr+.lnk')); $Shortcut.TargetPath = 'C:\Program Files\Cleanmgr+\Cleanmgr+.exe'; $Shortcut.Save(); $Shell = New-Object -ComObject Shell.Application; $Folder = $Shell.Namespace('C:\Program Files\Cleanmgr+'); $Item = $Folder.ParseName('Cleanmgr+.exe'); if ($Item) { $Item.InvokeVerb('pin to start') }; Remove-Item $tempFile -Force -ErrorAction SilentlyContinue | Out-Null}" 2>nul
                if !errorlevel! equ 0 (
                    echo.
                    echo ► Installation de Cleanmgr+ réussie
                ) else (
                    echo.
                    echo x Échec de l'installation de Cleanmgr+
                )
            )
        ) else (
            cls
            echo %ligne1%
            echo %ligne2%
            echo %ligne3%
            echo.
            echo - Installation de !name!
            winget install !id! --silent --accept-source-agreements --accept-package-agreements
            if !errorlevel! equ 0 (
                echo.
                echo ► Installation de !name! réussie
            ) else (
                echo.
                echo x Échec de l'installation de !name!
            )
        )
    ) else (
        echo.
        echo x Le programme numéro %%i n'existe pas dans la liste.
    )
)

echo.
pause
goto :install_programmes

:install_all_programs
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Installation de tous les programmes
for /f "tokens=1,2 delims=|" %%a in (%ORIGINAL_PATH%packages.txt) do (
    echo.
    echo - Installation de %%a
    winget install %%b --silent --accept-source-agreements --accept-package-agreements
    if !errorlevel! equ 0 (
        echo ► Installation de %%a réussie
    ) else (
        echo x Échec de l'installation de %%a
    )
)

echo.
echo - Installation de Cleanmgr+
powershell -Command "Invoke-WebRequest -Uri 'https://github.com/builtbybel/CleanmgrPlus/releases/download/1.50.1300/cleanmgrplus.zip' -OutFile '$env:TEMP\cleanmgrplus.zip' -ErrorAction SilentlyContinue | Out-Null; New-Item -ItemType Directory -Path 'C:\Program Files\Cleanmgr+' -Force -ErrorAction SilentlyContinue | Out-Null; Expand-Archive -Path '$env:TEMP\cleanmgrplus.zip' -DestinationPath 'C:\Program Files\Cleanmgr+' -Force -ErrorAction SilentlyContinue | Out-Null; $WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('$env:USERPROFILE\Desktop\Cleanmgr+.lnk'); $Shortcut.TargetPath = 'C:\Program Files\Cleanmgr+\Cleanmgr+.exe'; $Shortcut.Save(); $Shell = New-Object -ComObject Shell.Application; $Folder = $Shell.Namespace('C:\Program Files\Cleanmgr+'); $Item = $Folder.ParseName('Cleanmgr+.exe'); $Item.InvokeVerb('pin to start'); Remove-Item '$env:TEMP\cleanmgrplus.zip' -Force -ErrorAction SilentlyContinue | Out-Null"
if !errorlevel! equ 0 (
    echo ► Installation de Cleanmgr+ réussie
) else (
    echo x Échec de l'installation de Cleanmgr+
)

echo.
pause
goto :main_menu

:apply_windows_settings
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Application des paramètres Windows
echo.
echo ■ Redémarrage de l'explorateur nécessaire
echo.
pause

if not exist "C:\Windows\Blank.ico" (
    if exist "%ORIGINAL_PATH%Blank.ico" (
        copy "%ORIGINAL_PATH%Blank.ico" "C:\Windows\Blank.ico" /Y
    ) else (
        powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/GiGiDKR/OhMyWindows/refs/heads/0.2.0/files/Blank.ico' -OutFile 'C:\Windows\Blank.ico'"
    )
)

if exist "C:\Windows\Blank.ico" (
    set "shellIconValue=C:\\Windows\\Blank.ico,0"
) else (
    set "shellIconValue=%windir%\\System32\\imageres.dll,-17"
)

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
echo [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes]
echo "CurrentTheme"="C:\\WINDOWS\\resources\\Themes\\dark.theme"
echo.
echo ;Visible Places
echo [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Start]
echo "VisiblePlaces"=hex:86,08,73,52,aa,51,43,42,9f,7b,27,76,58,46,59,d4
echo.
echo ;SearchboxTaskbarMode
echo [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Search]
echo "SearchboxTaskbarMode"=dword:00000000
echo.
echo ;ShowTaskViewButton
echo [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced]
echo "ShowTaskViewButton"=dword:00000000
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
echo ;Shell Icon
echo [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons]
echo "29"="!shellIconValue!"
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
echo ;No Recent Docs History
echo [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer]
echo "NoRecentDocsHistory"=dword:00000001
echo.
echo ;Start_TrackDocs
echo [HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced]
echo "Start_TrackDocs"=dword:00000000
echo.
echo ;Disable Subscribed Content
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

taskkill /F /IM explorer.exe
start explorer.exe
goto :main_menu

:install_microsoft_store
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Installation de Microsoft Store
echo.

powershell -Command "if (Get-AppxPackage Microsoft.WindowsStore) { exit 0 } else { exit 1 }" >nul 2>&1
if %errorlevel% equ 0 (
    echo x Microsoft Store est déjà installé
    echo.
    pause
    goto :main_menu 
) else (
    set "tempFolder=%TEMP%\MicrosoftStoreInstall"
    mkdir "%tempFolder%" 2>nul

    echo - Téléchargement des fichiers nécessaires
    start /wait bitsadmin /transfer MicrosoftStoreDownload /dynamic /priority high ^
        https://github.com/GiGiDKR/OhMyWindows/raw/refs/heads/0.2.0/files/LTSC-Add-MicrosoftStore-24H2/Microsoft.WindowsStore_8wekyb3d8bbwe.xml "%tempFolder%\Microsoft.WindowsStore_8wekyb3d8bbwe.xml" ^
        https://github.com/GiGiDKR/OhMyWindows/raw/refs/heads/0.2.0/files/LTSC-Add-MicrosoftStore-24H2/Microsoft.WindowsStore_8wekyb3d8bbwe.msixbundle "%tempFolder%\WindowsStore.msixbundle" ^
        https://github.com/GiGiDKR/OhMyWindows/raw/refs/heads/0.2.0/files/LTSC-Add-MicrosoftStore-24H2/Microsoft.NET.Native.Framework.x64.2.2.appx "%tempFolder%\Framework6X64.appx" ^
        https://github.com/GiGiDKR/OhMyWindows/raw/refs/heads/0.2.0/files/LTSC-Add-MicrosoftStore-24H2/Microsoft.NET.Native.Runtime.x64.2.2.appx "%tempFolder%\Runtime6X64.appx" ^
        https://github.com/GiGiDKR/OhMyWindows/raw/refs/heads/0.2.0/files/LTSC-Add-MicrosoftStore-24H2/Microsoft.StorePurchaseApp_8wekyb3d8bbwe.appxbundle "%tempFolder%\StorePurchaseApp.appxbundle" ^
        https://github.com/GiGiDKR/OhMyWindows/raw/refs/heads/0.2.0/files/LTSC-Add-MicrosoftStore-24H2/Microsoft.StorePurchaseApp_8wekyb3d8bbwe.xml "%tempFolder%\Microsoft.StorePurchaseApp_8wekyb3d8bbwe.xml" ^
        https://github.com/GiGiDKR/OhMyWindows/raw/refs/heads/0.2.0/files/LTSC-Add-MicrosoftStore-24H2/Microsoft.XboxIdentityProvider_8wekyb3d8bbwe.appxbundle "%tempFolder%\XboxIdentityProvider.appxbundle" ^
        https://github.com/GiGiDKR/OhMyWindows/raw/refs/heads/0.2.0/files/LTSC-Add-MicrosoftStore-24H2/Microsoft.XboxIdentityProvider_8wekyb3d8bbwe.xml "%tempFolder%\Microsoft.XboxIdentityProvider_8wekyb3d8bbwe.xml"

    echo - Installation de Microsoft Store et ses composants
    powershell -Command "Add-AppxProvisionedPackage -Online -PackagePath '%tempFolder%\WindowsStore.msixbundle' -DependencyPackagePath '%tempFolder%\Framework6X64.appx','%tempFolder%\Runtime6X64.appx' -LicensePath '%tempFolder%\Microsoft.WindowsStore_8wekyb3d8bbwe.xml' -ErrorAction SilentlyContinue | Out-Null"
    powershell -Command "Add-AppxPackage -Path '%tempFolder%\Framework6X64.appx' -ErrorAction SilentlyContinue | Out-Null"
    powershell -Command "Add-AppxPackage -Path '%tempFolder%\Runtime6X64.appx' -ErrorAction SilentlyContinue | Out-Null"
    powershell -Command "Add-AppxPackage -Path '%tempFolder%\WindowsStore.msixbundle' -ErrorAction SilentlyContinue | Out-Null"
    powershell -Command "Add-AppxProvisionedPackage -Online -PackagePath '%tempFolder%\StorePurchaseApp.appxbundle' -LicensePath '%tempFolder%\Microsoft.StorePurchaseApp_8wekyb3d8bbwe.xml' -ErrorAction SilentlyContinue | Out-Null"
    powershell -Command "Add-AppxProvisionedPackage -Online -PackagePath '%tempFolder%\XboxIdentityProvider.appxbundle' -LicensePath '%tempFolder%\Microsoft.XboxIdentityProvider_8wekyb3d8bbwe.xml' -ErrorAction SilentlyContinue | Out-Null"

    rmdir /s /q "%tempFolder%" 2>nul

    echo.
    echo ► Microsoft Store installé avec succès
    echo.
    pause
    goto :main_menu
)

:install_microsoft_office
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Installation de Microsoft Office
echo.

set "tempFolder=%TEMP%\MicrosoftOfficeInstall"
mkdir "%tempFolder%" 2>nul

echo - Téléchargement de Microsoft Office
start /wait bitsadmin /transfer OfficeSetupDownload /dynamic /priority high ^
    "https://c2rsetup.officeapps.live.com/c2r/download.aspx?ProductreleaseID=O365ProPlusRetail&platform=x64&language=fr-fr&version=O16GA" ^
    "%tempFolder%\OfficeSetup.exe"

if %errorlevel% equ 0 (
    echo - Installation de Microsoft Office
    start /wait "" "%tempFolder%\OfficeSetup.exe"
    if %errorlevel% equ 0 (
        echo.
        echo ► Microsoft Office installé avec succès
    ) else (    
        echo.
        echo x Échec de l'installation de Microsoft Office
    )
) else (
    echo.
    echo x Échec du téléchargement de Microsoft Office
)

echo - Nettoyage des fichiers temporaires
rmdir /s /q "%tempFolder%" 2>nul

echo.
pause
goto :main_menu

:wallpaper_dl
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Téléchargement et installation du fond d'écran
echo.

set "tempFolder=%TEMP%\WallpaperDownload"
set "extractFolder=C:\Users\%username%\Pictures\Wallpapers"
mkdir "%tempFolder%" 2>nul
mkdir "%extractFolder%" 2>nul

echo - Téléchargement du fond d'écran
start /wait bitsadmin /transfer WallpaperDownload /dynamic /priority high ^
    "https://github.com/GiGiDKR/OhMyWindows/raw/refs/heads/0.2.0/files/Wallpaper.zip" ^
    "%tempFolder%\Wallpaper.zip"

if %errorlevel% equ 0 (
    echo - Extraction du fond d'écran
    powershell -Command "Expand-Archive -Path '%tempFolder%\Wallpaper.zip' -DestinationPath '%extractFolder%' -Force"
    if %errorlevel% equ 0 (
        echo - Configuration du fond d'écran
        reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v WallPaper /t REG_SZ /d "C:\Users\%username%\Pictures\Wallpapers\purple.png" /f
        if %errorlevel% equ 0 (
            echo ► Fond d'écran installé avec succès
        ) else (     
            echo x Échec de la configuration du fond d'écran
        )
    ) else (
        echo x Échec de l'extraction du fond d'écran
    )
) else (
    echo x Échec du téléchargement du fond d'écran
)

echo - Nettoyage des fichiers temporaires
rmdir /s /q "%tempFolder%" 2>nul

echo.
pause
goto :main_menu

:install_fonts
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Installation de la police Meslo LGL Nerd
echo.

set "tempFolder=%TEMP%\Font"
set "fontUrl=https://github.com/GiGiDKR/OhMyWindows/raw/refs/heads/0.2.0/files/MesloLGLNerdFont.zip"
set "fontZip=%tempFolder%\MesloLGLNerdFont.zip"
set "extractFolder=%tempFolder%\MesloLGLNerdFont"

mkdir "%tempFolder%" 2>nul
mkdir "%extractFolder%" 2>nul

echo - Téléchargement des polices
powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%fontUrl%' -OutFile '%fontZip%' }"

if %errorlevel% equ 0 (
    echo - Extraction des polices
    powershell -Command "Expand-Archive -Path '%fontZip%' -DestinationPath '%extractFolder%' -Force"
    if %errorlevel% equ 0 (
        echo - Installation des polices
        for %%F in ("%extractFolder%\*.ttf") do (
            powershell -Command "& { Add-Type -AssemblyName System.Drawing; $fontCollection = New-Object System.Drawing.Text.PrivateFontCollection; $fontCollection.AddFontFile('%%F'); $fontName = $fontCollection.Families[0].Name; $shell = New-Object -ComObject Shell.Application; $destination = $shell.Namespace(0x14); $destination.CopyHere('%%F', 0x10); }"
        )
        echo - Nettoyage des fichiers temporaires
        rmdir /s /q "%extractFolder%" 2>nul
        echo.
        echo ► Polices installées avec succès
    ) else (
        echo x Échec de l'extraction des polices
    )
) else (
    echo.
    echo x Échec du téléchargement des polices
)

echo.
pause
goto :main_menu

:configure_powershell_profile
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Configuration du profil PowerShell
echo.

echo - Installation des modules PowerShell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; if (!(Get-Module -ListAvailable -Name PowerShellGet)) { Install-Module -Name PowerShellGet -Force -Scope CurrentUser -AllowClobber }; Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted; Install-Module oh-my-posh -Scope CurrentUser -Force -AllowClobber; Install-Module -Name Terminal-Icons -Scope CurrentUser -Force -AllowClobber; Install-Module -Name PSReadLine -Force -SkipPublisherCheck -AllowClobber; Install-Module -Name Z -Scope CurrentUser -Force -AllowClobber; Install-Module posh-git -Scope CurrentUser -Force -AllowClobber; Install-Module -Name PSFzf -Scope CurrentUser -Force -AllowClobber }"

echo - Installation de fzf
winget install fzf --accept-source-agreements --accept-package-agreements >nul 2>&1

echo - Téléchargement du profil PowerShell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { $profilePath = Join-Path $env:USERPROFILE 'Documents\PowerShell'; if (-not (Test-Path $profilePath)) { New-Item -ItemType Directory -Path $profilePath -Force | Out-Null }; $profileFile = Join-Path $profilePath 'Microsoft.PowerShell_profile.ps1'; Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/GiGiDKR/OhMyWindows/refs/heads/0.2.0/files/PowerShell/Microsoft.PowerShell_profile.ps1' -OutFile $profileFile }"

if %errorlevel% equ 0 (
    echo.
    echo ► Profil PowerShell configuré avec succès
) else (
    echo.
    echo x Échec de la configuration du profil PowerShell
)

echo.
pause
goto :main_menu

:end_of_script
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ► Script terminé !
echo.
pause

endlocal