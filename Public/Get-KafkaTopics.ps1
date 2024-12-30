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
	
	try {
		$kafka = ConvertTo-TopicCommand -BrokerList $BrokerList -Arguments "--list" -Partitions 1 -ReplicationFactor 1
		Write-Debug "Kafka command constructed: $($kafka.path) with arguments: $($kafka.args)"

		if (-not $kafka) {
			Write-Error "Failed to construct Kafka command. The command object is null."
			return
		}

		Write-Verbose "Constructed command path and arguments for Kafka topics retrieval."

		# Execute the command
		$output = ExecuteKafkaCommand -CommandPath $kafka.path -CommandArgs $kafka.args

		# Check if output is null or empty
		if (-not $output) {
			Write-Error "No output received from Kafka command execution."
			return
		}

		# Process the output from kafkacat to extract topic names
		$topicNames = @()
		foreach ($line in $output) {
			if ($line -match 'topic "(.+?)"') {
				$topicNames += $Matches[1]
			}
		}

		Write-Debug "Extracted topic names: $topicNames"
		Write-Verbose "Retrieved topics successfully, returning the list of topics."
        Write-Output $output
	#	Write-Output @($topicNames | Where-Object { -not $TopicName -or ($_ -like $TopicName) } | Sort-Object)
	} catch {   
		Write-Debug "Error executing Kafka command: $_"
		Write-Verbose "An error occurred while executing the Kafka command: $_"
		Write-Error "Error executing Kafka command: $_"
	}
}
