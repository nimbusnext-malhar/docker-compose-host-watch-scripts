#! powershell
# watches services of async-worker 
## and recreates it if the total disk usage goes above limit
$env = '/home/civitaiusr/.env'
$max_allowed_du_bytes = 25 * 1024 * 1024 * 1024 # convert to bytes -- here 25 GB
$service_name = 'async-workers'
$compose_file = '/home/civitaiusr/docker-compose.yml'

## set envs
Get-Content $env | ForEach-Object { if ($_ -match '^\s*([^#][^=]*)=(.*)$') { [System.Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim(), 'Process'); Write-Output "Set environment variable: $($matches[1].Trim()) value: $($matches[2].Trim())" } }

$containers = docker compose -f $compose_file --project-name $env:PROJECT_NAME ps -q $service_name

foreach ($container in $containers) {
	$du_bytes =  docker inspect --size --format='{{.SizeRw}}' $container
	$container_name = docker inspect --format='{{.Name}}' $container
	if ([Int64]$du_bytes -gt [Int64]$max_allowed_du_bytes) {
		Write-Output "Disk usage ${du_bytes} for container $container_name is above limit: $max_allowed_du_bytes. Removing ..."
		docker rm -f $container

		Write-Output "Reconciling services with default scrptipt ... "
		bash /home/civitaiusr/start.sh

	} else {
		Write-Output "Disk usage ${du_bytes} for container $container_name is within limit: $max_allowed_du_bytes."
	}
}