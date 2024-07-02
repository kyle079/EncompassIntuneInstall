# EncompassIntuneInstall

## Usage
Used to install Encompass Smart Client by ICE Mortgage Technologies via a Win32 app in Intune.

Uses PSDeploymentToolKit to install all components, configure registry keys, and create shortcuts.

## Configuration
### Registry Keys
- Modify ` /Files/RegistryKeys/SmartClient.reg `
	- Update any line that has ` "SmartClientIDs"="Your Company SmartClient ID" ` with your company ID. This should be in a format like "BExxxxxxxx"

### Package .IntuneWin File
- Launch [IntuneWinAppUtil.exe](https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool)
	- Source Folder: Root of this repository
	- Setup File: `Deploy-Application.exe`
	- Output Folder: Any location you would like

### Import to Intune and setup
**Not this app does not install Adobe Reader I kept this seperate due to ever changing versions of Adobe Reader.**

- Go to Intune > Apps > All Apps > + Add
- Select Windows App (Win32) from dropdown
- Upload your newly created **Deploy-Application.intunewin** file
- Set the required fields
	- Name: `EncompassInstaller`
	- Publisher: `ICE Mortgage Technology`
	- Any other fields you would like to populate for your end users
- On the Program Screen use the following
	- Install Command: `Deploy-Application.exe -DeploymentType 'Install'`
	- Uninstall Command: `Deploy-Application.exe -DeploymentType 'Uninstall'`
	- Installation Time Required: `60`
	- Install Behavior: `System`
	- Device Restart Behavior: `App install may force a device restart`
	- Leave return codes default
- Requirements
	- Operationg system architecture: x64
	- Minimum operating system: I set this to 20H2
	- The rest can be left blank
- Detection Rules
	- Rules Format: Manually Configure Detection Rules
	- Click Add
	- Rule Type: `File`
	- Path: `C:\SmartClientCache\Apps\Ellie Mae\Encompass`
	- File or Folder: `AppLauncher.exe`
	- Detection method: `File or folder exists`
	- Associated with a 32-bit app on 64-bit clients: `No`
- Dependencies
	- Adobe Acrobat Reader DC
		- You can use the Microsoft Store App version found under Add App > Microsoft Store app (new) > Adobe Acrobat Reader DC
	- Microsoft Visual C++ 2015 Redistributable
		- I use [VcRedist](https://vcredist.com/import-vcintuneapplication/) for updating and uploading C++ Redistributables to Intune
- Supersedence
	- None

- Assignments
	- Recommend assigning to Device Groups to ensure it runs during Device OOBE





