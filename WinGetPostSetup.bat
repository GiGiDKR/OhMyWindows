@echo off
setlocal enabledelayedexpansion

:: Vérifier et modifier la politique d'exécution PowerShell si nécessaire
powershell -Command "& {$policy = Get-ExecutionPolicy; if ($policy -eq 'Restricted') {Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; Write-Host 'Modified'} else {Write-Host 'OK'}}" > "%TEMP%\policy_check.txt"
set /p policy_status=<"%TEMP%\policy_check.txt"
del "%TEMP%\policy_check.txt"

if "%policy_status%"=="Modified" (
    echo La politique d'execution PowerShell a ete modifiee en RemoteSigned.
) else (
    echo La politique d'execution PowerShell est deja correctement configuree.
)

:: Vérifier les privilèges d'administrateur
net session >nul 2>&1
if %errorLevel% == 0 (
    goto :admin
) else (
    echo Redémarrage en tant qu'administrateur dans une nouvelle fenêtre...
    powershell -Command "Start-Process '%~dpnx0' -Verb RunAs"
    exit /b
)

:admin
echo Installation de WinGet et application des paramètres Windows...

:: Créer un dossier temporaire
set "tempFolder=%TEMP%\WinGetInstall"
if not exist "%tempFolder%" mkdir "%tempFolder%"

:: Télécharger les fichiers nécessaires
powershell -Command "& {Invoke-WebRequest -Uri 'https://aka.ms/getwinget' -OutFile '%tempFolder%\winget.msixbundle'}"
powershell -Command "& {Invoke-WebRequest -Uri 'https://aka.ms/Microsoft.VCLibs.x86.14.00.Desktop.appx' -OutFile '%tempFolder%\vclibs_x86.appx'}"
powershell -Command "& {Invoke-WebRequest -Uri 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx' -OutFile '%tempFolder%\vclibs_x64.appx'}"
powershell -Command "& {Invoke-WebRequest -Uri 'https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.7.3' -OutFile '%tempFolder%\xaml.zip'}"

:: Extraire le fichier XAML
powershell -Command "& {Expand-Archive -Path '%tempFolder%\xaml.zip' -DestinationPath '%tempFolder%\xaml'}"

:: Trouver le fichier APPX XAML
for /f "delims=" %%i in ('powershell -Command "& {Get-ChildItem -Path '%tempFolder%\xaml' -Recurse -Filter '*.appx' | Where-Object { $_.Name -like '*x64*' } | Select-Object -First 1 -ExpandProperty FullName}"') do set "xamlAppxPath=%%i"

:: Installer les dépendances
powershell -Command "& {Add-AppxPackage -Path '%tempFolder%\vclibs_x86.appx'}"
powershell -Command "& {Add-AppxPackage -Path '%tempFolder%\vclibs_x64.appx'}"
if defined xamlAppxPath powershell -Command "& {Add-AppxPackage -Path '!xamlAppxPath!'}"

:: Installer WinGet
powershell -Command "& {Add-AppxPackage -Path '%tempFolder%\winget.msixbundle'}"

:: Nettoyer les fichiers temporaires
rmdir /s /q "%tempFolder%"

echo WinGet a été installé avec succès.
echo Appuyez sur une touche pour continuer avec l'application des paramètres Windows...
pause >nul

:: Ici, vous pouvez ajouter les commandes pour appliquer les paramètres Windows

endlocal
