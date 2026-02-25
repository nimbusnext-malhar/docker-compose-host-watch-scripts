# Makefile for async-worker-du-limit actions

# Variables
NAME=async-worker-du-limit
SERVICE=$(NAME).service
TIMER=$(NAME).timer
	
.PHONY: build install start stop status logs logs-all clean

build:
	echo "No build step required."

install:
	sudo ln -sf $(PWD)/$(SERVICE) /etc/systemd/system/$(SERVICE)
	sudo ln -sf $(PWD)/$(TIMER) /etc/systemd/system/$(TIMER)
	sudo systemctl daemon-reload

start:
	sudo systemctl start $(TIMER)

install-start: install start

stop:
	sudo systemctl stop $(TIMER)

status:
	sudo systemctl status $(TIMER)

logs:
	sudo journalctl -u $(SERVICE) -n 50 -f

logs-all:
	sudo journalctl -u $(SERVICE) --no-pager

clean:
	sudo rm -f /etc/systemd/system/$(SERVICE)
	sudo rm -f /etc/systemd/system/$(TIMER)
	sudo systemctl daemon-reload
