#!/bin/bash
#ref: https://unix.stackexchange.com/questions/28791/prompt-for-sudo-password-and-programmatically-elevate-privilege-in-bash-script
#ref: https://askubuntu.com/a/30157/8698

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
echo "This script stops nextcloud services namely PHP Session Clean timer, PHP7.4fpm, MariaDB, Apache2. After"
echo "stopping these services, it reports the mount status of the NextCloud Data partition and unmounts it too"
echo "AUTHENTICATION SUCCESSFUL. You are executing the script as" $USER
#echo
#echo
#echo "---------------------------------------------------------------------------------------------------"
#echo "Status of phpsessionclean.timer, php7.4-fpm.service, mariadb.service, apache2.service"
#echo "---------------------------------------------------------------------------------------------------"
#systemctl status phpsessionclean.timer php7.4-fpm.service mariadb.service apache2.service
echo
echo
echo "---------------------------------------------------------------------------------------------------"
echo "Stopping phpsessionclean.timer, php7.4-fpm.service, mariadb.service, apache2.service, ufw.service"
echo "---------------------------------------------------------------------------------------------------"
systemctl stop phpsessionclean.timer php7.4-fpm.service mariadb.service apache2.service ufw.service
echo
echo
echo "---------------------------------------------------------------------------------------------------"
echo "Disable phpsessionclean.timer, php7.4-fpm.service, mariadb.service, apache2.service, ufw.service"
echo "---------------------------------------------------------------------------------------------------"
systemctl disable phpsessionclean.timer php7.4-fpm.service mariadb.service apache2.service ufw.service
echo
echo
echo "---------------------------------------------------------------------------------------------------"
echo "Disable Firewall"
echo "---------------------------------------------------------------------------------------------------"
ufw disable
echo
echo
echo "---------------------------------------------------------------------------------------------------"
echo "Firewall status"
echo "---------------------------------------------------------------------------------------------------"
ufw status
echo
echo
echo "---------------------------------------------------------------------------------------------------"
echo "Unmount /dev/sda6"
echo "---------------------------------------------------------------------------------------------------"
umount /dev/sda6
echo
echo
echo "---------------------------------------------------------------------------------------------------"
echo "Mount status of /dev/sda6"
echo "---------------------------------------------------------------------------------------------------"
findmnt /dev/sda6
echo
echo
echo "---------------------------------------------------------------------------------------------------"
echo "Run fsck /dev/sda6 after unmounting"
echo "---------------------------------------------------------------------------------------------------"
fsck /dev/sda6
echo
echo
echo "Exit"
