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
    goto :packages_manager
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

:packages_manager
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Installation des gestionnaires de paquets
echo.

echo - Installation de Winget
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
echo - Installation de Chocolatey
powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"

if %errorlevel% equ 0 (
    echo.
    echo ► Chocolatey a été installé avec succès !
    echo.
    choco --version
) else (
    echo.
    echo x Échec de l'installation de Chocolatey
)

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
    echo.
    echo Redémarrage du script dans Windows Terminal
    timeout /t 2 >nul
    start wt "%~dpnx0"
    exit /b
) else (
    echo.
    echo x Échec de l'installation de Windows Terminal
    echo Poursuite du script dans la fenêtre actuelle
    timeout /t 2 >nul
)

:main_menu
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.  
echo ■ Menu principal
echo.

echo 1 - Installation programmes
echo 2 - Installation Microsoft Store
echo 3 - Installation Microsoft Office
echo 4 - Fonctionnalités Windows
echo 5 - Activation Windows / Office
echo 6 - Optimiser Windows
echo 7 - Paramètres Windows
echo 8 - Nettoyage Windows
echo 9 - Configuration Terminal
echo 10 - Configuration programmes
echo 11 - Mise à jour programmes
echo 12 - Outils Android

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
if "%choix%"=="6" goto :optimize_windows
if "%choix%"=="7" goto :windows_settings_menu
if "%choix%"=="8" goto :clean_windows
if "%choix%"=="9" goto :configure_terminal
if "%choix%"=="10" goto :configure_programs
if "%choix%"=="11" goto :update_programs
if "%choix%"=="12" goto :android_tools
if "%choix%"=="0" goto :end_of_script

echo.
echo Option invalide. Veuillez réessayer.
pause
goto :main_menu

:optimize_windows
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Optimiser Windows
echo.
echo 1 - WinUtil
echo 2 - Optimizer
echo.
echo 0 - Retour au menu principal
echo.
set /p optimize_choice=■ Sélectionner une option : 

if "%optimize_choice%"=="0" goto :main_menu
if "%optimize_choice%"=="1" goto :winutil_menu
if "%optimize_choice%"=="2" goto :install_optimizer

echo.
echo Option invalide. Veuillez réessayer.
pause
goto :optimize_windows

:install_optimizer
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Installation et exécution d'Optimizer
echo.

set "install_dir=C:\Program Files\Optimizer"
mkdir "%install_dir%" 2>nul

echo - Téléchargement d'Optimizer
powershell -Command "& { $latestRelease = (Invoke-WebRequest -Uri 'https://api.github.com/repos/hellzerg/optimizer/releases/latest' | ConvertFrom-Json); $downloadUrl = $latestRelease.assets | Where-Object { $_.name -like '*.exe' } | Select-Object -ExpandProperty browser_download_url; Invoke-WebRequest -Uri $downloadUrl -OutFile '%install_dir%\Optimizer.exe' }"

if %errorlevel% equ 0 (
    echo.
    echo ► Optimizer téléchargé avec succès

    :: Création du raccourci sur le bureau
    powershell -Command "& { $WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut($env:USERPROFILE + '\Desktop\Optimizer.lnk'); $Shortcut.TargetPath = '%install_dir%\Optimizer.exe'; $Shortcut.WorkingDirectory = '%install_dir%'; $Shortcut.Save() }"

    echo  Création d'un raccourci

    :: Création du désinstallateur
    echo @echo off > "%install_dir%\uninstall.bat"
    echo taskkill /F /IM Optimizer.exe 2^>nul >> "%install_dir%\uninstall.bat"
    echo rmdir /s /q "%install_dir%" >> "%install_dir%\uninstall.bat"
    echo reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Optimizer" /f >> "%install_dir%\uninstall.bat"
    echo del "%USERPROFILE%\Desktop\Optimizer.lnk" >> "%install_dir%\uninstall.bat"
    echo exit >> "%install_dir%\uninstall.bat"

    :: Ajout des informations de désinstallation dans le registre
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Optimizer" /v "DisplayName" /t REG_SZ /d "Optimizer" /f
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Optimizer" /v "UninstallString" /t REG_SZ /d "\"%install_dir%\uninstall.bat\"" /f
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Optimizer" /v "DisplayIcon" /t REG_SZ /d "%install_dir%\Optimizer.exe" /f
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Optimizer" /v "Publisher" /t REG_SZ /d "Hellzerg" /f

    echo ► Création d'un désinstallateur
    
    start "" "%install_dir%\Optimizer.exe"
) else (
    echo x Échec du téléchargement d'Optimizer
)

