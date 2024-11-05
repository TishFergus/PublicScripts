# Ensure the script is running with administrative privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "You do not have Administrator rights to run this script.`nPlease re-run this script as an Administrator."
    exit
}

# List of apps to remove
$apps = @(
    "Microsoft.3DBuilder",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo",
    "Microsoft.OneNote",
    "Microsoft.People",
    "Microsoft.SkypeApp",
    "Clipchamp.Clipchamp",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.OutlookForWindows",
    "Microsoft.Xbox.TCUI",
    "MSTeams",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.YourPhone",
    "MicrosoftWindows.CrossDevice",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.XboxGameCallableUI",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.BingSports",
    "Microsoft.XboxApp"
)

# Function to retrieve all user SIDs (Security Identifiers) excluding system accounts
function Get-UserSIDs {
    try {
        $userProfiles = Get-WmiObject -Class Win32_UserProfile | Where-Object { 
            -not $_.Special -and $_.Loaded 
        }
        $sids = $userProfiles | Select-Object -ExpandProperty SID
        return $sids
    }
    catch {
        Write-Warning "Failed to retrieve user profiles. Ensure you have the necessary permissions."
        return @()
    }
}

# Function to remove an app for a specific user
function Remove-AppForUser {
    param (
        [string]$AppName,
        [string]$UserSID
    )
    try {
        # Retrieve the user's Appx packages
        $packages = Get-AppxPackage -Name $AppName -User $UserSID -ErrorAction SilentlyContinue
        if ($packages) {
            foreach ($package in $packages) {
                Write-Host "Removing '$AppName' for user SID '$UserSID'..." -ForegroundColor Cyan
                Remove-AppxPackage -Package $package.PackageFullName -User $UserSID -ErrorAction Stop
                Write-Host "Successfully removed '$AppName' for user SID '$UserSID'." -ForegroundColor Green
            }
        }
        else {
            Write-Warning "App '$AppName' is not installed for user SID '$UserSID'."
        }
    }
    catch {
        Write-Warning "Failed to remove '$AppName' for user SID '$UserSID'. Error: $_"
    }
}

# Function to remove a provisioned app for all users
function Remove-ProvisionedApp {
    param (
        [string]$AppName
    )
    try {
        $provisionedPackages = Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -like "*$AppName*" }
        if ($provisionedPackages) {
            foreach ($package in $provisionedPackages) {
                Write-Host "Removing provisioned app '$AppName'..." -ForegroundColor Cyan
                Remove-AppxProvisionedPackage -Online -PackageName $package.PackageName -ErrorAction Stop
                Write-Host "Successfully removed provisioned app '$AppName'." -ForegroundColor Green
            }
        }
        else {
            Write-Warning "Provisioned app '$AppName' is not found."
        }
    }
    catch {
        Write-Warning "Failed to remove provisioned app '$AppName'. Error: $_"
    }
}

# Retrieve all user SIDs
Write-Host "Retrieving user SIDs..." -ForegroundColor Yellow
$userSIDs = Get-UserSIDs
if ($userSIDs.Count -eq 0) {
    Write-Warning "No user SIDs found. Exiting script."
    exit
}
Write-Host "Found $($userSIDs.Count) user(s)." -ForegroundColor Yellow

# Remove each app for all existing users
Write-Host "`nStarting removal of apps for all existing users..." -ForegroundColor Yellow
foreach ($app in $apps) {
    foreach ($sid in $userSIDs) {
        Remove-AppForUser -AppName $app -UserSID $sid
    }
}
Write-Host "Completed removal of apps for all existing users.`n" -ForegroundColor Yellow

# Remove provisioned apps to prevent installation for new users
Write-Host "Starting removal of provisioned apps for all users..." -ForegroundColor Yellow
foreach ($app in $apps) {
    Remove-ProvisionedApp -AppName $app
}
Write-Host "Completed removal of provisioned apps for all users.`n" -ForegroundColor Yellow

Write-Host "All specified apps have been processed for all existing and future users." -ForegroundColor Green
