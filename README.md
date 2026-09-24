# Windows Onboarding App Automation

A PowerShell-based automation project for downloading, validating, and installing applications during Windows workstation onboarding.

The project is designed to simplify the initial software setup process for IT staff by allowing applications to be managed through a centralized application configuration and selected based on the client.

The PowerShell script contains the main onboarding automation logic, while a WiX Toolset configuration packages the script into an `.msi` deployment package for use with endpoint-management platforms such as Atera.

---

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

Application definitions are centralized in the `$Apps` hashtable, while `$StandardApps` and `$ClientApps` determine which applications should be installed for a particular workstation.

This separates application configuration from the core installation functions, making it easier to add or modify applications and client configurations without creating separate installation functions for each application.

---

## Features

* Download application installers automatically
* Support both `.EXE` and `.MSI` installers
* Install applications using PowerShell
* Standard application configuration
* Client-specific application configurations
* Centralized application definitions
* Administrator privilege check
* Automatic creation of required directories
* Detect already-installed applications
* Prevent unnecessary duplicate downloads
* Verify Authenticode digital signatures before installation
* Support silent installation arguments where supported
* Installation exit-code handling
* Installation verification
* Automatic desktop shortcut creation for applications that require it
* Installation logging
* Timestamped console and log messages
* WiX-based MSI packaging
* MSI deployment through endpoint-management platforms
* Client selection through an MSI property
* Designed to support additional clients and applications

---

## Current Applications

| Application          | Installer Type | Download | Installation |
| -------------------- | -------------- | -------- | ------------ |
| AnyDesk              | EXE            | Yes      | Configured   |
| TeamViewer           | EXE            | Yes      | Configured   |
| Google Chrome        | MSI            | Yes      | Configured   |
| Adobe Acrobat Reader | EXE            | Yes      | Configured   |
| LibreOffice          | MSI            | Yes      | Configured   |
| Egnyte               | MSI            | Yes      | Configured   |

Installation behavior and command-line arguments are configured individually for each application.

Some installers may behave differently depending on the vendor's installer implementation. For example, certain installers may take longer to complete or may require application-specific completion detection.

---

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

---

## Client Configuration

Applications are managed through client-specific application lists.

For example:

```powershell
$ClientApps = @{
    clientName = @(
        "TeamViewer"
        "Chrome"
        "LibreOffice"
        "Egnyte"
        "Acrobat"
        "AnyDesk"
    )
}
```

The project also contains a standard application list:

```powershell
$StandardApps = @(
    "AnyDesk"
)
```

When a client name is provided, the script uses the application list configured for that client.

When no client name is provided, the script uses the standard application list.

This allows different clients to have:

* Only a few applications
* A standard set of applications
* Standard applications plus additional applications
* A completely different application combination

Adding another client only requires adding another application list to `$ClientApps`.

Example:

```powershell
$ClientApps = @{
    clientName = @(
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

The installation functions do not need to be duplicated for each client.

---

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

Each application definition contains properties such as:

| Property         | Purpose                                             |
| ---------------- | --------------------------------------------------- |
| `Name`           | Display name of the application                     |
| `Url`            | Download URL                                        |
| `Output`         | Location where the installer is saved               |
| `Type`           | Installer type (`EXE` or `MSI`)                     |
| `Arguments`      | Command-line arguments used during installation     |
| `ShortcutTarget` | Optional executable path used for shortcut creation |

`ShortcutTarget` is optional and is only configured when an application requires automatic desktop shortcut creation.

The script uses `$PSScriptRoot` to create paths relative to the location of the PowerShell script. This allows the script to work correctly when launched from different working directories, including when executed from the installed MSI location.

---

## Requirements

### Direct PowerShell Execution

* Windows 10 or Windows 11
* Windows PowerShell
* Internet connection
* Administrator privileges

### MSI Packaging

The MSI package is built during development using:

* Windows 10 or Windows 11
* WiX Toolset 6
* WiX Toolset Util extension
* .NET SDK/runtime required by the WiX Toolset installation

Install the WiX Toolset 6 global tool:

```powershell
dotnet tool install --global wix --version 6.0.0
```

Install the WiX Toolset Util extension:

```powershell
wix extension add -g WixToolset.Util.wixext/6.0.0
```

Verify the WiX installation:

```powershell
wix --version
```

The WiX Toolset and extension are development/build requirements. They are **not required on the target workstation simply to run the generated `onboarding.msi`**.

### MSI Deployment

The generated MSI requires:

* Windows 10 or Windows 11
* The generated `onboarding.msi`
* Administrator or SYSTEM execution context
* Internet connection for downloading application installers
* An endpoint-management platform such as Atera for remote deployment

The target workstation does not need the WiX Toolset installed.

---

## Usage

### Option 1: Run the PowerShell Script Directly

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

---

### Option 2: Build the MSI Package

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

The MSI contains the PowerShell onboarding script and installs it to:

```text
C:\Program Files\OnboardingAppAutomation\
```

The MSI then launches the onboarding script automatically after the MSI installation transaction has completed.

This design is important because the onboarding script may install other MSI-based applications such as Google Chrome, LibreOffice, and Egnyte.

Launching the PowerShell script only after the parent MSI has completed prevents the child MSI installations from conflicting with the parent MSI transaction.

---

## MSI Deployment Workflow

The final deployment architecture is:

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
                 Endpoint Management
                    (e.g. Atera)
                          │
                          ↓
                  Windows Workstation
                          │
                          ↓
              Install onboarding.ps1
                          │
                          ↓
                 MSI installation ends
                          │
                          ↓
            PowerShell launches separately
                          │
                          ↓
              Windows Onboarding Script
                          │
                          ↓
               Application Installation
```

The MSI is therefore the deployment wrapper, while `onboarding.ps1` remains the main automation program.

---

## MSI Command-Line Usage

The same `onboarding.msi` can be used for both standard and client-specific onboarding.

### Standard Onboarding

Run:

```powershell
msiexec /i "onboarding.msi" /qn
```

The MSI does not receive a client name, so the script uses:

```powershell
$StandardApps
```

### Client-Specific Onboarding

For a client-specific configuration:

```powershell
msiexec /i "onboarding.msi" /qn CLIENTNAME=clientName
```

The MSI passes the `CLIENTNAME` property to the PowerShell script.

The script then selects:

```powershell
$ClientApps["clientName"]
```

This means the same MSI package can be used for different clients.

Only the deployment argument changes.

### Endpoint-Management Deployment

When deployed through an endpoint-management platform such as Atera, the same MSI can be used for multiple workstation configurations.

Example:

```text
Standard workstation:
 /qn

Client-specific workstation:
 /qn CLIENTNAME=clientName
```

The MSI package itself does not need to be rebuilt for each client as long as the client already exists in `$ClientApps`.

---

## Project Structure

The source repository contains the automation and packaging files:

```text
onboarding-app-automation/
│
├── onboarding.ps1
├── Package.wxs
├── README.md
├── .gitignore
└── onboarding.msi
```

The generated MSI package is a deployment artifact and may be excluded from source control depending on the project's repository policy.

The PowerShell script automatically creates the following directories on the target workstation:

```text
C:\Program Files\OnboardingAppAutomation\
│
├── onboarding.ps1
├── installers\
└── logs\
```

The `installers\` directory contains downloaded application installers.

The `logs\` directory contains onboarding execution logs.

For example:

```text
C:\Program Files\OnboardingAppAutomation\
│
├── onboarding.ps1
│
├── installers\
│   ├── anydesk.exe
│   ├── teamviewer.exe
│   ├── chrome.exe
│   ├── libreoffice.msi
│   └── ...
│
└── logs\
    └── onboarding.log