echo.
pause
goto :optimize_windows

:winutil_menu
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Installation et exécution de WinUtil
echo.

call :create_winutil_shortcut

powershell -Command "irm https://christitus.com/win | iex"

echo.
pause
goto :main_menu

:create_winutil_shortcut
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { $desktopPath = [Environment]::GetFolderPath('Desktop'); $shortcutPath = Join-Path $desktopPath 'WinUtil.lnk'; $shell = New-Object -ComObject WScript.Shell; $shortcut = $shell.CreateShortcut($shortcutPath); $shortcut.TargetPath = 'powershell.exe'; $shortcut.Arguments = '-NoProfile -ExecutionPolicy Bypass -Command ""irm https://christitus.com/win | iex""'; $shortcut.WorkingDirectory = $env:USERPROFILE; $winutilDir = Join-Path $env:LOCALAPPDATA 'WinUtil'; $iconPath = Join-Path $winutilDir 'cttlogo.ico'; if (-not (Test-Path $iconPath)) { New-Item -ItemType Directory -Force -Path $winutilDir | Out-Null; Invoke-WebRequest -Uri 'https://christitus.com/images/logo-full.ico' -OutFile $iconPath }; if (Test-Path $iconPath) { $shortcut.IconLocation = $iconPath }; $shortcut.Save(); $bytes = [System.IO.File]::ReadAllBytes($shortcutPath); $bytes[0x15] = $bytes[0x15] -bor 0x20; [System.IO.File]::WriteAllBytes($shortcutPath, $bytes)}"
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
echo 2 - Fond d'écran
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
echo 4 - Sous-système Windows pour Linux
echo.
echo 0 - Retour au menu principal
echo.
set /p feature_choice=■ Sélectionner une option : 

if "%feature_choice%"=="0" goto :main_menu
if "%feature_choice%"=="1" goto :enable_hyperv
if "%feature_choice%"=="2" goto :enable_sandbox
if "%feature_choice%"=="3" goto :enable_dotnet35
if "%feature_choice%"=="4" goto :enable_wsl

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
    echo ► Windows Sandbox a t install avec succs
    echo.
    echo Un redémarrage sera nécessaire pour finaliser l'installation
) elseif %errorlevel% equ 3010 (
    echo ► Windows Sandbox a été installé avec succès
    echo.
    echo Un redmarrage sera ncessaire pour finaliser l'installation
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
    echo ► .NET Framework 3.5 a t install avec succs
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

:enable_wsl
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Installation du Sous-système Windows pour Linux (WSL)
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
if %errorlevel% equ 0 (
    echo.
    echo ► WSL a été activé avec succès
    echo.
    echo Un redémarrage sera nécessaire pour finaliser l'installation
) else if %errorlevel% equ 3010 (
    echo.
    echo ► WSL a été activé avec succès
    echo.
    echo Un redémarrage sera nécessaire pour finaliser l'installation
) else (
    echo.
    echo x Échec de l'activation de WSL
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

if not exist "%ORIGINAL_PATH%packages.json" (
    powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/GiGiDKR/OhMyWindows/refs/heads/0.3.0/files/packages.json' -OutFile '%ORIGINAL_PATH%packages.json'"
)

set "counter=1"
for /f "tokens=* usebackq delims=" %%a in (`powershell -Command "Get-Content '%ORIGINAL_PATH%packages.json' | ConvertFrom-Json | Select-Object -ExpandProperty packages | ForEach-Object { $counter = 1 } { $_.name + '|' + $_.id + '|' + $_.source + '|' + ($counter++) }"`) do (
    for /f "tokens=1-4 delims=|" %%b in ("%%a") do (
        set "program[!counter!]=%%b|%%c|%%d"
        echo !counter! - %%b
        set /a "counter+=1"
    )
)

set /a "total_programs=counter-1"
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
        for /f "tokens=1,2,3 delims=|" %%a in ("!program[%%i]!") do (
            set "name=%%a"
            set "id=%%b"
            set "source=%%c"
        )
        call :install_programme "!name!" "!id!" "!source!"
    ) else (
        echo.
        echo x Le programme numéro %%i n'existe pas dans la liste.
    )
)

