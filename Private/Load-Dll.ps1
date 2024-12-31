function Load-Dll {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$dllPath
    )

    Write-Verbose "Attempting to load DLL from: $dllPath"
    
    # Check if file exists
    if (-not (Test-Path $dllPath)) {
        Write-Error "DLL file not found at path: $dllPath"
        Write-Output ([IntPtr]::Zero)
        return
    }

    Write-Verbose "DLL file exists at specified path"

    # Add the DLL's directory to the PATH temporarily
    $dllDirectory = Split-Path -Parent $dllPath
    $originalPath = $env:PATH
    $env:PATH = "$dllDirectory;$env:PATH"
    Write-Verbose "Added DLL directory to PATH: $dllDirectory"
    Write-Verbose "Current PATH: $env:PATH"

    try {
        # Define a simple type with just LoadLibrary
        Add-Type -TypeDefinition @"
        using System;
        using System.Runtime.InteropServices;

        public class SimpleLoader
        {
            [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
            public static extern IntPtr LoadLibrary(string lpFileName);

            [DllImport("kernel32.dll")]
            public static extern uint GetLastError();
        }
"@ -ErrorAction SilentlyContinue

        # Try to load the DLL
        $result = [SimpleLoader]::LoadLibrary($dllPath)

        if ($result -eq [IntPtr]::Zero) {
            $errorCode = [SimpleLoader]::GetLastError()
            Write-Verbose "LoadLibrary failed with error code: $errorCode"
            Write-Error "Failed to load DLL: $dllPath. Error code: $errorCode"
            Write-Output ([IntPtr]::Zero)
        } else {
            Write-Verbose "Successfully loaded DLL: $dllPath with handle: $result"
            Write-Output $result
        }
    }
    catch {
        Write-Error "Exception occurred while loading DLL: $_"
        Write-Output ([IntPtr]::Zero)
    }
    finally {
        # Restore the original PATH
        $env:PATH = $originalPath
        Write-Verbose "Restored original PATH"
    }
}
