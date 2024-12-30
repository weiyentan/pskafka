function Get-KafkaTopics
{
	<#
	.DESCRIPTION
		Returns an array of Kafka topics.

	.PARAMETER BrokerList
		The Kafka broker(s) to connect to.
	.PARAMETER TopicName
		An optional wildcard string used to filter returned objects.

	.OUTPUTS
		A string array of Kafka topic names.
	.EXAMPLE
        Get-KafkaTopics -BrokerList 'localhost'
	#>
	[cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$BrokerList,
        [string]$TopicName
    )
	
	Write-Debug "Starting Get-KafkaTopics with BrokerList: $BrokerList"
	Write-Verbose "Starting command to retrieve Kafka topics for the provided broker list."
	
	$kafka = ConvertTo-TopicCommand -BrokerList $BrokerList -Arguments "--list" -Partitions 1 -ReplicationFactor 1
	Write-Debug "Kafka command constructed: $($kafka.path) with arguments: $($kafka.args)"
	Write-Verbose "Constructed command path and arguments for Kafka topics retrieval."

    try {
		$output = ExecuteKafkaCommand -CommandPath $kafka.path -CommandArgs $kafka.args
		if ($LASTEXITCODE -ne 0) {
			Write-Debug "Command failed with exit code $LASTEXITCODE"
			Write-Verbose "Command execution failed, throwing an error."
			throw "Command failed with exit code $LASTEXITCODE"
		}

		if ([System.IO.Path]::GetFileNameWithoutExtension($kafka.path) -eq 'kafkacat') {
			Write-Debug "Processing output from kafkacat"
			$output = $output | Where-Object { $_ -match 'topic "(.+)"' } |
				Select-Object @{Name='Matches';Expression= {$Matches[1]}} |
				Select-Object -ExpandProperty Matches
		}

		Write-Debug "Returning topics: $output"
		Write-Verbose "Retrieved topics successfully, returning the list of topics."
		Write-Output @($output | Where-Object { -not $TopicName -or ($_ -like $TopicName) } | Sort-Object)
    } catch {
        Write-Debug "Error executing Kafka command: $_"
        Write-Verbose "An error occurred while executing the Kafka command: $_"
        Write-Error "Error executing Kafka command: $_"
    }
}
