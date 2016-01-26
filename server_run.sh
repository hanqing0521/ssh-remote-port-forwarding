#!/bin/bash
case $1 in
    start) 
	echo "start ssh remote forwarding service"
	[ ! -d "$HOME/.ssh" ] && mkdir "$HOME/.ssh"
	echo "StrictHostKeyChecking no">"$HOME/.ssh/config"
	echo "UserKnownHostsFile $HOME/.ssh/UnTrustHosts">>"$HOME/.ssh/config"
	chmod 600 $HOME/.ssh/config
	while read info
	do
	    CancelOrNot=$(echo $info|grep '^#' )
	    if [ -z "$CancelOrNot" ];then
		listen_port_r=$(echo $info|awk '{print $1}')
		des_port=$(echo $info|awk '{print $2}')
		server_port=$(echo $info|awk '{print $3}')
		user=$(echo $info|awk '{print $4}')
		server_ip_addrs=$(echo $info|awk '{print $5}')
		dir="${server_ip}:$server_port"
		[ ! -d "$HOME/logs/ssh_from_WAN/${dir}" ] && mkdir -p "$HOME/logs/ssh_from_WAN/${dir}"
		./ssh-daemon.sh $listen_port_r $des_port $server_port $user $server_ip_addrs &
		#echo  "$listen_port_r $des_port $server_port $user $server_ip_addrs" &
	    else 
		continue
	    fi
	done < tables
	;;
    stop)
	echo "stop ssh remote forwarding service"
	[ -f "$HOME/.ssh/config" ] && rm -f "$HOME/.ssh/config"
	[ -f "$HOME/.ssh/UnTrustHosts" ] && echo "unkown host $(cat $HOME/.ssh/UnTrustHosts) had been login by ssh-daemon service"
	if [ -f "$HOME/logs/ssh_from_WAN/${dir}/cmd_file" ];then
	    cmds=$(cat  $HOME/logs/ssh_from_WAN/${dir}/cmd_file)
	    for cmd_tmp in "$cmds"
	    do
                pids=$(ps -aux|grep "$cmd_tmp"|grep -v 'grep'|awk '{print $2}')
                echo $pids
                for pid_tmp in $pids
                do
                    kill -9 "$pid_tmp"
                    echo "$($current_time) : stop unvailable ssh remote port forwarding $cmd_tmp pid:  $pid_tmp"
                done
	    done
	else 
	    echo "can not find file $HOME/logs/ssh_from_WAN/${dir}/cmd_file !"
	fi
	;;
    *)
	echo "start ssh remote forwarding service"
	[ ! -d "$HOME/.ssh" ] && mkdir "$HOME/.ssh"
	echo "StrictHostKeyChecking no">"$HOME/.ssh/config"
	echo "UserKnownHostsFile $HOME/.ssh/UnTrustHosts">>"$HOME/.ssh/config"
	[ ! -d "$HOME/logs/ssh_from_WAN" ] && mkdir -p "$HOME/logs/ssh_from_WAN"
	infos=$(sed -n '2,$ p' tables)
	for info in $infos 
	do
	    listen_port_r=$(echo $info|awk '{print $1}')
	    des_port=$(echo $info|awk '{print $2}')
	    server_port=$(echo $info|awk '{print $3}')
	    user=$(echo $info|awk '{print $4}')
	    server_ip_addrs=$(echo $info|awk '{print $5}')
	./ssh-daemon.sh $listen_port_r $des_port $server_port $user $server_ip_addrs &
	done
	;;
esac







