function ExecuteKafkaCommand {
    param (
        [string]$CommandPath,
        [string]$CommandArgs
    )

    Write-Debug "Executing command: $CommandPath with arguments: $CommandArgs"

    # Call the Invoke-CommandLine function to execute the Kafka command
    $output = Invoke-CommandLine -CommandLine $CommandPath -Arguments $CommandArgs -ReturnStdOut

    # Check the exit code
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Command failed with exit code: $LASTEXITCODE"
        throw "Command execution failed"
    }

    Write-Debug "Command executed successfully. Output: $output"
    Write-Output $output
}