echo.
pause
goto :install_programmes

:install_programme
set "programme_name=%~1"
set "programme_id=%~2"
set "programme_source=%~3"

cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Installation de %programme_name%
echo.

:: Initialiser la barre de progression
set "progress=0"

:: Créer un fichier PowerShell temporaire pour l'installation
echo $ErrorActionPreference = 'Stop' > "%TEMP%\install_script.ps1"
echo try { >> "%TEMP%\install_script.ps1"
if "%programme_source%"=="winget" (
    echo     winget install %programme_id% --silent --accept-source-agreements --accept-package-agreements >> "%TEMP%\install_script.ps1"
) else if "%programme_source%"=="choco" (
    echo     choco install %programme_id% -y >> "%TEMP%\install_script.ps1"
)
echo     Write-Host "Installation completed successfully" >> "%TEMP%\install_script.ps1"
echo } catch { >> "%TEMP%\install_script.ps1"
echo     Write-Host "Error: $($_.Exception.Message)" >> "%TEMP%\install_script.ps1"
echo     exit 1 >> "%TEMP%\install_script.ps1"
echo } >> "%TEMP%\install_script.ps1"

:: Exécuter le script PowerShell
powershell -NoProfile -ExecutionPolicy Bypass -File "%TEMP%\install_script.ps1" > "%TEMP%\install_output.txt" 2>&1

:: Afficher une barre de progression simulée
for /l %%i in (0,10,100) do (
    cls
    echo %ligne1%
    echo %ligne2%
    echo %ligne3%
    echo.
    echo ■ Installation de %programme_name%
    echo.
    call :draw_progress_bar %%i
    timeout /t 1 >nul
)

:: Vérifier le résultat de l'installation
findstr /C:"Installation completed successfully" "%TEMP%\install_output.txt" >nul
if %errorlevel% equ 0 (
    cls
    echo %ligne1%
    echo %ligne2%
    echo %ligne3%
    echo.
    echo ■ Installation de %programme_name%
    echo.
    call :draw_progress_bar 100
    echo.
    echo ► Installation de %programme_name% réussie
) else (
    cls
    echo %ligne1%
    echo %ligne2%
    echo %ligne3%
    echo.
    echo ■ Installation de %programme_name%
    echo.
    call :draw_progress_bar 100
    echo.
    echo x Échec de l'installation de %programme_name%
    type "%TEMP%\install_output.txt"
)

:: Nettoyer les fichiers temporaires
del "%TEMP%\install_script.ps1" 2>nul
del "%TEMP%\install_output.txt" 2>nul

goto :eof

:draw_progress_bar
setlocal enabledelayedexpansion
set /a filled=(%1+1)/3
set "bar=□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□"
set "fillbar=■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■"
set "progress_bar=!fillbar:~0,%filled%!!bar:~%filled%!"
echo [!progress_bar!] %1%%
endlocal
goto :eof

