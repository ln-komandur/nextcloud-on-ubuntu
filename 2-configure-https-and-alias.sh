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

echo "This script configures Apache on a nextcloud server installation for use with Tailscale Serve."
echo "Apache will serve plain HTTP on port 80 only. Tailscale Serve handles HTTPS/TLS on port 443."
echo "################################################################################################"
echo
echo "AUTHENTICATION SUCCESSFUL. You are executing the script as" $USER
echo
echo "The Hostname of this server is : " $HOSTNAME

#http://moo.nac.uci.edu/~hjm/biolinux/Linux_Tutorial_12.html
wlan_ip4address=`ip a | grep -A1 "wlan\|wlp"| grep inet | cut -f6 -d' ' | cut -f1 -d/` # Detect the wireless LAN IP address to use in Apache ServerAlias and nextcloud.conf
echo "The wireless IP4 address of this server is : " $wlan_ip4address

conf_file_path="/etc/apache2/sites-available/nextcloud.conf"

echo
echo
echo "Step A : Updating /etc/apache2/ports.conf to listen on port 80 only"
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
echo "Port 443 is owned by Tailscale Serve — Apache must not bind to it."
echo

cat > /etc/apache2/ports.conf << 'PORTS_EOF'
# If you just change the port or add more ports here, you will likely also
# have to change the VirtualHost statement in
# /etc/apache2/sites-enabled/000-default.conf

# Apache listens on port 80 only.
# Port 443 (HTTPS) is handled by Tailscale Serve, not Apache.
# Tailscale terminates TLS and forwards plain HTTP to Apache on port 80.

Listen 80

# Port 443 intentionally disabled — Tailscale Serve owns it.
# Re-enabling this would conflict with Tailscale and prevent Apache from starting.
#
# <IfModule ssl_module>
#     Listen 443
# </IfModule>
#
# <IfModule mod_gnutls.c>
#     Listen 443
# </IfModule>

# vim: syntax=apache ts=4 sw=4 sts=4 sr noet
PORTS_EOF
# Write the ports.conf file restricting Apache to port 80 only

echo
echo
echo "Step B : Creating the "$conf_file_path" configuration file"
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
echo "Single VirtualHost on port 80. Tailscale Serve handles port 443."
echo

cat > $conf_file_path << CONFEOF
<VirtualHost *:80>
    # Replace these with your actual values:
    #   Tailscale hostname  → output of: tailscale status | head -1
    #   computername.local  → your machine's mDNS hostname (requires avahi-daemon)
    #   LAN IP address      → output of: hostname -I | awk '{print \$1}'

    ServerName  ${HOSTNAME}.tail1234.ts.net
    ServerAlias ${HOSTNAME}.local ${wlan_ip4address} localhost

    DocumentRoot /var/www/html

    Alias /nextcloud /var/www/nextcloud

    <Directory /var/www/nextcloud>
        Options +FollowSymlinks
        AllowOverride All
        Require all granted

        <IfModule mod_dav.c>
            Dav off
        </IfModule>

        SetEnv HOME /var/www/nextcloud
        SetEnv HTTP_HOME /var/www/nextcloud
    </Directory>

    # Applied only to requests forwarded by Tailscale Serve (arrives from 127.0.0.1).
    # Local network access via computername.local or LAN IP is unaffected.
    <If "%{REMOTE_ADDR} == '127.0.0.1'">
        RequestHeader set X-Forwarded-Proto "https"
        RequestHeader set X-Forwarded-Host "${HOSTNAME}.tail1234.ts.net"
        Header always set Strict-Transport-Security "max-age=15552000; includeSubDomains"
    </If>

    # Strip HSTS for all non-Tailscale requests.
    # Prevents browsers from caching HTTPS enforcement for the local hostname,
    # which would cause redirect loops on plain HTTP local network access.
    <If "%{REMOTE_ADDR} != '127.0.0.1'">
        Header always unset Strict-Transport-Security
    </If>

    ErrorLog  \${APACHE_LOG_DIR}/nextcloud_error.log
    CustomLog \${APACHE_LOG_DIR}/nextcloud_access.log combined

</VirtualHost>
CONFEOF
# Write the Nextcloud virtual host config — single port 80 block, no SSL directives

echo
echo "IMPORTANT: Edit $conf_file_path and replace the Tailscale hostname placeholder"
echo "(${HOSTNAME}.tail1234.ts.net) with your actual Tailscale hostname."
echo "Run: tailscale status | head -1    to find your actual hostname."
echo
echo

echo "Step C : Disabling ssl module — Tailscale handles TLS, not Apache"
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
a2dismod ssl # Disable the Apache SSL module — not needed since Tailscale Serve terminates all TLS
a2dissite default-ssl # Disable the default SSL virtual host — Tailscale Serve replaces this role
echo
echo

echo "Step D : Enabling required Apache modules"
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
a2enmod rewrite headers alias env dir mime setenvif
# rewrite  — required for Nextcloud .htaccess URL rewriting rules
# headers  — required for RequestHeader (X-Forwarded-Proto) and Header (HSTS/unset) directives
# alias    — required for the Alias /nextcloud directive
# env dir mime setenvif — required by Nextcloud for correct MIME handling and environment variables
echo
echo

echo "Step E : Enabling the nextcloud site and disabling the default site"
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
a2ensite nextcloud.conf # Activate the Nextcloud virtual host by creating a symlink in sites-enabled
a2dissite 000-default.conf # Deactivate the default Apache site so it does not intercept requests before nextcloud.conf
echo
echo

echo "Step F : Validating config and restarting apache2"
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
apache2ctl -t # Validate Apache configuration syntax — must show Syntax OK before restarting
echo
systemctl restart apache2 # Apply all configuration changes — Apache will now serve on port 80 only

echo
echo "Done. Next steps:"
echo "  1. Edit $conf_file_path and set the correct Tailscale hostname"
echo "  2. Update /var/www/nextcloud/config/config.php — see Using Tailscale Serve.md"
echo "  3. sudo tailscale serve --bg http://localhost:80   # Start Tailscale Serve"
echo "  4. sudo tailscale serve status                     # Verify Tailscale Serve is running"
echo
echo "Exiting"
exit
