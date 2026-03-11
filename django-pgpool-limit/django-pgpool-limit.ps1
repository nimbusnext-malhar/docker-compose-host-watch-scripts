#! powershell
# Watches Django backend services
## and restarts them if critical PostgreSQL database connection errors are detected in logs
## Monitors for: connection pool timeouts, too many connections, connection refused, server closed connection, etc.

$env = '/home/civitaiusr/.env'
$compose_file = '/home/civitaiusr/docker-compose.yml'
$service_to_watch = 'http-backend'
## set envs
Get-Content $env | ForEach-Object { if ($_ -match '^\s*([^#][^=]*)=(.*)$') { [System.Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim(), 'Process'); Write-Output "Set environment variable: $($matches[1].Trim()) value: $($matches[2].Trim())" } }

$service_containers = docker compose -f $compose_file --project-name $env:PROJECT_NAME ps -q $service_to_watch 


Write-Output "PHASE 1: Checking for Connection Pool Exhaustion Errors"


## First loop: Check each container for PostgreSQL connection pool exhaustion errors
foreach ($container in $service_containers) {
    $container_name = docker inspect --format='{{.Name}}' $container
    $container_name = $container_name.TrimStart('/')
    
    Write-Output "`nChecking container: $container_name (ID: $container)"
    
    # Get recent logs (last 200 lines) and search for connection pool exhaustion
    $recent_logs = docker logs --tail 200 $container 2>&1 | Out-String
    
    # Define connection pool exhaustion error patterns
    $pool_error_patterns = @{
        "ConnectionPoolTimeout" = "psycopg_pool\.PoolTimeout.*couldn't get a connection"
        "OperationalError" = "django\.db\.utils\.OperationalError.*couldn't get a connection"
    }
    
    $error_found = $false
    $error_type = ""
    
    foreach ($pattern in $pool_error_patterns.GetEnumerator()) {
        if ($recent_logs -match $pattern.Value) {
            $error_found = $true
            $error_type = $pattern.Key
            break
        }
    }
    
    if ($error_found) {
        Write-Warning "Container '$container_name' has CONNECTION POOL EXHAUSTION ($error_type) in recent logs. Restarting container..."
        docker restart $container
        Write-Output "Container '$container_name' restarted successfully."
    } else {
        Write-Output "Container '$container_name' - No connection pool exhaustion errors detected."
    }
}

Write-Output "`n"

Write-Output "PHASE 2: Checking for Other Database Connection Errors"


## Second loop: Check each container for other database connection errors
foreach ($container in $service_containers) {
    $container_name = docker inspect --format='{{.Name}}' $container
    $container_name = $container_name.TrimStart('/')
    
    Write-Output "`nChecking container: $container_name (ID: $container)"
    
    # Get recent logs (last 200 lines) and search for other database errors
    $recent_logs = docker logs --tail 200 $container 2>&1 | Out-String
    
    # Define other database error patterns
    $other_error_patterns = @{
        "TooManyConnections" = "FATAL:.*too many connections"
        "ConnectionRefused" = "(Connection refused|could not connect to server)"
        "ServerClosedConnection" = "server closed the connection unexpectedly"
        "ConnectionReset" = "Connection reset by peer"
        "ReservedSlots" = "FATAL:.*remaining connection slots are reserved"
    }
    
    $error_found = $false
    $error_type = ""
    
    foreach ($pattern in $other_error_patterns.GetEnumerator()) {
        if ($recent_logs -match $pattern.Value) {
            $error_found = $true
            $error_type = $pattern.Key
            break
        }
    }
    
    if ($error_found) {
        Write-Warning "Container '$container_name' has DATABASE CONNECTION ERROR ($error_type) in recent logs. Restarting container..."
        docker restart $container
        Write-Output "Container '$container_name' restarted successfully."
    } else {
        Write-Output "Container '$container_name' - No other database connection errors detected."
    }
}

Write-Output "`n"
Write-Output "Health check completed for service: $service_to_watch"

