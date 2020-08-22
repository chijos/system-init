# -----------------------------------------------------------------------------
# - Initialize my developer machine the lazy way -
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# - Helper Functions -
# -----------------------------------------------------------------------------
Function Get-ChocoInstalledStatus($packageName) {
    $matchingPackages = $(choco list --local-only | Where-Object { $_.StartsWith($packageName) -eq $true })
    Return $matchingPackages.Count -ge 1
}

Function Invoke-ChocoInstallCustomized($packageName, $packageArgs) {
    If ($(Get-ChocoInstalledStatus $packageName) -eq $true) {
        choco upgrade -y $packageName --package-parameters="$packageArgs"
    }
    Else {
        choco install -y $packageName --package-parameters="$packageArgs"
    }
}

Function Invoke-ChocoInstall($packageName) { 
    If ($(Get-ChocoInstalledStatus $packageName) -eq $true) { choco upgrade -y $packageName }
    Else { choco install -y $packageName }
}

# -----------------------------------------------------------------------------
# - Configure PowerShell Repository -
# -----------------------------------------------------------------------------
"Configure PowerShell to only use packages vetted for Orbis use"
Get-PSRepository | Unregister-PSRepository
Register-PSRepository `
    -Name 'packages.orbis.com' `
    -SourceLocation 'https://packages.orbis.com/nuget/ops-ps-aggregate' `
    -InstallationPolicy Trusted
"DONE!"

# -----------------------------------------------------------------------------
# - Disable UAC so we can get this down without pesky elevation prompts -
# -----------------------------------------------------------------------------
"Disable UAC temporarily so we don't get pesky prompts throughout"
Disable-UAC
"DONE!"

# -----------------------------------------------------------------------------
# - Configure Windows Explorer -
# -----------------------------------------------------------------------------
"Configure Windows Explorer with some sane options"
# Show hidden files / protected OS files, file extensions
Set-WindowsExplorerOptions `
    -EnableShowHiddenFilesFoldersDrives `
    -EnableShowProtectedOSFiles `
    -EnableShowFileExtensions

# Expand navigation pane to the current folder
Set-ItemProperty `
    -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' `
    -Name 'NavPaneExpandToCurrentFolder' `
    -Value 1

# Add some useful locations to navigation pane
Set-ItemProperty `
    -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' `
    -Name 'NavPaneShowAllFolders' `
    -Value 1

# Hide the TaskView button from the taskbar
Set-ItemProperty `
    -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' `
    -Name 'ShowTaskViewButton' `
    -Value 0

# Open Explorer to 'This PC', not quick access
Set-ItemProperty `
    -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' `
    -Name 'LaunchTo' `
    -Value 1
"DONE!"

# -----------------------------------------------------------------------------
# - Enable Windows Features
# -----------------------------------------------------------------------------
"Installing Windows Subsystem for Linux"
Invoke-ChocoInstall "wsl"
"DONE!"

# -----------------------------------------------------------------------------
# - Installations -
# -----------------------------------------------------------------------------
If($(Get-AppxPackage -Name 'CanonicalGroupLimited.Ubuntu20.04onWindows').Count -ge 1) {
    "Skipping Ubuntu install as 20.04 is already on the system"
}
Else {
    "Installing Ubuntu 20.04"
    # Install Ubuntu (Do this before Windows Terminal so it can auto-create a Ubuntu profile)
    # Find the URL to the distro appx file from here: https://docs.microsoft.com/en-us/windows/wsl/install-manual
    Invoke-WebRequest -Uri 'https://aka.ms/wslubuntu2004' -OutFile Ubuntu.appx -UseBasicParsing
    Add-AppxPackage .\Ubuntu.appx
    Remove-Item -Path .\Ubuntu.appx
}
"DONE!"

# Utilities
"Installing utilities"
@(
    "powershell-core", # Install before Windows Terminal so a PS Core profile gets auto-created
    "notepadplusplus",
    "microsoft-edge",
    "7zip.install",
    "powertoys",
    "sysinternals",
    "beyondcompare",
    "sharex",
    "microsoft-windows-terminal",
    "jetbrainsmono"
) | ForEach-Object { Invoke-ChocoInstall $_ }
"DONE!"

# Dev Tools
"Installing developer tools"
Invoke-ChocoInstallCustomized "git" "/GitAndUnixToolsOnPath /WindowsTerminal /NoShellIntegration /SChannel"
@(
    "vscode",
    "linqpad",
    "rdmfree",
    "visualstudio2019professional", # TODO: Figure out which workloads to install
    "sql-server-management-studio",
    "jetbrains-rider",
    "insomnia-rest-api-client",
    "fiddler",
    "nodejs-lts"
) | ForEach-Object { Invoke-ChocoInstall $_ }
Invoke-ChocoInstallCustomized "sqltoolbelt" "/products: 'SQL Compare, SQL Data Compare, SQL Dependency Tracker, SQL Prompt, SQL Search'"
Invoke-ChocoInstallCustomized "resharper-ultimate-all" "/PerMachine /NoCpp /NoTeamCityAddin"
"DONE!"

# -----------------------------------------------------------------------------
# - Configure Tools -
# -----------------------------------------------------------------------------
"Configuring Tools"
npm config set registry 'https://packages.orbis.com/npm/ops-npm-aggregate/'
Ubuntu2004 install --root
Ubuntu2004 run apt update
Ubuntu2004 run apt upgrade -y
"DONE!"

# -----------------------------------------------------------------------------
# - TODO: Pull down any customized settings  -
# -----------------------------------------------------------------------------
# Git Config
# VSCode
# Windows Terminal

# -----------------------------------------------------------------------------
# - Install VSCode extensions -
# -----------------------------------------------------------------------------
#TODO: Can't use these until we VSCode config in place to disable strict SSL (ノಠ益ಠ)ノ彡┻━┻
#"Installing VSCode extensions"
#code --install-extension ms-dotnettools.csharp
#code --install-extension editorconfig.editorconfig
#code --install-extension github.github-vscode-theme
#code --install-extension ionide.ionide-fsharp
#code --install-extension ionide.ionide-paket
#code --install-extension davidanson.vscode-markdownlint
#code --install-extension pkief.material-icon-theme
#code --install-extension ms-vscode.powershell
#code --install-extension 2gua.rainbow-brackets
#code --install-extension mechatroner.rainbow-csv
#code --install-extension ms-vscode-remote.remote-wsl
#code --install-extension vscodevim.vim
#"DONE!"

# -----------------------------------------------------------------------------
# - Clone Source Code Repos -
# -----------------------------------------------------------------------------
If ($(Test-Path -Path 'C:\Source\ops-main')) {
    "ops-main is already cloned to C:\Source"
}
Else {
    "Cloning ops-main to C:\Source"
    If ($(Test-Path -Path 'C:\Source') -ne $true) {
        New-Item -Type Directory -Path 'C:\Source'
    }
    cd 'C:\Source'
    git clone --recurse-submodules 'https://azd.orbis.app/tfs/Main/OPS/_git/ops-main'
}
"DONE!"

# -----------------------------------------------------------------------------
# - Re-enable any critical items -
# -----------------------------------------------------------------------------
"Re-enabling UAC now that we're finishing up"
Enable-UAC
"DONE!"

Enable-MicrosoftUpdate
Install-WindowsUpdate -acceptEula

# -----------------------------------------------------------------------------
# - List things that will need to be installed/configured manually -
# -----------------------------------------------------------------------------
"=============================================="
"Manual installation/configuration required"
"=============================================="
" * SQL Sentry Plan Explorer"
" * SSMS Boost"
