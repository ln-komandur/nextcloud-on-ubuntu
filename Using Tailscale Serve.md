`grep -r "Listen" /etc/apache2/ports.conf /etc/apache2/sites-enabled/` # Check what ports Apache is trying to bind

`sudo nano /etc/apache2/ports.conf` # Remove port 443 from Apache's config. i.e. Remove or comment out Listen 443

```
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
```

`sudo a2dissite default-ssl ; sudo a2dismod ssl` # Disable any SSL virtual hosts. These are unnecessary since Tailscale is doing TLS for you

`sudo tailscale serve reset` # Stop tailscale serve if it is already running

`sudo systemctl restart apache2` # Restart Apache


**Checks if nextcloud is installed in /var/www/nextcloud or /var/www/html/nextcloud**

```
for path in /var/www/nextcloud /var/www/html/nextcloud; do
    [ -f "$path/config/config.php" ] && echo "✓ Found at $path" || echo "✗ Not at $path"
done
# Checks if nextcloud is installed in /var/www/nextcloud or /var/www/html/nextcloud
```
**For this procedure** `nextcloud.conf` and `config.php` are updated to align with the finding that nextcloud is installed in `/var/www/nextcloud`


`sudo nano /etc/apache2/sites-available/nextcloud.conf` # Update nextcloud.conf to handle port 80 on apache and 443 on tailscale

```
<VirtualHost *:80>
    # Replace these with your actual values:
    #   your-machine.tail1234.ts.net  → output of: tailscale status | head -1
    #   computername.local            → your machine's mDNS hostname
    #   192.168.1.x                   → output of: hostname -I | awk '{print $1}'

    ServerName your-machine.tail1234.ts.net
    ServerAlias computername.local 192.168.x.y localhost

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

    # Applied only to requests forwarded by Tailscale Serve (arrives from 127.0.0.1)
    # Local network access via computername.local or LAN IP is unaffected
    <If "%{REMOTE_ADDR} == '127.0.0.1'">
        RequestHeader set X-Forwarded-Proto "https"
        RequestHeader set X-Forwarded-Host "your-machine.tail1234.ts.net"
        Header always set Strict-Transport-Security "max-age=15552000; includeSubDomains"
    </If>

    ErrorLog  ${APACHE_LOG_DIR}/nextcloud_error.log
    CustomLog ${APACHE_LOG_DIR}/nextcloud_access.log combined

</VirtualHost>

```

`sudo systemctl restart apache2` # Restart Apache
`sudo nano /var/www/nextcloud/config/config.php` # Update config.php to handle tailscale serve handling TLS/SSL/port 443

**Key parts of the file are as below**
```
  'trusted_domains' => 
  array (
    0 => 'localhost',
    1 => 'computername.local',
    2 => '192.168.x.y',
    3 => 'your-machine.tail1234.ts.net',
  ),
  'overwrite.cli.url' => 'https://your-machine.tail1234.ts.net/nextcloud',
  'overwriteprotocol' => 'https',
  'overwritehost' => 'your-machine.tail1234.ts.net',
  'overwritecondaddr' => '^127\\.0\\.0\\.1$',
  'trusted_proxies' => 
  array (
    0 => '127.0.0.1',
    1 => '::1',
  ),
  'forwarded_for_headers' => 
  array (
    0 => 'HTTP_X_FORWARDED_FOR',
  ),
```

`sudo a2enmod headers rewrite` # Verify required modules are enabled
`sudo a2dismod ssl ; sudo a2dissite default-ssl`# Disable SSL module — no longer needed
`sudo a2ensite nextcloud.conf ; sudo a2dissite 000-default.conf` # Enable nextcloud site, disable the default. Apache removes the symlink from /etc/apache2/sites-enabled/ to 000-default.conf so the file is never read.

`ls -la /etc/apache2/sites-enabled/ | grep 000-default` # Should show nothing — no symlink means /etc/apache2/sites-enabled/000-default.conf is disabled

`sudo apachectl configtest` # Validate config before restarting
`sudo systemctl restart apache2` # Restart Apache
`sudo tailscale serve status` # Confirm Tailscale Serve is still running
`sudo -u www-data php /var/www/nextcloud/occ maintenance:repair` # Clear Nextcloud cache

`sudo tailscale serve --bg http://localhost:80` # Start tailscale serve - per New (1.52+) tailscale syntax

`tailscale serve status` # Verify tailscale serve is running

Should show:

```
https://your-machine.tail1234.ts.net (tailnet only)
|-- / proxy http://localhost:80
```
