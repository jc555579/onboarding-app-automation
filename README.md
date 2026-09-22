# Windows Onboarding App Automation

A PowerShell-based automation project for downloading, validating, and installing applications during Windows workstation onboarding.

The project is designed to simplify the initial software setup process for IT staff by allowing applications to be managed through a centralized configuration and selected based on the client.

The PowerShell script contains the onboarding automation logic, while a WiX Toolset configuration can package the script into an `.msi` installer for deployment through endpoint-management tools such as Atera.

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
Verify Installation
     ↓
Create Desktop Shortcuts
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
- Installation verification
- Automatic desktop shortcut creation for applications that require it
- Installation logging
- Timestamped user output and log messages
- WiX-based MSI packaging for deployment
- Designed to support additional clients and applications

## Current Applications

| Application          | Installer Type | Download | Installation |
| -------------------- | -------------- | -------- | ------------ |
| AnyDesk              | EXE            | Yes      | Configured   |
| TeamViewer           | EXE            | Yes      | Configured   |
| Google Chrome        | MSI            | Yes      | Configured   |
| Adobe Acrobat Reader | EXE            | Yes      | Configured   |
| LibreOffice          | MSI            | Yes      | Configured   |
| Egnyte               | MSI            | Yes      | Configured   |

> Installation behavior and command-line arguments are configured individually for each application. Some installers may display a graphical interface or take longer to complete depending on the vendor's installer behavior.

## Desktop Shortcuts

Some applications do not automatically create a desktop shortcut after installation.

The script supports optional desktop shortcut creation through the application configuration.

For example:

```powershell
AnyDesk = @{
    Name           = "AnyDesk"
    Url            = $anyDeskUrl
    Output         = Join-Path $InstallerFolder "anydesk.exe"
    Type           = "EXE"
    Arguments      = '--install "C:\Program Files (x86)\AnyDesk" --silent'
    ShortcutTarget = "C:\Program Files (x86)\AnyDesk\AnyDesk.exe"
}
```

When `ShortcutTarget` is configured, the script checks whether the target executable exists after installation and creates a desktop shortcut automatically.

The shortcut is created on the common Windows desktop so it is available to users on the workstation.

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
        Output    = Join-Path $InstallerFolder "libreoffice.msi"
        Type      = "MSI"
        Arguments = "/qn /norestart"
    }
}
```

Each application definition contains:

| Property         | Purpose                                             |
| ---------------- | --------------------------------------------------- |
| `Name`           | Display name of the application                     |
| `Url`            | Download URL                                        |
| `Output`         | Location where the installer is saved               |
| `Type`           | Installer type (`EXE` or `MSI`)                     |
| `Arguments`      | Command-line arguments used during installation     |
| `ShortcutTarget` | Optional executable path used for shortcut creation |

`ShortcutTarget` is optional and is only configured when an application requires automatic desktop shortcut creation.

The script uses `$PSScriptRoot` to create paths relative to the location of the PowerShell script. This allows the script to work correctly when launched from different working directories, including when executed from an installed MSI package.

## Requirements

### Direct PowerShell execution

- Windows 10 or Windows 11
- PowerShell
- Internet connection
- Administrator privileges

### MSI packaging

- Windows 10 or Windows 11
- WiX Toolset 6
- WiX Toolset Util extension (`WixToolset.Util.wixext`)
- Administrator privileges for MSI testing

The WiX Util extension is required because the MSI package uses `WixQuietExec` to execute the PowerShell onboarding script during MSI installation.

Install the required WiX Util extension:

```powershell
wix extension add -g WixToolset.Util.wixext/6.0.0
```

Verify the WiX installation:

```powershell
wix --version
```

### MSI deployment

- Windows 10 or Windows 11
- Generated `.msi` package
- Administrator/System execution context
- Internet connection for downloading application installers
- An endpoint-management platform such as Atera

## Usage

### Option 1: Run the PowerShell script directly

Clone the repository:

```powershell
git clone <repository-url>
cd onboarding-app-automation
```

Run the script:

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

### Option 2: Build the MSI package

The PowerShell script can be packaged into an MSI using WiX Toolset.

The WiX source file is:

```text
Package.wxs
```

Build the MSI:

```powershell
wix build Package.wxs -arch x64 -ext WixToolset.Util.wixext -o onboarding.msi
```

The resulting file:

```text
onboarding.msi
```

is the deployment package.

The MSI installs the PowerShell script and executes it as part of the installation process.

This allows the onboarding automation to be deployed through endpoint-management software such as Atera.

### MSI deployment workflow

```text
onboarding.ps1
      │
      ↓
Package.wxs
      │
      ↓
WiX Toolset + Util Extension
      │
      ↓
onboarding.msi
      │
      ↓
Endpoint Management
      │
      ↓
Windows Workstation
      │
      ↓
PowerShell Onboarding Script
      │
      ↓
