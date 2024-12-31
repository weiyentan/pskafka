function New-KafkaTopic {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$brokerlist,

        [Parameter(Mandatory = $true)]
        [string]$TopicName,

        [Parameter(Mandatory = $false)]
        [string]$Username,

        [Parameter(Mandatory = $false)]
        [SecureString]$Password,

        [Parameter(Mandatory = $false)]
        [string]$SecurityProtocol,

        [Parameter(Mandatory = $false)]
        [string]$SaslMechanism,

        [Parameter(Mandatory = $false)]
        [int]$NumPartitions = 1,

        [Parameter(Mandatory = $false)]
        [int]$ReplicationFactor = 1,

        [Parameter(Mandatory = $false)]
        [hashtable]$Config = @{},

        [Parameter(Mandatory = $false)]
        [int]$TimeoutMs = 60000
    )

    begin {
        # Check if Confluent.Kafka assembly is loaded
        $assemblies = [System.AppDomain]::CurrentDomain.GetAssemblies()
        $confluentAssembly = $assemblies | Where-Object { $_.GetName().Name -eq 'Confluent.Kafka' }
        
        if (-not $confluentAssembly) {
            Write-Error "Confluent.Kafka assembly is not loaded"
            throw "Confluent.Kafka assembly is not loaded"
        }
        
        Write-Output "Using Confluent.Kafka assembly version: $($confluentAssembly.GetName().Version)"
    }

    process {
        try {
            Write-Output "Creating AdminClient using the helper function"
            # Create AdminClient using the helper function
            # Define a hashtable for parameters
            $finalhash = @{ 'brokerlist' = $brokerlist; 'SecurityProtocol' = $SecurityProtocol; 'SaslMechanism' = $SaslMechanism }

            if ($PSBoundParameters['Username']) {
                $Password = $PSBoundParameters['Password']
                if ($Password -is [System.Security.SecureString]) {
                    $PasswordHash = ConvertFrom-SecureString -SecureString $Password -asPlainText
                } elseif ($Password -is [System.String]) {
                    $PasswordHash = ConvertTo-SecureString -String $Password -AsPlainText -Force
                } else {
                    Write-Error "Invalid password type"
                    throw "Invalid password type"
                }
                
                # Add Username and Password to the hashtable
                $finalhash['Username'] = $PSBoundParameters['Username']
                $finalhash['Password'] = $PasswordHash
            }

            # Check for additional parameters and add them to the hashtable
            if ($PSBoundParameters['SecurityProtocol']) {
                $finalhash['SecurityProtocol'] = $PSBoundParameters['SecurityProtocol']
            }
            if ($PSBoundParameters['SaslMechanism']) {
                $finalhash['SaslMechanism'] = $PSBoundParameters['SaslMechanism']
            }
            if ($PSBoundParameters['NumPartitions']) {
                $finalhash['NumPartitions'] = $PSBoundParameters['NumPartitions']
            }
            if ($PSBoundParameters['ReplicationFactor']) {
                $finalhash['ReplicationFactor'] = $PSBoundParameters['ReplicationFactor']
            }
            if ($PSBoundParameters['Config']) {
                $finalhash['Config'] = $PSBoundParameters['Config']
            }
            if ($PSBoundParameters['TimeoutMs']) {
                $finalhash['TimeoutMs'] = $PSBoundParameters['TimeoutMs']
            }

            try {
                $adminClient = Connect-Kafka @finalhash
            } catch {
                Write-Error "Authentication failed: $_"
                throw "Stopping connection attempts."
            }

            Write-Output "Creating TopicSpecification"
            $topicSpecType = $confluentAssembly.GetType('Confluent.Kafka.Admin.TopicSpecification')
            if (-not $topicSpecType) {
                Write-Error "TopicSpecification type not found in assembly"
                throw "TopicSpecification type not found in assembly"
            }

            $topicSpec = New-Object -TypeName $topicSpecType
            $topicSpec.Name = $TopicName
            $topicSpec.NumPartitions = $NumPartitions
            $topicSpec.ReplicationFactor = $ReplicationFactor
            Write-Output "TopicSpecification created: Name=$($topicSpec.Name), Partitions=$($topicSpec.NumPartitions), ReplicationFactor=$($topicSpec.ReplicationFactor)"

            Write-Output "Creating topic..."
            $topicSpecs = New-Object System.Collections.Generic.List[Confluent.Kafka.Admin.TopicSpecification]
            $topicSpecs.Add($topicSpec)
            $options = New-Object Confluent.Kafka.Admin.CreateTopicsOptions
            $result = $adminClient.CreateTopicsAsync($topicSpecs, $options).GetAwaiter().GetResult()
            Write-Output "Topic '$TopicName' created successfully"
        }
        catch {
            Write-Error "Failed to create topic: $_"
            Write-Output "Exception details: $($_.Exception.GetType().FullName)"
            Write-Output "Stack trace: $($_.Exception.StackTrace)"
            throw
        }
        finally {
            if ($adminClient) {
                Write-Output "Disposing AdminClient"
                $adminClient.Dispose()
            }
        }
    }
}

function Remove-KafkaTopic {
    param (
        [string]$brokerlist,
        [string]$TopicName
    )

    try {
        # Create AdminClientConfig
        $adminConfig = New-Object Confluent.Kafka.AdminClientConfig
        $adminConfig.BootstrapServers = $brokerlist

        # Create AdminClient
        $adminClient = New-Object Confluent.Kafka.Admin.AdminClientBuilder($adminConfig).Build()

        # Define the topic to delete
        $topicSpec = New-Object Confluent.Kafka.Admin.TopicSpecification
        $topicSpec.Name = $TopicName

        # Delete the topic
        $result = $adminClient.DeleteTopicsAsync(@($topicSpec)).GetAwaiter().GetResult()
        
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
