Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object System.Windows.Forms.Form
$form.Text = 'OhMyWindows'
$form.Size = New-Object System.Drawing.Size(600,600)  # Augmentation de la taille
$form.StartPosition = 'CenterScreen'

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(580,20)
$label.Text = 'Sélectionnez une option :'
$form.Controls.Add($label)

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(10,50)
$listBox.Size = New-Object System.Drawing.Size(560,200)
$listBox.Height = 200

[void] $listBox.Items.Add('Installation programmes')
[void] $listBox.Items.Add('Installation Microsoft Store')
[void] $listBox.Items.Add('Installation Microsoft Office')
[void] $listBox.Items.Add('Fonctionnalités Windows')
[void] $listBox.Items.Add('Activation Windows / Office')
[void] $listBox.Items.Add('Optimiser Windows')
[void] $listBox.Items.Add('Paramètres Windows')
[void] $listBox.Items.Add('Nettoyage Windows')
[void] $listBox.Items.Add('Configuration Terminal')
[void] $listBox.Items.Add('Configuration programmes')
[void] $listBox.Items.Add('Mise à jour programmes')
[void] $listBox.Items.Add('Outils Android')

$form.Controls.Add($listBox)

# Ajout d'une zone de texte pour afficher les messages
$outputTextBox = New-Object System.Windows.Forms.TextBox
$outputTextBox.Location = New-Object System.Drawing.Point(10,260)
$outputTextBox.Size = New-Object System.Drawing.Size(560,250)
$outputTextBox.Multiline = $true
$outputTextBox.ScrollBars = 'Vertical'
$outputTextBox.ReadOnly = $true
$form.Controls.Add($outputTextBox)

