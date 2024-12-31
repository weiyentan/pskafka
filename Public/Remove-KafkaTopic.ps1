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
        [SecureString]$Password,

        [Parameter(Mandatory = $false)]
        [ValidateSet('SaslPlaintext', 'Plaintext')]
        [string]$SecurityProtocol = 'SaslPlaintext',

        [Parameter(Mandatory = $false)]
        [ValidateSet('Plain', 'ScramSha256', 'ScramSha512')]
        [string]$SaslMechanism = 'Plain',

        [Parameter(Mandatory = $false)]
        [int]$TimeoutMs = 60000
    )

    begin {
        if ($Username -and $Password) {
            $credential = New-Object PSCredential($Username, $Password)
        } else {
            $credential = $null
        }
    }

    process {
        try {
            # Create AdminClient using the helper function
            $adminClient = Connect-Kafka -brokerlist $brokerlist -Credential $credential -SecurityProtocol $SecurityProtocol -SaslMechanism $SaslMechanism

            # Create a list of topic names
            $topicNames = New-Object System.Collections.Generic.List[string]
            $topicNames.Add($TopicName)

            # Delete the topic
            $result = $adminClient.DeleteTopicsAsync($topicNames).GetAwaiter().GetResult()
            Write-Output "Topic deleted successfully: $TopicName"
        }
        catch {
            Write-Output "An error occurred: $_"
        }
        finally {
            # Dispose of the AdminClient
            $adminClient.Dispose()
        }
    }
}