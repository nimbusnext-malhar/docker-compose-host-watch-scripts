# watches container name yavi-studio-civit-bot-backend-1
## and recreates it if the total file descriptor count goes above 900
$env = "/home/civitaiusr/.env"
$max_allowed_fd_count = 500
$container_name = "yavi-studio-civit-bot-backend-1"
$compose_file = "docker-compose.yml"
$service_name = "bot-backend"

Get-Content $env | ForEach-Object { if ($_ -match '^\s*([^#][^=]*)=(.*)$') { [System.Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim(), 'Process'); Write-Output "Set environment variable: $($matches[1].Trim()) value: $($matches[2].Trim())" } }


$current_fd_count = (docker exec $container_name sh -c "ls /proc/1/fd | wc -l")
if ([int]$current_fd_count -gt [int]$max_allowed_fd_count) {
	Write-Host "File descriptor count ($current_fd_count) exceeds the maximum allowed ($max_allowed_fd_count). Recreating the container..."
	docker rm -f $container_name
	# You can add the command to recreate the container here, e.g.:
	# docker run --name $container_name ...
	# handoff to bash script to start the container using docker compose
	bash ~/start.sh

} else {
	Write-Host "File descriptor count ($current_fd_count) is within the allowed limit ($max_allowed_fd_count). No action needed."
}