```

These directories do not need to be manually included with the MSI. They are created automatically when the onboarding script runs.

Generated build and test files such as WiX symbols, CAB files, MSI test logs, and local WiX files should not be committed to the source repository.

---

## How It Works

### 1. Administrator Check

The script first checks whether PowerShell is running with administrator privileges.

If administrator privileges are not detected, the script stops and asks the user to run it as Administrator.

This is required because application installation and Windows system changes may require elevated privileges.

---

### 2. Directory Setup

The script creates the required directories:

```text
installers/
logs/
```

if they do not already exist.

The directories are created relative to the script location using:

```powershell
$PSScriptRoot
```

When deployed through the MSI, these directories are therefore created inside:

```text
C:\Program Files\OnboardingAppAutomation\
```

---

### 3. Application Catalog

All supported applications are defined in the centralized `$Apps` hashtable.

Each application contains information such as:

* Application name
* Download URL
* Installer output path
* Installer type
* Installation arguments
* Optional shortcut target

This allows the same installation functions to handle different applications.

---

### 4. Client Selection

The script determines which application list to use.

If a client is provided directly:

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

When launched through the MSI, the client can be passed through the `CLIENTNAME` MSI property.

For example:

```text
CLIENTNAME=clientName
```

---

### 5. Installed Application Detection

Before downloading or installing an application, the script checks whether the application is already installed.

If the application is detected:

```text
Application already installed
        ↓
      Skip
```

This prevents unnecessary installation attempts.

The script checks Windows application registration information through the uninstall registry locations.

---

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

Otherwise, the installer is downloaded using:

```powershell
curl.exe -L $Url -o $Output
```

This prevents unnecessary duplicate downloads during repeated runs.

---

### 7. Digital Signature Verification

After downloading an installer, the script checks its Authenticode digital signature using:

```powershell
Get-AuthenticodeSignature
```

The installer is only allowed to continue to installation when Windows reports a valid signature.

If signature verification fails, installation is skipped.

Example log output:

```text
Verifying digital signature for LibreOffice...
LibreOffice signature is valid.
Signer: The Document Foundation
```

This provides an additional validation step before executing downloaded installers.

---

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

The script normally waits for the installation process to complete before continuing to the next application.

Application-specific handling is used where an installer does not behave like a normal synchronous installer.

---

### 9. Installation Result Handling

The script checks the installer's exit code after installation.

Successful installations are recorded as successful.

Exit code:

```text
0
```

is treated as a successful installation.

Exit code:

```text
3010
```

is treated as a successful installation where a restart is required.

Other non-zero exit codes are reported as installation failures.

The script also performs post-installation verification where application detection is available.

---

### 10. MSI Packaging and Execution

The WiX package installs the PowerShell script into:

```text
C:\Program Files\OnboardingAppAutomation\
```

The MSI then launches PowerShell asynchronously after the MSI installation transaction has completed.

This is intentional.

Some applications installed by the onboarding script are themselves MSI packages.

If the PowerShell script were executed while the parent `onboarding.msi` transaction was still active, Windows Installer could return:

```text
1618
Another installation is already in progress.
```

The final MSI design avoids this nested Windows Installer conflict by allowing the parent MSI installation to complete before the onboarding script starts installing additional MSI packages.

The result is:

```text
onboarding.msi
      ↓
Install onboarding.ps1
      ↓
Complete parent MSI transaction
      ↓
Launch PowerShell
      ↓
Install application MSIs
```

This behavior was tested locally with the onboarding MSI.

---

### 11. Desktop Shortcut Creation

For applications with a configured `ShortcutTarget`, the script checks whether the target executable exists after installation.

If the executable is found, a desktop shortcut is created automatically.

If the executable cannot be found, the shortcut is not created and the event is recorded in the log.

This allows applications to have different post-installation behavior without requiring separate installation functions.

---

### 12. Installation Logging

The script records important events in:

```text
C:\Program Files\OnboardingAppAutomation\logs\onboarding.log
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

The same general progress messages are displayed in the PowerShell console while the script is running.

---

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

---

### Application Installer Changes

Application vendors may change:

* Download URLs
* Installer filenames
* Installer versions
* Silent-installation arguments
* Installer behavior
* Digital signatures
* Installation locations

The corresponding application configuration should therefore be tested whenever an installer source or version changes.

---

### Client Configuration

Client configurations are currently defined inside the PowerShell script.

