# Host Watch Scripts

This directory contains automated monitoring and maintenance scripts for Docker containers running on the host system. These scripts use systemd timers and PowerShell to monitor container health metrics and automatically remediate issues.

## Overview

The monitoring solutions in this directory are designed to:
- Run periodically via systemd timers
- Monitor specific container metrics (file descriptors, disk usage, database connections, error logs)
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

### `pg-connectionpool-limit/`

Monitors **PostgreSQL connection pool usage** across all services.

**What it does:**
- Queries PostgreSQL for active connections grouped by client IP
- Maps client IPs to Docker containers using service names
- Restarts containers if connection count exceeds the limit (default: 10 connections per service)
- Runs every **5 minutes** (triggered 5 minutes after boot)

**Key files:**
- `pg-connectionpool-limit.ps1` - PowerShell script that performs the monitoring
- `pg-connectionpool-limit.service` - Systemd service definition
- `pg-connectionpool-limit.timer` - Systemd timer (5-minute interval)
- `Makefile` - Management commands for install/start/stop/status/logs
- `readme.md` - Detailed documentation

**Quick start:**
```bash
cd pg-connectionpool-limit
make install-start    # Install and start the monitoring
make status           # Check if it's running
make logs             # View recent logs
```

### `django-pgpool-limit/`

Monitors **Django backend logs for PostgreSQL connection errors**.

**What it does:**
- Checks logs of `http-backend` containers for database connection errors
- Detects connection pool timeouts, too many connections, connection refused, and other critical errors
- Automatically restarts containers experiencing database connection issues
- Runs every **5 minutes** (triggered 5 minutes after boot)

**Key files:**
- `django-pgpool-limit.ps1` - PowerShell script that performs the monitoring
- `django-pgpool-limit.service` - Systemd service definition
- `django-pgpool-limit.timer` - Systemd timer (5-minute interval)
- `Makefile` - Management commands for install/start/stop/status/logs
- `readme.md` - Detailed documentation

**Quick start:**
```bash
cd django-pgpool-limit
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
# View logs for individual services
sudo journalctl -u bot-backend-fd-limit.service -f
sudo journalctl -u async-worker-du-limit.service -f
sudo journalctl -u pg-connectionpool-limit.service -f
sudo journalctl -u django-pgpool-limit.service -f

# View all watch service logs combined
sudo journalctl -u async-worker-du-limit.service \
                -u bot-backend-fd-limit.service \
                -u django-pgpool-limit.service \
                -u pg-connectionpool-limit.service \
                -n 50 --no-pager

# Follow all watch services in real-time
sudo journalctl -u async-worker-du-limit.service \
                -u bot-backend-fd-limit.service \
                -u django-pgpool-limit.service \
                -u pg-connectionpool-limit.service \
                -f

# List all watch service timers and schedules
sudo systemctl list-timers '*-limit.timer'
```

Or use the Makefile in each directory:

```bash
cd bot-backend-fd-limit && make logs
cd async-worker-du-limit && make logs
cd pg-connectionpool-limit && make logs
cd django-pgpool-limit && make logs
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
- Different remediation strategies:
  - **Container removal**: `bot-backend-fd-limit`, `async-worker-du-limit` (triggers `~/start.sh` to reconcile)
  - **Container restart**: `pg-connectionpool-limit`, `django-pgpool-limit` (direct restart via docker)
- Timers use **OnActiveSec** to ensure scheduling works after timer restarts
- Timer intervals vary by service (5min, 55min, 56min) to avoid overlapping execution

## See Also

- [bot-backend-fd-limit documentation](bot-backend-fd-limit/readme.md)
- [async-worker-du-limit documentation](async-worker-du-limit/readme.md)
- [pg-connectionpool-limit documentation](pg-connectionpool-limit/readme.md)
- [django-pgpool-limit documentation](django-pgpool-limit/readme.md)