:install_all_programs
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Installation de tous les programmes
powershell -Command "Get-Content '%ORIGINAL_PATH%packages.json' | ConvertFrom-Json | Select-Object -ExpandProperty packages | ForEach-Object { $name = $_.name; $id = $_.id; $source = $_.source; Write-Host ''; Write-Host '- Installation de ' $name; if ($source -eq 'winget') { $result = winget install $id --silent --accept-source-agreements --accept-package-agreements; if ($LASTEXITCODE -eq 0) { Write-Host '► Installation de ' $name ' réussie' } elseif ($LASTEXITCODE -eq -1978335189) { Write-Host '► La dernière version de ' $name ' est déjà installée' } else { Write-Host 'x Échec de l''installation de ' $name } } elseif ($source -eq 'choco') { $result = choco install $id -y -f; if ($LASTEXITCODE -eq 0) { Write-Host '► Installation de ' $name ' réussie' } elseif ($LASTEXITCODE -eq 3010) { Write-Host '► La dernière version de ' $name ' est déjà installée' } else { Write-Host 'x Échec de l''installation de ' $name } } elseif ($source -eq 'exe') { & cmd /c call :install_custom_exe '$name' '$id' } elseif ($source -eq 'zip') { & cmd /c call :install_custom_archive '$name' '$id' } else { Write-Host 'Source inconnue pour ' $name } }"

echo.
pause
goto :main_menu

:install_custom_exe
set "program_name=%~1"
set "program_url=%~2"
set "install_dir=C:\Program Files\%program_name%"

mkdir "%install_dir%" 2>nul
powershell -Command "& { Invoke-WebRequest -Uri '%program_url%' -OutFile '%install_dir%\%program_name%.exe' }"
if %errorlevel% equ 0 (
    echo - Création du raccourci sur le bureau
    powershell -Command "& { $WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut([System.IO.Path]::Combine($env:USERPROFILE, 'Desktop', '%program_name%.lnk')); $Shortcut.TargetPath = '%install_dir%\%program_name%.exe'; $Shortcut.Save() }"
goto :eof
)

:install_custom_archive
set "program_name=%~1"
set "program_url=%~2"
set "temp_dir=%TEMP%\%program_name%_install"
set "install_dir=C:\Program Files\%program_name%"

mkdir "%temp_dir%" 2>nul
powershell -Command "& { Invoke-WebRequest -Uri '%program_url%' -OutFile '%temp_dir%\archive.zip'; Expand-Archive -Path '%temp_dir%\archive.zip' -DestinationPath '%temp_dir%' -Force; $extractedFolder = Get-ChildItem -Path '%temp_dir%' -Directory | Select-Object -First 1; Move-Item -Path $extractedFolder.FullName -Destination '%install_dir%' -Force }"
if %errorlevel% equ 0 (
    echo - Création du raccourci sur le bureau
    powershell -Command "& { $WshShell = New-Object -ComObject WScript.Shell; $exeFile = Get-ChildItem -Path '%install_dir%' -Recurse -Filter '*.exe' | Where-Object { $_.Name -like '*%program_name%*' } | Select-Object -First 1; if ($exeFile) { $Shortcut = $WshShell.CreateShortcut([System.IO.Path]::Combine($env:USERPROFILE, 'Desktop', '%program_name%.lnk')); $Shortcut.TargetPath = $exeFile.FullName; $Shortcut.WorkingDirectory = $exeFile.DirectoryName; $Shortcut.Save(); echo '► Raccourci créé pour ' + $exeFile.Name } else { echo 'x Aucun exécutable correspondant trouvé pour %program_name%' } }"
)

rmdir /s /q "%temp_dir%" 2>nul
goto :eof

:apply_windows_settings
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Application des paramètres Windows
echo.
echo - Redémarrage de l'explorateur nécessaire
echo.
pause

if not exist "C:\Windows\Blank.ico" (
    if exist "%ORIGINAL_PATH%Blank.ico" (
        copy "%ORIGINAL_PATH%Blank.ico" "C:\Windows\Blank.ico" /Y
    ) else (
        powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/GiGiDKR/OhMyWindows/refs/heads/0.3.0/files/Blank.ico' -OutFile 'C:\Windows\Blank.ico'"
    )
)

