function Remove-KafkaTopic {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$brokerlist,

        [Parameter(Mandatory = $true)]
        [string]$TopicName,

        [Parameter(Mandatory = $false)]
        [string]$Username,

        [Parameter(Mandatory = $false)]
        [string]$Password,

        [Parameter(Mandatory = $false)]
        [string]$SecurityProtocol,

        [Parameter(Mandatory = $false)]
        [string]$SaslMechanism,

        [Parameter(Mandatory = $false)]
        [int]$TimeoutMs = 60000
    )

    try {
        # Create AdminClient using the helper function
        $adminClient = Connect-Kafka -brokerlist $brokerlist -Username $Username -Password $Password -SecurityProtocol $SecurityProtocol -SaslMechanism $SaslMechanism

        # Create a list of topic names
        $topicNames = New-Object System.Collections.Generic.List[string]
        $topicNames.Add($TopicName)

        # Delete the topic
        $result = $adminClient.DeleteTopicsAsync($topicNames).GetAwaiter().GetResult()
        
        Write-Output "Topic '$TopicName' deleted successfully."
    }
    catch {
        Write-Error "Failed to delete topic '$TopicName': $_"
    }
    finally {
        # Dispose of the AdminClient
        $adminClient.Dispose()
    }
}

# Example usage
# Remove-KafkaTopic -brokerlist '192.168.1.107:9094,192.168.1.106:9094,192.168.1.108:9094' -TopicName 'code-releases'
