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
findmnt /dev/sda6 # Show current mount status of the Nextcloud data partition before attempting to mount

echo
echo
echo "---------------------------------------------------------------------------------------------------"
echo "Mounting /dev/sda6"
echo "---------------------------------------------------------------------------------------------------"
mount /dev/sda6 # Mount the dedicated Nextcloud data partition — uses the options defined in /etc/fstab

echo
echo
echo "---------------------------------------------------------------------------------------------------"
echo "Enable Firewall"
echo "---------------------------------------------------------------------------------------------------"
ufw enable # Re-enable UFW firewall before starting services to ensure traffic is filtered from the start

echo
echo
echo "---------------------------------------------------------------------------------------------------"
echo "Firewall status"
echo "---------------------------------------------------------------------------------------------------"
ufw status # Confirm UFW is active and show current rules

echo
echo
echo "---------------------------------------------------------------------------------------------------"
echo "Starting ufw.service apache2.service mariadb.service php8.3-fpm.service phpsessionclean.timer"
echo "---------------------------------------------------------------------------------------------------"
systemctl start ufw.service apache2.service mariadb.service php8.3-fpm.service phpsessionclean.timer # Start all Nextcloud-related services in one command

echo
echo
echo "---------------------------------------------------------------------------------------------------"
echo "Ensuring tailscaled is running (required for Tailscale Serve)"
echo "---------------------------------------------------------------------------------------------------"
systemctl start tailscaled.service # Start tailscaled if not already running — Tailscale Serve requires it to proxy HTTPS to Apache
echo "tailscaled status:"
systemctl is-active tailscaled.service # Confirm tailscaled is active — should print: active

echo
echo
echo "---------------------------------------------------------------------------------------------------"
echo "Checking Tailscale Serve status"
echo "(Tailscale Serve resumes automatically when tailscaled starts — no manual action needed)"
echo "---------------------------------------------------------------------------------------------------"
tailscale serve status # Verify Tailscale Serve is running and proxying HTTPS to localhost:80

echo
echo
echo "Exit"