if exist "C:\Windows\Blank.ico" (
    set "shellIconValue=C:\\Windows\\Blank.ico,0"
) else (
    set "shellIconValue=%windir%\\System32\\imageres.dll,-17"
)

echo.
pause
goto :main_menu

:android_tools
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Outils Android
echo.
echo 1 - ADB
echo 2 - Scrcpy
echo 3 - Odin 3
echo 4 - SamFwTool
echo 5 - Pixel Flasher
echo.
echo 0 - Retour au menu principal
echo.
set /p android_choice=■ Sélectionner une option : 

if "%android_choice%"=="0" goto :main_menu
if "%android_choice%"=="1" goto :install_adb
if "%android_choice%"=="2" goto :install_scrcpy
if "%android_choice%"=="3" goto :install_odin3
if "%android_choice%"=="4" goto :install_samfwtool
if "%android_choice%"=="5" goto :install_pixel_flasher

echo.
echo Option invalide. Veuillez réessayer.
pause
goto :android_tools

:install_adb
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Installation de ADB
echo.
set "tempFolder=%TEMP%\ADBInstall"
set "adbUrl=https://dl.google.com/android/repository/platform-tools-latest-windows.zip?hl=fr"
set "adbZip=%tempFolder%\platform-tools.zip"
set "adbDestination=C:\Android\adb"

mkdir "%tempFolder%" 2>nul
mkdir "C:\Android" 2>nul

powershell -Command "& { Invoke-WebRequest -Uri '%adbUrl%' -OutFile '%adbZip%' } | Out-Null"
powershell -Command "& { Expand-Archive -Path '%adbZip%' -DestinationPath '%tempFolder%' -Force } | Out-Null"

:: Renommer et déplacer le dossier
move "%tempFolder%\platform-tools" "%adbDestination%" >nul 2>&1

setx PATH "%PATH%;%adbDestination%" /M >nul 2>&1

if %errorlevel% equ 0 (
    echo ► ADB installé avec succès
    
    :: Création du désinstallateur
    echo @echo off > "%adbDestination%\uninstall.bat"
    echo setx PATH "%%PATH:%adbDestination%;=%%" /M >> "%adbDestination%\uninstall.bat"
    echo rmdir /s /q "%adbDestination%" >> "%adbDestination%\uninstall.bat"
    echo reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\ADB" /f >> "%adbDestination%\uninstall.bat"
    echo exit >> "%adbDestination%\uninstall.bat"

    :: Ajout des informations de désinstallation dans le registre
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\ADB" /v "DisplayName" /t REG_SZ /d "Android Debug Bridge (ADB)" /f
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\ADB" /v "UninstallString" /t REG_SZ /d "\"%adbDestination%\uninstall.bat\"" /f
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\ADB" /v "DisplayIcon" /t REG_SZ /d "%adbDestination%\adb.exe" /f
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\ADB" /v "Publisher" /t REG_SZ /d "Google LLC" /f

    echo ► Création d'un désinstallateur
) else (
    echo x Échec de l'installation de ADB
)

rmdir /s /q "%tempFolder%" 2>nul
echo.
pause
goto :android_tools

:install_scrcpy
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Installation de Scrcpy
echo.
set "tempFolder=%TEMP%\ScrcpyInstall"
set "scrcpyApiUrl=https://api.github.com/repos/Genymobile/scrcpy/releases/latest"
set "scrcpyZip=%tempFolder%\scrcpy.zip"
set "scrcpyDestination=C:\Android\scrcpy"

mkdir "%tempFolder%" 2>nul
mkdir "C:\Android" 2>nul

