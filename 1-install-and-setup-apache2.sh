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
echo
echo "AUTHENTICATION SUCCESSFUL. You are executing the script as" $USER
echo

echo "Step: A - Installing apache2"
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
echo
if ! nala install apache2 apache2-utils; then # Try nala first (faster apt frontend); fall back to apt if nala is not installed
  apt install apache2 apache2-utils
fi
echo
echo
echo "apache2 version is:"
echo "-------------------"
echo
apache2 -v # Print the installed Apache version to confirm the installation succeeded
echo
echo
echo "Status of apache2 service is:"
echo "-----------------------------"
echo
systemctl status apache2 # Check whether Apache started successfully after installation
echo
echo
echo "Starting apache2 service:"
echo "-------------------------"
echo
systemctl start apache2 # Start Apache in case it did not start automatically after install
echo
echo

echo "Step: B - document root (/var/www/html/) ownership. Now with:"
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
echo
ls -l /var/www/html/ # List current ownership of the document root before changing it
echo
echo
echo "Assigning web root (www-data) as the owner and group for document root (/var/www/html/)"
echo "---------------------------------------------------------------------------------------"
echo
chown www-data:www-data /var/www/html/ -R # Transfer ownership of the document root to the Apache web-root user
echo
echo
echo "Running a configuration file syntax test. Expect to see errors such as 'Could not reliably determine the server's fully qualified domain name'."
echo "-----------------------------------------------------------------------------------------------------------------------------------------------"
echo
apache2ctl -t # Test Apache config syntax — the FQDN warning is expected and harmless at this stage
echo
echo

echo "Step: C - Setting the 'ServerName' directive globally with 'ServerName localhost' in /etc/apache2/conf-available/servername.conf"
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
echo 'ServerName localhost' > /etc/apache2/conf-available/servername.conf # Suppress the FQDN warning by setting a global ServerName directive
echo "Enabling the new configuration with the 'ServerName' directive"
echo "--------------------------------------------------------------"
echo
a2enconf servername.conf # Activate the servername.conf so Apache reads the global ServerName
echo
echo
echo "Running a configuration file syntax test again. The FQDN warning should now be GONE."
echo "--------------------------------------------------------------------------------------"
echo
apache2ctl -t # Re-test config — the 'Could not reliably determine FQDN' error should no longer appear
echo
echo

# Tailscale Serve handles TLS on port 443 — Apache must NOT have ssl enabled.
# Enabling ssl here would conflict with Tailscale Serve and prevent Apache from starting.
echo "Step: D - Disabling the apache2 ssl module and default-ssl site"
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
echo "Tailscale Serve handles TLS/HTTPS on port 443. Apache serves plain HTTP on port 80 only."
echo "Enabling Apache ssl would conflict with Tailscale Serve and prevent Apache from starting."
echo
a2dismod ssl # Disable the Apache SSL module — not needed since Tailscale Serve handles all TLS
echo
echo
echo "Disabling the default-ssl site"
echo "------------------------------"
echo
a2dissite default-ssl # Disable the default SSL virtual host — Tailscale Serve replaces this role
echo
echo
echo "Reloading apache2"
echo "-----------------"
echo
systemctl reload apache2 # Reload Apache to apply the module and site changes without a full restart

echo "Exiting"
exit
