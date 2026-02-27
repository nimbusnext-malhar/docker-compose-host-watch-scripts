# Watch Script for PostgreSQL Connection Pool Limit

This is a systemd-based monitoring solution that periodically checks PostgreSQL database connection counts per service and automatically restarts containers that exceed the configured connection limit.

## Overview

The solution consists of:
- **PowerShell Script** (`pg-connectionpool-limit.ps1`): Monitors database connections per service and triggers container restart when limit is exceeded
- **Systemd Service** (`pg-connectionpool-limit.service`): Wraps the PowerShell script as a systemd service
- **Systemd Timer** (`pg-connectionpool-limit.timer`): Triggers the service every 5 minutes
- **Makefile**: Provides convenient commands for installation and management

## How It Works

1. Every 5 minutes (configurable in the timer), the systemd timer triggers the service
2. The service runs the PowerShell script which:
   - Loads environment variables from `~/.env`
   - Queries PostgreSQL for active connections grouped by client IP address
   - Maps client IPs to Docker containers using service names
   - If any service exceeds the connection limit (default: 10):
     - Logs a warning with service details
     - Restarts the offending container
   - Displays connection details for all services

## Configuration

To change the maximum connections per service, edit the `pg-connectionpool-limit.ps1` file:

```powershell
$max_conn_per_service = 10  # default: 10 connections
```

You can adjust this value based on your application's needs and database capacity.

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
pwsh pg-connectionpool-limit.ps1
```

Or trigger the service directly:
```bash
sudo systemctl start pg-connectionpool-limit.service
```

## Notes

- The timer starts 5 minutes after system boot and then runs every 5 minutes
- The script requires PowerShell (`pwsh`) to be installed on the system
- Environment variables are loaded from `~/.env`
- The script identifies containers by matching PostgreSQL client IP addresses with Docker network IPs
- Only containers with known service names (not 'Unknown') are subject to automatic restart
- Connection counts include both active and idle connections

## Requirements

- Requires sudo privileges for systemd actions
- PostgreSQL container must be running and accessible
- Docker Compose project must be properly configured with service labels
