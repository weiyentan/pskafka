[cmdletbinding()]
param(
	[Parameter(Mandatory=$true)]
	[string]$TopicName,
	[string]$Broker = 'localhost'
)

$ErrorActionPreference = 'Stop'

if (Test-Path "$PWD/pskafka.psd1") {
	Import-Module "$PWD/pskafka.psd1"
} else {
	Import-Module "$PSScriptRoot/../pskafka.psd1" -ea Stop
}

Set-KafkaHome $null

[string]$kafka = '~/kafka' # Get-KafkaHome

[string]$zookeeper = $Broker + ':2181'

Write-Host 'creating topic'
& "$kafka/bin/kafka-topics.sh" --delete --if-exists --topic $TopicName --zookeeper $zookeeper
& "$kafka/bin/kafka-topics.sh" --create --topic $TopicName --zookeeper $zookeeper --replication-factor 1 --partitions 1

[int]$n_produced = 9999

[hashtable]$params = @{
	'TopicName'=$TopicName;
	'BrokerList'=$Broker+':9092';
	'Verbose'=$true
}

Write-Host 'producing'
1..$n_produced |
	Select-Object @{'Name'='Message'; Expression={ 'Hello world #' + $_.ToString() }} |
		Out-KafkaTopic @params -BatchSize ($n_produced/5) -ErrorAction Stop

Write-Host 'consuming'
[int]$n_consumed = Read-KafkaTopic @params -MessageCount $n_produced -FromBeginning |
					Measure-Object | Select-Object -ExpandProperty Count

Write-Host 'deleting topic'
# $null = & "$kafka/bin/kafka-topics.sh" --delete --topic $TopicName --zookeeper $zookeeper

if ($n_produced -eq $n_consumed) {
	Write-Host 'Passed' -ForegroundColor Green
}
else {
	Write-Host 'Failed' -ForegroundColor Red
}

function Configure-NetworkManagerAndResolved {  
    $symlinkPath = '/etc/resolv.conf'  
    $targetPath = '/run/systemd/resolve/stub-resolv.conf'  
    
    # Check if the symlink exists  
    if (!(Test-Path $symlinkPath)) {  
        Write-Output "Creating symlink from $targetPath to $symlinkPath"  
        New-Object -TypeName System.IO.FileInfo -ArgumentList $symlinkPath | ForEach-Object { $_.Delete() }  
        cmd.exe /c mklink /Y $symlinkPath $targetPath  
    } else {  
        Write-Output "Symlink already exists at $symlinkPath"  
    }  
    
    # Restart services  
    Write-Output "Restarting systemd-resolved..."  
    Start-Process -FilePath 'systemctl' -ArgumentList 'restart', 'systemd-resolved' -NoNewWindow -Wait  
    Write-Output "Restarting NetworkManager..."  
    Start-Process -FilePath 'systemctl' -ArgumentList 'restart', 'NetworkManager' -NoNewWindow -Wait  
    Write-Output "Restarting tailscaled..."  
    Start-Process -FilePath 'systemctl' -ArgumentList 'restart', 'tailscaled' -NoNewWindow -Wait  
}  

# Call the function  
Configure-NetworkManagerAndResolved
