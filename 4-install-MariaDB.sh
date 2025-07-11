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
echo "This script installs mariadb for nextcloud server installation"
echo "##############################################################"
echo

echo
echo
echo "Install software-properties-common. This may have already been installed"
echo "########################################################################"
echo
nala install software-properties-common #May have already been installed

echo
echo
echo "Fetch signing keys for mariadbb release"
echo "########################################################################"
echo
apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'

echo
echo
echo "Add the repo for mariadb 10.11"
echo "##############################################################"
echo
add-apt-repository 'deb [arch=amd64] http://mirror.mariadb.org/repo/10.11/ubuntu/ jammy main'

echo
echo
echo "Update repos"
echo "##############################################################"
echo
apt update #Update repos

echo
echo
echo "Install mariadb server and client"
echo "##############################################################"
echo
nala install mariadb-server mariadb-client # Install mariadb server and client

echo
echo
echo "Check the version of mariadb installed now"
echo "##########################################################################"
echo
mariadb --version # Verify if the version intended is installed 

echo
echo
echo "Check the version of mysql installed now"
echo "##########################################################################"
echo
mysql --version # Verify if the version intended is installed

echo
echo
echo "Start mariadb to configure it"
echo "##########################################################################"
echo
systemctl status mariadb # Start MariaDB to configure it

exit
