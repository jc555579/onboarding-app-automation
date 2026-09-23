# Optional client name for client-specific application configuration
param (
  [string]$ClientName
)

# Admin is required for this script
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  Write-Host "Please run this script as Administrator."
  exit
}

# Get the folder where this script is located
$ScriptRoot = $PSScriptRoot

# Create installer folder
$InstallerFolder = Join-Path $ScriptRoot "installers"

if (-not (Test-Path $InstallerFolder)) {
  New-Item -ItemType Directory -Path $InstallerFolder | Out-Null
}

# Create log folder

$LogFolder = Join-Path $ScriptRoot "logs"

if (-not (Test-Path $LogFolder)) {
  New-Item -ItemType Directory -Path $LogFolder | Out-Null
}

$LogFile = Join-Path $LogFolder "onboarding.log"

# Application URLs for download

$chromeUrl = "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi"
$teamViewerUrl = "https://download.teamviewer.com/download/TeamViewer_Setup_x64.exe"
$anyDeskUrl = "https://download.anydesk.com/AnyDesk.exe"
$acrobatUrl = "https://admdownload.adobe.com/rdcm/installers/live/readerdc64_a_cra_hrma_install.exe?filename=Reader_en_install.exe"
$libreOfficeUrl = "https://download.documentfoundation.org/libreoffice/stable/26.8.0/win/x86_64/LibreOffice_26.8.0_Win_x86-64.msi"
$egnyteUrl = "https://egnyte-cdn.egnyte.com/egnytedrive/win/en-us/4.6.1/EgnyteDesktopApp_4.6.1_204.msi"


# Application definitions
$Apps = @{
  AnyDesk     = @{
    Name           = "AnyDesk"
    Url            = $anyDeskUrl
    Output         = Join-Path $InstallerFolder "anydesk.exe"
    Type           = "EXE"
    Arguments      = '--install "C:\Program Files (x86)\AnyDesk" --silent'
    ShortcutTarget = "C:\Program Files (x86)\AnyDesk\AnyDesk.exe"
  }

  TeamViewer  = @{
    Name      = "TeamViewer"
    Url       = $teamViewerUrl
    Output    = Join-Path $InstallerFolder "teamviewer.exe"
    Type      = "EXE"
    Arguments = "/S"
  }

  Chrome      = @{
    Name      = "Google Chrome"
    Url       = $chromeUrl
    Output    = Join-Path $InstallerFolder "chrome.exe"
    Type      = "MSI"
    Arguments = "/qn /norestart"
  }

  Acrobat     = @{
    Name      = "Adobe Acrobat"
    Url       = $acrobatUrl
    Output    = Join-Path $InstallerFolder "acrobat.exe"
    Type      = "EXE"
    Arguments = "/sAll /rs /rps /msi /qn EULA_ACCEPT=YES"
  }

  LibreOffice = @{
    Name      = "LibreOffice"
    Url       = $libreOfficeUrl
    Output    = Join-Path $InstallerFolder "libreoffice.msi"
    Type      = "MSI"
    Arguments = "/qn /norestart"
  }

  Egnyte      = @{
    Name      = "Egnyte"
    Url       = $egnyteUrl
    Output    = Join-Path $InstallerFolder "egnyte.msi"
    Type      = "MSI"
    Arguments = "/qn /norestart ED_UPDATE_ON_BOOT=1"
  }
}


# Standard applications
$StandardApps = @(
  "TeamViewer"
  "AnyDesk"
)


# Client applications
$ClientApps = @{
  urbanx = @(
    "TeamViewer"
    "Chrome"
    "LibreOffice"
    "Egnyte"
    "Acrobat"
    "AnyDesk"
  )

  # TO ADD CLIENT, JUST MAKE THIS FORMAT
  # Then add the URL .exe or .msi and app definitions

  # Future clients:
  # client2Name = @(
  #     "Chrome"
  #     "Acrobat"
  # )

  # client3Name = @(
  #     "AnyDesk"
  #     "Chrome"
  #     "Egnyte"
  # )
}

# Functions
function Download-App {
  param(
    $Name,
    $Url,
    $Output
  )

  # Prevent duplicate downloads
  if (Test-Path $Output) {
    Write-Log "$Name installer already exists. Skipping download."
    return $true
  }

  Write-Log "Downloading $Name..."

  curl.exe -L $Url -o $Output

  if ($LASTEXITCODE -eq 0 -and (Test-Path $Output)) {
    Write-Log "$Name downloaded successfully."
    return $true
  }
  else {
    Write-Log "Failed to download $Name."
    return $false
  }
}


function Test-AppInstalled {
  param(
    $Name
  )

  $UninstallPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
  )

  foreach ($Path in $UninstallPaths) {

    $App = Get-ItemProperty $Path -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -like "*$Name*" }

    if ($App) {
      return $true
    }
  }

  return $false
}


# Verify the digital signature of the downloaded installer.
#
# This checks whether Windows considers the Authenticode
# digital signature valid before allowing installation.
#
# If the signature is not valid, installation will be skipped.

function Test-AppSignature {

  param(
    $Name,
    $Installer
  )

  Write-Log "Verifying digital signature for $Name..."

  $Signature = Get-AuthenticodeSignature -FilePath $Installer

  if ($Signature.Status -eq "Valid") {

    Write-Log "$Name signature is valid."
    Write-Log "Signer: $($Signature.SignerCertificate.Subject)"

    return $true
  }
  else {

    Write-Log "$Name signature verification failed."
    Write-Log "Signature status: $($Signature.Status)"

    return $false
  }
}


