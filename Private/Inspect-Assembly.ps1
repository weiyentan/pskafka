function Inspect-Assembly {
    param (
        [Parameter(Mandatory = $true)]
        [string]$AssemblyPath
    )

    try {
        Write-Output "Loading assembly from: $AssemblyPath"
        if (-not (Test-Path $AssemblyPath)) {
            throw "Cannot find assembly at path: $AssemblyPath"
        }

        $assembly = [System.Reflection.Assembly]::LoadFile($AssemblyPath)
        Write-Output "\nAssembly Name: $($assembly.FullName)"
        Write-Output "Location: $($assembly.Location)"
        
        Write-Output "\nExported Types:"
        $type = $assembly.GetExportedTypes() | Where-Object { $_.Name -eq 'AdminClientBuilder' }

        if ($null -eq $type) {
            throw "Cannot find type 'AdminClientBuilder' in assembly"
        }

        Write-Output "\nType: $($type.FullName)"
        Write-Output "  IsPublic: $($type.IsPublic)"
        Write-Output "  IsClass: $($type.IsClass)"
        Write-Output "  IsInterface: $($type.IsInterface)"
        Write-Output "  IsAbstract: $($type.IsAbstract)"
        if ($type.BaseType) {
            Write-Output "  Base type: $($type.BaseType.FullName)"
        }
        
        Write-Output "  Constructors:"
        $type.GetConstructors() | ForEach-Object {
            $params = $_.GetParameters() | ForEach-Object { "$($_.ParameterType.Name) $($_.Name)" }
            Write-Output "    - .ctor($($params -join ', '))"
        }
    }
    catch {
        Write-Error "Failed to inspect assembly: $($_.Exception.Message)"
        Write-Output "Exception type: $($_.Exception.GetType().FullName)"
        Write-Output "Stack trace: $($_.Exception.StackTrace)"
        throw
    }
}
