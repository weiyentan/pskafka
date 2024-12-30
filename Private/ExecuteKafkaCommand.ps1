function ExecuteKafkaCommand {
    param (
        [string]$CommandPath,
        [string]$CommandArgs
    )

    Write-Debug "Executing command: $CommandPath with arguments: $CommandArgs"

    # Execute the command
    $process = Start-Process -FilePath $CommandPath -ArgumentList $CommandArgs -NoNewWindow -PassThru -Wait

    # Capture the output
    $output = $process.StandardOutput.ReadToEnd()
    $errorOutput = $process.StandardError.ReadToEnd()

    # Check the exit code
    if ($process.ExitCode -ne 0) {
        Write-Error "Command failed with exit code: $($process.ExitCode)"
        Write-Debug "Error output: $errorOutput"
        throw "Command execution failed: $errorOutput"
    }

    Write-Debug "Command executed successfully. Output: $output"
    Write-Output $output
}
