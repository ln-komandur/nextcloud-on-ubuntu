#!/bin/bash
#ref: https://unix.stackexchange.com/questions/28791/prompt-for-sudo-password-and-programmatically-elevate-privilege-in-bash-script
#ref: https://askubuntu.com/a/30157/8698
#
if (($EUID != 0)); then
  if [[ -t 1 ]]; then
#https://unix.stackexchange.com/questions/218715/what-does-t-1-do
    sudo "$0" "$@"
  else
    exec 1>output_file
    gksu "$0 $@"
  fi
  exit
fi

echo "This script configures Uncomplicated Firewall (UFW) on a nextcloud server installation"
echo "######################################################################################"
echo
echo "AUTHENTICATION SUCCESSFUL. You are executing the script as" $USER
echo
#http://moo.nac.uci.edu/~hjm/biolinux/Linux_Tutorial_12.html - gives "ifconfig | grep -A1 "wlan\|wlp"| grep inet | cut -f2 -d: | cut -f1 -d' ' "
#https://www.unix.com/shell-programming-and-scripting/112831-trim-last-octate-ip-address-using-bash-script.html - trim last octate of ip address using bash script

wlan_ip4address_3_blocks=`ip a | grep -A1 "wlan\|wlp"| grep inet | cut -f6 -d' ' | cut -f1 -d/ | cut -f1-3 -d.`
#echo "The first 3 blocks of wireless IP4 address of this server is : " $wlan_ip4address_3_blocks

subnet_mask_CIDR_format=$wlan_ip4address_3_blocks".0/24"

router_address=$wlan_ip4address_3_blocks".1"

echo "Subnet mask CIDR format "$subnet_mask_CIDR_format
echo
echo "Router address "$router_address
echo
echo "UFW Status is : "
ufw status
echo
echo "Opening and allowing incoming ssh TCP port 22"
ufw allow from $subnet_mask_CIDR_format to any port 22 proto tcp #opens and allows incoming ssh TCP port 22
echo
echo "Opening and allowing incoming HTTP TCP port 80"
ufw allow from $subnet_mask_CIDR_format to any port 80 proto tcp #opens and allows incoming HTTP TCP port 80
echo
echo "Opening and allowing incoming HTTPS TCP port 443"
ufw allow from $subnet_mask_CIDR_format to any port 443 proto tcp #opens and allows incoming HTTPS TCP port 443
echo
echo "Allowing multicast packets from the router"
ufw allow in from $router_address to 224.0.0.0/24 # To allow multicast packets from the router
echo
echo "Refreshing UFW "
ufw disable && ufw enable && ufw status # Refresh UFW 

exit
