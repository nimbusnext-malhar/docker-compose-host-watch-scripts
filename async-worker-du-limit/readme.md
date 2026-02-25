# Watch Script for `async-worker` service's Disk Usage Limit

This is a systemd-based monitoring solution that periodically checks the disk usage of `async-worker` containers and automatically removes and restarts them if they exceed a configured threshold.

## Overview

The solution consists of:
- **PowerShell Script** (`watch-async-worker-du-limit.ps1`): Monitors container disk usage and triggers container removal/restart when limit is exceeded
- **Systemd Service** (`async-worker-du-limit.service`): Wraps the PowerShell script as a systemd service
- **Systemd Timer** (`async-worker-du-limit.timer`): Triggers the service every 56 minutes
- **Makefile**: Provides convenient commands for installation and management

## How It Works

1. Every 56 minutes (configurable in the timer), the systemd timer triggers the service
2. The service runs the PowerShell script which:
   - Loads environment variables from `~/.env`
   - Checks disk usage (`SizeRw`) of all async-worker containers
   - If any container exceeds the limit (default: 25 GB):
     - Removes the container forcefully
     - Runs `~/start.sh` to reconcile/restart services
   - If within limits, logs the current usage

## Configuration

To change the disk usage limit, edit the `watch-async-worker-du-limit.ps1` file:

```powershell
$max_allowed_du_bytes = 25 * 1024 * 1024 * 1024 # default: 25 GB
```

You can specify it in bytes directly (e.g., `26843545600`) or use the conversion formula.

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

Install and start in one command:
```bash
make install-start
```

Uninstall (remove service and timer):
```bash
make clean
```

## Manual Execution

To run the script manually without waiting for the timer:

```bash
pwsh watch-async-worker-du-limit.ps1
```

Or trigger the service directly:
```bash
sudo systemctl start async-worker-du-limit.service
```

## Notes

- The timer starts 5 minutes after system boot and then runs every 56 minutes
- The script requires PowerShell (`pwsh`) to be installed on the system
- Environment variables are loaded from `~/.env`
- When a container is removed, the entire stack is reconciled using `start.sh`