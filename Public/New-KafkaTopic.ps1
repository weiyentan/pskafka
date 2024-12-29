function New-KafkaTopic {
    <#
    .SYNOPSIS
    Creates a new Kafka topic.

    .DESCRIPTION
    This function creates a new topic in Kafka with the specified number of partitions and replication factor.

    .PARAMETER TopicName
    The name of the topic to be created.

    .PARAMETER Partitions
    The number of partitions for the new topic. Default is 1.

    .PARAMETER ReplicationFactor
    The replication factor for the new topic. Default is 1.

    .PARAMETER BrokerList
    An array of Kafka broker addresses to connect to.

    .EXAMPLE
    New-KafkaTopic -TopicName "my-new-topic" -Partitions 3 -ReplicationFactor 2 -BrokerList '192.168.1.106:9094'
    This command creates a new topic named 'my-new-topic' with 3 partitions and a replication factor of 2.
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TopicName,
        
        [Parameter()]
        [int]$Partitions = 1,
        
        [Parameter()]
        [int]$ReplicationFactor = 1,
        
        [Parameter(Mandatory=$true)]
        [string[]]$BrokerList
    )

    $kafka = ConvertTo-TopicCommand -BrokerList $BrokerList -Arguments "--create --topic $TopicName --partitions $Partitions --replication-factor $ReplicationFactor"
    
    
    # Execute the command
    & $kafka.path $kafka.args
}
