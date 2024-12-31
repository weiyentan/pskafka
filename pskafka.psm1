Import-Module ThreadJob -ErrorAction Stop

# Handle PS2
if (-not $PSScriptRoot) {
    $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
}
$ModuleRoot = $PSScriptRoot

# Load native libraries
$binPath = Join-Path $PSScriptRoot "bin\win"
if (Test-Path $binPath) {
    Write-Output "Adding $binPath to PATH for librdkafka"
    $env:PATH = "$binPath;$env:PATH"
    
    # Load Confluent.Kafka assembly
    $confluentKafkaPath = Join-Path $binPath "Confluent.Kafka.dll"
    if (Test-Path $confluentKafkaPath) {
        try {
            Write-Output "Loading Confluent.Kafka assembly from $confluentKafkaPath"
            
            # Check if assembly is already loaded
            $assemblies = [System.AppDomain]::CurrentDomain.GetAssemblies()
            $confluentAssembly = $assemblies | Where-Object { $_.GetName().Name -eq 'Confluent.Kafka' }
            
            if (-not $confluentAssembly) {
                Write-Output "Assembly not loaded, loading from file"
                Add-Type -AssemblyName 'System.Memory' -ErrorAction SilentlyContinue
                Add-Type -Path $confluentKafkaPath
                Write-Output "Successfully loaded Confluent.Kafka assembly"
            }
            else {
                Write-Output "Confluent.Kafka assembly already loaded"
            }
        }
        catch {
            Write-Error "Failed to load Confluent.Kafka assembly: $_"
            throw
        }
    }
    else {
        Write-Error "Confluent.Kafka.dll not found at $confluentKafkaPath"
        throw
    }
}

# Get public and private function definition files
$Public = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )
$Types = @( Get-ChildItem -Path $PSScriptRoot\Types\*.ps1 -ErrorAction SilentlyContinue )

# Dot source the files
foreach ($import in @($Public + $Private + $Types)) {
    try {
        Write-Output "Importing $($import.fullname)"
        . $import.fullname
    }
    catch {
        Write-Error "Failed to import $($import.fullname): $_"
    }
}

$aliases = @()
foreach ($verb in @('Read', 'Stop', 'Get', 'Receive', 'Wait', 'Remove')) {
    $alias_name = "$verb-KafkaConsumer"
    $aliases += @($alias_name)
    New-Alias -Name $alias_name -Value "$verb-Job" -Force
}

Export-ModuleMember -Function ($Public | Select-Object -ExpandProperty BaseName) -Alias $aliases
