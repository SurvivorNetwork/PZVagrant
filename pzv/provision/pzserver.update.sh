#!/bin/bash
#
# provision.sh
# 
start_seconds="$(date +%s)"
steam_home=$(eval echo ~steam)
steam_cmd=$steam_home/steamcmd
pz_server=steam_home/pzserver
action="update"

if [ ! -f "$pz_server/start-server.sh" ]; then
	action="installation"
fi

echo "[PZV-Update] Project Zomboid 64-bit Dedicated Server $action started..."

#TODO: update this to use a file containing SteamCMD shell commands in order to validate and check success/failure status
sudo -u steam $steam_cmd/steamcmd.sh +login anonymous +force_install_dir $pz_server +app_update 380870 +quit

end_seconds="$(date +%s)"
echo "-------------------------------------------------------------------------"
echo "[PZV-Update] Server $action completed in "$(expr $end_seconds - $start_seconds)" seconds"
echo "-------------------------------------------------------------------------"