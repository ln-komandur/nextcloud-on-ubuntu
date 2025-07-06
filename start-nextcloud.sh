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
echo "This script reports the mount status of the NextCloud Data partition and mounts it too. It then"
echo "enables UFW and starts nextcloud services namely PHP Session Clean timer, PHP8.3fpm, MariaDB, Apache2."
echo "AUTHENTICATION SUCCESSFUL. You are executing the script as" $USER
echo
echo
echo "---------------------------------------------------------------------------------------------------"
echo "Mount status of /dev/sda6"
echo "---------------------------------------------------------------------------------------------------"
findmnt /dev/sda6
#echo
#echo
#echo "---------------------------------------------------------------------------------------------------"
#echo "Unmount /dev/sda6 if it is already mounted for any other reasons whatsoever"
#echo "---------------------------------------------------------------------------------------------------"
#umount /dev/sda6
#echo
#echo
#echo "---------------------------------------------------------------------------------------------------"
#echo "Run fsck /dev/sda6 prior to mounting again"
#echo "---------------------------------------------------------------------------------------------------"
#fsck -f -r /dev/sda6
echo
echo
echo "---------------------------------------------------------------------------------------------------"
echo "Mounting /dev/sda6"
echo "---------------------------------------------------------------------------------------------------"
mount /dev/sda6
echo
echo
echo "---------------------------------------------------------------------------------------------------"
echo "Enable Firewall"
echo "---------------------------------------------------------------------------------------------------"
ufw enable
echo
echo
echo "---------------------------------------------------------------------------------------------------"
echo "Firewall status"
echo "---------------------------------------------------------------------------------------------------"
ufw status
#echo
#echo
#echo "---------------------------------------------------------------------------------------------------"
#echo "Status of ufw.service, phpsessionclean.timer, php8.3-fpm.service, mariadb.service, apache2.service"
#echo "---------------------------------------------------------------------------------------------------"
#systemctl status ufw.service, phpsessionclean.timer php8.3-fpm.service mariadb.service apache2.service
echo
echo
echo "---------------------------------------------------------------------------------------------------"
echo "Starting ufw.service apache2.service mariadb.service php8.3-fpm.service phpsessionclean.timer"
echo "---------------------------------------------------------------------------------------------------"
systemctl start ufw.service apache2.service mariadb.service php8.3-fpm.service phpsessionclean.timer   

echo
echo
echo "Exit"
