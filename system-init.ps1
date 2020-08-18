# -----------------------------------------------------------------------------
# - Initialize my developer machine the lazy way -
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# - Logging Helpers  -
# -----------------------------------------------------------------------------
Function Write-TaskStart($description) { Write-Host -ForegroundColor DarkCyan "$description..." }
Function Write-TaskComplete() { Write-Host -ForegroundColor DarkGreen "DONE!" }
Function Invoke-ChocoInstall($packageName, $packageArgs) { 
    If ([String]::IsNullOrWhitespace($packageArgs)) {
        Write-TaskStart "Installing Chocolatey package: '$packageName' with options '$packageArgs'"
        choco install -y $packageName --package-parameters="$packageArgs"
    }
    Else {
        Write-TaskStart "Installing Chocolatey package: '$packageName'"
        choco install -y $packageName
    }
    Write-TaskComplete
}

Write-Host "Ready? Get set! GO!"

# -----------------------------------------------------------------------------
# - Configure PowerShell Repository -
# -----------------------------------------------------------------------------
Write-TaskStart "Configure PowerShell to only use packages vetted for Orbis use"
Get-PSRepository | Unregister-PSRepository
Register-PSRepository `
    -Name 'packages.orbis.com' `
    -SourceLocation 'https://packages.orbis.com/nuget/ops-ps-aggregate' `
    -InstallationPolicy Trusted
Write-TaskComplete

# -----------------------------------------------------------------------------
# - Disable UAC so we can get this down without pesky elevation prompts -
# -----------------------------------------------------------------------------
Write-TaskStart "Disable UAC temporarily so we don't get pesky prompts throughout"
Disable-UAC
Write-TaskComplete

# -----------------------------------------------------------------------------
# - Ensure Chocolatey helper modules are imported -
# -----------------------------------------------------------------------------
# Boxstarter will install Chocolatey as part of this, but Chocolatey's helper
#  modules are not made available immediately in the current PowerShell session.
#  Manually import the module in so we can use them below.
# See https://stackoverflow.com/a/46760714/2709150 for a more detailed explanation.
$env:ChocolateyInstall = Convert-Path "$((Get-Command choco).Path)\..\.."
Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"

# -----------------------------------------------------------------------------
# - Configure Windows Explorer -
# -----------------------------------------------------------------------------
Write-TaskStart "Configure Windows Explorer with some sane options"
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

# Open Explorer to 'This PC', not quick access
Set-ItemProperty `
    -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' `
    -Name 'LaunchTo' `
    -Value 1

# Taskbar where window is open for multi-monitor
Set-ItemProperty `
    -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' `
    -Name 'MMTaskbarMode' `
    -Value 2
    
# Win+X should launch PowerShell
Set-CornerNavigationOptions -EnableUsePowerShellOnWinX

# Set Taskbar options
#Set-BoxstarterTaskbarOptions -Size Small -Dock Left -Combine Always -AlwaysShowIconsOn -MultiMonitorOn -MultiMonitorMode All -MultiMonitorCombine Always

Write-TaskComplete

# -----------------------------------------------------------------------------
# - Enable Windows Features
# -----------------------------------------------------------------------------
Write-TaskStart "Installing Windows Subsystem for Linux"
choco install -y wsl
Write-TaskComplete

# -----------------------------------------------------------------------------
# - Installations -
# -----------------------------------------------------------------------------
Write-TaskStart "Installing Ubuntu 20.04"
# Install Ubuntu (Do this before Windows Terminal so it can auto-create a Ubuntu profile)
# Find the URL to the distro appx file from here: https://docs.microsoft.com/en-us/windows/wsl/install-manual
Invoke-WebRequest -Uri 'https://aka.ms/wslubuntu2004' -OutFile Ubuntu.appx -UseBasicParsing
Add-AppxPackage .\Ubuntu.appx
Remove-Item -Path .\Ubuntu.appx
Write-TaskComplete

# Utilities
Write-TaskStart "Installing utilities"
Invoke-ChocoInstall "powershell-core"
choco install -y powershell-core # Install before Windows Terminal so a PS Core profile gets auto-created
choco install -y notepadplusplus
choco install -y microsoft-edge
choco install -y 7zip.install
choco install -y powertoys
choco install -y sysinternals
choco install -y beyondcompare
choco install -y sharex
choco install -y microsoft-windows-terminal
choco install -y jetbrainsmono
Write-TaskComplete

# Dev Tools
Write-TaskStart "Installing developer tools"
choco install -y git --package-parameters="/GitAndUnixToolsOnPath /WindowsTerminal /NoShellIntegration /SChannel"
choco install -y vscode
choco install -y linqpad
choco install -y rdmfree
choco install -y visualstudio2019professional # TODO: Figure out which workloads to install
choco install -y sql-server-management-studio
choco install -y sqltoolbelt --package-parameters="/products: 'SQL Compare, SQL Data Compare, SQL Dependency Tracker, SQL Prompt, SQL Search'"
choco install -y jetbrains-rider
choco install -y resharper-ultimate-all --params="/PerMachine /NoCpp /NoTeamCityAddin"
choco install -y insomnia-rest-api-client
choco install -y fiddler
choco install -y nodejs-lts
Write-TaskComplete

RefreshEnv # refresh environment variables, so we can resolve tools like npm, node, git, etc.

# -----------------------------------------------------------------------------
# - Configure Tools -
# -----------------------------------------------------------------------------
Write-TaskStart "Configuring Tools"
npm config set registry 'https://packages.orbis.com/npm/ops-npm-aggregate/'
Ubuntu2004 install --root
Ubuntu2004 run apt update
Ubuntu2004 run apt upgrade -y
Write-TaskComplete

# -----------------------------------------------------------------------------
# - Install VSCode extensions -
# -----------------------------------------------------------------------------
Write-TaskStart "Installing VSCode extensions"
code --install-extension ms-dotnettools.csharp
code --install-extension editorconfig.editorconfig
code --install-extension github.github-vscode-theme
code --install-extension ionide.ionide-fsharp
code --install-extension ionide.ionide-paket
code --install-extension davidanson.vscode-markdownlint
code --install-extension pkief.material-icon-theme
code --install-extension ms-vscode.powershell
code --install-extension 2gua.rainbow-brackets
code --install-extension mechatroner.rainbow-csv
code --install-extension ms-vscode-remote.remote-wsl
code --install-extension vscodevim.vim
Write-TaskComplete

# -----------------------------------------------------------------------------
# - TODO: Pull down any customized settings  -
# -----------------------------------------------------------------------------
# Git Config
# VSCode
# Windows Terminal

# -----------------------------------------------------------------------------
# - Clone Source Code Repos -
# -----------------------------------------------------------------------------
Write-TaskStart "Clone source code repos"
New-Item -Type Directory -Path 'C:\Source'
cd 'C:\Source'
git.exe clone --recurse-submodules 'https://azd.orbis.app/tfs/Main/OPS/_git/ops-main'
Write-TaskComplete

# -----------------------------------------------------------------------------
# - Re-enable any critical items -
# -----------------------------------------------------------------------------
Write-TaskStart "Re-enabling UAC now that we're finishing up"
Enable-UAC
Write-TaskComplete

Enable-MicrosoftUpdate
Install-WindowsUpdate -acceptEula

# -----------------------------------------------------------------------------
# - List things that will need to be installed/configured manually -
# -----------------------------------------------------------------------------
Write-Host "=============================================="
Write-Host "Manual installation/configuration required" -ForegroundColor Magenta 
Write-Host "=============================================="
Write-Host " * SQL Sentry Plan Explorer"
Write-Host " * SSMS Boost"
