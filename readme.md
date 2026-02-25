# Host Watch Scripts

This directory contains automated monitoring and maintenance scripts for Docker containers running on the host system. These scripts use systemd timers and PowerShell to monitor container health metrics and automatically remediate issues.

## Overview

The monitoring solutions in this directory are designed to:
- Run periodically via systemd timers
- Monitor specific container metrics (file descriptors, disk usage)
- Automatically restart or recreate containers when thresholds are exceeded
- Log all activities to systemd journal for debugging

## Directory Structure

### `bot-backend-fd-limit/`

Monitors the **file descriptor (FD) count** of the `bot-backend` container.

**What it does:**
- Checks the number of open file descriptors in the bot-backend container
- Recreates the container if FD count exceeds the configured limit
- Runs every **55 minutes** (triggered 5 minutes after boot)

**Key files:**
- `watch-fd-botbackend.ps1` - PowerShell script that performs the monitoring
- `bot-backend-fd-limit.service` - Systemd service definition
- `bot-backend-fd-limit.timer` - Systemd timer (55-minute interval)
- `Makefile` - Management commands for install/start/stop/status/logs
- `readme.md` - Detailed documentation

**Quick start:**
```bash
cd bot-backend-fd-limit
make install-start    # Install and start the monitoring
make status           # Check if it's running
make logs             # View recent logs
```

### `async-worker-du-limit/`

Monitors the **disk usage (DU)** of `async-worker` containers.

**What it does:**
- Checks the disk usage (`SizeRw`) of all async-worker containers
- Removes and restarts containers if disk usage exceeds the limit (default: 25 GB)
- Runs every **56 minutes** (triggered 5 minutes after boot)

**Key files:**
- `watch-async-worker-du-limit.ps1` - PowerShell script that performs the monitoring
- `async-worker-du-limit.service` - Systemd service definition
- `async-worker-du-limit.timer` - Systemd timer (56-minute interval)
- `Makefile` - Management commands for install/start/stop/status/logs
- `readme.md` - Detailed documentation

**Quick start:**
```bash
cd async-worker-du-limit
make install-start    # Install and start the monitoring
make status           # Check if it's running
make logs             # View recent logs
```

## How It Works

### Architecture

Each monitoring solution follows the same pattern:

1. **Systemd Timer** - Triggers the service at regular intervals
2. **Systemd Service** - Runs the PowerShell script as a oneshot service
3. **PowerShell Script** - Performs the actual monitoring and remediation
4. **Makefile** - Provides convenient management commands

### Workflow

```
┌─────────────────┐
│  Systemd Timer  │  ← Triggers every N minutes
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Systemd Service │  ← Runs PowerShell script
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ PowerShell      │  ← Checks container metrics
│ Monitoring      │
│ Script          │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
  OK      EXCEEDED
  │         │
  │         ▼
  │    ┌─────────────────┐
  │    │ Remove/Restart  │
  │    │ Container       │
  │    │ Run start.sh    │
  │    └─────────────────┘
  │         │
  └────┬────┘
       │
       ▼
   ┌──────────┐
   │   Log    │
   │ Results  │
   └──────────┘
```

## Common Management Commands

All folders use the same Makefile pattern:

```bash
make install       # Install service and timer (creates symlinks in /etc/systemd/system)
make start         # Start the timer
make stop          # Stop the timer
make status        # Check timer status
make logs          # View recent logs (follows in real-time)
make logs-all      # View all logs (no paging)
make clean         # Uninstall (removes symlinks)
make reinstall     # Clean, install, and start in one command
make install-start # Install and start in one command
```

## Requirements

- **PowerShell** (`pwsh`) installed on the host system
- **sudo** privileges for systemd operations
- **Docker** containers running on the host
- **Environment variables** in `~/.env` (loaded by scripts)

## Logs and Debugging

All scripts log to systemd journal. View logs using:

```bash
# View logs for bot-backend monitoring
sudo journalctl -u bot-backend-fd-limit.service -f

# View logs for async-worker monitoring
sudo journalctl -u async-worker-du-limit.service -f

# View all logs without pagination
sudo journalctl -u bot-backend-fd-limit.service --no-pager
sudo journalctl -u async-worker-du-limit.service --no-pager
```

Or use the Makefile:

```bash
cd bot-backend-fd-limit && make logs
cd async-worker-du-limit && make logs-all
```

## Adding New Monitoring Scripts

To add a new monitoring script, follow this pattern:

1. Create a new directory under `host-watch-scripts/`
2. Create a PowerShell script that performs the monitoring
3. Create a `.service` file that runs your script
4. Create a `.timer` file with your desired interval
5. Create a `Makefile` with standard targets (install, start, stop, status, logs, clean)
6. Create a `readme.md` documenting the specific monitoring solution

## Notes

- Timers start **5 minutes after boot** to allow services to initialize
- Scripts use **oneshot** service type (run once per trigger, then exit)
- All output goes to **systemd journal** (journalctl)
- Scripts load environment variables from **~/.env**
- Container removal triggers **~/start.sh** to reconcile services

## See Also

- [bot-backend-fd-limit documentation](bot-backend-fd-limit/readme.md)
- [async-worker-du-limit documentation](async-worker-du-limit/readme.md)
