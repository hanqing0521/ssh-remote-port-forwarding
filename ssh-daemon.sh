#!/bin/bash
# this script is writen to keep ssh and its remote port running
default_user='lixun'
default_server_ip='xushuang-vps-sf-ipv6'  # WAN(public network) server ip addrs and user info
default_server_info="${default_user}@${default_server_ip}"  # WAN(public network) server ip addrs and user info
default_server_port=443   #public network server ssh port if didn't change default is 22
#Some company or school forbid the 22 port,such as dlut(Dalian University of technology),but 443 or 80 port
default_server="-p $default_server_port $default_server_info"
default_listen_port='7778' # the listend port can be any available port which will be used to connect your LAN server ssh -p listen_port_r user@127.0.0.1 
default_des_port='0702'  # LAN  server ssh port is the destination server port if didn't change default is 22
# check args

case "$#" in 
    0)
	echo "you do not give me your ssh server info.Now,use defaule server $default_server"
	server_port=$default_server_port
	user=$default_user
	server_ip=$default_server_ip
	ssh_server=$default_server
	listen_port_r=$default_listen_port
	des_port=$default_des_port
	;;
    1)
	if [ "$1" == "--help" ];then
	    echo -e "help: \n args format \n server_port server_ip listen_port_r des_port"
	    exit
	else 
	    echo "you just give me a ip_addrs:$1 ,port is default:22"
	fi
	ssh_server="-p $default_server_port ${default_user}@$1"
	listen_port_r=$default_listen_port
	des_port=$default_des_port
	;;
    2)
	echo "your ip is : $2  port $1"
	ssh_server="-p $1 ${default_user}@$2"
	listen_port_r=$default_listen_port
	des_port=$default_des_port
	;;
    3)
	echo "your ip is : $3 user :$2 port:$1"
	ssh_server="-p $1 $2@$3"
	listen_port_r=$default_listen_port
	des_port=$default_des_port
	;;

    4)
	echo "your listen_port_r: $1  server_port: $2 user: $3 server_ip $4"
	echo "des_port is default args $default_des_port !"
	listen_port_r="$1"
	server_port="$2"
	user="$3"
	server_ip="$4"
	ssh_server="-p $server_port ${user}@$server_ip"
	des_port="$default_des_port"
	;;
    5)
	echo " all args are custom!"
	echo " listen_port_r:$1 des_port: $2 server_port: $3 user: $4 server_ip: $5"
	listen_port_r="$1"
	des_port="$2"
	server_port="$3"
	user="$4"
	server_ip="$5"
	ssh_server="-p $server_port ${user}@$server_ip"
	;;
    *)
 
    echo "error! please use --help to check args!"
    ;;
esac


#ssh remote port forwarding command
dir="${server_ip}P$server_port"
[ ! -d "$HOME/logs/ssh_from_WAN/$dir" ]&& mkdir -p "$HOME/logs/ssh_from_WAN/${dir}"
echo $dir
cmd="ssh -Nfg -R ${listen_port_r}:127.0.0.1:${des_port} ${ssh_server}"
exit_ssh='sleep 0.5;exit'
ssh_commands="sleep 0.5;mkdir -p logs/ssh_from_LAN/;echo 'LAN server run '${cmd} >> 'logs/ssh_from_LAN/login_info'; exit"
inverse_test_com='"'"sleep 0.5;echo '1' > $HOME/logs/ssh_from_WAN/${dir}/flag;exit"'"'
test_connection="ssh $ssh_server $exit_ssh" #to check LAN server connect WAN server by ssh
test_inverse_connection='"'"ssh -p $listen_port_r ${user}@127.0.0.1 $inverse_test_com"'"'
#test_inverse_connection='"'"ssh -p $listen_port_r ${user}@127.0.0.1 'exit'"'"'
write_info_to_wan_device="ssh $ssh_server $ssh_commands"
current_time='date -Iseconds' 
if [ -d "$HOME/logs/ssh_from_WAN/${dir}" ];then
    echo " $HOME/logs/ssh_from_WAN/${dir}   exist!"
else 
    mkdir -p $HOME/logs/ssh_from_WAN/${dir}/
fi
echo 0 > "$HOME/logs/ssh_from_WAN/${dir}/flag"
while :
do
    It_Is_Run=$(ps -ax|grep "$cmd"|grep -v 'grep')  #is there are ssh -Nfg.....($cmd) runing?
    if [ -z "$It_Is_Run" ];then  # if no 
        echo "$($current_time):	ssh server stoped. start server!" 
        connections="1"
        while [ "$connections" -ne "0" ]  
        do
            sleep 10
            $test_connection
            connections=$?
            echo "$($current_time): $connections " 
        done 
            $cmd
	    echo "$cmd">>"$HOME/logs/ssh_from_WAN/${dir}/cmd_file"
        if [ "$?" -eq "0" ];then
            echo "$($current_time) : succeed!"
        $write_info_to_wan_device
        else 
            echo "unkown error can not start ssh connection!"
        fi
    else     #if there $cmd runing
        connections=1
        $test_connection  #test the connection status
        connections=$? 
        if [ "$connections" -ne "0" ];then  #unconnect
            echo "$($current_time) :	loss connections!"
            pids=$(ps -aux|grep "$cmd"|grep -v 'grep'|awk '{print $2}')
            for pid_tmp in $pids
            do
                kill -9 "$pid_tmp"
                echo "$($current_time) : stoped unconnection ssh $cmd pid: $pid_tmp"
            done
        else 
            echo '0'> "$HOME/logs/ssh_from_WAN/${dir}/flag"
            for check_inverse_connection_times in {1..3}
            do
                ssh $ssh_server '"'$test_inverse_connection'"'
                #echo $test_inverse_connection
                flag=$(cat "$HOME/logs/ssh_from_WAN/${dir}/flag")
                sleep 5
            done
            if [ "$flag" -ne "1" ];then
                echo "the ssh remote port forwarding faild. restart!"
                pids=$(ps -aux|grep "$cmd"|grep -v 'grep'|awk '{print $2}')
                for pid_tmp in $pids
                do
                    kill -9 "$pid_tmp"
                    echo "$($current_time) : stop unvailable ssh remote port forwarding $cmd pid:  $pid_tmp"
                done
            else 
                echo "$($current_time) :  Nice it work well!"
                echo "Every man is his own worst ennemy!"
                sleep 10
            fi
        fi
    fi
done