Adding a new client requires modifying `$ClientApps` and rebuilding the MSI before the new client configuration is available through the packaged deployment.

The project does not currently use a database or external API for application/client configuration.

---

### MSI Deployment Testing

The MSI has been tested locally.

Deployment through an endpoint-management platform such as Atera should still be tested on a controlled workstation before broader deployment.

The final deployment should verify:

* MSI installation
* PowerShell execution
* SYSTEM/elevated execution context
* Application downloads
* Application installations
* Client-specific configuration
* Installation logs
* Desktop shortcut creation
* Reboot-required behavior

---

## Development Status

### Completed

* [x] PowerShell project setup
* [x] Application catalog
* [x] Standard application list
* [x] Client-specific application lists
* [x] Automatic installer directory creation
* [x] Automatic log directory creation
* [x] Application download function
* [x] Administrator privilege check
* [x] EXE/MSI installer type configuration
* [x] Installation function structure
* [x] LibreOffice installation configuration
* [x] Chrome installation configuration
* [x] AnyDesk installation configuration
* [x] Adobe Acrobat Reader installation configuration
* [x] TeamViewer installation configuration
* [x] Egnyte installation configuration
* [x] Already-installed application detection
* [x] Duplicate-download prevention
* [x] Digital signature verification
* [x] Installation exit-code handling
* [x] Installation verification
* [x] Desktop shortcut creation
* [x] Installation logging
* [x] User output and progress messages
* [x] WiX MSI packaging
* [x] WiX Toolset Util extension integration
* [x] Automatic PowerShell execution from the MSI
* [x] MSI installation testing
* [x] Client selection through MSI properties
* [x] MSI architecture designed to avoid nested Windows Installer error `1618`
* [x] Local testing of standard onboarding
* [x] Local testing of client-specific onboarding

### Future Improvements

* [ ] Support additional clients
* [ ] Support additional applications
* [ ] Application version management
* [ ] Better installer validation
* [ ] Optional application installation
* [ ] External configuration file for applications and clients
* [ ] Improved error recovery
* [ ] More detailed installation reports
* [ ] Improve Adobe Acrobat installation completion detection
* [ ] Further testing through endpoint-management deployment
* [ ] Centralized application/client configuration outside the PowerShell source

---

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

This approach separates the automation logic from the deployment package while allowing the same PowerShell script to be tested directly during development and deployed through endpoint-management software.

---

## Learning Resources

This project was developed while learning Windows automation, PowerShell scripting, MSI deployment, and endpoint-management concepts.

The implementation uses concepts such as:

* PowerShell functions
* Parameters
* Hashtables
* Arrays
* Conditional statements
* Loops
* `Start-Process`
* `curl.exe`
* `msiexec`
* Windows Installer exit codes
* Windows Registry
* Authenticode digital signatures
* Windows administrator privileges
* SYSTEM execution context
* Command-line application installation
* File and directory handling
* Logging
* Windows shortcut creation
* WiX Toolset
* WiX Toolset Util extension
* MSI packaging
* MSI properties
* Custom actions
* Asynchronous MSI-launched processes
* Endpoint-management deployment

Official vendor documentation is used when determining supported installation and silent-installation methods for individual applications.

---

## AI Assistance

AI tools were used as a development and learning aid during the project.

AI assistance was used to:

* Explain PowerShell syntax and concepts
* Discuss script structure and organization
* Troubleshoot errors
* Suggest maintainable configuration patterns
* Explain Windows installation commands
* Help investigate application installation methods
* Review and improve the script structure
* Assist with MSI packaging concepts
* Troubleshoot WiX Toolset configuration
* Investigate Windows Installer error `1618`
* Explain MSI properties and deployment arguments

The project was tested and adjusted manually to verify that the commands and implementation worked in the intended Windows environment.

---

## Disclaimer

This project is intended for internal IT onboarding and automation purposes.

Application download URLs, installer behavior, application versions, installation arguments, and installation locations may change when vendors release new versions.

Installation methods should therefore be verified before deploying the script in a production environment.

The MSI package should also be tested on a controlled workstation before wider endpoint-management deployment.
