#!/bin/bash
case $1 in
    start)
	echo "start to find the ssh remote forwarding service from scholl device"
	[ ! -d "$HOME/.ssh" ] && mkdir "$HOME/.ssh"
	echo "StrictHostKeyChecking no">"$HOME/.ssh/config"
	echo "UserKnownHostsFile $HOME/.ssh/UnTrustHosts">>"$HOME/.ssh/config"
	chmod 600 $HOME/.ssh/config
	[ ! -d "$HOME/logs/ssh_from_LAN" ] && mkdir -p "$HOME/logs/ssh_from_WAN"
	;;
    stop)

	echo "stop ssh remote forwarding service"
	[ -f "$HOME/.ssh/config" ] && rm -f "$HOME/.ssh/config"
	[ -f "$HOME/.ssh/UnTrustHosts" ] && echo "unkown host $(cat $HOME/.ssh/UnTrustHosts) had been login by ssh-daemon service"
	;;
esac

