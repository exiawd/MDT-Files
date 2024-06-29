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
cls
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

# List all Windows Autopilot deployment profiles
(Get-AutopilotProfile).displayName

# Select one of the supported Autopilot deployment profiles
$ProfileName = "UserDriven Scenario Standard User" 
$id = (Get-AutopilotProfile | Where-Object { $_.displayName -eq $ProfileName }).id

# Download the selected profile, convert it to JSON format, and save as ANSI file
$OutPutFile = "C:\Temp\AutopilotConfigurationFile.json"
Get-AutopilotProfile -id $id | ConvertTo-AutopilotConfigurationJSON | Out-File $OutPutFile -Encoding ascii
