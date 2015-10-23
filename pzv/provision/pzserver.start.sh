#!/bin/bash
#
# provision.sh
# 
pz_server=$(eval echo ~steam)/pzserver

if [ ! -f "$pz_server/start-server.sh" ]; then
	echo "[PZV-Run] Cannot start the Project Zomboid Dedicated Server: the server is not installed!"
else
	echo "[PZV-Run] Starting Project Zomboid 64-bit Dedicated Server..."
	screen -t "pz-server" bash -c "cd $pz_server; ./start-server.sh; read"
fi
