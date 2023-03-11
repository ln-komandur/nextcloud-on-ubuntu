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
echo "#############################################################################"
echo "This script Installs and Configures apache2 for nextcloud server installation"
echo "#############################################################################"
echo "Step: A - Installing apache2"
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
echo
apt install apache2 apache2-utils

echo
echo
echo "apache2 version is:"
echo "-------------------"
echo
apache2 -v

echo
echo
echo "Status of apache2 service is:"
echo "-----------------------------"
echo
systemctl status apache2
echo
echo
echo "Starting apache2 service:"
echo "-------------------------"
echo
systemctl start apache2

echo
echo
echo "Step: B - document root (/var/www/html/) ownership. Now with:"
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
echo
ls -l /var/www/html/

echo
echo
echo "Assigning web root (www-data) as the owner and group for document root (/var/www/html/)"
echo "---------------------------------------------------------------------------------------"
echo
chown www-data:www-data /var/www/html/ -R

echo
echo
echo "Running a configuration file syntax test. Expect to see errors such as 'Could not reliably determine the server's fully qualified domain name'."
echo "-----------------------------------------------------------------------------------------------------------------------------------------------"
echo
apache2ctl -t

echo
echo
echo "Step: C - Setting the 'ServerName' directive globally with 'ServerName localhost' in /etc/apache2/conf-available/servername.conf"
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
echo 'ServerName localhost' > /etc/apache2/conf-available/servername.conf # And added the line ServerName localhost in this file
echo "Enabling the new configuration with the 'ServerName' directive"
echo "--------------------------------------------------------------"
echo
a2enconf servername.conf

echo
echo
echo "Running a configuration file syntax test again. Errors such as 'Could not reliably determine the server's fully qualified domain name' should be GONE."
echo "------------------------------------------------------------------------------------------------------------------------------------------------------"
echo
apache2ctl -t
# The below is slightly different from https://www.linuxbabe.com/ubuntu/install-nextcloud-ubuntu-20-04-apache-lamp-stack as this nextcloud installation does NOT use TLS certificates from Let's encrypt, and instead uses self-signed certificates like described in https://docs.nextcloud.com/server/latest/admin_manual/installation/source_installation.html

echo
echo
echo "Step: D - Enabling the apache2 ssl module"
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
echo
a2enmod ssl

echo
echo
echo "Enabling the site for default-ssl"
echo "---------------------------------"
echo
a2ensite default-ssl
echo
echo

echo "Reloading apache2"
echo "-----------------"
echo
systemctl reload apache2
