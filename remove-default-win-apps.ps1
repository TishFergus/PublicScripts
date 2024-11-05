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

# Function to remove an app for the current user
function Remove-AppForUser {
    param (
        [string]$AppName
    )
    Write-Host "Attempting to remove '$AppName' for user '$env:UserName'..." -ForegroundColor Cyan
    try {
        $package = Get-AppxPackage -Name $AppName -User $env:UserName -ErrorAction Stop
        Remove-AppxPackage -Package $package.PackageFullName -ErrorAction Stop
        Write-Host "Successfully removed '$AppName'." -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to remove '$AppName'. It may not be installed for the current user."
    }
}

# Function to remove a provisioned app for all users
function Remove-ProvisionedApp {
    param (
        [string]$AppName
    )
    Write-Host "Attempting to remove provisioned app '$AppName' for all users..." -ForegroundColor Cyan
    try {
        $provisionedPackages = Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -like "*$AppName*" }
        foreach ($package in $provisionedPackages) {
            Remove-AppxProvisionedPackage -Online -PackageName $package.PackageName -ErrorAction Stop
            Write-Host "Successfully removed provisioned app '$AppName'." -ForegroundColor Green
        }
    }
    catch {
        Write-Warning "Failed to remove provisioned app '$AppName'. It may not be provisioned or an error occurred."
    }
}

# Remove each app for the current user
Write-Host "Starting removal of apps for the current user..." -ForegroundColor Yellow
foreach ($app in $apps) {
    Remove-AppForUser -AppName $app
}
Write-Host "Completed removal of apps for the current user." -ForegroundColor Yellow

# Remove provisioned apps for all users (prevents installation for new users)
Write-Host "Starting removal of provisioned apps for all users..." -ForegroundColor Yellow
foreach ($app in $apps) {
    Remove-ProvisionedApp -AppName $app
}
Write-Host "Completed removal of provisioned apps for all users." -ForegroundColor Yellow

Write-Host "All specified apps have been processed." -ForegroundColor Green
