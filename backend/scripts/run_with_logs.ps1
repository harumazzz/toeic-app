# Start the TOEIC application with logging enabled
# This PowerShell script runs the application and creates a logs directory

# Create logs directory if it doesn't exist
$logDir = Join-Path -Path "$PSScriptRoot\.." -ChildPath "logs"
if (-not (Test-Path -Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
    Write-Output "Created logs directory: $logDir"
}

# Get the current date for log filename
$currentDate = Get-Date -Format "yyyy-MM-dd"
$logFile = Join-Path -Path $logDir -ChildPath "app-$currentDate.log"
Write-Output "Logging to: $logFile"

# Navigate to the backend directory
Set-Location -Path "$PSScriptRoot\.."

# Run the application (use "go run" in development, adjust if needed for production)
# Note: We don't need to explicitly set up logging directory as it's handled in the code
Write-Output "Starting the application with logging enabled..."
go run main.go
