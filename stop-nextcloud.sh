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

echo "This script stops nextcloud services namely PHP Session Clean timer, PHP8.3fpm, MariaDB, Apache2."
echo "It then disables UFW, reports the mount status of the NextCloud Data partition and unmounts it too."
echo "Note: tailscaled is intentionally NOT stopped — Tailscale Serve resumes automatically on next start."
echo "AUTHENTICATION SUCCESSFUL. You are executing the script as" $USER

echo
echo
echo "---------------------------------------------------------------------------------------------------"
echo "Stopping phpsessionclean.timer, php8.3-fpm.service, mariadb.service, apache2.service, ufw.service"
echo "---------------------------------------------------------------------------------------------------"
systemctl stop phpsessionclean.timer php8.3-fpm.service mariadb.service apache2.service ufw.service # Stop all Nextcloud-related services — tailscaled is intentionally excluded as it manages Tailscale independently

echo
echo
echo "---------------------------------------------------------------------------------------------------"
echo "Disable phpsessionclean.timer, php8.3-fpm.service, mariadb.service, apache2.service, ufw.service"
echo "---------------------------------------------------------------------------------------------------"
systemctl disable phpsessionclean.timer php8.3-fpm.service mariadb.service apache2.service ufw.service # Disable autostart for these services so they only run when manually started via start-nextcloud.sh

echo
echo
echo "---------------------------------------------------------------------------------------------------"
echo "Disable Firewall"
echo "---------------------------------------------------------------------------------------------------"
ufw disable # Disable UFW firewall after stopping services — re-enabled by start-nextcloud.sh on next start

echo
echo
echo "---------------------------------------------------------------------------------------------------"
echo "Firewall status"
echo "---------------------------------------------------------------------------------------------------"
ufw status # Confirm UFW is now inactive

echo
echo
echo "---------------------------------------------------------------------------------------------------"
echo "Unmount /dev/sda6"
echo "---------------------------------------------------------------------------------------------------"
umount /dev/sda6 # Safely unmount the Nextcloud data partition — safe now that all services are stopped

echo
echo
echo "---------------------------------------------------------------------------------------------------"
echo "Mount status of /dev/sda6"
echo "---------------------------------------------------------------------------------------------------"
findmnt /dev/sda6 # Confirm the partition is no longer mounted — expected to show no output

echo
echo
echo "Exit"