function Remove-InstallerLockFiles {

  $LockFiles = @(
    (Join-Path $ScriptRoot "service.conf.lock"),
    (Join-Path $ScriptRoot "system.conf.lock")
  )

  foreach ($LockFile in $LockFiles) {

    if (Test-Path $LockFile) {

      try {

        Remove-Item $LockFile -Force -ErrorAction Stop

        Write-Log "Removed temporary lock file: $LockFile"

      }
      catch {

        Write-Log "Could not remove temporary lock file: $LockFile"

      }
    }
  }
}


function Install-App {

  param(
    $Name,
    $Installer,
    $Type,
    $Arguments,
    $ShortcutTarget
  )

  try {

    Write-Log "Installing $Name..."

    # Acrobat uses a different completion check because
    # its installer may launch another process and keep
    # the original process running after installation finishes.

    if ($Name -eq "Adobe Acrobat") {

      Start-Process $Installer `
        -ArgumentList $Arguments

      Write-Log "Waiting for Adobe Acrobat installation to finish..."

      $TimeoutSeconds = 600
      $ElapsedSeconds = 0
      $CheckInterval = 3

      while ($ElapsedSeconds -lt $TimeoutSeconds) {

        if (Test-AppInstalled "Adobe Acrobat") {

          Write-Log "Adobe Acrobat installed successfully."

          return
        }

        Start-Sleep -Seconds $CheckInterval

        $ElapsedSeconds += $CheckInterval
      }

      Write-Log "Adobe Acrobat installation timed out after $TimeoutSeconds seconds."

      return
    }


    # Normal installation process for MSI applications

    if ($Type -eq "MSI") {

      $process = Start-Process "msiexec.exe" `
        -ArgumentList "/i `"$Installer`" $Arguments" `
        -Wait `
        -PassThru
    }

    # Normal installation process for EXE applications

    else {

      $process = Start-Process $Installer `
        -ArgumentList $Arguments `
        -Wait `
        -PassThru
    }


    # Check installation result

    if ($process.ExitCode -eq 0) {

      if (Test-AppInstalled $Name) {

        Write-Log "$Name installed successfully."

        if ($ShortcutTarget) {

          New-DesktopShortcut `
            -Name $Name `
            -TargetPath $ShortcutTarget
        }
      }
      else {

        Write-Log "$Name installer exited successfully, but the application was not detected."
      }
    }
    
    elseif ($process.ExitCode -eq 1618) {
      Write-Log "$Name installation could not start because another Windows Installer installation is already in progress. Exit code: 1618"
    }

    elseif ($process.ExitCode -eq 3010) {

      if (Test-AppInstalled $Name) {

        Write-Log "$Name installed successfully. Restart required."

        if ($ShortcutTarget) {

          New-DesktopShortcut `
            -Name $Name `
            -TargetPath $ShortcutTarget
        }
      }
      else {

        Write-Log "$Name installer requested a restart, but the application was not detected."
      }
    }

    else {

      Write-Log "$Name installation failed. Exit code: $($process.ExitCode)"
    }
  }

  finally {

    # Remove temporary lock files created in the project directory.

    Remove-InstallerLockFiles
  }
}


function New-DesktopShortcut {

  param(
    $Name,
    $TargetPath
  )

  if (-not (Test-Path $TargetPath)) {

    Write-Log "$Name executable not found. Desktop shortcut was not created."

    return
  }

  $DesktopPath = [Environment]::GetFolderPath("CommonDesktopDirectory")

  $ShortcutPath = Join-Path $DesktopPath "$Name.lnk"

  $WshShell = New-Object -ComObject WScript.Shell

  $Shortcut = $WshShell.CreateShortcut($ShortcutPath)

  $Shortcut.TargetPath = $TargetPath

  $Shortcut.WorkingDirectory = Split-Path $TargetPath

  $Shortcut.Description = $Name

  $Shortcut.Save()

  Write-Log "$Name desktop shortcut created."
}


function Write-Log {

  param(
    $Message
  )

  $Timestamp = Get-Date -Format "yyyy-MM-dd HH\:mm\:ss"

  $LogMessage = "[$Timestamp] $Message"

  Write-Host $LogMessage

  Add-Content -Path $LogFile -Value $LogMessage
}


# Main logic

if ($ClientName) {

  # Check if the client exists

  if ($ClientApps.ContainsKey($ClientName)) {

    # Get this client's exact app list

    $AppList = $ClientApps[$ClientName]
  }

  else {

    Write-Log "Client '$ClientName' was not found."

    exit
  }
}

else {

  # No client specified, use standard applications

  $AppList = $StandardApps
}


# Start

Write-Log "===== Windows Onboarding Started ====="


# Download all applications in the selected list

foreach ($AppName in $AppList) {

  Write-Log ""

  Write-Log "----- $AppName -----"

  $App = $Apps[$AppName]


  # Check if the application is already installed

  if (Test-AppInstalled $App.Name) {

    Write-Log "$($App.Name) is already installed. Skipping."

    continue
  }


  # Download installer

  $Downloaded = Download-App $App.Name $App.Url $App.Output

  if ($Downloaded) {

    $InstallerPath = (Resolve-Path $App.Output).Path


    # Verify the installer signature AFTER downloading
    # and BEFORE installing.

    $SignatureValid = Test-AppSignature $App.Name $InstallerPath


    if ($SignatureValid) {

      # Only install if the digital signature is valid

      Install-App `
        -Name $App.Name `
        -Installer $InstallerPath `
        -Type $App.Type `
        -Arguments $App.Arguments `
        -ShortcutTarget $App.ShortcutTarget
    }

    else {

      # No installation with an invalid,
      # missing, or otherwise untrusted signature.

      Write-Log "Skipping installation of $($App.Name) because signature verification failed."
    }
  }
}