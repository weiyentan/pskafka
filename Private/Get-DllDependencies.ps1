function Get-DllDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$DllPath
    )

    Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;
    using System.Text;

    public class DllDependencyHelper {
        [DllImport("dbghelp.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern bool ImageEnumerateCertificates(
            IntPtr FileHandle,
            uint TypeFilter,
            out uint CertificateCount,
            uint[] Indices,
            uint IndexCount
        );

        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern IntPtr LoadLibraryEx(
            string lpFileName,
            IntPtr hFile,
            uint dwFlags
        );

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool FreeLibrary(IntPtr hModule);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern IntPtr GetProcAddress(
            IntPtr hModule,
            string lpProcName
        );

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern uint GetLastError();
    }
"@

    try {
        # Load the DLL with DONT_RESOLVE_DLL_REFERENCES flag (0x00000001)
        $hModule = [DllDependencyHelper]::LoadLibraryEx($DllPath, [IntPtr]::Zero, 0x00000001)
        if ($hModule -eq [IntPtr]::Zero) {
            $errorCode = [DllDependencyHelper]::GetLastError()
            Write-Error "Failed to load DLL for analysis. Error code: $errorCode"
            return
        }

        Write-Verbose "Successfully loaded DLL for analysis"
        
        # Use dumpbin.exe if available
        $dumpbinPath = "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.38.33130\bin\Hostx64\x64\dumpbin.exe"
        if (Test-Path $dumpbinPath) {
            Write-Verbose "Using dumpbin.exe to analyze dependencies"
            $result = & $dumpbinPath /DEPENDENTS $DllPath
            $result | Where-Object { $_ -match '^\s+\w+\.dll' } | ForEach-Object {
                $dll = $_.Trim()
                Write-Output $dll
            }
        } else {
            Write-Warning "dumpbin.exe not found. Cannot analyze dependencies in detail."
            Write-Output "Consider installing Visual Studio Build Tools to get dumpbin.exe"
        }

    } finally {
        if ($hModule -ne [IntPtr]::Zero) {
            [void][DllDependencyHelper]::FreeLibrary($hModule)
        }
    }
}

# Example usage
$dllPath = "C:\Users\weiye\pskafka\bin\win\librdkafka.dll"
Write-Output "Analyzing dependencies for: $dllPath"
Get-DllDependencies -DllPath $dllPath -Verbose
