#!/bin/bash
# this script is writen to keep ssh and its remote port running
user='lixun'
default_server_ip='xushuang-vps-sf-ipv6'  # WAN(public network) server ip addrs and user info
default_server_info="${user}@${default_server_ip}"  # WAN(public network) server ip addrs and user info
default_server_port="-p 443"   #public network server ssh port if didn't change default is 22
#Some company or school forbid the 22 port,such as dlut(Dalian University of technology),but 443 or 80 port
default_server="$default_server_port $default_server_info"
default_listen_port='7778' # the listend port can be any available port which will be used to connect your LAN server ssh -p listen_port_r user@127.0.0.1 
default_des_port='0702'  # LAN  server ssh port is the destination server port if didn't change default is 22
# check args

if [ "$#" -eq "0" ];then  
    ssh_server=$default_server
    listen_port_r=$default_listen_port
    des_port=$default_des_port
elif [ "$#" -eq "1" ];then 
    if [ "$1" == "--help" ];then
        echo -e "help: \n args format \n server_port server_ip listen_port_r des_port"
        exit
    else 
	echo "you do not give me your ssh server info.Now,use defaule server $default_server"
    fi
    echo "you just give me a ip_addrs,port is default:22"
    ssh_server="-p 22 $1"
    listen_port_r=$default_listen_port
    des_port=$default_des_port
elif [ "$#" -eq "2" ];then
    echo "your ip is : $2  port $1"
    ssh_server="-p $1 $2"
    listen_port_r=$default_listen_port
    des_port=$default_des_port
elif [ "$#" -eq "4" ];then
    echo "your ip is :$2 port $1 listen_port_r $3 des_port $4"
    listen_port_r="$3"
    des_port="$4"
else 
    echo "error! please use --help to check args!"
fi
#ssh remote port forwarding command
cmd="ssh -Nfg -R ${listen_port_r}:127.0.0.1:${des_port} ${ssh_server}"
exit_ssh='sleep 0.5;exit'
ssh_commands="sleep 0.5;mkdir -p log/ssh_from_LAN/;echo 'LAN server run '${cmd} >> 'log/ssh_from_LAN/login_info'; exit"
inverse_test_com='"'"sleep 0.5;echo '1' > 'log/ssh_from_WAN/flag';exit"'"'
test_connection="ssh $ssh_server $exit_ssh" #to check LAN server connect WAN server by ssh
test_inverse_connection='"'"ssh -p $listen_port_r ${user}@127.0.0.1 $inverse_test_com"'"'
#test_inverse_connection='"'"ssh -p $listen_port_r ${user}@127.0.0.1 'exit'"'"'
write_info_to_wan_device="ssh $ssh_server $ssh_commands"
current_time='date -Iseconds' 
if [ -d "log/ssh_from_WAN/" ];then
    echo " log/ssh_from_WAN/   exist!"
else 
    mkdir -p log/ssh_from_WAN/
fi
echo 0 > 'log/ssh_from_WAN/flag'
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
        echo $connections
        if [ "$connections" -ne "0" ];then  #unconnect
            echo "$($current_time) :	loss connections!"
            pids=$(ps -aux|grep "$cmd"|grep -v 'grep'|awk '{print $2}')
            echo $pids
            for pid_tmp in $pids
            do
                kill -9 "$pid_tmp"
                echo "$($current_time) : stoped unconnection ssh $cmd pid: $pid_tmp"
            done
        else 
            echo '0'> 'log/ssh_from_WAN/flag'
	    for check_inverse_connection_times in {1..3}
	    do
            ssh $ssh_server '"'$test_inverse_connection'"'
            echo $test_inverse_connection

            flag=$(cat "log/ssh_from_WAN/flag")
	    done
	    if [ "$flag" -ne "1" ];then
		echo "the ssh remote port forwarding faild. restart!"
		pids=$(ps -aux|grep "$cmd"|grep -v 'grep'|awk '{print $2}')
		echo $pids
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
