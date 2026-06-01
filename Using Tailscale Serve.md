# Using Tailscale Serve with Nextcloud on LAMP Stack

Tailscale Serve acts as a reverse proxy that terminates HTTPS on your tailnet and forwards plain HTTP to Apache. This allows Nextcloud to be securely accessible across all your Tailscale-connected devices without manually managing TLS certificates.

## Traffic Flow

```
Tailnet devices  →  HTTPS (port 443)  →  Tailscale Serve (TLS termination)  →  HTTP (port 80)  →  Apache  →  Nextcloud
Local network    →  HTTP  (port 80)   →  Apache  →  Nextcloud
```

Tailscale owns port 443 and handles all TLS. Apache only ever sees plain HTTP on port 80 — SSL directives (`SSLEngine`, `SSLCertificateFile`, `SSLCertificateKeyFile`) are not needed and must not be present.

---

## Prerequisites

- Ubuntu with LAMP stack and Nextcloud installed
- Tailscale installed and connected:
  ```bash
  sudo tailscale status # Verify Tailscale is installed and connected before proceeding
  ```
- **Avahi daemon** installed for `computername.local` mDNS resolution:
  ```bash
  sudo apt install avahi-daemon # Install mDNS daemon so computername.local resolves on the LAN
  sudo systemctl enable --now avahi-daemon # Enable avahi at boot and start it immediately
  ```
- **HTTPS certificates enabled** in your Tailscale admin console — required for automatic TLS provisioning on your `*.ts.net` domain:
  > Tailscale Admin Console → **DNS** → **HTTPS Certificates** → **Enable**

---

## Step 1: Check your Nextcloud installation path

```bash
for path in /var/www/nextcloud /var/www/html/nextcloud; do
    [ -f "$path/config/config.php" ] && echo "✓ Found at $path" || echo "✗ Not at $path"
done # Check both common Nextcloud install locations — the correct path is needed throughout this guide
```

> This guide assumes Nextcloud is installed at `/var/www/nextcloud`. Adjust all paths if yours differs.

---

## Step 2: Configure `/etc/apache2/ports.conf`

Apache must only listen on port 80. Port 443 belongs to Tailscale Serve — having Apache also try to bind to it prevents Apache from starting.

```bash
grep -r "Listen" /etc/apache2/ports.conf /etc/apache2/sites-enabled/ # Check what ports Apache is currently configured to bind to
sudo nano /etc/apache2/ports.conf # Edit ports config — remove Listen 443, keep only Listen 80
```

Set the file to:

```apache
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

---

## Step 3: Disable Apache SSL

```bash
sudo a2dissite default-ssl # Disable the default SSL virtual host — not needed, Tailscale handles TLS
sudo a2dismod ssl # Disable the SSL module — Apache does not serve HTTPS in this setup
```

---

## Step 4: Reset any existing Tailscale Serve config

```bash
sudo tailscale serve reset # Clear any prior Tailscale Serve configuration before setting up fresh
```

---

## Step 5: Configure `/etc/apache2/sites-available/nextcloud.conf`

```bash
sudo nano /etc/apache2/sites-available/nextcloud.conf # Create or edit the Nextcloud Apache virtual host
```

```apache
<VirtualHost *:80>
    # Replace these with your actual values:
    #   your-machine.tail1234.ts.net  → output of: tailscale status | head -1
    #   computername.local            → your machine's mDNS hostname (requires avahi-daemon)
    #   192.168.1.x                   → output of: hostname -I | awk '{print $1}'

    ServerName  your-machine.tail1234.ts.net
    ServerAlias computername.local 192.168.1.x localhost

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
        RequestHeader set X-Forwarded-Host "your-machine.tail1234.ts.net"
        Header always set Strict-Transport-Security "max-age=15552000; includeSubDomains"
    </If>

    # Strip HSTS for all non-Tailscale requests.
    # Prevents browsers from caching HTTPS enforcement for the local hostname,
    # which would cause redirect loops on plain HTTP local network access.
    <If "%{REMOTE_ADDR} != '127.0.0.1'">
        Header always unset Strict-Transport-Security
    </If>

    ErrorLog  ${APACHE_LOG_DIR}/nextcloud_error.log
    CustomLog ${APACHE_LOG_DIR}/nextcloud_access.log combined

