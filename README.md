# Windows Onboarding App Automation

A PowerShell-based automation script for downloading, validating, and installing applications during Windows workstation onboarding.

The project is designed to simplify the initial software setup process for IT staff by allowing applications to be managed through a centralized configuration and selected based on the client.

## Overview

When preparing a newly installed Windows workstation, IT staff may need to install several applications repeatedly.

Instead of manually downloading and installing each application, this project automates the process:

```text
Select Client
     ↓
Get Application List
     ↓
Check Installed Applications
     ↓
Check Existing Installers
     ↓
Download Installers
     ↓
Verify Digital Signatures
     ↓
Install Applications
     ↓
Log Installation Results
     ↓
Ready for Onboarding
```

The application configuration is separated from the installation logic, making it easier to add new applications and clients without creating additional installation functions.

## Features

- Download application installers automatically
- Support both `.EXE` and `.MSI` installers
- Install applications using PowerShell
- Client-specific application configurations
- Standard application configuration
- Centralized application definitions
- Administrator privilege check
- Automatic creation of required directories
- Detect already-installed applications
- Prevent unnecessary duplicate downloads
- Verify Authenticode digital signatures before installation
- Support silent installation arguments where supported
- Installation exit-code handling
- Installation logging
- Timestamped user output and log messages
- Designed to support additional clients and applications

## Current Applications

| Application          | Installer Type | Download | Installation |
| -------------------- | -------------- | -------- | ------------ |
| AnyDesk              | EXE            | Yes      | Configured   |
| TeamViewer           | EXE            | Yes      | Configured   |
| Google Chrome        | EXE            | Yes      | Configured   |
| Adobe Acrobat Reader | EXE            | Yes      | Configured   |
| LibreOffice          | MSI            | Yes      | Configured   |
| Egnyte               | MSI            | Yes      | Configured   |

> Installation behavior and command-line arguments are configured individually for each application. Some installers may display a graphical interface depending on the vendor's installer behavior.

## Client Configuration

Applications are managed through client-specific lists.

For example:

```powershell
$ClientApps = @{
    clientName = @(
        "AnyDesk"
        "TeamViewer"
        "Chrome"
        "Egnyte"
    )
}
```

Each client has its own exact application list.

This allows a client to have:

- Only a few applications
- The standard applications
- Standard applications plus additional applications
- A completely different application combination

Adding a new client does not require creating another installation function.

Example:

```powershell
$ClientApps = @{
    Client1 = @(
        "AnyDesk"
        "Chrome"
        "LibreOffice"
    )

    Client2 = @(
        "Chrome"
        "Acrobat"
    )

    Client3 = @(
        "AnyDesk"
        "Egnyte"
        "LibreOffice"
    )
}
```

## Application Configuration

Applications are defined in a centralized `$Apps` hashtable.

Example:

```powershell
$Apps = @{
    LibreOffice = @{
        Name      = "LibreOffice"
        Url       = $libreOfficeUrl
        Output    = ".\installers\libreoffice.msi"
        Type      = "MSI"
        Arguments = "/qn /norestart"
    }
}
```

Each application definition contains:

| Property    | Purpose                                         |
| ----------- | ----------------------------------------------- |
| `Name`      | Display name of the application                 |
| `Url`       | Download URL                                    |
| `Output`    | Location where the installer is saved           |
| `Type`      | Installer type (`EXE` or `MSI`)                 |
| `Arguments` | Command-line arguments used during installation |

This keeps application data separate from the functions that perform downloading, validation, and installation.

## Requirements

- Windows 10 or Windows 11
- PowerShell
- Internet connection
- Administrator privileges

## Usage

### 1. Clone the repository

```powershell
git clone <repository-url>
cd onboarding-app-automation
```

### 2. Run the script

Without specifying a client:

```powershell
.\onboarding.ps1
```

This uses the applications defined in:

```powershell
$StandardApps
```

For a specific client:

```powershell
.\onboarding.ps1 clientName
```

The script retrieves the exact application list configured for that client.

The script must be run with administrator privileges.

## Project Structure

```text
onboarding-app-automation/
│
├── onboarding.ps1
├── README.md
│
├── installers/
│   ├── anydesk.exe
│   ├── teamviewer.exe
│   ├── chrome.exe
│   ├── acrobat.exe
│   ├── libreoffice.msi
│   └── egnyte.msi
│
└── logs/
    └── onboarding.log
```

The `installers/` and `logs/` directories are created automatically by the script if they do not already exist.

Downloaded installers are stored locally in the `installers/` directory.

Installation activity is recorded in:

```text
logs/onboarding.log
```

## How It Works

### 1. Administrator Check

The script first checks whether PowerShell is running with administrator privileges.

If administrator privileges are not detected, the script stops and asks the user to run it as Administrator.

### 2. Directory Setup

The script creates the required directories:

```text
installers/
logs/
```

if they do not already exist.

### 3. Application Catalog

All supported applications are defined in the centralized `$Apps` hashtable.

Each application contains its download URL, installer path, installer type, and installation arguments.

### 4. Client Selection

The script determines which application list to use.

If a client is provided:

```powershell
.\onboarding.ps1 clientName
```