powershell -Command "& { $latestRelease = Invoke-RestMethod -Uri '%scrcpyApiUrl%'; $asset = $latestRelease.assets | Where-Object { $_.name -like 'scrcpy-win64-v*.zip' } | Select-Object -First 1; if ($asset) { if (Test-Path '%scrcpyDestination%') { Write-Host '► Scrcpy est déjà installé' } else { Invoke-WebRequest -Uri $asset.browser_download_url -OutFile '%scrcpyZip%'; if (Test-Path '%scrcpyZip%') { Expand-Archive -Path '%scrcpyZip%' -DestinationPath '%tempFolder%' -Force; $extractedFolder = Get-ChildItem -Path '%tempFolder%' -Directory | Select-Object -First 1; if ($extractedFolder) { Move-Item -Path $extractedFolder.FullName -Destination '%scrcpyDestination%' -Force; Write-Host '► Scrcpy installé avec succès' } else { Write-Host 'x Dossier extrait non trouvé' } } else { Write-Host 'x Échec du tléchargement' } } } else { Write-Host 'x Asset non trouvé' } }"

if exist "%scrcpyDestination%" (
    setx PATH "%PATH%;%scrcpyDestination%" /M >nul 2>&1

    :: Création du désinstallateur
    echo @echo off > "%scrcpyDestination%\uninstall.bat"
    echo setx PATH "%%PATH:%scrcpyDestination%;=%%" /M >> "%scrcpyDestination%\uninstall.bat"
    echo rmdir /s /q "%scrcpyDestination%" >> "%scrcpyDestination%\uninstall.bat"
    echo reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Scrcpy" /f >> "%scrcpyDestination%\uninstall.bat"
    echo exit >> "%scrcpyDestination%\uninstall.bat"

    :: Ajout des informations de désinstallation dans le registre
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Scrcpy" /v "DisplayName" /t REG_SZ /d "Scrcpy" /f
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Scrcpy" /v "UninstallString" /t REG_SZ /d "\"%scrcpyDestination%\uninstall.bat\"" /f
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Scrcpy" /v "DisplayIcon" /t REG_SZ /d "%scrcpyDestination%\scrcpy.exe" /f
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Scrcpy" /v "Publisher" /t REG_SZ /d "Genymobile" /f

    echo ► Création d'un désinstallateur
)

rmdir /s /q "%tempFolder%" 2>nul
echo.
goto :eof

:install_odin3
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Installation de Odin 3
echo.
set "tempFolder=%TEMP%\Odin3Install"
set "odin3Url=https://samfw.com/Odin/Samfw.com_Odin3_v3.14.4.zip"
set "odin3Zip=%tempFolder%\odin3.zip"
set "odin3Destination=C:\Android\Odin 3"

mkdir "%tempFolder%" 2>nul
mkdir "C:\Android" 2>nul

powershell -Command "& { Invoke-WebRequest -Uri '%odin3Url%' -OutFile '%odin3Zip%' }"
powershell -Command "& { Expand-Archive -Path '%odin3Zip%' -DestinationPath '%tempFolder%' -Force }"

:: Renommer et déplacer le dossier
move "%tempFolder%\Samfw.com_Odin3_v3.14.4" "%odin3Destination%" >nul 2>&1

if %errorlevel% equ 0 (
    echo ► Odin 3 installé avec succès
    
    :: Création du raccourci sur le bureau
    powershell -Command "& { $WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut($env:USERPROFILE + '\Desktop\Odin 3.lnk'); $Shortcut.TargetPath = '%odin3Destination%\Odin3_v3.14.4_Samfw.com.exe'; $Shortcut.WorkingDirectory = '%odin3Destination%'; $Shortcut.Save() }"
    
    if %errorlevel% equ 0 (
        echo ► Création d'un raccourci
    ) else (
        echo x Échec de la création du raccourci
    )

    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Odin3" /v "DisplayName" /t REG_SZ /d "Odin 3" /f
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Odin3" /v "DisplayVersion" /t REG_SZ /d "3.14.4" /f
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Odin3" /v "Publisher" /t REG_SZ /d "SamFW" /f
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Odin3" /v "UninstallString" /t REG_SZ /d "\"C:\Android\Odin 3\uninstall.bat\"" /f

    echo @echo off > "%odin3Destination%\uninstall.bat"
    echo rmdir /s /q "%odin3Destination%" >> "%odin3Destination%\uninstall.bat"
    echo reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Odin3" /f >> "%odin3Destination%\uninstall.bat"
    echo del "%USERPROFILE%\Desktop\Odin 3.lnk" >> "%odin3Destination%\uninstall.bat"
    echo exit >> "%odin3Destination%\uninstall.bat"

    echo ► Création d'un désinstallateur
) else (
    echo x Échec de l'installation de Odin 3
)

