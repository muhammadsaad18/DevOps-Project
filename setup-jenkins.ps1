# DevOps Pipeline - Jenkins Setup Script for Windows
# This script sets up Jenkins in Docker with all required tools pre-installed

param(
    [switch]$Force = $false
)

# Function to write colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

Write-Host "🚀 Setting up Jenkins DevOps Pipeline for Windows" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green

# Check if Docker Desktop is installed and running
Write-Status "Checking Docker Desktop..."
try {
    $dockerVersion = docker --version
    Write-Success "Docker is installed: $dockerVersion"
} catch {
    Write-Error "Docker Desktop is not installed."
    Write-Host "Please install Docker Desktop for Windows from: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    exit 1
}

try {
    docker info | Out-Null
    Write-Success "Docker Desktop is running"
} catch {
    Write-Error "Docker Desktop is not running."
    Write-Host "Please start Docker Desktop and try again." -ForegroundColor Yellow
    exit 1
}

# Stop and remove existing Jenkins container if it exists
Write-Status "Cleaning up existing Jenkins container..."
try {
    docker stop jenkins 2>$null
    docker rm jenkins 2>$null
    Write-Success "Cleaned up existing Jenkins container"
} catch {
    Write-Status "No existing Jenkins container found"
}

# Build custom Jenkins image
Write-Status "Building custom Jenkins image with Terraform and Ansible..."
try {
    docker build -f Dockerfile.jenkins -t jenkins-devops:latest .
    Write-Success "Jenkins image built successfully"
} catch {
    Write-Error "Failed to build Jenkins image"
    exit 1
}

# Create Jenkins volume if it doesn't exist
Write-Status "Creating Jenkins volume..."
try {
    docker volume create jenkins_home | Out-Null
    Write-Success "Jenkins volume created"
} catch {
    Write-Status "Jenkins volume already exists"
}

# Generate SSH key pair for VM access using Docker (no local tools needed)
Write-Status "Generating SSH key pair for VM access..."
if (!(Test-Path "./ssh-keys")) {
    New-Item -ItemType Directory -Path "./ssh-keys" | Out-Null
}

if (!(Test-Path "./ssh-keys/id_rsa") -or $Force) {
    Write-Status "Using Docker to generate SSH keys (no local installation needed)..."
    try {
        # Use Alpine Linux container to generate SSH keys
        docker run --rm -v "${PWD}/ssh-keys:/keys" alpine:latest sh -c "apk add --no-cache openssh-keygen && ssh-keygen -t rsa -b 4096 -f /keys/id_rsa -N '' -C 'jenkins@devops-pipeline'"
        Write-Success "SSH key pair generated in ./ssh-keys/"
    } catch {
        Write-Error "Failed to generate SSH keys using Docker."
        Write-Warning "You can generate them manually later or install Git for Windows."
        # Create placeholder files
        New-Item -Path "./ssh-keys/id_rsa" -ItemType File -Force | Out-Null
        New-Item -Path "./ssh-keys/id_rsa.pub" -ItemType File -Force | Out-Null
        Set-Content -Path "./ssh-keys/id_rsa.pub" -Value "# Replace with your SSH public key"
    }
} else {
    Write-Status "SSH keys already exist in ./ssh-keys/"
}

# Display public key if it exists and is not empty
if ((Test-Path "./ssh-keys/id_rsa.pub") -and (Get-Content "./ssh-keys/id_rsa.pub" | Where-Object {$_ -notmatch "^#"})) {
    Write-Warning "SSH Public Key (copy this to your terraform.tfvars file):"
    Write-Host "----------------------------------------" -ForegroundColor Yellow
    Get-Content "./ssh-keys/id_rsa.pub"
    Write-Host "----------------------------------------" -ForegroundColor Yellow
}

# Run Jenkins container
Write-Status "Starting Jenkins container..."
try {
    $currentDir = (Get-Location).Path
    docker run -d `
        --name jenkins `
        --restart unless-stopped `
        -p 8080:8080 `
        -p 50000:50000 `
        -v jenkins_home:/var/jenkins_home `
        -v /var/run/docker.sock:/var/run/docker.sock `
        -v "${currentDir}:/workspace" `
        jenkins-devops:latest
    
    Write-Success "Jenkins container started"
} catch {
    Write-Error "Failed to start Jenkins container"
    exit 1
}

# Wait for Jenkins to start
Write-Status "Waiting for Jenkins to start..."
Start-Sleep -Seconds 30

# Check if Jenkins is running
$jenkinsRunning = docker ps --filter "name=jenkins" --format "table {{.Names}}" | Select-String "jenkins"
if ($jenkinsRunning) {
    Write-Success "Jenkins is running successfully!"
} else {
    Write-Error "Failed to start Jenkins"
    exit 1
}

# Get initial admin password
Write-Status "Getting Jenkins initial admin password..."
try {
    $adminPassword = docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
    Write-Success "Retrieved initial admin password"
} catch {
    $adminPassword = "Not available yet - check again in a few minutes"
    Write-Warning "Initial admin password not ready yet"
}

# Display setup information
Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "🎉 Jenkins Setup Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "📍 Jenkins URL: http://localhost:8080" -ForegroundColor Cyan
Write-Host "🔑 Initial Admin Password: $adminPassword" -ForegroundColor Yellow
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor White
Write-Host "1. Open http://localhost:8080 in your browser"
Write-Host "2. Use the admin password above to unlock Jenkins"
Write-Host "3. Install suggested plugins or skip and install manually"
Write-Host "4. Create an admin user"
Write-Host "5. Configure the following credentials in Jenkins:"
Write-Host "   - Azure Service Principal credentials"
Write-Host "   - SSH private key (use ./ssh-keys/id_rsa)"
Write-Host ""
Write-Host "🔧 Required Jenkins Credentials:" -ForegroundColor Yellow
Write-Host "   - azure-client-id (Secret text)"
Write-Host "   - azure-client-secret (Secret text)"
Write-Host "   - azure-subscription-id (Secret text)"
Write-Host "   - azure-tenant-id (Secret text)"
Write-Host "   - ssh-private-key (SSH Username with private key)"
Write-Host ""
Write-Host "📁 SSH Keys Location: ./ssh-keys/" -ForegroundColor Cyan
Write-Host "   - Private key: ./ssh-keys/id_rsa"
Write-Host "   - Public key: ./ssh-keys/id_rsa.pub"
Write-Host ""
Write-Host "⚠️  Remember to:" -ForegroundColor Red
Write-Host "   - Add the public key to your terraform.tfvars file"
Write-Host "   - Configure Azure credentials in Jenkins"
Write-Host "   - Create a new Pipeline job pointing to this repository"
Write-Host ""
Write-Host "==========================================" -ForegroundColor Green

# Show container logs
Write-Status "Showing Jenkins container logs (last 20 lines)..."
docker logs --tail 20 jenkins

Write-Success "Setup complete! Jenkins is ready for your DevOps pipeline."

# Open browser
$openBrowser = Read-Host "Would you like to open Jenkins in your browser now? (y/n)"
if ($openBrowser -eq "y" -or $openBrowser -eq "Y") {
    Start-Process "http://localhost:8080"
}
