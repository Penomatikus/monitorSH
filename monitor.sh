#!/bin/bash
clear


echo " __  __             _ _                                   _      "
echo "|  \/  | ___  _ __ (_) |_ ___  _ __   _ __ ___   ___   __| | ___ "
echo "| |\/| |/ _ \| '_ \| | __/ _ \| '__| | '_ \` _ \ / _ \ / _\` |/ _ \\"
echo "| |  | | (_) | | | | | || (_) | |    | | | | | | (_) | (_| |  __/"
echo "|_|  |_|\___/|_| |_|_|\__\___/|_|    |_| |_| |_|\___/ \__,_|\___| enabler. playground :)"
echo

device=$1
up=$2

#### check if root
if [ "$(id -u)" != "0" ]; then
    echo [-] Script must be run as root.
    echo [!] sudo ./monitor.sh wlan-device-name
    exit 1
else
    echo [+] Root
    #### Check if device as parameter was given
    if [ -z "$1" ];    then
        echo [-] No parameter found. Syntax: \"monitor.sh wifi-device\"
        echo
        exit 1
    else
        # Check if device can be found
        if ifconfig | grep -wq $device; then
            echo [+] Found device: $device
            mac=`ifconfig $device | grep -wo '[0-9a-f]\{2\}\(:[0-9a-f]\{2\}\)\{5\}'`

            #### Check if 2nd arg was not null
            if [ -n  "$up" ]; then
                #### Check if 2nd arg was "up"
                if [ $up = "up" ]; then
                    #### No further checks if already up or not, just down, change, up
                    ifconfig $device down
                    iwconfig $device mode managed
                    ifconfig $device up
                    echo [+] Putting $device up
                    #### Check if changeing was successfull and print info on screen
                    if iwconfig $device | grep -wq Managed;    then
                        managed=`iwconfig $device | grep -wo Mode:Managed`
                        echo -e "[+] Check OK: \033[1;32m $managed \033[0m"
                        exit 0
                    else
                        echo [-] Changeing mode was not successfull.
                    fi
                else
                    echo [-] Only \"up\" is allowed as 2nd parameter
                    exit 1
                fi
            fi

            #### Check if device is already in monitor mode
            if iwconfig $device | grep -wq Monitor; then
                echo ['!'] $device is already 'in' monitor mode
                exit 0
            fi
        else
            echo [-] No device found
            echo [?] Mayby one of them':'
            echo -e  "   \033[1;37m" `ifconfig | egrep -o '^w([a-zA-Z]|[0-9])*'` "\033[0m"
            exit 1
        fi
    fi
fi

##### "user interface"
printf "[!] Setup device: ["
raute='#'
for i in `seq 1 20`;
do
    printf $raute
    sleep 0.03
done
echo "]"

##### grap some infotmation about the current network
ssid=`iwgetid -a $device | grep -wo '[0-9a-fA-F]\{2\}\(:[0-9a-fA-F]\{2\}\)\{5\}'`
noSsid='00:00:00:00:00:00 '
if [ $ssid==$noSsid ]; then
  channel='No connection before monitorSH'
  ssid='No connection before monitorSH'
  essid='No connection before monitorSH'
else
  channel=`iwgetid -c $device | egrep -o '(Channel:)[0-9]*'`
  essid=`iwgetid -r $device`
fi


#### Trying to put the device down for changeing mode
if ifconfig $device down; then
    echo [+] Putting $device down
else
    echo [-] Error 'while' trying to put $device down
    exit 1
fi

#### Trying to put device in monitor mode
if iwconfig $device mode monitor 2> /dev/null; then
    echo [+] Putting $device to monitor mode
else
    echo [-] Error 'while' trying to put $device on monitor mode
    printf "[!] Waking up $device...."

    #### Trying to "wake up" device from beeing down
    if ifconfig $device up; then
        printf ' Success!\n'
        echo [!] Checking internet connection. This may take a 'while'.
        wget -q --spider www.stackoverflow.com
        if [ $? -eq 0 ]; then
          echo [+] Your are now online
        else
          echo [-] Offline. Do you want to restart your network-manager by monitorSH? [ y / n ]
          read input
          if [[ $input == "Y" || $input == "y" ]]; then
            echo [!] Stopping network manager.
            service network-manager stop
            echo [!] Starting network manager.
            service network-manager start
          fi
        fi
    else
        printf Failed. Please wake up device by hand.
        exit 1
    fi

    exit 1
fi

#### Trying to "wake up" device from beeing down
if ifconfig $device up; then
    echo [+] Putting $device up
else
    echo [-] Error 'while' trying to put $device up
    exit 1
fi

##### Check if all went well and printing some addition information
if iwconfig $device | grep -wq Monitor
then
    monitor=`iwconfig $device | grep -wo Mode:Monitor`
    wirelessMode=`iwconfig $device | grep -wo 'IEEE 802.11[(a|b|g|n)]\{1,4\}'`
    echo -e "\n[+] Check OK: \t\t\033[1;32m $monitor \033[0m"
    echo -e "[!] Mac:  \t\t\033[1;37m $mac \033[0m"
    echo -e "[!] Wireless mode: \t\033[1;37m $wirelessMode \033[0m"
    echo -e "[!] Old ESSID: \t\t\033[1;37m $essid \033[0m"
    echo -e "[!] Old SSID: \t\t\033[1;37m $ssid \033[0m"
    echo -e "[!] Old B/E/SSID channel:\033[1;37m $channel \033[0m \n"
    printf "[?] If you enable wireshak decryption, you can only might decrypt\n    frames from devices, that are using the same modus: $wirelessMode\n"
else
    echo [-] Please run this script again.
    exit 1
fi

#### Check if aircrack-ng is installed
#### which's output is going to /dev/null for no text on screen if aircrack-ng was found
if which aircrack-ng > /dev/null; then
    echo [+] aircrack-ng is installed
    echo "    You can now run airmon-ng start $device [channel or frequency]"
else
    echo [-] aircrack-ng is not installed. Please 'install' aircrack-ng.
fi



exit 0
