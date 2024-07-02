[CmdletBinding()]
Param (
    [Parameter(Mandatory = $false)]
    [ValidateSet('Install', 'Uninstall')]
    [String]$DeploymentType = 'Install',
    [Parameter(Mandatory = $false)]
    [ValidateSet('Interactive', 'Silent', 'NonInteractive')]
    [String]$DeployMode = 'Interactive',
    [Parameter(Mandatory = $false)]
    [switch]$AllowRebootPassThru = $false,
    [Parameter(Mandatory = $false)]
    [switch]$TerminalServerMode = $false,
    [Parameter(Mandatory = $false)]
    [switch]$DisableLogging = $false
)

Try {
    ## Set the script execution policy for this process
    Try {
        Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop'
    } Catch {
        Write-Error -Message "Unable to set Execution Policy, Error: $($_.Exception.Message)"
        exit 1
    }

    ##*===============================================
    ##* VARIABLE DECLARATION
    ##*===============================================
    ## Variables: Application
    [String]$appVendor = 'ICE Mortgage Technology'
    [String]$appName = 'Encompass SmartClient'
    [String]$appVersion = ''
    [String]$appArch = 'x64'
    [String]$appLang = 'EN'
    [String]$appRevision = '01'
    [String]$appScriptVersion = '1.0.0'
    [String]$appScriptDate = '05/14/2024'
    [String]$appScriptAuthor = 'Kyle Miller'
    ##*===============================================
    ## Variables: Install Titles (Only set here to override defaults set by the toolkit)
    [String]$installName = ''
    [String]$installTitle = ''

    ##* Do not modify section below
    #region DoNotModify

    ## Variables: Exit Code
    [Int32]$mainExitCode = 0

    ## Variables: Script
    [String]$deployAppScriptFriendlyName = 'Deploy Application'
    [Version]$deployAppScriptVersion = [Version]'3.10.1'
    [String]$deployAppScriptDate = '05/03/2024'
    [Hashtable]$deployAppScriptParameters = $PsBoundParameters

    ## Variables: Environment
    If (Test-Path -LiteralPath 'variable:HostInvocation') {
        $InvocationInfo = $HostInvocation
    } Else {
        $InvocationInfo = $MyInvocation
    }
    [String]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent

    ## Dot source the required App Deploy Toolkit Functions
    Try {
        [String]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
        If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) {
            Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]."
        }
        If ($DisableLogging) {
            . $moduleAppDeployToolkitMain -DisableLogging
        } Else {
            . $moduleAppDeployToolkitMain
        }
    } Catch {
        If ($mainExitCode -eq 0) {
            [Int32]$mainExitCode = 60008
        }
        Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
        ## Exit the script, returning the exit code to SCCM
        If (Test-Path -LiteralPath 'variable:HostInvocation') {
            $script:ExitCode = $mainExitCode; Exit
        } Else {
            Exit $mainExitCode
        }
    }

    #endregion
    ##* Do not modify section above
    ##*===============================================
    ##* END VARIABLE DECLARATION
    ##*===============================================

    If ($deploymentType -ine 'Uninstall' -and $deploymentType -ine 'Repair') {
        ##*===============================================
        ##* PRE-INSTALLATION
        ##*===============================================
        [String]$installPhase = 'Pre-Installation'

        ## Show Welcome Message, close Internet Explorer if required, allow up to 3 deferrals, verify there is enough disk space to complete the install, and persist the prompt
        Show-InstallationWelcome -CloseApps 'encsc,sccoreinstaller,EPDInstaller,DocumentConverter,InstallPdfConverter' -AllowDefer -DeferTimes 3 -CheckDiskSpace -PersistPrompt

        ## Show Progress Message (with the default message)
        Show-InstallationProgress

        ## <Perform Pre-Installation tasks here>

        #Online installer
        if ((Get-WindowsOptionalFeature -FeatureName 'NetFx3' -Online).state -ne 'Enabled') {
            Enable-WindowsOptionalFeature -Online -FeatureName 'NetFx3' -NoRestart
        }


        ##*===============================================
        ##* INSTALLATION
        ##*===============================================
        [String]$installPhase = 'Installation'

        ## <Perform Installation tasks here>
        Execute-Process -Path "$scriptDirectory\Files\PdfConverter\InstallPdfConverter.exe" -Parameters '-s' -WindowStyle Hidden
        Execute-Process -Path "$scriptDirectory\Files\BlackIce\DocumentConverter.exe" -Parameters '/s' -WindowStyle Hidden
        Execute-Process -Path "$scriptDirectory\Files\EPDInstaller\EPDInstaller.exe" -Parameters '/qn /norestart' -WindowStyle Hidden
        Execute-MSI -Path "$scriptDirectory\Files\SmartClientCore.MSI" -Parameters '/qn /norestart'
        Execute-MSI -Path "$scriptDirectory\Files\SmartClient.MSI" -Parameters '/qn /norestart'


        function New-Shortcut {
            param (
                [string]$Path,
                [string]$TargetPath,
                [string]$IconLocation = $null,
                [string]$Description = $null
            )
            $WScriptShell = New-Object -ComObject WScript.Shell
            $shortcut = $WScriptShell.CreateShortcut($Path)
            $shortcut.TargetPath = $TargetPath
            if ($IconLocation) { $shortcut.IconLocation = $IconLocation }
            if ($Description) { $shortcut.Description = $Description }
            $shortcut.Save()
        }

        # Encompass Start Menu Shortcuts
        $shortcutPath = [System.IO.Path]::Combine([System.Environment]::GetFolderPath('CommonPrograms'), 'Encompass.lnk')
        $targetPath = 'C:\SmartClientCache\Apps\Ellie Mae\Encompass\AppLauncher.exe'
        $iconPath = 'C:\SmartClientCache\Apps\Ellie Mae\Encompass\App.ico'
        New-Shortcut -Path $shortcutPath -TargetPath $targetPath -IconLocation $iconPath -Description 'Encompass SmartClient'

        # Encompass Desktop Shortcut
        $desktopPath = [System.IO.Path]::Combine([System.Environment]::GetFolderPath('CommonDesktopDirectory'), 'Encompass.lnk')
        New-Shortcut -Path $desktopPath -TargetPath $targetPath -IconLocation $iconPath -Description 'Encompass SmartClient'

        # Encompass Form Builder Start Menu Shortcut
        $shortcutPath = [System.IO.Path]::Combine([System.Environment]::GetFolderPath('CommonPrograms'), 'Form Builder.lnk')
        $targetPath = 'C:\SmartClientCache\Apps\Ellie Mae\Encompass\FormBuilder.exe'
        New-Shortcut -Path $shortcutPath -TargetPath $targetPath -Description 'Encompass Form Builder'

        ##*===============================================
        ##* POST-INSTALLATION
        ##*===============================================
        [String]$installPhase = 'Post-Installation'

        # Assign Registry Keys for Encompass
        Start-Process -FilePath 'regedit.exe' -ArgumentList "/s $scriptDirectory\Files\RegistryKeys\SmartClientCore_Uninstall.reg" -Wait
        Start-Process -FilePath 'regedit.exe' -ArgumentList "/s $scriptDirectory\Files\RegistryKeys\SmartClient_Uninstall.reg" -Wait
        Start-Process -FilePath 'regedit.exe' -ArgumentList "/s $scriptDirectory\Files\RegistryKeys\SmartClient.reg" -Wait

    } ElseIf ($deploymentType -ieq 'Uninstall') {
        ##*===============================================
        ##* PRE-UNINSTALLATION
        ##*===============================================
        [String]$installPhase = 'Pre-Uninstallation'

        ## Show Welcome Message, close Internet Explorer with a 60 second countdown before automatically closing
        Show-InstallationWelcome -CloseApps 'encsc,sccoreinstaller,EPDInstaller,DocumentConverter,InstallPdfConverter' -CloseAppsCountdown 60

        ## Show Progress Message (with the default message)
        Show-InstallationProgress

        ## <Perform Pre-Uninstallation tasks here>

        ##*===============================================
        ##* UNINSTALLATION
        ##*===============================================
        [String]$installPhase = 'Uninstallation'

        ## <Perform Uninstallation tasks here>
        Execute-Process -Path "$scriptDirectory\Files\encsc\encsc.exe" -Parameters '/uninstall' -WindowStyle Hidden
        Execute-Process -Path "$scriptDirectory\Files\sccoreinstaller\sccoreinstaller.exe" -Parameters '/uninstall' -WindowStyle Hidden
        Execute-Process -Path "$scriptDirectory\Files\EPDInstaller\EPDInstaller.exe" -Parameters '/uninstall' -WindowStyle Hidden
        Execute-Process -Path "$scriptDirectory\Files\BlackIce\DocumentConverter.exe" -Parameters '/uninstall' -WindowStyle Hidden
        Execute-Process -Path "$scriptDirectory\Files\PdfConverter\InstallPdfConverter.exe" -Parameters '-u -s' -WindowStyle Hidden
        Disable-WindowsOptionalFeature -Online -FeatureName 'NetFx3' -Remove -NoRestart


        ##*===============================================
        ##* POST-UNINSTALLATION
        ##*===============================================
        [String]$installPhase = 'Post-Uninstallation'

        ## <Perform Post-Uninstallation tasks here>


    }
    ##*===============================================
    ##* END SCRIPT BODY
    ##*===============================================

    ## Call the Exit-Script function to perform final cleanup operations
    Exit-Script -ExitCode $mainExitCode
} Catch {
    [Int32]$mainExitCode = 60001
    [String]$mainErrorMessage = "$(Resolve-Error)"
    Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
    Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
    Exit-Script -ExitCode $mainExitCode
}
