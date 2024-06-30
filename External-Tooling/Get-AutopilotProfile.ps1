Add-Type -AssemblyName System.Windows.Forms

# Function to select a folder
function Select-FolderDialog {
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Select a folder"
    $folderBrowser.ShowNewFolderButton = $true

    $result = $folderBrowser.ShowDialog()
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return $folderBrowser.SelectedPath
    } else {
        return $null
    }
}

# Function to check if a module is installed
function Install-ModuleIfNeeded {
    param (
        [string]$ModuleName,
        [string]$MinimumVersion = ""
    )

    if (!(Get-Module -ListAvailable -Name $ModuleName -ErrorAction SilentlyContinue)) {
        if ($MinimumVersion) {
            Install-Module -Name $ModuleName -MinimumVersion $MinimumVersion -Force
        } else {
            Install-Module -Name $ModuleName -Force
        }
    } else {
        Write-Host "$ModuleName is already installed."
    }
}

# Check and install the required modules
Install-ModuleIfNeeded -ModuleName "WindowsAutopilotIntuneCommunity" -MinimumVersion "2.5"
Install-ModuleIfNeeded -ModuleName "Microsoft.Graph.Groups"
Install-ModuleIfNeeded -ModuleName "Microsoft.Graph.Authentication"
Install-ModuleIfNeeded -ModuleName "Microsoft.Graph.Identity.DirectoryManagement"

# Import the modules
Import-Module WindowsAutopilotIntuneCommunity -MinimumVersion 2.5
Import-Module Microsoft.Graph.Groups
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Identity.DirectoryManagement

# Connect to Microsoft Graph
$Scopes = @(
    "Device.ReadWrite.All", 
    "DeviceManagementManagedDevices.ReadWrite.All", 
    "DeviceManagementServiceConfig.ReadWrite.All", 
    "Domain.ReadWrite.All", 
    "Group.ReadWrite.All", 
    "GroupMember.ReadWrite.All", 
    "User.Read"
)
Connect-MgGraph -Scopes $Scopes -NoWelcome

# Save the selected path into the variable targetRoot
$targetRoot = Select-FolderDialog
$TenantDomain = (Get-MgDomain | Where-Object {$_.isDefault}).Id

try {
    # Get the organization details
    $organization = Get-MgOrganization

    if ($organization) {
        $organizationId = $organization.Id
        Write-Host "Organization ID: $organizationId"

        # Get Autopilot profiles
        $autopilotProfiles = Get-AutopilotProfile

        if ($autopilotProfiles.Count -eq 0) {
            Write-Host "No Autopilot profiles found in your organization."
        } else {
            # Create a list of profile objects
            $profileList = @()
            foreach ($profile in $autopilotProfiles) {
                $profileList += [PSCustomObject]@{
                    "Profile Name" = $profile.DisplayName
                    "correlationId" = $profile.Id
                    "CloudAssignedLanguage" = $profile.Language
                }
            }
            CLS
            # Display a grid view to select a profile
            $selectedProfile = $profileList | Out-GridView -Title "Select Autopilot Profile" -OutputMode Single

            if ($selectedProfile) {
                $profileName = $selectedProfile."Profile Name"
                $spId = $selectedProfile."Profile ID"

                # Create subfolder with the name of the selected profile
                $Save2Folder = "$targetRoot\$TenantDomain\$profileName\AutopilotConfigurationFile.json"
                New-Item -ItemType Directory -Path "$targetRoot\$TenantDomain\$profileName" -Force
                
                CLS
                Get-AutopilotProfile | ConvertTo-AutopilotConfigurationJSON | Set-Content -Path $Save2Folder
                Disconnect-MgGraph
                cls
                Write-Host "Autopilot JSON configuration successfully file saved to: $Save2Folder"
            } else {
                Write-Host "No profile selected."
            }
        }
    } else {
        Write-Host "Unable to retrieve organization details."
    }
} catch {
    Write-Host "An error occurred: $_"
}
