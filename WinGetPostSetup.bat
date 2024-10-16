@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "ligne1=============================================="
set "ligne2=               OhMyWindows                 "
set "ligne3=============================================="

:: Sauvegarder le chemin d'origine
if not defined ORIGINAL_PATH set "ORIGINAL_PATH=%~dp0"


:: V�rifier les privil�ges administrateur et relancer si n�cessaire
net session >nul 2>&1
if %errorLevel% == 0 (
    goto :admin_ok
) else (
    cls
    echo %ligne1%
    echo %ligne2%
    echo %ligne3%
    echo.
    echo Red�marrage en tant qu'administrateur
    powershell -Command "Start-Process '%~dpnx0' -Verb RunAs -ArgumentList '-ORIGINAL_PATH:%ORIGINAL_PATH%'" >nul 2>&1
    exit /b
)

:admin_ok
powershell -Command "& {$policy = Get-ExecutionPolicy; if ($policy -eq 'Restricted') {Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; Write-Host 'Modified'} else {Write-Host 'OK'}}" > "%TEMP%\policy_check.txt" 2>nul
set /p policy_status=<"%TEMP%\policy_check.txt"
del "%TEMP%\policy_check.txt" >nul 2>&1

if "%policy_status%"=="Modified" (
    echo Politique d'ex�cution PowerShell modifi�e
    echo.
) else (

    echo Politique d'ex�cution PowerShell correctement configur�e
    echo.
)

:: D�finir la taille de la fen�tre
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
    echo ? Version de Winget : %winget_version%
    goto :check_windows_terminal
) else (
    echo x Winget n'est pas install� sur votre syst�me
    goto :packages_manager
)

