# Windows Onboarding App Automation

A PowerShell-based automation script for downloading and installing applications during Windows workstation onboarding.

The project is designed to simplify the initial software setup process for IT staff by allowing applications to be managed through a centralized configuration and selected based on the client.

## Overview

When preparing a newly installed Windows workstation, IT staff may need to install several applications repeatedly.

Instead of manually downloading and installing each application, this project aims to automate the process:

```text
Select Client
     ↓
Get Application List
     ↓
Download Installers
     ↓
Install Applications
     ↓
Ready for Onboarding
```

The application configuration is separated from the installation logic, making it easier to add new applications and clients without creating additional installation functions.

## Features

- Download application installers automatically
- Install applications using PowerShell
- Support both `.EXE` and `.MSI` installers
- Client-specific application configurations
- Standard application configuration
- Centralized application definitions
- Administrator privilege check
- Automatic creation of the installer directory
- Installation exit-code handling
- Designed to support additional clients and applications

## Current Applications

| Application | Installer Type | Download | Silent Installation |
|---|---|---|---|
| AnyDesk | EXE | Yes | In progress |
| TeamViewer | EXE | Yes | In progress |
| Google Chrome | EXE | Yes | In progress |
| Adobe Acrobat Reader | EXE | Yes | In progress |
| LibreOffice | MSI | Yes | In Progress |
| Egnyte | MSI | Yes | In progress |

> Installation methods and silent-install arguments are being tested individually for each application.

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

This means a client can have:

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

    client2 = @(
        "Chrome"
        "Acrobat"
    )

    client3 = @(
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
    }
}
```

Each application definition contains:

| Property | Purpose |
|---|---|
| `Name` | Display name of the application |
| `Url` | Download URL |
| `Output` | Location where the installer is saved |

This keeps application data separate from the functions that perform downloading and installation.

## Requirements

- Windows 10 or Windows 11
- PowerShell
- Internet connection

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

## Project Structure

```text
onboarding-app-automation/
│
├── onboarding.ps1
├── README.md
│
└── installers/
    ├── anydesk.exe
    ├── teamviewer.exe
    ├── chrome.exe
    ├── acrobat.exe
    ├── libreoffice.msi
    └── egnyte.msi
```

The `installers/` directory is created automatically by the script if it does not already exist.

Downloaded installers are stored locally in this directory.

## How It Works

### 1. Installer Directory

The script creates the `installers` directory when necessary.

### 2. Application Catalog

All supported applications are defined in `$Apps`.

### 3. Client Selection

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

### 4. Download

Each application installer is downloaded using `curl.exe`.

```powershell
curl.exe -L $Url -o $Output
```

### 5. Installation

The `Install-App` function determines whether the application uses an MSI or EXE installer.

For MSI applications:

```text
msiexec.exe
```

is used.

For EXE applications, the installer executable is launched directly with its configured arguments.

## Development Status

### Completed

- [x] PowerShell project setup
- [x] Application catalog
- [x] Standard application list
- [x] Client-specific application lists
- [x] Automatic installer directory creation
- [x] Application download function

### In Progress
- [ ] Administrator privilege check
- [ ] EXE/MSI installer type configuration
- [ ] Installation function structure
- [ ] LibreOffice silent installation 
- [ ] Verify Chrome silent installation
- [ ] Verify AnyDesk silent installation
- [ ] Configure Adobe Acrobat silent installation
- [ ] Configure TeamViewer installation
- [ ] Configure Egnyte installation
- [ ] Detect already-installed applications
- [ ] Prevent unnecessary downloads
- [ ] Improve installation error handling
- [ ] Add installation logging
- [ ] Improve user output/progress messages

### Future Improvements

- Support additional clients
- Support additional applications
- Application version management
- Better installer validation
- Installation logging
- Already-installed application detection
- Optional application installation
- Configuration separated into an external file
- Improved error recovery

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
                   Download-App
                          ↓
                    Install-App
```

This approach makes the script easier to maintain as the number of clients and applications increases.

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
- `msiexec`
- Exit codes
- Windows administrator privileges
- Command-line application installation

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

The project was tested and adjusted manually to verify that the commands and implementation worked in the intended Windows environment.

## Disclaimer

This project is intended for internal IT onboarding and automation purposes.

Application download URLs, installer behavior, and silent-installation arguments may change when vendors release new versions. Installation methods should therefore be verified before deploying the script in a production environment.
