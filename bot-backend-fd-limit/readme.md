# Watch Script for `bot-backend` service's File Descriptor Limit

This script monitors the file descriptor count of the `bot-backend` container and recreates it if the count exceeds the specified limit.

## Usage

## Makefile Actions

The Makefile provides convenient targets for managing the bot-backend-fd-limit systemd timer and service.

### Usage

Run any action with:

	make <action>

### Actions

- **build**: No build step required (placeholder).
- **install**: Creates symlinks for the service and timer in /etc/systemd/system, reloads systemd, and starts the timer.
- **start**: Starts the bot-backend-fd-limit.timer.
- **stop**: Stops the bot-backend-fd-limit.timer.
- **status**: Shows the status of the bot-backend-fd-limit.timer.
- **clean**: Removes the symlinks from /etc/systemd/system and reloads systemd.

### Example

To install and start the timer:

	make install

To check status:

	make status

To stop the timer:

	make stop

To remove the timer and service:

	make clean

## Requirements

- Requires sudo privileges for systemd actions.
