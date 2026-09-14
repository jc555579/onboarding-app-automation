
function Download-App {
  param(
    $Name,
    $Url,
    $Output
  )

  Write-Host "Downloading $Name..."

  # getting the download urlnd storing it to output location 
  curl.exe -L $Url -o $Output

  # Checks if downloaded successfully
  if ($LASTEXITCODE -eq 0 -and (Test-Path $Output)) {
    Write-Host "$Name downloaded successfully."
  }
  else {
    Write-Host "Failed to download $Name."
  }
}

# url for apps
$chromeUrl = "https://dl.google.com/chrome/install/ChromeStandaloneSetup64.exe"
$teamViewerUrl = "https://download.teamviewer.com/download/TeamViewer_Setup_x64.exe"
$anyDeskUrl = "https://anydesk.com/en/downloads/thank-you?dv=win_exe"



# Calls function
# Google Chrome
Download-App "Google Chrome"  $chromeUrl "installers/chrome.exe"

# Team Viewer
Download-App "TeamViewer" $teamViewerUrl ".\installers\teamviewer.exe"

# Any Desk
Download-App "AnyDesk" $anydeskUrl ".\installers\anydesk.exe"