Application Installation
```

The MSI is therefore the deployment wrapper, while `onboarding.ps1` remains the main automation program.

## Project Structure

```text
onboarding-app-automation/
│
├── onboarding.ps1
├── Package.wxs
├── README.md
├── .gitignore
│
├── installers/
│   └── downloaded installers are created automatically
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

Generated build and test files such as the MSI package, WiX symbols, CAB files, MSI test logs, and local WiX files should not be committed to the source repository.

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

The directories are created relative to the script location using `$PSScriptRoot`.

### 3. Application Catalog

All supported applications are defined in the centralized `$Apps` hashtable.

Each application contains its download URL, installer path, installer type, and installation arguments.

Optional properties, such as `ShortcutTarget`, can also be configured for applications that require desktop shortcuts.

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

Example log output:

```text
Verifying digital signature for LibreOffice...
LibreOffice signature is valid.
Signer: E=info@documentfoundation.org, CN=The Document Foundation...
```

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

The script waits for the installation process to finish before continuing to the next application, with application-specific handling where required.

### 9. Installation Result Handling

The script checks the installer's exit code after installation.

Successful installations are recorded as successful.

Exit code `3010` is treated as a successful installation where a restart is required.

Other non-zero exit codes are reported as installation failures.

The script also verifies whether the application was successfully detected after the installer reports completion.

### 10. Desktop Shortcut Creation

For applications with a configured `ShortcutTarget`, the script checks whether the target executable exists after installation.

If the executable is found, a desktop shortcut is created automatically.

If the executable cannot be found, the shortcut is not created and the event is recorded in the log.

This allows the script to handle applications differently depending on their installer behavior without requiring separate installation functions.

### 11. Installation Logging

The script records important events in:

```text
logs/onboarding.log
```

Log entries include timestamps and events such as:

```text
[2026-09-23 02:07:01] ===== Windows Onboarding Started =====
[2026-09-23 02:07:01] Downloading TeamViewer...
[2026-09-23 02:07:08] TeamViewer downloaded successfully.
[2026-09-23 02:07:08] Verifying digital signature for TeamViewer...
[2026-09-23 02:07:10] TeamViewer signature is valid.
[2026-09-23 02:07:10] Installing TeamViewer...
[2026-09-23 02:07:43] TeamViewer installed successfully.
```

The same messages are displayed in the PowerShell console while the script is running.

## Known Limitations

### Adobe Acrobat Reader

Adobe Acrobat Reader may take significantly longer to complete its installation than the other applications.

The installer may display a graphical installation interface and may continue performing installation tasks after the visible progress reaches a high percentage.

The current script allows up to **600 seconds (10 minutes)** for Acrobat installation completion detection.

If the installation does not complete within the configured timeout, the script records the timeout and continues to the next application.

Example:

```text
Waiting for Adobe Acrobat installation to finish...
Adobe Acrobat installation timed out after 600 seconds.
```

The Acrobat installer should therefore be validated separately when changes are made to the application version, installer source, or installation arguments.

> **Known limitation:** Adobe Acrobat's installer does not always behave like a normal synchronous installer. Its visible progress and underlying installation process may not finish at the same time.

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
- [x] Adobe Acrobat Reader installation configuration
- [x] TeamViewer installation configuration
- [x] Egnyte installation configuration
- [x] Already-installed application detection
- [x] Duplicate-download prevention
- [x] Digital signature verification
- [x] Installation exit-code handling
- [x] Installation verification
- [x] Desktop shortcut creation
- [x] Installation logging
- [x] User output and progress messages
- [x] WiX MSI packaging
- [x] WiX Util extension integration
- [x] MSI execution of the PowerShell onboarding script
- [x] Local MSI installation testing

### Future Improvements

- Support additional clients
- Support additional applications
- Application version management
- Better installer validation
- Optional application installation
- Configuration separated into an external file
- Improved error recovery
- More detailed installation reports
- Improve Adobe Acrobat installation completion detection
- Improve MSI client-argument handling
- Further testing through endpoint-management deployment

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
              Verify Installation
                          ↓
             Create Desktop Shortcut
                          ↓
                     Write-Log
```

For deployment, the PowerShell automation can be wrapped inside an MSI:

```text
             onboarding.ps1
                    │
                    ↓
               Package.wxs
                    │
                    ↓
              WiX Toolset
                    │
                    ↓
              onboarding.msi
                    │
                    ↓
          Endpoint Management Tool
                    │
                    ↓
             Windows Workstation
```

This approach separates the automation logic from the deployment package while allowing the same PowerShell script to be tested directly during development.

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
- Windows shortcut creation
- WiX Toolset
- WiX Toolset Util extension
- MSI packaging

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
- Assist with MSI packaging concepts

The project was tested and adjusted manually to verify that the commands and implementation worked in the intended Windows environment.

## Disclaimer

This project is intended for internal IT onboarding and automation purposes.

Application download URLs, installer behavior, application versions, and installation arguments may change when vendors release new versions. Installation methods should therefore be verified before deploying the script in a production environment.
