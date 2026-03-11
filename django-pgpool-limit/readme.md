# Watch Script for Django PostgreSQL Connection Pool Limit

This is a systemd-based monitoring solution that periodically checks Django backend service logs for PostgreSQL database connection errors and automatically restarts containers experiencing critical database issues.

## Overview

The solution consists of:
- **PowerShell Script** (`django-pgpool-limit.ps1`): Monitors Django backend container logs for database connection errors and triggers container restart when critical errors are detected
- **Systemd Service** (`django-pgpool-limit.service`): Wraps the PowerShell script as a systemd service
- **Systemd Timer** (`django-pgpool-limit.timer`): Triggers the service every 5 minutes
- **Makefile**: Provides convenient commands for installation and management

## How It Works

1. Every 5 minutes (configurable in the timer), the systemd timer triggers the service
2. The service runs the PowerShell script which:
   - Loads environment variables from `~/.env`
   - Gets all containers for the specified service (default: `http-backend`)
   - Checks the last 100 lines of logs from each container for critical database errors
   - If any of the following errors are detected, the container is automatically restarted:
     - **Connection Pool Timeout**: `psycopg_pool.PoolTimeout` - Pool exhausted, no connections available
     - **Operational Errors**: `django.db.utils.OperationalError` - General connection failures
     - **Too Many Connections**: PostgreSQL max_connections limit reached
     - **Connection Refused**: Cannot connect to PostgreSQL server
     - **Server Closed Connection**: Unexpected connection termination
     - **Connection Reset**: Network-level connection reset
     - **Reserved Slots**: All connection slots reserved for superusers
   - Logs detailed information about which error type was detected and actions taken

## Configuration

To change which service to monitor, edit the `django-pgpool-limit.ps1` file:

```powershell
$service_to_watch = 'http-backend'  # default: http-backend
```

To adjust how many log lines to check for errors:

```powershell
docker logs --tail 100 $container  # default: last 100 lines
```

You can also modify the `$error_patterns` hash table to add or remove specific error patterns to monitor.

## Installation

Install the systemd service and timer:

```bash
make install
```

This creates symlinks in `/etc/systemd/system/` and reloads systemd.

## Usage

Start the timer:
```bash
make start
```

Stop the timer:
```bash
make stop
```

Check status:
```bash
make status
```

View recent logs (follow mode):
```bash
make logs
```

View all logs:
```bash
make logs-all
```

Install and start in one command:
```bash
make install-start
```

Uninstall (remove service and timer):
```bash
make clean
```

Reinstall (clean, install, and start):
```bash
make reinstall
```

## Manual Execution

To run the script manually without waiting for the timer:

```bash
pwsh django-pgpool-limit.ps1
```

Or trigger the service directly:
```bash
sudo systemctl start django-pgpool-limit.service
```

## Notes

- This script specifically monitors the `http-backend` service by default (configurable via `$service_to_watch`)
- Checks the last 100 lines of container logs for database-related errors
- The script logs detailed error information and container restart actions to systemd journal
- Automatically handles multiple error types that indicate connection pool or database issues
- Restarting containers helps recover from connection pool exhaustion, deadlocks, and other transient database issues
- The timer interval can be adjusted in the `.timer` file by modifying the `OnUnitActiveSec` value (default: 5 minutes)
- The script uses `docker logs --tail 100` so only recent errors trigger restarts, avoiding false positives from old logs
