#!/bin/bash
#
# provision.sh
# 

start_seconds="$(date +%s)"

# Network Detection
#
# Make an HTTP request to google.com to determine if outside access is available
# to us. If 3 attempts with a timeout of 5 seconds are not successful, then we'll
# skip a few things further in provisioning rather than create a bunch of errors.
if [[ "$(wget --tries=3 --timeout=5 --spider http://google.com 2>&1 | grep 'connected')" ]]; then
	echo "[PZV-Provision] Network connection detected - running update and installation routines..."
	ping_result="Connected"

	#Pre-package installation
	curl -sL https://deb.nodesource.com/setup_4.x | bash -
	dpkg --add-architecture i386 #for lgsm - also steamcmd lib32gcc1 dep(?) TODO: Add configurable architecture

	# PACKAGE INSTALLATION
	apt_package_check_list=(
		lib32gcc1 #required for steamcmd
		git-core
		nginx
		curl
		ntp       #keep the system clock current
		dos2unix  #allows conversion of DOS style line endings to UNIX style
		nodejs
	#lgsm deps
		#tmux
		#mailutils
		#postfix
		#ca-certificates
		#libstdc++6
		#libstdc++6:i386
		#openjdk-7-jre
	)

	apt_package_install_list=()

	echo "[PZV-Provision] Check for apt packages to install..."
	for pkg in "${apt_package_check_list[@]}"; do
		package_version="$(dpkg -s $pkg 2>&1 | grep 'Version:' | cut -d " " -f 2)"
		if [[ -n "${package_version}" ]]; then
			space_count="$(expr 20 - "${#pkg}")" #11
			pack_space_count="$(expr 30 - "${#package_version}")"
			real_space="$(expr ${space_count} + ${pack_space_count} + ${#package_version})"
			printf " * $pkg %${real_space}.${#package_version}s ${package_version}\n"
		else
			echo " *" $pkg [not installed]
			apt_package_install_list+=($pkg)
		fi
	done

	if [[ ${#apt_package_install_list[@]} = 0 ]]; then
		echo -e "[PZV-Provision] No apt packages to install.\n"
	else
		# update all of the package references before installing anything
		echo "[PZV-Provision] Running apt-get update..."
		apt-get update --assume-yes

		# install required packages
		echo "[PZV-Provision] Installing apt-get packages..."
		apt-get install --assume-yes ${apt_package_install_list[@]}

		# Clean up apt caches
		apt-get clean
	fi

	# npm
	#
	# Make sure we have the latest npm version and the update checker module
	npm install -g npm
	npm install -g npm-check-updates

	# Grunt
	#
	# Install or Update Grunt based on current state.  Updates are direct
	# from NPM
	echo ""
	if [[ "$(grunt --version)" ]]; then
		echo "[PZV-Provision] Updating Grunt CLI - this can take a few minutes"
		npm update -g grunt-cli > /dev/null 2>&1
		npm update -g grunt-sass > /dev/null 2>&1
		npm update -g grunt-cssjanus > /dev/null 2>&1
		npm update -g grunt-rtlcss > /dev/null 2>&1
	else
		echo "[PZV-Provision] Installing Grunt CLI - this can take a few minutes"
		npm install -g grunt-cli > /dev/null 2>&1
		npm install -g grunt-sass > /dev/null 2>&1
		npm install -g grunt-cssjanus > /dev/null 2>&1
		npm install -g grunt-rtlcss > /dev/null 2>&1
	fi

	steam_home=$(eval echo ~steam)
	steam_tmp=$steam_home/tmp
	steam_cmd=$steam_home/steamcmd
	steam_logs=$steam_home/Steam/logs
	pz_server=$steam_home/pzserver

	if [ -d $steam_tmp ]; then
		rm -fr $steam_tmp
	fi

	sudo -u steam mkdir $steam_home/tmp

	if [ ! -d $steam_cmd ]; then
		echo "[PZV-Provision] Installing SteamCMD..."
		sudo -u steam mkdir $steam_cmd
		sudo -u steam wget -P $steam_tmp https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
		sudo -u steam tar -xvzf $steam_tmp/steamcmd_linux.tar.gz -C $steam_cmd

		# Initialize and update steamcmd with an empty call
		sudo -u steam $steam_cmd/steamcmd.sh +login anonymous +quit

		# Symlink Steam logs to synced host directory and move any pre-existing logs into the new symlink
		echo "[PZV-Provision] Symlinking Steam Logs: /vagrant/logs/steam => $steam_logs"
		if [ "$(ls -A $steam_logs)" ]; then
			if [ -d $steam_tmp/steamlogs ]; then
				sudo -u steam rm -fr $steam_tmp/steamlogs/*
			else
				sudo -u steam mkdir $steam_tmp/steamlogs
			fi

			sudo -u steam mv $steam_logs/* $steam_tmp/steamlogs
		fi

		if [ -d $steam_logs ]; then
			sudo -u steam rm -fr $steam_logs
		fi

		if [ ! -d /vagrant/logs/steam ]; then
			mkdir -p /vagrant/logs/steam
		fi

		sudo -u steam ln -sf /vagrant/logs/steam $steam_logs

		if [ -d $steam_tmp/steamlogs ]; then
			sudo -u steam mv $steam_tmp/steamlogs/* $steam_logs 

			sudo -u steam rm -fr $steam_tmp/steamlogs
		fi
	fi

	#TODO: update this to use a file containing SteamCMD shell commands in order to validate and check success/failure status
	echo "[PZV-Provision] Installing the Project Zomboid 64-bit Dedicated Server..."
	sudo -u steam $steam_cmd/steamcmd.sh +login anonymous +force_install_dir $pz_server +app_update 380870 +quit
else
	ping_result="Not Connected"
	echo -e "\n[PZV-Provision] ERROR: No network connection detected - installation and update routines have been skipped!"
fi

# Create the "steam" user if it doesn't already exist
if ! id -u steam >/dev/null 2>&1; then
	echo "Creating user 'steam'..."
    useradd -m steam
fi

end_seconds="$(date +%s)"
echo "-------------------------------------------------------------------------"
echo "[PZV-Provision] Provisioning completed in "$(expr $end_seconds - $start_seconds)" seconds"
echo "-------------------------------------------------------------------------"

if [ ! -f $pz_server/start-server.sh ]; then
	echo "[PZV-Provision] ERROR - The Project Zomboid Dedicated Server could not be installed!"
	echo "                Scan the console for errors, then try reprovisioning with \"vagrant reload --provision\""
fi
