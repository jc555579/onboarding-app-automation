
$url = "https://github.com/ip7z/7zip/releases/download/26.03/7z2603-x64.exe"

# This stores the destination.
$installer = ".\installers\7zip.exe" #

# Writing instruction for user
Write-Host "Downloading 7-Zip.exe"

# Process for downloading the url then put it to installer folder
curl.exe -L $url -o $installer

# Verify if the file actually downloaded
if (Test-Path $installer) {
  Write-Host "7-Zip installer downloaded successfully."
} 
else {
  Write-Host "Download failed."
}