rmdir /s /q "%tempFolder%" 2>nul
echo.
goto :eof

:install_samfwtool
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Installation de SamFwTool
echo.
set "tempFolder=%TEMP%\SamFwToolInstall"
set "samfwToolUrl=https://samfw.com/SamFwToolSetup_v4.9.zip"
set "samfwToolZip=%tempFolder%\samfwtool.zip"

mkdir "%tempFolder%" 2>nul

powershell -Command "& { Invoke-WebRequest -Uri '%samfwToolUrl%' -OutFile '%samfwToolZip%' }"
powershell -Command "& { Expand-Archive -Path '%samfwToolZip%' -DestinationPath '%tempFolder%' -Force }"
start /wait "" "%tempFolder%\SamFwToolSetup.exe" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-

if %errorlevel% equ 0 (
    echo ► SamFwTool installé avec succès
) else (
    echo x Échec de l'installation de SamFwTool
)

rmdir /s /q "%tempFolder%" 2>nul
echo.
goto :eof

:install_pixel_flasher
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Installation de Pixel Flasher
echo.
set "pixelFlasherDestination=C:\Android\Pixel Flasher"

mkdir "%pixelFlasherDestination%" 2>nul

powershell -Command "& { $releases = Invoke-RestMethod -Uri 'https://api.github.com/repos/badabing2005/PixelFlasher/releases/latest'; $asset = $releases.assets | Where-Object { $_.name -like '*.exe' } | Select-Object -First 1; Invoke-WebRequest -Uri $asset.browser_download_url -OutFile '%pixelFlasherDestination%\PixelFlasher.exe' }"

if %errorlevel% equ 0 (
    echo ► Pixel Flasher installé avec succès

    powershell -Command "& { $WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut($env:USERPROFILE + '\Desktop\Pixel Flasher.lnk'); $Shortcut.TargetPath = '%pixelFlasherDestination%\PixelFlasher.exe'; $Shortcut.Save() }"

    if %errorlevel% equ 0 (
        echo ► Création d'un raccourci
    ) else (
        echo x Échec de la création du raccourci
    )

    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\PixelFlasher" /v "DisplayName" /t REG_SZ /d "Pixel Flasher" /f
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\PixelFlasher" /v "DisplayVersion" /t REG_SZ /d "7.5.0.0" /f
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\PixelFlasher" /v "Publisher" /t REG_SZ /d "Badabing" /f
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\PixelFlasher" /v "UninstallString" /t REG_SZ /d "\"C:\Android\Pixel Flasher\uninstall.bat\"" /f

    echo @echo off > "%pixelFlasherDestination%\uninstall.bat"
    echo rmdir /s /q "%pixelFlasherDestination%" >> "%pixelFlasherDestination%\uninstall.bat"
    echo reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\PixelFlasher" /f >> "%pixelFlasherDestination%\uninstall.bat"
    echo del "%USERPROFILE%\Desktop\Pixel Flasher.lnk" >> "%pixelFlasherDestination%\uninstall.bat"
    echo exit >> "%pixelFlasherDestination%\uninstall.bat"

    echo ► Création d'un désinstallateur
) else (
    echo x Échec de l'installation de Pixel Flasher
)

