function AppendSecurityArgs {
    param (
        [string]$KafkaArgs
    )

    # Initialize the arguments with the original value
    $updatedArgs = $KafkaArgs

    # Check if the environment variables are set
    if ($env:KAFKA_SECURITY_PROTOCOL) {
        Write-Debug "Appending security protocol: $($env:KAFKA_SECURITY_PROTOCOL)"
        $updatedArgs += " -X security.protocol=$($env:KAFKA_SECURITY_PROTOCOL)"
    }

    if ($env:KAFKA_SASL_MECHANISM) {
        Write-Debug "Appending SASL mechanism: $($env:KAFKA_SASL_MECHANISM)"
        $updatedArgs += " -X sasl.mechanism=$($env:KAFKA_SASL_MECHANISM)"
    }

    if ($env:KAFKA_SASL_USERNAME) {
        Write-Debug "Appending SASL username: $($env:KAFKA_SASL_USERNAME)"
        $updatedArgs += " -X sasl.username=$($env:KAFKA_SASL_USERNAME)"
    }

    if ($env:KAFKA_SASL_PASSWORD) {
        Write-Debug "Appending SASL password: [REDACTED]"
        $updatedArgs += " -X sasl.password=$($env:KAFKA_SASL_PASSWORD)"
    }

    Write-Debug "Final arguments after appending security: $updatedArgs"
    Write-Output $updatedArgs
}