the script retrieves:

```powershell
$ClientApps["clientName"]
```

If no client is provided, it uses:

```powershell
$StandardApps
```

### 5. Installed Application Detection

Before downloading anything, the script checks whether the application is already installed.

If the application is detected, the script skips it:

```text
Application already installed
        ↓
      Skip
```

This prevents unnecessary installation attempts.

### 6. Installer Download

If the application is not installed, the script checks whether its installer already exists locally.

If the installer already exists:

```text
Installer already exists
        ↓
   Skip download
        ↓
Use existing installer
```

Otherwise, the installer is downloaded using `curl.exe`:

```powershell
curl.exe -L $Url -o $Output
```

This prevents the same installer from being downloaded repeatedly during subsequent runs.

### 7. Digital Signature Verification

After downloading an installer, the script checks its Authenticode digital signature:

```powershell
Get-AuthenticodeSignature
```

The installer is only allowed to continue to installation when Windows reports a valid signature.

If signature verification fails, installation is skipped.

### 8. Installation

The `Install-App` function determines whether the application uses an `.EXE` or `.MSI` installer.

For MSI applications, the script uses:

```text
msiexec.exe
```

For EXE applications, the installer executable is launched directly with its configured arguments.

Example MSI installation:

```text
msiexec.exe /i installer.msi /qn /norestart
```

The script waits for the installation process to finish before continuing to the next application.

### 9. Installation Result Handling

The script checks the installer's exit code after installation.

Successful installations are recorded as successful.

Exit code `3010` is treated as a successful installation where a restart is required.

Other non-zero exit codes are reported as installation failures.

### 10. Installation Logging

The script records important events in:

```text
logs/onboarding.log
```

Log entries include timestamps and events such as:

```text
[2026-09-18 02:30:01] ===== Windows Onboarding Started =====
[2026-09-18 02:30:02] Downloading Google Chrome...
[2026-09-18 02:30:05] Google Chrome downloaded successfully.
[2026-09-18 02:30:05] Verifying digital signature for Google Chrome...
[2026-09-18 02:30:05] Google Chrome signature is valid.
[2026-09-18 02:30:06] Installing Google Chrome...
[2026-09-18 02:30:12] Google Chrome installed successfully.
```

The same messages are displayed in the PowerShell console while the script is running.

## Development Status

### Completed

- [x] PowerShell project setup
- [x] Application catalog
- [x] Standard application list
- [x] Client-specific application lists
- [x] Automatic installer directory creation
- [x] Automatic log directory creation
- [x] Application download function
- [x] Administrator privilege check
- [x] EXE/MSI installer type configuration
- [x] Installation function structure
- [x] LibreOffice silent installation
- [x] Chrome installation configuration
- [x] AnyDesk installation configuration
- [ ] Adobe Acrobat Reader installation configuration
- [x] TeamViewer installation configuration
- [x] Egnyte installation configuration
- [x] Already-installed application detection
- [x] Duplicate-download prevention
- [x] Digital signature verification
- [x] Installation exit-code handling
- [x] Installation logging
- [x] User output and progress messages

### Future Improvements

- Support additional clients
- Support additional applications
- Application version management
- Better installer validation
- Optional application installation
- Configuration separated into an external file
- Improved error recovery
- More detailed installation reports

## Design Approach

The project separates **configuration** from **automation logic**.

```text
                 Application Catalog
                        $Apps
                          │
                          ↓
                ┌──────────────────┐
                │ Client Selection │
                └──────────────────┘
                          │
                 ┌────────┴────────┐
                 ↓                 ↓
          Standard Apps       Client Apps
          $StandardApps       $ClientApps
                 │                 │
                 └────────┬────────┘
                          ↓
               Check Installed Apps
                          ↓
               Check Existing Files
                          ↓
                    Download-App
                          ↓
                Test-AppSignature
                          ↓
                    Install-App
                          ↓
                     Write-Log
```

This approach keeps the application configuration separate from the automation logic, making the script easier to maintain as the number of clients and applications increases.

## Learning Resources

This project was developed while learning Windows automation and PowerShell scripting.

The implementation uses concepts such as:

- PowerShell functions
- Parameters
- Hashtables
- Arrays
- Conditional statements
- Loops
- `Start-Process`
- `curl.exe`
- `msiexec`
- Exit codes
- Windows Registry
- Authenticode digital signatures
- Windows administrator privileges
- Command-line application installation
- File and directory handling
- Logging

Official vendor documentation is used when determining supported installation and silent-installation methods for individual applications.

## AI Assistance

AI tools were used as a development and learning aid during the project.

AI assistance was used to:

- Explain PowerShell syntax and concepts
- Discuss script structure and organization
- Troubleshoot errors
- Suggest maintainable configuration patterns
- Explain Windows installation commands
- Help investigate application installation methods
- Review and improve the script structure

The project was tested and adjusted manually to verify that the commands and implementation worked in the intended Windows environment.

## Disclaimer

This project is intended for internal IT onboarding and automation purposes.

Application download URLs, installer behavior, application versions, and installation arguments may change when vendors release new versions. Installation methods should therefore be verified before deploying the script in a production environment.