</VirtualHost>
```

> **Why no SSL directives?** Apache serves plain HTTP only. Tailscale Serve handles HTTPS and its certificate on its own interface — Apache never sees port 443.

> **Why `DocumentRoot /var/www/html` with an `Alias`?** The `Alias /nextcloud /var/www/nextcloud` directive maps the `/nextcloud/` URL path to the Nextcloud directory. `DocumentRoot` is required by Apache for the VirtualHost to be valid, but any request to `/nextcloud/` bypasses it entirely and is handled by the `Alias`. This allows other services to coexist at other paths if needed.

---

## Step 6: Configure `/var/www/nextcloud/config/config.php`

```bash
sudo nano /var/www/nextcloud/config/config.php # Edit Nextcloud's main config to add Tailscale-aware settings
```

Add or update these settings. **Do not change** `instanceid`, `passwordsalt`, `secret`, `version`, or any database credentials.

```php
'trusted_domains' =>
array (
  0 => 'localhost',
  1 => 'your-machine.tail1234.ts.net',
  2 => 'computername.local',
  3 => '192.168.1.x',
),

'overwrite.cli.url' => 'https://your-machine.tail1234.ts.net/nextcloud',

'overwriteprotocol' => 'https',
'overwritehost'     => 'your-machine.tail1234.ts.net',
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

> **Why `overwritecondaddr`?**
> `overwriteprotocol` and `overwritehost` tell Nextcloud it is behind an HTTPS reverse proxy. Without `overwritecondaddr`, these apply to **all** requests — including plain HTTP from the local network — causing redirect loops. Setting it to `^127\.0\.0\.1$` restricts these overrides to only apply when the request arrives from `127.0.0.1`, which is exactly where Tailscale Serve proxies from.

> **Note on the regex:** In PHP single-quoted strings `\\` produces a single literal backslash, so `'^127\\.0\\.0\\.1$'` correctly becomes the regex `^127\.0\.0\.1$`.

---

## Step 7: Enable Apache modules and activate the site

```bash
sudo a2enmod headers rewrite alias # Enable required modules: headers for X-Forwarded-* and HSTS, rewrite for Nextcloud .htaccess rules, alias for the Alias /nextcloud directive
sudo a2ensite nextcloud.conf # Enable the Nextcloud virtual host configuration
sudo a2dissite 000-default.conf # Disable the default Apache site so it does not intercept requests before nextcloud.conf
sudo apachectl configtest # Validate Apache configuration syntax — must show Syntax OK before restarting
sudo systemctl restart apache2 # Apply all configuration changes
```

Verify only the Nextcloud site is active:

```bash
ls -la /etc/apache2/sites-enabled/ # Should show only nextcloud.conf — no 000-default.conf symlink
```

Verify Apache is only on port 80:

```bash
sudo ss -tlnp | grep apache2 # Should show :80 only — nothing on :443
```

---

## Step 8: Ensure Tailscale daemon starts at boot

```bash
sudo systemctl enable tailscaled # Mark tailscaled to start automatically at every boot
sudo systemctl is-enabled tailscaled # Confirm — should print: enabled
```

---

## Step 9: Start Tailscale Serve

```bash
sudo tailscale serve --bg http://localhost:80 # Start Tailscale Serve — proxies HTTPS on tailnet to Apache on port 80. --bg saves this config persistently so it resumes automatically after every reboot
```

Verify it is running:

```bash
sudo tailscale serve status # Confirm Tailscale Serve is active and showing the correct proxy configuration
```

Expected output:

```
https://your-machine.tail1234.ts.net (tailnet only)
|-- / proxy http://localhost:80
```

---

## Step 10: Clear Nextcloud cache

```bash
sudo -u www-data php /var/www/nextcloud/occ maintenance:repair # Clear Nextcloud's internal cache and repair any inconsistencies after config.php changes
```

---

## Step 11: Verify access

| Access method | URL | Protocol |
|---|---|---|
| Tailscale (any tailnet device) | `https://your-machine.tail1234.ts.net/nextcloud/` | HTTPS ✅ |
| Local network via mDNS | `http://computername.local/nextcloud/` | HTTP |
| Local network via IP | `http://192.168.1.x/nextcloud/` | HTTP |

---

## Tailscale certificate storage

Tailscale Serve manages TLS certificates internally and renews them automatically. To access the raw certificate files if needed by another service:

