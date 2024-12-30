function Get-KafkaTopic
{
	<#
	.DESCRIPTION
		Returns details for a single Kafka topic.

	.PARAMETER TopicName
		The name of the Kafka topic to retrieve details for.
	.PARAMETER BrokerList
		The Kafka broker(s) to connect to.

	.OUTPUTS
		A string containing the topic name and details.
	.EXAMPLE
        Get-KafkaTopic -TopicName 'my_topic' -BrokerList 'localhost'
	#>
	[cmdletbinding()]
    param(
        [string]$TopicName,
        [string[]]$BrokerList
    )
	
	Write-Debug "Starting Get-KafkaTopic for topic: $TopicName"
	Write-Verbose "Starting command to retrieve Kafka topic details for the provided topic name and broker list."
	
	try {
		$kafka = ConvertTo-TopicCommand -BrokerList $BrokerList -Arguments "--list" 
		Write-Debug "Kafka command constructed: $($kafka.path) with arguments: $($kafka.args)"

		if (-not $kafka) {
			Write-Error "Failed to construct Kafka command. The command object is null."
			return
		}

		Write-Verbose "Constructed command path and arguments for Kafka topic retrieval."

		# Execute the command
		$output = ExecuteKafkaCommand -CommandPath $kafka.path -CommandArgs $kafka.args

		# Check if output is null or empty
		if (-not $output) {
			Write-Error "No output received from Kafka command execution."
			return
		}

		# Parse the output
		Write-Debug "Output from Kafka command: $output"
		$lines = $output -split "`n"

		foreach ($line in $lines) {
			if ($line -match 'topic "([^"]+)"') {
				$topicName = $Matches[1]
				
				# Skip __consumer_offsets topic
				if ($topicName -ne "__consumer_offsets") {
					# Create a structured object using New-Object cmdlet
					$topicDetail = [PSCustomObject]@{ 
						Topic = $topicName
					}
					
					write-output  $topicDetail
				}
			}
		}
	} catch {   
		Write-Debug "Error executing Kafka command: $_"
		Write-Verbose "An error occurred while executing the Kafka command: $_"
		Write-Error "Error executing Kafka command: $_"
	}
}