$button = New-Object System.Windows.Forms.Button
$button.Location = New-Object System.Drawing.Point(10,520)
$button.Size = New-Object System.Drawing.Size(560,30)
$button.Text = 'Exécuter'
$button.Add_Click({
    $selectedItem = $listBox.SelectedItem
    if ($selectedItem) {
        $outputTextBox.Clear()  # Effacer les messages précédents
        switch ($selectedItem) {
            'Installation programmes' { 
                $tempFolder = [System.IO.Path]::GetTempPath()
                $packagesJsonPath = Join-Path $tempFolder "packages.json"
                
                if (-not (Test-Path $packagesJsonPath)) {
                    Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/GiGiDKR/OhMyWindows/refs/heads/0.3.0/files/packages.json' -OutFile $packagesJsonPath
                }

                $packages = Get-Content $packagesJsonPath | ConvertFrom-Json

                $selectedPackages = $packages.packages | Out-GridView -Title "Sélectionnez les programmes à installer" -OutputMode Multiple

                # Exemple d'affichage de message dans la zone de texte
                $outputTextBox.AppendText("Installation des programmes en cours...`r`n")
                
                foreach ($package in $selectedPackages) {
                    switch ($package.source) {
                        "winget" {
                            $result = Start-Process "winget" -ArgumentList "install -e --id $($package.id)" -NoNewWindow -Wait -PassThru
                            if ($result.ExitCode -eq 0) {
                                $outputTextBox.AppendText("► Installation de $($package.name) réussie`r`n")
                            } else {
                                $outputTextBox.AppendText("x Échec de l'installation de $($package.name)`r`n")
                            }
                        }
                        "choco" {
                            $result = Start-Process "choco" -ArgumentList "install $($package.id) -y" -NoNewWindow -Wait -PassThru
                            if ($result.ExitCode -eq 0) {
                                $outputTextBox.AppendText("► Installation de $($package.name) réussie`r`n")
                            } else {
                                $outputTextBox.AppendText("x Échec de l'installation de $($package.name)`r`n")
                            }
                        }
                        "custom" {
                            # Logique personnalisée pour les installations spécifiques
                            $outputTextBox.AppendText("Installation personnalisée de $($package.name) en cours...`r`n")
                            # Ajoutez ici la logique d'installation personnalisée
                        }
                    }
                }
                
                $outputTextBox.AppendText("Installation des programmes terminée.`r`n")
            }
            'Installation Microsoft Store' { 
                $isStoreInstalled = Get-AppxPackage -Name "Microsoft.WindowsStore"
                if ($isStoreInstalled) {
                    $outputTextBox.AppendText("► Microsoft Store est déjà installé.`r`n")
                } else {
                    $outputTextBox.AppendText("Installation de Microsoft Store...`r`n")
                    Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.WindowsStore_8wekyb3d8bbwe
                    $outputTextBox.AppendText("► Installation de Microsoft Store terminée.`r`n")
                }
            }
            'Installation Microsoft Office' { 
                $officePath = "C:\Program Files\Microsoft Office"
                if (Test-Path $officePath) {
                    Write-Host "Microsoft Office est déjà installé."
                } else {
                    Write-Host "Téléchargement de l'outil de déploiement Office..."
                    $setupUrl = "https://download.microsoft.com/download/2/7/A/27AF1BE6-DD20-4CB4-B154-EBAB8A7D4A7E/officedeploymenttool_14326-20404.exe"
                    $setupPath = "$env:TEMP\ODTSetup.exe"
                    Invoke-WebRequest -Uri $setupUrl -OutFile $setupPath

                    Write-Host "Extraction de l'outil de déploiement..."
                    Start-Process -FilePath $setupPath -ArgumentList "/extract:$env:TEMP\ODT" -NoNewWindow -Wait

                    Write-Host "Création du fichier de configuration..."
                    $configXml = @"
<Configuration>
  <Add OfficeClientEdition="64" Channel="Current">
    <Product ID="O365ProPlusRetail">
      <Language ID="fr-fr" />
    </Product>
  </Add>
  <Display Level="None" AcceptEULA="TRUE" />
  <Property Name="AUTOACTIVATE" Value="1" />
</Configuration>
"@
                    $configXml | Out-File "$env:TEMP\ODT\config.xml" -Encoding UTF8

                    Write-Host "Installation de Microsoft Office..."
                    Start-Process -FilePath "$env:TEMP\ODT\setup.exe" -ArgumentList "/configure $env:TEMP\ODT\config.xml" -NoNewWindow -Wait

                    Write-Host "Nettoyage des fichiers temporaires..."
                    Remove-Item -Path $setupPath -Force
                    Remove-Item -Path "$env:TEMP\ODT" -Recurse -Force
                }
            }
            'Fonctionnalités Windows' { 
                $features = @(
                    @{Name="Hyper-V"; Id="Microsoft-Hyper-V-All"},
                    @{Name="Windows Sandbox"; Id="Containers-DisposableClientVM"},
                    @{Name=".NET Framework 3.5"; Id="NetFx3"},
                    @{Name="Sous-système Windows pour Linux"; Id="Microsoft-Windows-Subsystem-Linux"}
                )

                $selectedFeatures = $features | Out-GridView -Title "Sélectionnez les fonctionnalités à installer" -OutputMode Multiple

                foreach ($feature in $selectedFeatures) {
                    Write-Host "Installation de $($feature.Name)..."
                    Enable-WindowsOptionalFeature -Online -FeatureName $feature.Id -All -NoRestart
                }

                Write-Host "Installation des fonctionnalités terminée. Un redémarrage peut être nécessaire."
            }
            'Activation Windows / Office' { 
                Write-Host "Activation de Windows et Office..."
                Invoke-Expression (Invoke-WebRequest -Uri "https://get.activated.win" -UseBasicParsing).Content
            }
            'Optimiser Windows' { 
                Write-Host "Optimisation de Windows..."

                # Désactiver les effets visuels inutiles
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2

                # Désactiver la télémétrie
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0

                # Désactiver Cortana
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0

                # Désactiver les applications en arrière-plan
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1

                # Optimiser les performances du disque dur
                fsutil behavior set disabledeletenotify 0

                Write-Host "Optimisation terminée."
            }
            'Paramètres Windows' { 
                Write-Host "Application des paramètres Windows..."

                # Activer le mode sombre
                Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0
                Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0

                # Désactiver la barre de recherche dans la barre des tâches
                Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 0

                # Masquer le bouton Vue des tâches
                Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 0

                # Définir l'explorateur pour ouvrir "Ce PC" par défaut
                Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value 1

                # Activer le mode compact dans l'explorateur
                Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "UseCompactMode" -Value 1

                Write-Host "Paramètres Windows appliqués. Un redémarrage peut être nécessaire pour que tous les changements prennent effet."
            }
            'Nettoyage Windows' { 
                Write-Host "Nettoyage de Windows..."

                # Nettoyer les fichiers temporaires
                Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

                # Exécuter Disk Cleanup
                cleanmgr /sagerun:1 | Out-Null

                # Nettoyer les composants Windows obsolètes
                Dism.exe /online /Cleanup-Image /StartComponentCleanup

                Write-Host "Nettoyage terminé."
            }
            'Configuration Terminal' { 
                Write-Host "Configuration du terminal Windows..."

                $settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

                # Vérifier si le fichier de configuration existe
                if (Test-Path $settingsPath) {
                    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json

                    # Configurer le thème sombre
                    $settings.theme = "dark"

                    # Configurer la police
                    $settings.profiles.defaults.font.face = "Cascadia Code"
                    $settings.profiles.defaults.font.size = 11

                    # Ajouter un profil PowerShell avec des couleurs personnalisées
                    $newProfile = @{
                        name = "PowerShell Personnalisé"
                        commandline = "powershell.exe"
                        hidden = $false
                        colorScheme = "Campbell"
                    }
                    $settings.profiles.list += $newProfile

                    # Sauvegarder les modifications
                    $settings | ConvertTo-Json -Depth 32 | Set-Content $settingsPath

                    Write-Host "Configuration du terminal Windows terminée."
                } else {
                    Write-Host "Le fichier de configuration du terminal Windows n'a pas été trouvé."
                }
            }
            'Configuration programmes' { 
                Write-Host "Configuration des programmes..."

                # Configuration de Nilesoft Shell
                $nilesoftPath = "C:\Program Files\Nilesoft Shell"
                if (Test-Path $nilesoftPath) {
                    $importsPath = Join-Path $nilesoftPath "imports"
                    New-Item -ItemType Directory -Force -Path $importsPath | Out-Null

                    $files = @('develop.nss', 'file-manage.nss', 'goto.nss', 'modify.nss', 'taskbar.nss', 'terminal.nss', 'theme.nss')
                    foreach ($file in $files) {
                        $url = "https://raw.githubusercontent.com/GiGiDKR/OhMyWindows/refs/heads/0.3.0/files/Config/Nilesoft%20Shell/imports/$file"
                        Invoke-WebRequest -Uri $url -OutFile (Join-Path $importsPath $file)
                    }
                    Write-Host "Configuration de Nilesoft Shell terminée."
                } else {
                    Write-Host "Nilesoft Shell n'est pas installé."
                }

                # Configuration de Flow Launcher
                $flowLauncherPath = "$env:APPDATA\FlowLauncher"
                if (Test-Path $flowLauncherPath) {
                    $settingsPath = Join-Path $flowLauncherPath "Settings\Settings.json"
                    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
                    $settings.Theme = "Dark"
                    $settings.Language = "fr"
                    $settings | ConvertTo-Json -Depth 32 | Set-Content $settingsPath
                    Write-Host "Configuration de Flow Launcher terminée."
                } else {
                    Write-Host "Flow Launcher n'est pas installé."
                }

                # Configuration de 7-Zip
                $sevenZipPath = "C:\Program Files\7-Zip"
                if (Test-Path $sevenZipPath) {
                    $regFile = @"
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\7-Zip\FM]
"FolderShortcuts"="C:\\"
"FolderHistory"="C:\\"
"PanelPath0"="C:\\"
"PanelPath1"="C:\\"
"ListMode"=dword:00000000
"FullRow"=dword:00000001
"ShowDots"=dword:00000000
"ShowRealFileIcons"=dword:00000001
"ShowSystemMenu"=dword:00000000
"AlternativeSelection"=dword:00000001
"@
                    $regFile | Out-File "$env:TEMP\7-Zip.reg" -Encoding ASCII
                    reg import "$env:TEMP\7-Zip.reg"
                    Remove-Item "$env:TEMP\7-Zip.reg" -Force
                    Write-Host "Configuration de 7-Zip terminée."
                } else {
                    Write-Host "7-Zip n'est pas installé."
                }
            }
            'Mise à jour programmes' { 
                Write-Host "Mise à jour des programmes..."

                # Mise à jour des applications via winget
                Write-Host "Mise à jour des applications via winget..."
                winget upgrade --all

                # Mise à jour des applications via Chocolatey
                if (Get-Command choco -ErrorAction SilentlyContinue) {
                    Write-Host "Mise à jour des applications via Chocolatey..."
                    choco upgrade all -y
                } else {
                    Write-Host "Chocolatey n'est pas installé."
                }

                Write-Host "Mise à jour des programmes terminée."
            }
            'Outils Android' { 
                $androidTools = @(
                    [PSCustomObject]@{Nom="ADB"; Description="Android Debug Bridge"}
                    [PSCustomObject]@{Nom="Scrcpy"; Description="Affichage et contrôle d'appareils Android"}
                    [PSCustomObject]@{Nom="Odin"; Description="Outil de flashage pour appareils Samsung"}
                    [PSCustomObject]@{Nom="Pixel Flasher"; Description="Outil de flashage pour appareils Google Pixel"}
                )

                $selectedTools = $androidTools | Out-GridView -Title "Sélectionnez les outils Android à installer" -OutputMode Multiple

                if ($selectedTools) {
                    $androidPath = "C:\Android"
                    New-Item -ItemType Directory -Force -Path $androidPath | Out-Null

                    foreach ($tool in $selectedTools) {
                        switch ($tool.Name) {
                            "ADB" {
                                $adbPath = Join-Path $androidPath "platform-tools"
                                if (-not (Test-Path $adbPath)) {
                                    $adbUrl = "https://dl.google.com/android/repository/platform-tools-latest-windows.zip"
                                    $adbZip = Join-Path $env:TEMP "platform-tools.zip"
                                    Invoke-WebRequest -Uri $adbUrl -OutFile $adbZip
                                    Expand-Archive -Path $adbZip -DestinationPath $androidPath -Force
                                    Remove-Item $adbZip -Force
                                    [Environment]::SetEnvironmentVariable("Path", $env:Path + ";$adbPath", [EnvironmentVariableTarget]::Machine)
                                    Write-Host "ADB installé avec succès."
                                } else {
                                    Write-Host "ADB est déjà installé."
                                }
                            }
                            "Scrcpy" {
                                $scrcpyPath = Join-Path $androidPath "scrcpy"
                                if (-not (Test-Path $scrcpyPath)) {
                                    $scrcpyUrl = "https://github.com/Genymobile/scrcpy/releases/download/v1.24/scrcpy-win64-v1.24.zip"
                                    $scrcpyZip = Join-Path $env:TEMP "scrcpy.zip"
                                    Invoke-WebRequest -Uri $scrcpyUrl -OutFile $scrcpyZip
                                    Expand-Archive -Path $scrcpyZip -DestinationPath $scrcpyPath -Force
                                    Remove-Item $scrcpyZip -Force
                                    [Environment]::SetEnvironmentVariable("Path", $env:Path + ";$scrcpyPath", [EnvironmentVariableTarget]::Machine)
                                    Write-Host "Scrcpy installé avec succès."
                                } else {
                                    Write-Host "Scrcpy est déjà installé."
                                }
                            }
                            "Odin" {
                                $odinPath = Join-Path $androidPath "Odin"
                                if (-not (Test-Path $odinPath)) {
                                    $odinUrl = "https://odindownload.com/download/Odin3_v3.14.4.zip"
                                    $odinZip = Join-Path $env:TEMP "Odin.zip"
                                    Invoke-WebRequest -Uri $odinUrl -OutFile $odinZip
                                    Expand-Archive -Path $odinZip -DestinationPath $odinPath -Force
                                    Remove-Item $odinZip -Force
                                    Write-Host "Odin installé avec succès."
                                } else {
                                    Write-Host "Odin est déjà installé."
                                }
                            }
                            "Pixel Flasher" {
                                $pixelFlasherPath = Join-Path $androidPath "PixelFlasher"
                                if (-not (Test-Path $pixelFlasherPath)) {
                                    $pixelFlasherUrl = "https://github.com/badabing2005/PixelFlasher/releases/download/v1.0.4/PixelFlasher_v1.0.4.zip"
                                    $pixelFlasherZip = Join-Path $env:TEMP "PixelFlasher.zip"
                                    Invoke-WebRequest -Uri $pixelFlasherUrl -OutFile $pixelFlasherZip
                                    Expand-Archive -Path $pixelFlasherZip -DestinationPath $pixelFlasherPath -Force
                                    Remove-Item $pixelFlasherZip -Force
                                    Write-Host "Pixel Flasher installé avec succès."
                                } else {
                                    Write-Host "Pixel Flasher est déjà installé."
                                }
                            }
                        }
                    }

                    Write-Host "Installation des outils Android sélectionnés terminée."
                } else {
                    Write-Host "Aucun outil Android sélectionné."
                }
            }
        }
    }
})
$form.Controls.Add($button)

$form.ShowDialog()