echo.
goto :eof

:configure_programs
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Configuration des programmes
echo.
echo 1 - Nilesoft Shell
echo 2 - Flow Launcher
echo 3 - 7-Zip
echo.
echo 0 - Retour au menu principal
echo.
set /p config_choice=■ Sélectionner une option : 

if "%config_choice%"=="0" goto :main_menu
if "%config_choice%"=="1" goto :configure_nilesoft_shell
if "%config_choice%"=="2" goto :configure_flow_launcher
if "%config_choice%"=="3" goto :configure_7zip

echo.
echo Option invalide. Veuillez réessayer
pause
goto :configure_programs

:configure_nilesoft_shell
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Configuration de Nilesoft Shell
echo.

if not exist "C:\Program Files\Nilesoft Shell\" (
    echo x Nilesoft Shell n'est pas installé
    echo Veuillez l'installer avant de le configurer
    pause
    goto :configure_programs
)

set "nilesoft_imports=C:\Program Files\Nilesoft Shell\imports"
mkdir "%nilesoft_imports%" 2>nul

powershell -Command "& { $files = @('develop.nss', 'file-manage.nss', 'goto.nss', 'modify.nss', 'taskbar.nss', 'terminal.nss', 'theme.nss'); foreach ($file in $files) { Invoke-WebRequest -Uri \"https://raw.githubusercontent.com/GiGiDKR/OhMyWindows/refs/heads/0.3.0/files/Config/Nilesoft%%20Shell/imports/$file\" -OutFile \"$env:nilesoft_imports\$file\" } }"

if %errorlevel% equ 0 (
    echo ► Nilesoft Shell configuré
) else (
    echo x Échec de la configuration de Nilesoft Shell
)

echo.
pause
goto :configure_programs

:configure_flow_launcher
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Configuration de Flow Launcher
echo.

if not exist "%userprofile%\AppData\Local\FlowLauncher" (
    echo x Flow Launcher n'est pas installé
    pause
    goto :configure_programs
)

# taskkill /F /IM Flow.Launcher.exe 2>nul

set "flow_launcher_config=%appdata%\"
set "temp_zip=%TEMP%\FlowLauncher.zip"

powershell -Command "& { Invoke-WebRequest -Uri 'https://github.com/GiGiDKR/OhMyWindows/raw/refs/heads/0.3.0/files/Config/FlowLauncher.zip' -OutFile '%temp_zip%' } | Out-Null"

if %errorlevel% equ 0 (
    powershell -Command "& { Expand-Archive -Path '%temp_zip%' -DestinationPath '%flow_launcher_config%' -Force } | Out-Null"
    if %errorlevel% equ 0 (
        echo ► Flow Launcher configuré
    ) else (
        echo x Échec de la configuration de Flow Launcher
    )
) else (
    echo x Échec du téléchargement de la configuration
)

del "%temp_zip%" 2>nul

echo.
pause
goto :configure_programs

:configure_7zip
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ■ Configuration de 7-Zip
echo.

if not exist "C:\Program Files\7-Zip" (
    echo x 7-Zip n'est pas installé
    pause
    goto :configure_programs
)

taskkill /F /IM 7zFM.exe 2>nul

set "temp_reg=%TEMP%\7-Zip.reg"
powershell -Command "& { Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/GiGiDKR/OhMyWindows/refs/heads/0.3.0/files/Config/7-Zip/7-Zip.reg' -OutFile '%temp_reg%' | Out-Null }"

if %errorlevel% equ 0 (
    regedit /s "%temp_reg%" >nul 2>&1
    if %errorlevel% equ 0 (
        echo ► Configuration de 7-Zip terminée
    ) else (
        echo x Échec de l'ajout des paramètres au registre
    )
) else (
    echo x Échec du téléchargement du fichier de configuration
)

del "%temp_reg%" 2>nul

echo.
pause
goto :configure_programs

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

echo ► Script terminé !
echo.
pause

endlocal