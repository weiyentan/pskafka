function ConvertTo-TopicCommand
{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$BrokerList,
        [string]$Arguments,
        [int]$Partitions,
        [int]$ReplicationFactor
    )

    [pscustomobject]$kafka = [pscustomobject]@{'path'=$null;'args'=''}

    $kafka.path = Get-KafkaHome

    [string]$kafkacat = [System.IO.Path]::Combine($kafka.path, 'kafkacat')

    [bool]$is_win = $($PSVersionTable.PSVersion.Major -lt 6 -or $IsWindows)

    if ($is_win) {
        $kafkacat += '.exe'
    }

    if (Test-Path $kafkacat) {
        $kafka.path = $kafkacat
        
        # For listing topics with kafkacat
        if (-not $Arguments -or -not ($Arguments -like "*--create*")) {
            $kafka.args = "-b $($BrokerList -join ',') -L"
        }
        else {
            # For creating topics
            $kafka.args = "-b $($BrokerList -join ',')"
            # Check if creating a topic
            if ($Arguments -like "*--create*") {
                # Extract the topic name from the arguments
                if ($Arguments -match "--topic (\S+)") {
                    $topicName = $matches[1]
                    write-verbose "Topic name: $topicName"
                    $kafka.args += " -t $topicName"  # Add the -t argument
                    # Remove the --topic argument from the arguments
                    $Arguments = $Arguments -replace "--topic \S+", ""
                }
            }

            # Append only the necessary arguments without --create
            $kafka.args += " --partitions $Partitions --replication-factor $ReplicationFactor $Arguments"

            # Initialize kafka.args as an empty string
            $kafka.args = ''

            # Append SASL and security protocol arguments
            if ($env:KAFKA_SECURITY_PROTOCOL) {
                Write-Verbose "Detected KAFKA_SECURITY_PROTOCOL: $($env:KAFKA_SECURITY_PROTOCOL)"
                $kafka.args += " -X security.protocol=$($env:KAFKA_SECURITY_PROTOCOL)"
            }
            if ($env:KAFKA_SASL_MECHANISM) {
                Write-Verbose "Detected KAFKA_SASL_MECHANISM: $($env:KAFKA_SASL_MECHANISM)"
                $kafka.args += " -X sasl.mechanism=$($env:KAFKA_SASL_MECHANISM)"
            }
            if ($env:KAFKA_SASL_USERNAME) {
                Write-Verbose "Detected KAFKA_SASL_USERNAME: $($env:KAFKA_SASL_USERNAME)"
                $kafka.args += " -X sasl.username=$($env:KAFKA_SASL_USERNAME)"
            }
            if ($env:KAFKA_SASL_PASSWORD) {
                Write-Verbose "Detected KAFKA_SASL_PASSWORD: [REDACTED]"
                $kafka.args += " -X sasl.password=$($env:KAFKA_SASL_PASSWORD)"
            }

            # Log the constructed arguments before execution
            Write-Verbose "Constructed arguments: $($kafka.args)"
        }
    }
    else {
        if ($is_win) {
            $kafka.path = [System.IO.Path]::Combine($kafka.path, 'bin', 'windows', 'kafka-topics.bat')
        }
        else {
            $kafka.path = [System.IO.Path]::Combine($kafka.path, 'bin', 'kafka-topics.sh')
        }

        if (-not (Test-Path $kafka.path)) {
            Write-Error -Exception $([System.IO.FileNotFoundException]::new($kafka.path))
        }

        $kafka.args = "--zookeeper $($BrokerList -join ',') --list"
    }

    # Ensure there are no unintended spaces in the command construction
    $kafka.args = $kafka.args.Trim()

    # Log the complete command with all arguments
    Write-Verbose "Full command to be executed: $($kafka.path) $($kafka.args)"
    Write-Verbose "Executing command: $($kafka.path) $($kafka.args)"

    return $kafka
}
