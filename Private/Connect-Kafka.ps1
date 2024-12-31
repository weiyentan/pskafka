function Connect-Kafka {
    param (
        [string]$brokerlist,
        [string]$Username,
        [string]$Password,
        [string]$SecurityProtocol = 'Plaintext',
        [string]$SaslMechanism = 'Plain'
    )

    # Create AdminClientConfig
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

    # Create AdminClient
    $adminClientBuilder = New-Object Confluent.Kafka.AdminClientBuilder($adminConfig)
    $adminClient = $adminClientBuilder.Build()
    return $adminClient
}
