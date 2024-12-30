function New-KafkaTopic {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TopicName,

        [Parameter()]
        [string[]]$BrokerList = @('localhost:9092'),

        [Parameter()]
        [int]$Partitions = 1,

        [Parameter()]
        [int]$ReplicationFactor = 1,

        [Parameter()]
        [ValidateSet('PLAIN', 'SCRAM-SHA-256', 'SCRAM-SHA-512')]
        [string]$SaslMechanism,

        [Parameter()]
        [string]$SaslUsername,

        [Parameter()]
        [string]$SaslPassword,

        [Parameter()]
        [ValidateSet('Plaintext', 'Ssl', 'SaslPlaintext', 'SaslSsl')]
        [string]$SecurityProtocol = 'Plaintext',

        [Parameter()]
        [string]$SslCaLocation,

        [Parameter()]
        [string]$SslCertificateLocation,

        [Parameter()]
        [string]$SslKeyLocation,

        [Parameter()]
        [string]$SslKeyPassword,

        [Parameter()]
        [bool]$EnableSslCertificateVerification = $true
    )

    try {
        Write-Verbose "Creating new Kafka topic: $TopicName"
        
        # Create a configuration object
        $config = New-Object Confluent.Kafka.AdminClientConfig
        $config.BootstrapServers = $BrokerList -join ','

        # Configure Security Protocol
        $config.SecurityProtocol = [Confluent.Kafka.SecurityProtocol]::$SecurityProtocol

        # Configure SSL if certificates are provided
        if ($SecurityProtocol -in @('Ssl', 'SaslSsl')) {
            Write-Verbose "Configuring SSL settings"
            
            if ($SslCaLocation) {
                Write-Verbose "Setting CA certificate location"
                $config.SslCaLocation = $SslCaLocation
            }

            if ($SslCertificateLocation) {
                Write-Verbose "Setting client certificate location"
                $config.SslCertificateLocation = $SslCertificateLocation
            }

            if ($SslKeyLocation) {
                Write-Verbose "Setting client key location"
                $config.SslKeyLocation = $SslKeyLocation
            }

            if ($SslKeyPassword) {
                Write-Verbose "Setting SSL key password"
                $config.SslKeyPassword = $SslKeyPassword
            }

            $config.EnableSslCertificateVerification = $EnableSslCertificateVerification
        }

        # Add SASL configuration if credentials are provided
        if ($SecurityProtocol -in @('SaslPlaintext', 'SaslSsl')) {
            if (-not ($SaslUsername -and $SaslPassword)) {
                throw "SASL username and password are required when using SASL security protocol"
            }

            Write-Verbose "Configuring SASL authentication"
            
            if ($SaslMechanism) {
                $config.SaslMechanism = [Confluent.Kafka.SaslMechanism]::$SaslMechanism
                $config.SaslUsername = $SaslUsername
                $config.SaslPassword = $SaslPassword
            }
            else {
                Write-Warning "SASL credentials provided but no mechanism specified. Defaulting to PLAIN"
                $config.SaslMechanism = [Confluent.Kafka.SaslMechanism]::Plain
                $config.SaslUsername = $SaslUsername
                $config.SaslPassword = $SaslPassword
            }
        }

        # Create the admin client
        $adminClient = New-Object Confluent.Kafka.AdminClientBuilder($config)
        $admin = $adminClient.Build()

        # Create topic specification
        $topicSpec = New-Object Confluent.Kafka.TopicSpecification
        $topicSpec.Name = $TopicName
        $topicSpec.NumPartitions = $Partitions
        $topicSpec.ReplicationFactor = $ReplicationFactor

        # Create the topic
        $null = $admin.CreateTopicsAsync(@($topicSpec)).GetAwaiter().GetResult()

        Write-Output "Topic '$TopicName' created successfully with $Partitions partitions and replication factor of $ReplicationFactor"
    }
    catch {
        Write-Error "Failed to create topic: $_"
    }
    finally {
        if ($admin) {
            $admin.Dispose()
        }
    }
}
