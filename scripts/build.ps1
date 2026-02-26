# PowerShell build script for CMOD A7 Verilog project
# Automates Vivado build and programming workflow

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('build', 'program', 'clean', 'all', 'simulate')]
    [string]$Action = 'build',
    
    [Parameter(Mandatory=$false)]
    [string]$VivadoPath = "C:\Xilinx\Vivado\2023.1\bin\vivado.bat"
)

# Color output functions
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Error { Write-Host $args -ForegroundColor Red }

# Check if Vivado is installed
if (-not (Test-Path $VivadoPath)) {
    Write-Error "ERROR: Vivado not found at: $VivadoPath"
    Write-Info "Please specify the correct path using -VivadoPath parameter"
    Write-Info "Example: .\build.ps1 -Action build -VivadoPath 'C:\Xilinx\Vivado\2023.2\bin\vivado.bat'"
    exit 1
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$buildTcl = Join-Path $scriptDir "build.tcl"
$programTcl = Join-Path $scriptDir "program.tcl"
$simulateTcl = Join-Path $scriptDir "simulate.tcl"

# Read BUILD_DIR from config.tcl to stay in sync with Vivado scripts
$configFile = Join-Path $scriptDir "config.tcl"
$buildDirLine = Select-String -Path $configFile -Pattern '^\s*set\s+BUILD_DIR\s+"([^"]+)"' | Select-Object -First 1
if ($buildDirLine) {
    $configBuildDir = $buildDirLine.Matches[0].Groups[1].Value
    if ([System.IO.Path]::IsPathRooted($configBuildDir)) {
        $buildDir = $configBuildDir
    } else {
        $buildDir = Join-Path $projectRoot $configBuildDir
    }
} else {
    $buildDir = Join-Path $projectRoot "build"
}

# Function to run Vivado in batch mode
function Invoke-Vivado {
    param([string]$TclScript)
    
    Write-Info "Running Vivado with script: $TclScript"
    & $VivadoPath -mode batch -source $TclScript
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Vivado execution failed with exit code: $LASTEXITCODE"
        exit $LASTEXITCODE
    }
}

# Main logic
switch ($Action) {
    'build' {
        Write-Info "=== Building FPGA Design ==="
        Invoke-Vivado -TclScript $buildTcl
        Write-Success "Build completed successfully!"
        Write-Info "Bitstream location: check build\cmod_a7_project.runs\impl_1\ for .bit file"
    }
    
    'program' {
        Write-Info "=== Programming FPGA ==="
        # Check if any .bit file exists in the implementation directory
        $bitFiles = Get-ChildItem -Path "$buildDir\cmod_a7_project.runs\impl_1\*.bit" -ErrorAction SilentlyContinue
        if (-not $bitFiles) {
            Write-Error "Bitstream not found! Please run build first."
            exit 1
        }
        Invoke-Vivado -TclScript $programTcl
        Write-Success "Programming completed successfully!"
    }
    
    'clean' {
        Write-Info "=== Cleaning Build Directory ==="
        if (Test-Path $buildDir) {
            Remove-Item -Recurse -Force $buildDir
            Write-Success "Build directory cleaned"
        } else {
            Write-Info "Build directory already clean"
        }
    }
    
    'all' {
        Write-Info "=== Building and Programming FPGA ==="
        Invoke-Vivado -TclScript $buildTcl
        Write-Success "Build completed successfully!"
        Start-Sleep -Seconds 2
        Invoke-Vivado -TclScript $programTcl
        Write-Success "Programming completed successfully!"
    }
    
    'simulate' {
        Write-Info "=== Running Simulation ==="
        Invoke-Vivado -TclScript $simulateTcl
        Write-Success "Simulation completed!"
        Write-Info "Waveform data saved in build/sim directory"
        Write-Info "Open Vivado GUI to view waveforms interactively"
    }
}

Write-Success "`nDone!"
