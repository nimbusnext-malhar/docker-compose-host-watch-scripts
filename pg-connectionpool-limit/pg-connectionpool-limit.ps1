$max_conn_per_service = 10

$env = '/home/civitaiusr/.env'
$max_allowed_du_bytes = 15 * 1024 * 1024 * 1024 # convert to bytes -- here 25 GB
$service_name = 'async-workers'
$compose_file = '/home/civitaiusr/docker-compose.yml'

## set envs
Get-Content $env | ForEach-Object { if ($_ -match '^\s*([^#][^=]*)=(.*)$') { [System.Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim(), 'Process'); Write-Output "Set environment variable: $($matches[1].Trim()) value: $($matches[2].Trim())" } }

$db_container = docker compose -f $compose_file --project-name $env:PROJECT_NAME ps -q 'postgres'

## get a list of clients accessing the postgres db with the ip and current connections (active or idle)

# docker exec $db_container psql -U postgres -c "SELECT *  FROM pg_stat_activity" -t -A


$connections = docker exec $db_container psql -U postgres -c "SELECT client_addr, COUNT(*) as connection_count FROM pg_stat_activity GROUP BY client_addr ORDER BY connection_count DESC" -t -A | 
    Where-Object { $_ -match '\S' } |
    ForEach-Object {
        $parts = $_ -split '\|'
        [PSCustomObject]@{
            ClientAddress = $parts[0].Trim()
            ConnectionCount = [int]$parts[1].Trim()
        }
    }

## get all containers with their IP addresses, service name, container name, and container ID
$container_list = docker compose -f $compose_file --project-name $env:PROJECT_NAME ps -q | ForEach-Object {
    $container_id = $_.Trim()
    $inspect_data = docker inspect $container_id | ConvertFrom-Json
    
    [PSCustomObject]@{
        ContainerId = $container_id
        ContainerName = $inspect_data.Name.TrimStart('/')
        ServiceName = $inspect_data.Config.Labels.'com.docker.compose.service'
        IPAddress = $inspect_data.NetworkSettings.Networks.PSObject.Properties.Value.IPAddress | Select-Object -First 1
    }
}

## map client addresses to containers
$connection_details = $connections | ForEach-Object {
    $client_addr = $_.ClientAddress
    $matching_container = $container_list | Where-Object { $_.IPAddress -eq $client_addr }
    
    [PSCustomObject]@{
        ClientAddress = $client_addr
        ConnectionCount = $_.ConnectionCount
        ServiceName = if ($matching_container) { $matching_container.ServiceName } else { 'Unknown' }
        ContainerName = if ($matching_container) { $matching_container.ContainerName } else { 'Unknown' }
        ContainerId = if ($matching_container) { $matching_container.ContainerId } else { 'Unknown' }
    }
}

$connection_details

$connection_details | Where-Object { $_.ServiceName -ne 'Unknown' -and $_.ConnectionCount -gt $max_conn_per_service } | ForEach-Object {
	Write-Warning "Service '$($_.ServiceName)' (Container: $($_.ContainerName)) has $($_.ConnectionCount) connections from IP $($_.ClientAddress). Restarting container to mitigate potential issues."
	docker restart $_.ContainerId
}
	