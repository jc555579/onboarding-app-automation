# Optional client name for client-specific application configuration
param (
  [string]$ClientName
)

# Create installer folder
$InstallerFolder = ".\installers"
if (-not (Test-Path $InstallerFolder)) {
  New-Item -ItemType Directory -Path $InstallerFolder | Out-Null
}

# Application URLs for download (it will be used for curl command)
$chromeUrl = "https://dl.google.com/chrome/install/ChromeStandaloneSetup64.exe"
$teamViewerUrl = "https://download.teamviewer.com/download/TeamViewer_Setup_x64.exe"
$anyDeskUrl = "https://anydesk.com/en/downloads/thank-you?dv=win_exe"
$acrobatUrl = "https://admdownload.adobe.com/rdcm/installers/live/readerdc64_a_cra_hrma_install.exe?filename=Reader_en_install.exe"
$libreOfficeUrl = "https://download.documentfoundation.org/libreoffice/stable/26.8.0/win/x86_64/LibreOffice_26.8.0_Win_x86-64.msi"
$egnyteUrl = "https://egnyte-cdn.egnyte.com/egnytedrive/win/en-us/4.6.1/EgnyteDesktopApp_4.6.1_204.msi"


# Application definitions
$Apps = @{

  AnyDesk     = @{
    Name   = "AnyDesk"
    Url    = $anyDeskUrl
    Output = ".\installers\anydesk.exe"
  }

  TeamViewer  = @{
    Name   = "TeamViewer"
    Url    = $teamViewerUrl
    Output = ".\installers\teamviewer.exe"
  }

  Chrome      = @{
    Name   = "Google Chrome"
    Url    = $chromeUrl
    Output = ".\installers\chrome.exe"
  }

  Acrobat     = @{
    Name   = "Adobe Acrobat"
    Url    = $acrobatUrl
    Output = ".\installers\acrobat.exe"
  }

  LibreOffice = @{
    Name   = "LibreOffice"
    Url    = $libreOfficeUrl
    Output = ".\installers\libreoffice.msi"
  }

  Egnyte      = @{
    Name   = "Egnyte"
    Url    = $egnyteUrl
    Output = ".\installers\egnyte.msi"
  }
}



# Standard applications
$StandardApps = @(
  "AnyDesk"
  "TeamViewer"
  "Chrome"
  "Acrobat"
  "LibreOffice"
)

# Client applications
$ClientApps = @{
  urbanx = @(
    "AnyDesk"
    "TeamViewer"
    "Chrome"
    "Acrobat"
    "LibreOffice"
    "Egnyte"
  )

  # TO ADD CLIENT, JUST MAKE THIS FORMAT(Then add the url .exe or .msi and app definitions)
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

  Write-Host "Downloading $Name..."

  # Download the file from the URL
  # and save it to the output location
  curl.exe -L $Url -o $Output

  # Check if the download was successful
  if ($LASTEXITCODE -eq 0 -and (Test-Path $Output)) {
    Write-Host "$Name downloaded successfully."
  }
  else {
    Write-Host "Failed to download $Name."
  }
}


# Main logic
if ($ClientName) {

  # Check if the client exists
  if ($ClientApps.ContainsKey($ClientName)) {

    # Get this client's exact app list
    $AppList = $ClientApps[$ClientName]

  }
  else {

    Write-Host "Client '$ClientName' was not found."
    exit
  }

}
else {

  # No client specified, use standard applications
  $AppList = $StandardApps
}


# Download all applications in the selected list

foreach ($AppName in $AppList) {
  $App = $Apps[$AppName]

  Download-App $App.Name $App.Url $App.Output
}