```bash
sudo tailscale cert your-machine.tail1234.ts.net # Generate and store the TLS certificate files on disk if needed for another service
# Stored at:
#   /var/lib/tailscale/your-machine.tail1234.ts.net.crt
#   /var/lib/tailscale/your-machine.tail1234.ts.net.key
```

You do not need to manage these files for this setup — Tailscale handles everything.

---

## Troubleshooting

### Apache fails to start — "Address already in use" on port 443

Tailscale Serve is already bound to port 443. Ensure `ports.conf` has no `Listen 443` and the SSL module is disabled:

```bash
sudo a2dismod ssl # Disable SSL module to remove the port 443 conflict with Tailscale
sudo apachectl configtest # Verify configuration is valid after the change
sudo systemctl restart apache2 # Start Apache — should now bind to port 80 only
```

### "Access through untrusted domain" error in Nextcloud

The hostname used in the browser is not in `trusted_domains` in `config.php`. Add it:

```bash
sudo nano /var/www/nextcloud/config/config.php # Add the missing hostname to the trusted_domains array
```
```
'trusted_domains' =>
array (
  // ... add the missing hostname here
),
```

### 404 Not Found when accessing `/nextcloud/`

Confirm the `alias` module is enabled and Apache was restarted after enabling it:

```bash
sudo a2enmod alias # Enable the Apache alias module required for the Alias /nextcloud directive
sudo systemctl restart apache2 # Apply the module change
```

Also confirm the Alias path in `nextcloud.conf` matches the actual Nextcloud installation path found in Step 1.

### Redirect loop (`ERR_TOO_MANY_REDIRECTS`) on `http://computername.local/nextcloud/`

Your browser has cached an HSTS policy for the local hostname from a previous Apache SSL configuration. Clear it:

**Chrome / Edge:**
1. Go to `chrome://net-internals/#hsts`
2. Under **Delete domain security policies**, enter `computername.local` and click **Delete**

**Ungoogled Chromium** (`chrome://net-internals` may be unavailable):
```bash
# Close the browser completely first, then:
rm ~/.config/chromium/Default/TransportSecurity # Delete the browser's HSTS state file — clears all cached HSTS policies
# or if ungoogled-chromium uses its own profile directory:
rm ~/.config/ungoogled-chromium/Default/TransportSecurity # Alternative path for ungoogled-chromium
```

**Firefox:**
Close the browser, then delete `SiteSecurityServiceState.txt` from your Firefox profile folder.

After clearing, `http://computername.local/nextcloud/` should load over plain HTTP without redirect loops.

### Blank page or no styling on local HTTP access

Likely cause: `overwriteprotocol` is applying to local requests and Nextcloud is generating asset URLs with `https://your-machine.tail1234.ts.net/...`. Check the browser console (F12) for failed requests and verify `overwritecondaddr` is correctly set in `config.php`.

Also check logs while loading the page:

```bash
sudo tail -f /var/log/apache2/nextcloud_error.log # Stream Apache error log — check for permission or path errors
sudo tail -f /var/www/nextcloud/data/nextcloud.log # Stream Nextcloud application log — check for PHP or config errors
```

Check what REMOTE_ADDR Apache sees for your local request:

```bash
sudo tail -f /var/log/apache2/nextcloud_access.log # Load the page in the browser and check the IP shown — should be your LAN IP, not 127.0.0.1
```

### Tailscale Serve command gives a syntax error

The Tailscale Serve CLI syntax changed in v1.52. Use the updated command:

```bash
# Old syntax (pre-1.52) — no longer works:
# sudo tailscale serve --bg https / http://localhost:80

# New syntax (v1.52+):
sudo tailscale serve --bg http://localhost:80 # Proxy HTTPS on tailnet to Apache on port 80 — --bg makes this persistent across reboots
```

### Tailscale Serve does not resume after reboot

Ensure the `--bg` flag was used when starting Serve, and that `tailscaled` is enabled at boot:

```bash
sudo systemctl enable tailscaled # Ensure Tailscale daemon starts at boot — required for Serve to resume
sudo tailscale serve --bg http://localhost:80 # Re-run with --bg if it was originally started without it — this saves the config persistently
sudo tailscale serve status # Verify Tailscale Serve is running with the correct configuration
```
