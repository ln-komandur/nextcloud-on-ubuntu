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

echo "This script configures Apache on a nextcloud server installation to redirect to https, and to use alias wherever supported by avahi.service"
echo "###########################################################################################################################################"
echo
echo "AUTHENTICATION SUCCESSFUL. You are executing the script as" $USER
echo
echo "The Hostname of this server is : " $HOSTNAME

#http://moo.nac.uci.edu/~hjm/biolinux/Linux_Tutorial_12.html gives "ifconfig | grep -A1 "wlan\|wlp"| grep inet | cut -f2 -d: | cut -f1 -d' ' "

wlan_ip4address=`ip a | grep -A1 "wlan\|wlp"| grep inet | cut -f6 -d' ' | cut -f1 -d/`

echo "The wireless IP4 address of this server is : " $wlan_ip4address

conf_file_path="/etc/apache2/sites-available/nextcloud.conf"

#conf_file_path="file.txt" # This is for testing purposes only

echo
echo
echo "Step A :Creating the "$conf_file_path" configuration file"
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"

echo '<VirtualHost *:80>
   ServerName '$wlan_ip4address'
   ServerAlias '$HOSTNAME'.local
   # Redirects any request to http://'$wlan_ip4address'/nextcloud or http://'$HOSTNAME'.local/nextcloud to https
   Redirect permanent /nextcloud https://'$HOSTNAME'.local/nextcloud
</VirtualHost>
<VirtualHost *:443>
    ServerName '$wlan_ip4address'
    ServerAlias '$HOSTNAME'.local
    Alias /nextcloud "/var/www/nextcloud/"
    ErrorLog ${APACHE_LOG_DIR}/nextcloud.error
    CustomLog ${APACHE_LOG_DIR}/nextcloud.access combined
        SSLEngine on
        # Apache installs with a pair of default encryption certificates: /etc/ssl/certs/ssl-cert-snakeoil.pem and /etc/ssl/private/ssl-cert-snakeoil.key. Refer https://www.linux.com/training-tutorials/apache-ubuntu-linux-beginners-part-2/
        SSLCertificateFile /etc/ssl/certs/ssl-cert-snakeoil.pem
        SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key    
    <Directory /var/www/html/nextcloud/>
        Require all granted
        Options FollowSymlinks MultiViews
        AllowOverride All
            <IfModule mod_dav.c>
                Dav off
            </IfModule>     
        SetEnv HOME /var/www/nextcloud
        SetEnv HTTP_HOME /var/www/nextcloud
        Satisfy Any
    </Directory>
    <IfModule mod_headers.c>
      Header always set Strict-Transport-Security "max-age=15552000; includeSubDomains"
    </IfModule>
</VirtualHost>' > $conf_file_path

echo
echo
echo "Running a configuration file syntax test"
apache2ctl -t # Run a configuration file syntax test

echo
echo
echo "Step B : Enabling the site with the new configuration"
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
a2ensite nextcloud.conf # Enable the site

echo
echo
echo "Enabling the apache2 modules"
a2enmod rewrite headers env dir mime setenvif ssl # Enable the apache2 modules

echo
echo
echo "Step C : Restarting apache2"
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^"
systemctl restart apache2 # Restart apache2

exit
