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
        [string]$Password,

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
            Write-Output "Creating AdminClientConfig"
            # Create AdminClientConfig with security settings
            $adminConfig = New-Object Confluent.Kafka.AdminClientConfig
            $adminConfig.BootstrapServers = $brokerlist

            if ($Username -and $Password) {
                $adminConfig.SecurityProtocol = [Confluent.Kafka.SecurityProtocol]::SaslPlaintext
                $adminConfig.SaslMechanism = [Confluent.Kafka.SaslMechanism]::Plain
                $adminConfig.SaslUsername = $Username
                $adminConfig.SaslPassword = $Password
            } else {
                $adminConfig.SecurityProtocol = [Confluent.Kafka.SecurityProtocol]::Plaintext
            }

            Write-Output "AdminClientConfig created with BootstrapServers: $($adminConfig.BootstrapServers)"
            Write-Output "Security Protocol: $($adminConfig.SecurityProtocol)"
            if ($Username) {
                Write-Output "SASL Mechanism: $($adminConfig.SaslMechanism)"
            }

            Write-Output "Creating AdminClientBuilder"
            $builder = New-Object Confluent.Kafka.AdminClientBuilder($adminConfig)
            $adminClient = $builder.Build()
            Write-Output "AdminClient created successfully"

            # Ensure the Confluent.Kafka assembly is loaded
            $loadedAssemblies = [System.AppDomain]::CurrentDomain.GetAssemblies()
            $kafkaAssembly = $loadedAssemblies | Where-Object { $_.GetName().Name -eq 'Confluent.Kafka' }

            if (-not $kafkaAssembly) {
                Write-Error "Confluent.Kafka assembly is not loaded."
                throw "Confluent.Kafka assembly is not loaded."
            }

            Write-Output "Creating TopicSpecification"
            $topicSpecType = $kafkaAssembly.GetType('Confluent.Kafka.Admin.TopicSpecification')
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
