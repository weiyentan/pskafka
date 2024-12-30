. "c:/Users/weiye/pskafka/Private/AppendSecurityArgs.ps1"
. "c:/Users/weiye/pskafka/Private/ExecuteKafkaCommand.ps1"

function ConvertTo-TopicCommand {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$BrokerList,
        
        [string]$Arguments,
        
        [int]$Partitions = 1,  # Default value for partitions
        [int]$ReplicationFactor = 1  # Default value for replication factor
    )

    Write-Debug "Starting ConvertTo-TopicCommand with BrokerList: $BrokerList"
    Write-Verbose "Starting command conversion for the provided broker list."

    $kafka = [pscustomobject]@{
        path = Get-KafkaHome
        args = ''
    }

    Write-Debug "Kafka home path retrieved: $($kafka.path)"
    Write-Verbose "Kafka home path is set to: $($kafka.path)"

    # Determine the appropriate command executable
    $kafkacat = [System.IO.Path]::Combine($kafka.path, 'kafkacat')
    if ($IsWindows) {
        $kafkacat += '.exe'
    }

    if (-not (Test-Path $kafkacat)) {
        Write-Error "Kafka command not found at path: $kafkacat"
        return
    }

    $kafka.path = $kafkacat

    # Construct command arguments based on the operation
    if ($Arguments -like "*--list*") {
        # Listing topics
        $kafka.args = "-b $($BrokerList -join ',') -L"
        Write-Debug "Listing topics with arguments: $kafka.args"
    } elseif ($Arguments -like "*--create*") {
        # Creating a new topic
        $kafka.args = "-b $($BrokerList -join ',')"
        Write-Debug "Creating topic with base arguments: $kafka.args"

        if ($Arguments -match "--topic (\S+)") {
            $topicName = $matches[1]
            Write-Verbose "Topic name: $topicName"
            $kafka.args += " -t $topicName"
            Write-Debug "Appended topic name to arguments: $kafka.args"
            $Arguments = $Arguments -replace "--topic \S+", ""
            Write-Debug "Remaining arguments after topic extraction: $Arguments"
        }

        # Append partitions and replication factor
        if ($Partitions -gt 0) {
            $kafka.args += " --partitions $Partitions"
            Write-Debug "Appended partitions: $Partitions"
        } else {
            Write-Debug "Partitions value is invalid: $Partitions"
        }

        if ($ReplicationFactor -gt 0) {
            $kafka.args += " --replication-factor $ReplicationFactor"
            Write-Debug "Appended replication factor: $ReplicationFactor"
        } else {
            Write-Debug "Replication factor value is invalid: $ReplicationFactor"
        }

        # Append any remaining arguments
        if ($Arguments) {
            $kafka.args += " $Arguments"
            Write-Debug "Final arguments after appending remaining arguments: $kafka.args"
        }
    } else {
        Write-Error "Invalid operation. Please specify either --list or --create."
        return
    }

    # Append security arguments in both cases
    Write-Debug "Arguments before appending security: $($kafka.args)"
    $kafka_args = AppendSecurityArgs -KafkaArgs $kafka.args
    Write-Debug "Arguments after appending security: $($kafka_args)"

    # Log the final constructed arguments before executing the command
    Write-Debug "Constructed arguments for execution: $($kafka_args)"

    # Create and return the command object using New-Object
    $commandObject = New-Object PSObject -Property @{ path = $kafka.path; args = $kafka_args }

    Write-Debug "Constructed command object: $commandObject"
    Write-Output $commandObject
}