:check_windows_terminal
if "%WT_SESSION%"=="" (
    where wt >nul 2>&1
    if %errorlevel% equ 0 (
        echo Windows Terminal est d�j� install�
        echo Red�marrage du script dans Windows Terminal
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
echo ? Installation des gestionnaires de paquets
echo.

echo - Installation de Winget
set "tempFolder=%TEMP%\WinGetInstall"
if not exist "%tempFolder%" mkdir "%tempFolder%" >nul 2>&1

echo - T�l�chargement des fichiers n�cessaires
start /wait bitsadmin /transfer WinGetDownload /dynamic /priority high ^
    https://aka.ms/getwinget "%tempFolder%\winget.msixbundle" ^
    https://aka.ms/Microsoft.VCLibs.x86.14.00.Desktop.appx "%tempFolder%\vclibs_x86.appx" ^
    https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx "%tempFolder%\vclibs_x64.appx" ^
    https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.7.3 "%tempFolder%\xaml.zip" >nul 2>&1

echo - Extraction des fichiers
powershell -Command "& {Expand-Archive -Path '%tempFolder%\xaml.zip' -DestinationPath '%tempFolder%\xaml'}" >nul 2>&1

for /f "delims=" %%i in ('powershell -Command "& {Get-ChildItem -Path '%tempFolder%\xaml' -Recurse -Filter '*.appx' | Where-Object { $_.Name -like '*x64*' } | Select-Object -First 1 -ExpandProperty FullName}" 2^>nul') do set "xamlAppxPath=%%i"

echo - Installation des d�pendances
powershell -Command "& {Add-AppxPackage -Path '%tempFolder%\vclibs_x86.appx'}" >nul 2>&1
powershell -Command "& {Add-AppxPackage -Path '%tempFolder%\vclibs_x64.appx'}" >nul 2>&1
if defined xamlAppxPath powershell -Command "& {Add-AppxPackage -Path '!xamlAppxPath!'}" >nul 2>&1

echo - Installation de WinGet
powershell -Command "& {Add-AppxPackage -Path '%tempFolder%\winget.msixbundle'}" >nul 2>&1

echo - Nettoyage des fichiers temporaires
rmdir /s /q "%tempFolder%" >nul 2>&1

echo.
echo ? Winget a �t� install� avec succ�s !
call :version_winget

echo.
echo - Installation de Chocolatey
powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"

if %errorlevel% equ 0 (
    echo.
    echo ? Chocolatey a �t� install� avec succ�s !
    echo.
    choco --version
) else (
    echo.
    echo x �chec de l'installation de Chocolatey
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
echo ? Installation de Windows Terminal
echo.
winget install Microsoft.WindowsTerminal --accept-source-agreements --accept-package-agreements
if %errorlevel% equ 0 (
    echo.
    echo ? Windows Terminal a �t� install� avec succ�s !
    echo.
    echo Red�marrage du script dans Windows Terminal
    timeout /t 2 >nul
    start wt "%~dpnx0"
    exit /b
) else (
    echo.
    echo x �chec de l'installation de Windows Terminal
    echo Poursuite du script dans la fen�tre actuelle
    timeout /t 2 >nul
)

:main_menu
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.  
echo ? Menu principal
echo.

echo 1 - Installation programmes
echo 2 - Installation Microsoft Store
echo 3 - Installation Microsoft Office
echo 4 - Fonctionnalit�s Windows
echo 5 - Activation Windows / Office
echo 6 - Optimiser Windows
echo 7 - Param�tres Windows
echo 8 - Nettoyage Windows
echo 9 - Configuration Terminal
echo 10 - Configuration programmes
echo 11 - Mise � jour programmes
echo 12 - Outils Android

echo.
echo 0 - Quitter
echo.
echo %ligne1%
echo.
set /p choix=? S�lectionner une option : 

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
echo Option invalide. Veuillez r�essayer.
pause
goto :main_menu

:optimize_windows
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ? Optimiser Windows
echo.
echo 1 - WinUtil
echo 2 - Optimizer
echo.
echo 0 - Retour au menu principal
echo.
set /p optimize_choice=? S�lectionner une option : 

if "%optimize_choice%"=="0" goto :main_menu
if "%optimize_choice%"=="1" goto :winutil_menu
if "%optimize_choice%"=="2" goto :install_optimizer

echo.
echo Option invalide. Veuillez r�essayer.
pause
goto :optimize_windows

:install_optimizer
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ? Installation et ex�cution d'Optimizer
echo.

set "install_dir=C:\Program Files\Optimizer"
mkdir "%install_dir%" 2>nul

echo - T�l�chargement d'Optimizer
powershell -Command "& { $latestRelease = (Invoke-WebRequest -Uri 'https://api.github.com/repos/hellzerg/optimizer/releases/latest' | ConvertFrom-Json); $downloadUrl = $latestRelease.assets | Where-Object { $_.name -like '*.exe' } | Select-Object -ExpandProperty browser_download_url; Invoke-WebRequest -Uri $downloadUrl -OutFile '%install_dir%\Optimizer.exe' }"

if %errorlevel% equ 0 (
    echo.
    echo ? Optimizer t�l�charg� avec succ�s
    start "" "%install_dir%\Optimizer.exe"
) else (
    echo x �chec du t�l�chargement d'Optimizer
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
echo ? Installation et ex�cution de WinUtil
echo.

call :create_winutil_shortcut

powershell -Command "irm https://christitus.com/win | iex"

echo.
pause
goto :main_menu

:create_winutil_shortcut
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { $desktopPath = [Environment]::GetFolderPath('Desktop'); $shortcutPath = Join-Path $desktopPath 'WinUtil.lnk'; $shell = New-Object -ComObject WScript.Shell; $shortcut = $shell.CreateShortcut($shortcutPath); $shortcut.TargetPath = 'powershell.exe'; $shortcut.Arguments = '-NoProfile -ExecutionPolicy Bypass -Command ""irm https://christitus.com/win | iex""'; $shortcut.WorkingDirectory = $env:USERPROFILE; $winutilDir = Join-Path $env:LOCALAPPDATA 'WinUtil'; $iconPath = Join-Path $winutilDir 'cttlogo.ico'; if (-not (Test-Path $iconPath)) { New-Item -ItemType Directory -Force -Path $winutilDir | Out-Null; Invoke-WebRequest -Uri 'https://christitus.com/images/logo-full.ico' -OutFile $iconPath }; if (Test-Path $iconPath) { $shortcut.IconLocation = $iconPath }; $shortcut.Save(); $bytes = [System.IO.File]::ReadAllBytes($shortcutPath); $bytes[0x15] = $bytes[0x15] -bor 0x20; [System.IO.File]::WriteAllBytes($shortcutPath, $bytes)}"
if %errorlevel% equ 0 (
    echo ? Raccourci WinUtil cr�� sur le bureau
) else (
    echo x �chec de la cr�ation du raccourci WinUtil
)
goto :eof

:clean_windows
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ? Nettoyage de Windows
echo.

echo - Nettoyage des fichiers temporaires
del /q /f /s %TEMP%\* >nul 2>&1
del /q /f /s C:\Windows\Temp\* >nul 2>&1

echo - Ex�cution de Dism.exe
Dism.exe /online /Cleanup-Image /StartComponentCleanup >nul 2>&1

echo - Ex�cution de cleanmgr
start /wait cleanmgr /sagerun:1 >nul 2>&1

echo.
echo ? Nettoyage termin�
pause
goto :main_menu

:windows_settings_menu
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ? Param�tres Windows
echo.
echo 1 - Registre Windows
echo 2 - Fond d'�cran
echo.
echo 0 - Retour au menu principal
echo.
set /p settings_choice=? S�lectionner une option : 

if "%settings_choice%"=="0" goto :main_menu
if "%settings_choice%"=="1" goto :apply_windows_settings
if "%settings_choice%"=="2" goto :wallpaper_dl

echo.
echo Option invalide. Veuillez r�essayer
pause
goto :windows_settings_menu

:windows_features
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ? Fonctionnalit�s Windows
echo.
echo 1 - Hyper-V
echo 2 - Sandbox
echo 3 - .NET Framework 3.5
echo 4 - Sous-syst�me Windows pour Linux
echo.
echo 0 - Retour au menu principal
echo.
set /p feature_choice=? S�lectionner une option : 

if "%feature_choice%"=="0" goto :main_menu
if "%feature_choice%"=="1" goto :enable_hyperv
if "%feature_choice%"=="2" goto :enable_sandbox
if "%feature_choice%"=="3" goto :enable_dotnet35
if "%feature_choice%"=="4" goto :enable_wsl

echo.
echo Option invalide. Veuillez r�essayer
pause
goto :windows_features

:enable_hyperv
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ? Installation de Hyper-V
DISM /Online /Enable-Feature /All /FeatureName:Microsoft-Hyper-V /NoRestart
if %errorlevel% equ 0 (
    echo.
    echo ? Hyper-V a �t� install� avec succ�s
    echo.
    echo Un red�marrage sera n�cessaire pour finaliser l'installation
) else if %errorlevel% equ 3010 (
    echo.
    echo ? Hyper-V a �t� install� avec succ�s
    echo.
    echo Un red�marrage sera n�cessaire pour finaliser l'installation
) else (
    echo.
    echo x �chec de l'installation de Hyper-V
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
echo ? Installation de Windows Sandbox
DISM /Online /Enable-Feature /FeatureName:"Containers-DisposableClientVM" /All /NoRestart
if %errorlevel% equ 0 (
    echo ? Windows Sandbox a t install avec succs
    echo.
    echo Un red�marrage sera n�cessaire pour finaliser l'installation
) elseif %errorlevel% equ 3010 (
    echo ? Windows Sandbox a �t� install� avec succ�s
    echo.
    echo Un redmarrage sera ncessaire pour finaliser l'installation
) else (
    echo x �chec de l'installation de Windows Sandbox
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
echo ? Installation de .NET Framework 3.5
DISM /Online /Enable-Feature /FeatureName:NetFx3 /All /NoRestart
if %errorlevel% equ 0 (
    echo ? .NET Framework 3.5 a t install avec succs
    echo.
    echo Un red�marrage peut �tre n�cessaire pour finaliser l'installation
) else if %errorlevel% equ 3010 (
    echo ? .NET Framework 3.5 a �t� install� avec succ�s
    echo.
    echo Un red�marrage sera n�cessaire pour finaliser l'installation
) else (
    echo x �chec de l'installation de .NET Framework 3.5
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
echo ? Installation du Sous-syst�me Windows pour Linux (WSL)
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
if %errorlevel% equ 0 (
    echo.
    echo ? WSL a �t� activ� avec succ�s
    echo.
    echo Un red�marrage sera n�cessaire pour finaliser l'installation
) else if %errorlevel% equ 3010 (
    echo.
    echo ? WSL a �t� activ� avec succ�s
    echo.
    echo Un red�marrage sera n�cessaire pour finaliser l'installation
) else (
    echo.
    echo x �chec de l'activation de WSL
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
echo ? S�lection des programmes � installer
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
set /p choix=? Saisir les num�ros (s�par�s par des espaces) : 

if "%choix%"=="0" goto :main_menu
if /i "%choix%"=="A" goto :install_all_programs

for %%i in (%choix%) do (
    if defined program[%%i] (
        for /f "tokens=1,2,3 delims=|" %%a in ("!program[%%i]!") do (
            set "name=%%a"
            set "id=%%b"
            set "source=%%c"
        )
        cls
        echo %ligne1%
        echo %ligne2%
        echo %ligne3%
        echo.
        echo - Installation de !name!
        if "!source!"=="winget" (
            winget install !id! --silent --accept-source-agreements --accept-package-agreements >nul 2>&1
            if !errorlevel! equ 0 (
                echo.
                echo ? Installation de !name! r�ussie
            ) else if !errorlevel! equ -1978335189 (
                echo.
                echo ? La derni�re version de !name! est d�j� install�e
            ) else (
                echo.
                echo x �chec de l'installation de !name!
            )
        ) else if "!source!"=="choco" (
            choco install !id! -y -f >nul 2>&1
            if !errorlevel! equ 0 (
                echo.
                echo ? Installation de !name! r�ussie
            ) else if !errorlevel! equ 3010 (
                echo.
                echo ? La derni�re version de !name! est d�j� install�e
            ) else (
                echo.
                echo x �chec de l'installation de !name!
            )
        ) else if "!source!"=="exe" (
            call :install_custom_exe "!name!" "!id!" >nul 2>&1
        ) else if "!source!"=="zip" (
            call :install_custom_archive "!name!" "!id!" >nul 2>&1
        ) else (
            echo Source inconnue pour !name!
        )
    ) else (
        echo.
        echo x Le programme num�ro %%i n'existe pas dans la liste.
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
echo ? Installation de tous les programmes
powershell -Command "Get-Content '%ORIGINAL_PATH%packages.json' | ConvertFrom-Json | Select-Object -ExpandProperty packages | ForEach-Object { $name = $_.name; $id = $_.id; $source = $_.source; Write-Host ''; Write-Host '- Installation de ' $name; if ($source -eq 'winget') { $result = winget install $id --silent --accept-source-agreements --accept-package-agreements; if ($LASTEXITCODE -eq 0) { Write-Host '? Installation de ' $name ' r�ussie' } elseif ($LASTEXITCODE -eq -1978335189) { Write-Host '? La derni�re version de ' $name ' est d�j� install�e' } else { Write-Host 'x �chec de l''installation de ' $name } } elseif ($source -eq 'choco') { $result = choco install $id -y -f; if ($LASTEXITCODE -eq 0) { Write-Host '? Installation de ' $name ' r�ussie' } elseif ($LASTEXITCODE -eq 3010) { Write-Host '? La derni�re version de ' $name ' est d�j� install�e' } else { Write-Host 'x �chec de l''installation de ' $name } } elseif ($source -eq 'exe') { & cmd /c call :install_custom_exe '$name' '$id' } elseif ($source -eq 'zip') { & cmd /c call :install_custom_archive '$name' '$id' } else { Write-Host 'Source inconnue pour ' $name } }"

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
    echo - Cr�ation du raccourci sur le bureau
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
    echo - Cr�ation du raccourci sur le bureau
    powershell -Command "& { $WshShell = New-Object -ComObject WScript.Shell; $exeFile = Get-ChildItem -Path '%install_dir%' -Recurse -Filter '*.exe' | Where-Object { $_.Name -like '*%program_name%*' } | Select-Object -First 1; if ($exeFile) { $Shortcut = $WshShell.CreateShortcut([System.IO.Path]::Combine($env:USERPROFILE, 'Desktop', '%program_name%.lnk')); $Shortcut.TargetPath = $exeFile.FullName; $Shortcut.WorkingDirectory = $exeFile.DirectoryName; $Shortcut.Save(); echo '? Raccourci cr�� pour ' + $exeFile.Name } else { echo 'x Aucun ex�cutable correspondant trouv� pour %program_name%' } }"
)

rmdir /s /q "%temp_dir%" 2>nul
goto :eof

:apply_windows_settings
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ? Application des param�tres Windows
echo.
echo - Red�marrage de l'explorateur n�cessaire
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
echo [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced]
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
echo ? Installation de Microsoft Store
echo.

powershell -Command "if (Get-AppxPackage Microsoft.WindowsStore) { exit 0 } else { exit 1 }" >nul 2>&1
if %errorlevel% equ 0 (
    echo x Microsoft Store est d�j� install�
    echo.
    pause
    goto :main_menu 
) else (
    set "tempFolder=%TEMP%\MicrosoftStoreInstall"
    mkdir "%tempFolder%" 2>nul

    echo - Tlchargement des fichiers ncessaires
    start /wait bitsadmin /transfer MicrosoftStoreDownload /dynamic /priority high ^
        https://github.com/GiGiDKR/OhMyWindows/raw/refs/heads/0.3.0/files/LTSC-Add-MicrosoftStore-24H2/Microsoft.WindowsStore_8wekyb3d8bbwe.xml "%tempFolder%\Microsoft.WindowsStore_8wekyb3d8bbwe.xml" ^
        https://github.com/GiGiDKR/OhMyWindows/raw/refs/heads/0.3.0/files/LTSC-Add-MicrosoftStore-24H2/Microsoft.WindowsStore_8wekyb3d8bbwe.msixbundle "%tempFolder%\WindowsStore.msixbundle" ^
        https://github.com/GiGiDKR/OhMyWindows/raw/refs/heads/0.3.0/files/LTSC-Add-MicrosoftStore-24H2/Microsoft.NET.Native.Framework.x64.2.2.appx "%tempFolder%\Framework6X64.appx" ^
        https://github.com/GiGiDKR/OhMyWindows/raw/refs/heads/0.3.0/files/LTSC-Add-MicrosoftStore-24H2/Microsoft.NET.Native.Runtime.x64.2.2.appx "%tempFolder%\Runtime6X64.appx" ^
        https://github.com/GiGiDKR/OhMyWindows/raw/refs/heads/0.3.0/files/LTSC-Add-MicrosoftStore-24H2/Microsoft.StorePurchaseApp_8wekyb3d8bbwe.appxbundle "%tempFolder%\StorePurchaseApp.appxbundle" ^
        https://github.com/GiGiDKR/OhMyWindows/raw/refs/heads/0.3.0/files/LTSC-Add-MicrosoftStore-24H2/Microsoft.StorePurchaseApp_8wekyb3d8bbwe.xml "%tempFolder%\Microsoft.StorePurchaseApp_8wekyb3d8bbwe.xml" ^
        https://github.com/GiGiDKR/OhMyWindows/raw/refs/heads/0.3.0/files/LTSC-Add-MicrosoftStore-24H2/Microsoft.XboxIdentityProvider_8wekyb3d8bbwe.appxbundle "%tempFolder%\XboxIdentityProvider.appxbundle" ^
        https://github.com/GiGiDKR/OhMyWindows/raw/refs/heads/0.3.0/files/LTSC-Add-MicrosoftStore-24H2/Microsoft.XboxIdentityProvider_8wekyb3d8bbwe.xml "%tempFolder%\Microsoft.XboxIdentityProvider_8wekyb3d8bbwe.xml"

    echo - Installation de Microsoft Store et ses composants
    powershell -Command "Add-AppxProvisionedPackage -Online -PackagePath '%tempFolder%\WindowsStore.msixbundle' -DependencyPackagePath '%tempFolder%\Framework6X64.appx','%tempFolder%\Runtime6X64.appx' -LicensePath '%tempFolder%\Microsoft.WindowsStore_8wekyb3d8bbwe.xml' -ErrorAction SilentlyContinue | Out-Null"
    powershell -Command "Add-AppxPackage -Path '%tempFolder%\Framework6X64.appx' -ErrorAction SilentlyContinue | Out-Null"
    powershell -Command "Add-AppxPackage -Path '%tempFolder%\Runtime6X64.appx' -ErrorAction SilentlyContinue | Out-Null"
    powershell -Command "Add-AppxPackage -Path '%tempFolder%\WindowsStore.msixbundle' -ErrorAction SilentlyContinue | Out-Null"
    powershell -Command "Add-AppxProvisionedPackage -Online -PackagePath '%tempFolder%\StorePurchaseApp.appxbundle' -LicensePath '%tempFolder%\Microsoft.StorePurchaseApp_8wekyb3d8bbwe.xml' -ErrorAction SilentlyContinue | Out-Null"
    powershell -Command "Add-AppxProvisionedPackage -Online -PackagePath '%tempFolder%\XboxIdentityProvider.appxbundle' -LicensePath '%tempFolder%\Microsoft.XboxIdentityProvider_8wekyb3d8bbwe.xml' -ErrorAction SilentlyContinue | Out-Null"

    rmdir /s /q "%tempFolder%" 2>nul

    echo.
    echo ? Microsoft Store install� avec succ�s
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
echo ? Installation de Microsoft Office
echo.

set "tempFolder=%TEMP%\MicrosoftOfficeInstall"
mkdir "%tempFolder%" 2>nul

echo - T�l�chargement de Microsoft Office
start /wait bitsadmin /transfer OfficeSetupDownload /dynamic /priority high ^
    "https://c2rsetup.officeapps.live.com/c2r/download.aspx?ProductreleaseID=O365ProPlusRetail&platform=x64&language=fr-fr&version=O16GA" ^
    "%tempFolder%\OfficeSetup.exe"

if %errorlevel% equ 0 (
    echo - Installation de Microsoft Office
    start /wait "" "%tempFolder%\OfficeSetup.exe"
    if %errorlevel% equ 0 (
        echo.
        echo ? Microsoft Office install� avec succ�s
    ) else (    
        echo.
        echo x �chec de l'installation de Microsoft Office
    )
) else (
    echo.
    echo x �chec du t�l�chargement de Microsoft Office
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
echo ? T�l�chargement et installation du fond d'�cran
echo.

set "tempFolder=%TEMP%\WallpaperDownload"
set "extractFolder=C:\Users\%username%\Pictures\Wallpapers"
mkdir "%tempFolder%" 2>nul
mkdir "%extractFolder%" 2>nul

echo - T�l�chargement du fond d'�cran
start /wait bitsadmin /transfer WallpaperDownload /dynamic /priority high ^
    "https://github.com/GiGiDKR/OhMyWindows/raw/refs/heads/0.3.0/files/Wallpaper.zip" ^
    "%tempFolder%\Wallpaper.zip"

if %errorlevel% equ 0 (
    echo - Extraction du fond d'�cran
    powershell -Command "Expand-Archive -Path '%tempFolder%\Wallpaper.zip' -DestinationPath '%extractFolder%' -Force"
    if %errorlevel% equ 0 (
        echo - Configuration du fond dcran
        reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v WallPaper /t REG_SZ /d "C:\Users\%username%\Pictures\Wallpapers\purple.png" /f
        if %errorlevel% equ 0 (
            echo ? Fond d'�cran install� avec succ�s
        ) else (     
            echo x �chec de la configuration du fond d'�cran
        )
    ) else (
        echo x �chec de l'extraction du fond d'�cran
    )
) else (
    echo x �chec du t�l�chargement du fond d'�cran
)

echo - Nettoyage des fichiers temporaires
rmdir /s /q "%tempFolder%" 2>nul

echo.
pause
goto :main_menu

:configure_terminal
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ? Configuration du Terminal
echo.

call :install_fonts

call :configure_powershell_profile

call :configure_doskey

call :configure_clink

echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$settingsPath = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'; Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/GiGiDKR/OhMyWindows/refs/heads/0.3.0/files/settings.json' -OutFile $settingsPath"

if %errorlevel% equ 0 (
    echo ? Configuration de Windows Terminal termin�e
) else (
    echo x �chec de la configuration de Windows Terminal
)

echo.
pause
goto :main_menu

:install_fonts
powershell -NoProfile -ExecutionPolicy Bypass -Command "$fontPath = '%userprofile%\AppData\Local\Microsoft\Windows\Fonts\MesloLGLNerdFont-Regular.ttf'; if (-not (Test-Path $fontPath)) { $tempFolder = Join-Path $env:TEMP 'Font'; $fontUrl = 'https://github.com/GiGiDKR/OhMyWindows/raw/refs/heads/0.3.0/files/MesloLGLNerdFont.zip'; $fontZip = Join-Path $tempFolder 'MesloLGLNerdFont.zip'; $extractFolder = Join-Path $tempFolder 'MesloLGLNerdFont'; New-Item -ItemType Directory -Force -Path $tempFolder | Out-Null; New-Item -ItemType Directory -Force -Path $extractFolder | Out-Null; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri $fontUrl -OutFile $fontZip; if (Test-Path $fontZip) { Expand-Archive -Path $fontZip -DestinationPath $extractFolder -Force; Get-ChildItem -Path $extractFolder -Filter '*.ttf' | ForEach-Object { $fontName = $_.Name; $fontPath = $_.FullName; $shell = New-Object -ComObject Shell.Application; $destination = $shell.Namespace(0x14); $destination.CopyHere($fontPath, 0x10) }; Remove-Item -Path $extractFolder -Recurse -Force; Write-Host '? Police Meslo LGL Nerd install�e avec succ�s' } else { Write-Host 'x �chec du t�l�chargement des polices' } } else { Write-Host '? La police Meslo LGL Nerd est d�j� install�e' }"
goto :eof

:configure_powershell_profile
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted; Install-Module -Name Terminal-Icons -Scope CurrentUser -Force -AllowClobber; Install-Module -Name PSReadLine -Force -SkipPublisherCheck -AllowClobber; Install-Module -Name Z -Scope CurrentUser -Force -AllowClobber; Install-Module posh-git -Scope CurrentUser -Force -AllowClobber; Install-Module -Name PSFzf -Scope CurrentUser -Force -AllowClobber }"

powershell -NoProfile -ExecutionPolicy Bypass -Command "$profileFile = Join-Path $env:USERPROFILE 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'; $profilePath = Split-Path $profileFile; if (-not (Test-Path $profilePath)) { New-Item -ItemType Directory -Path $profilePath -Force | Out-Null }; Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/GiGiDKR/OhMyWindows/refs/heads/0.3.0/files/PowerShell/Microsoft.PowerShell_profile.ps1' -OutFile $profileFile"

if %errorlevel% equ 0 (
    echo - Profil PowerShell configur�
) else (
    echo x �chec de la configuration du profil PowerShell
)

winget install fzf --accept-source-agreements --accept-package-agreements >nul 2>&1

goto :eof

:configure_doskey
if not exist "%userprofile%\.config\doskey" mkdir "%userprofile%\.config\doskey"

powershell -Command "& { Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/GiGiDKR/OhMyWindows/refs/heads/0.3.0/files/.doskey' -OutFile '%userprofile%\.config\doskey\.doskey' }"

if %errorlevel% equ 0 (
    reg add "HKLM\SOFTWARE\Microsoft\Command Processor" /v AutoRun /t REG_EXPAND_SZ /d "doskey /listsize=999 /macrofile=%userprofile%\.config\doskey\.doskey" /f >nul 2>&1
    if %errorlevel% equ 0 (
        echo - Aias Doskey configur�s
    ) else (
        echo x �chec de la configuration des alias Doskey
    )
) else (
    echo x �chec du t�l�chargement des alias Doskey
)
goto :eof

:configure_clink
set "tempFolder=%TEMP%\ClinkInstall"
set "clinkZip=%tempFolder%\clink.zip"
set "clinkDestination=%userprofile%\AppData\Local\clink"

mkdir "%tempFolder%" 2>nul

powershell -Command "& { Invoke-WebRequest -Uri 'https://github.com/GiGiDKR/OhMyWindows/raw/refs/heads/0.3.0/files/clink.zip' -OutFile '%clinkZip%' }"

if %errorlevel% equ 0 (
    powershell -Command "& { Expand-Archive -Path '%clinkZip%' -DestinationPath '%clinkDestination%' -Force }"
    if %errorlevel% equ 0 (
        rmdir /s /q "%tempFolder%" 2>nul
        echo - Clink configur�
    ) else (
        echo x �chec de la configuration de Clink
    )
) else (
    echo x �chec de la configuration de Clink
)
goto :eof

:upgrade_programs
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ? Mise � jour des programmes
echo.

set /p update_choice=Voulez-vous mettre � jour tous les programmes ? (o/n) 

if /i "%update_choice%"=="o" (
    echo.
    echo - Mise � jour des programmes Winget
    winget upgrade --all
    echo.
    echo - Mise � jour des programmes Chocolatey
    choco upgrade all -y
    echo.
    echo ? Mises � jour termin�es
) else (
    echo.
    echo x Mises � jour annul�es
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
echo ? Outils Android
echo.
echo 1 - ADB
echo 2 - Scrcpy
echo 3 - Odin 3
echo 4 - SamFwTool
echo 5 - Pixel Flasher
echo.
echo 0 - Retour au menu principal
echo.
set /p android_choice=? S�lectionner une option : 

if "%android_choice%"=="0" goto :main_menu
if "%android_choice%"=="1" goto :install_adb
if "%android_choice%"=="2" goto :install_scrcpy
if "%android_choice%"=="3" goto :install_odin3
if "%android_choice%"=="4" goto :install_samfwtool
if "%android_choice%"=="5" goto :install_pixel_flasher

echo.
echo Option invalide. Veuillez r�essayer.
pause
goto :android_tools

:install_adb
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ? Installation de ADB
echo.
set "tempFolder=%TEMP%\ADBInstall"
set "adbUrl=https://dl.google.com/android/repository/platform-tools-latest-windows.zip?hl=fr"
set "adbZip=%tempFolder%\platform-tools.zip"
set "adbDestination=C:\Android\adb"

mkdir "%tempFolder%" 2>nul
mkdir "C:\Android" 2>nul

powershell -Command "& { Invoke-WebRequest -Uri '%adbUrl%' -OutFile '%adbZip%' } | Out-Null"
powershell -Command "& { Expand-Archive -Path '%adbZip%' -DestinationPath '%tempFolder%' -Force } | Out-Null"

:: Renommer et d�placer le dossier
move "%tempFolder%\platform-tools" "%adbDestination%" >nul 2>&1

setx PATH "%PATH%;%adbDestination%" /M >nul 2>&1

if %errorlevel% equ 0 (
    echo ? ADB install avec succ�s
) else (
    echo x �chec de l'installation de ADB
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
echo ? Installation de Scrcpy
echo.
set "tempFolder=%TEMP%\ScrcpyInstall"
set "scrcpyApiUrl=https://api.github.com/repos/Genymobile/scrcpy/releases/latest"
set "scrcpyZip=%tempFolder%\scrcpy.zip"
set "scrcpyDestination=C:\Android\scrcpy"

mkdir "%tempFolder%" 2>nul
mkdir "C:\Android" 2>nul

powershell -Command "& { $latestRelease = Invoke-RestMethod -Uri '%scrcpyApiUrl%'; $asset = $latestRelease.assets | Where-Object { $_.name -like 'scrcpy-win64-v*.zip' } | Select-Object -First 1; if ($asset) { if (Test-Path '%scrcpyDestination%') { Write-Host '? Scrcpy est d�j� install�' } else { Invoke-WebRequest -Uri $asset.browser_download_url -OutFile '%scrcpyZip%'; if (Test-Path '%scrcpyZip%') { Expand-Archive -Path '%scrcpyZip%' -DestinationPath '%tempFolder%' -Force; $extractedFolder = Get-ChildItem -Path '%tempFolder%' -Directory | Select-Object -First 1; if ($extractedFolder) { Move-Item -Path $extractedFolder.FullName -Destination '%scrcpyDestination%' -Force; Write-Host '? Scrcpy install� avec succ�s' } else { Write-Host 'x Dossier extrait non trouv�' } } else { Write-Host 'x �chec du t�l�chargement' } } } else { Write-Host 'x Asset non trouv�' } }"

if exist "%scrcpyDestination%" (
    setx PATH "%PATH%;%scrcpyDestination%" /M >nul 2>&1
)

rmdir /s /q "%tempFolder%" 2>nul
echo.
pause
goto :android_tools

:install_odin3
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ? Installation de Odin 3
echo.
set "tempFolder=%TEMP%\Odin3Install"
set "odin3Url=https://samfw.com/Odin/Samfw.com_Odin3_v3.14.4.zip"
set "odin3Zip=%tempFolder%\odin3.zip"
set "odin3Destination=C:\Android\Odin 3"

mkdir "%tempFolder%" 2>nul
mkdir "C:\Android" 2>nul

powershell -Command "& { Invoke-WebRequest -Uri '%odin3Url%' -OutFile '%odin3Zip%' }"
powershell -Command "& { Expand-Archive -Path '%odin3Zip%' -DestinationPath '%tempFolder%' -Force }"

:: Renommer et d�placer le dossier
move "%tempFolder%\Samfw.com_Odin3_v3.14.4" "%odin3Destination%" >nul 2>&1

if %errorlevel% equ 0 (
    echo ? Odin 3 install� avec succ�s
    
    :: Cr�ation du raccourci sur le bureau
    powershell -Command "& { $WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut($env:USERPROFILE + '\Desktop\Odin 3.lnk'); $Shortcut.TargetPath = '%odin3Destination%\Odin3_v3.14.4_Samfw.com.exe'; $Shortcut.WorkingDirectory = '%odin3Destination%'; $Shortcut.Save() }"
    
    if %errorlevel% equ 0 (
        echo ? Raccourci cr�� sur le bureau
    ) else (
        echo x �chec de la cr�ation du raccourci
    )
) else (
    echo x �chec de l'installation de Odin 3
)

rmdir /s /q "%tempFolder%" 2>nul
echo.
pause
goto :android_tools

:install_samfwtool
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ? Installation de SamFwTool
echo.
set "tempFolder=%TEMP%\SamFwToolInstall"
set "samfwToolUrl=https://samfw.com/SamFwToolSetup_v4.9.zip"
set "samfwToolZip=%tempFolder%\samfwtool.zip"

mkdir "%tempFolder%" 2>nul

powershell -Command "& { Invoke-WebRequest -Uri '%samfwToolUrl%' -OutFile '%samfwToolZip%' }"
powershell -Command "& { Expand-Archive -Path '%samfwToolZip%' -DestinationPath '%tempFolder%' -Force }"
start /wait "" "%tempFolder%\SamFwToolSetup.exe" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-

if %errorlevel% equ 0 (
    echo ? SamFwTool install� avec succ�s
) else (
    echo x �chec de l'installation de SamFwTool
)

rmdir /s /q "%tempFolder%" 2>nul
echo.
pause
goto :android_tools

:install_pixel_flasher
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ? Installation de Pixel Flasher
echo.
set "pixelFlasherDestination=C:\Android\Pixel Flasher"

mkdir "%pixelFlasherDestination%" 2>nul

powershell -Command "& { $releases = Invoke-RestMethod -Uri 'https://api.github.com/repos/badabing2005/PixelFlasher/releases/latest'; $asset = $releases.assets | Where-Object { $_.name -like '*.exe' } | Select-Object -First 1; Invoke-WebRequest -Uri $asset.browser_download_url -OutFile '%pixelFlasherDestination%\PixelFlasher.exe' }"

if %errorlevel% equ 0 (
    echo ? Pixel Flasher install� avec succ�s

    powershell -Command "& { $WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut($env:USERPROFILE + '\Desktop\Pixel Flasher.lnk'); $Shortcut.TargetPath = '%pixelFlasherDestination%\PixelFlasher.exe'; $Shortcut.Save() }"

    if %errorlevel% equ 0 (
        echo ? Raccourci cr�� sur le bureau
    ) else (
        echo x �chec de la cr�ation du raccourci
    )
) else (
    echo x �chec de l'installation de Pixel Flasher
)

echo.
pause
goto :android_tools

:configure_programs
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ? Configuration des programmes
echo.
echo 1 - Nilesoft Shell
echo.
echo 0 - Retour au menu principal
echo.
set /p config_choice=? S�lectionner une option : 

if "%config_choice%"=="0" goto :main_menu
if "%config_choice%"=="1" goto :configure_nilesoft_shell

echo.
echo Option invalide. Veuillez r�essayer
pause
goto :configure_programs

:configure_nilesoft_shell
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ? Configuration de Nilesoft Shell
echo.

if not exist "C:\Program Files\Nilesoft Shell\" (
    echo x Nilesoft Shell n'est pas install�
    echo Veuillez l'installer avant de le configurer
    pause
    goto :configure_programs
)

set "nilesoft_imports=C:\Program Files\Nilesoft Shell\imports"
mkdir "%nilesoft_imports%" 2>nul

powershell -Command "& { $files = @('develop.nss', 'file-manage.nss', 'goto.nss', 'modify.nss', 'taskbar.nss', 'terminal.nss', 'theme.nss'); foreach ($file in $files) { Invoke-WebRequest -Uri \"https://raw.githubusercontent.com/GiGiDKR/OhMyWindows/refs/heads/0.3.0/files/Config/Nilesoft%%20Shell/imports/$file\" -OutFile \"$env:nilesoft_imports\$file\" } }"

if %errorlevel% equ 0 (
    echo ? Nilesoft Shell configur�
) else (
    echo x �chec de la configuration de Nilesoft Shell
)

echo.
pause
REM A activer apr�s l'ajout d'autres programmes
REM goto :configure_programs
goto :main_menu

:end_of_script
cls
echo %ligne1%
echo %ligne2%
echo %ligne3%
echo.
echo ? Script termin� !
echo.
pause

endlocal