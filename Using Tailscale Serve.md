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
  sudo tailscale status
  ```
- **Avahi daemon** installed for `computername.local` mDNS resolution:
  ```bash
  sudo apt install avahi-daemon
  sudo systemctl enable --now avahi-daemon
  ```
- **HTTPS certificates enabled** in your Tailscale admin console — required for automatic TLS provisioning on your `*.ts.net` domain:
  > Tailscale Admin Console → **DNS** → **HTTPS Certificates** → **Enable**

---

## Step 1: Check your Nextcloud installation path

```bash
for path in /var/www/nextcloud /var/www/html/nextcloud; do
    [ -f "$path/config/config.php" ] && echo "✓ Found at $path" || echo "✗ Not at $path"
done
```

> This guide assumes Nextcloud is installed at `/var/www/nextcloud`. Adjust all paths if yours differs.

---

## Step 2: Configure `/etc/apache2/ports.conf`

Apache must only listen on port 80. Port 443 belongs to Tailscale Serve — having Apache also try to bind to it prevents Apache from starting.

```bash
grep -r "Listen" /etc/apache2/ports.conf /etc/apache2/sites-enabled/
sudo nano /etc/apache2/ports.conf
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
sudo a2dissite default-ssl
sudo a2dismod ssl
```

SSL is handled entirely by Tailscale. Apache does not need the `ssl` module.

---

## Step 4: Reset any existing Tailscale Serve config

```bash
sudo tailscale serve reset
```

---

## Step 5: Configure `/etc/apache2/sites-available/nextcloud.conf`

```bash
sudo nano /etc/apache2/sites-available/nextcloud.conf
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
sudo nano /var/www/nextcloud/config/config.php
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
sudo a2enmod headers rewrite alias   # alias is required for the Alias directive in nextcloud.conf
sudo a2ensite nextcloud.conf         # Enable Nextcloud site
sudo a2dissite 000-default.conf      # Disable default site (prevents it catching requests before nextcloud.conf)
sudo apachectl configtest            # Must show: Syntax OK
sudo systemctl restart apache2       # Apply all changes
```

Verify only the Nextcloud site is active:

```bash
ls -la /etc/apache2/sites-enabled/
# Should show only nextcloud.conf — no 000-default.conf symlink
```

Verify Apache is only on port 80:

```bash
sudo ss -tlnp | grep apache2
# Should show :80 only — nothing on :443
```

---

## Step 8: Ensure Tailscale daemon starts at boot

```bash
sudo systemctl enable tailscaled
sudo systemctl is-enabled tailscaled   # Should show: enabled
```

---

## Step 9: Start Tailscale Serve

```bash
sudo tailscale serve --bg http://localhost:80
```

> The `--bg` flag saves this configuration persistently in the Tailscale daemon's state. Tailscale Serve **automatically resumes after reboots** when `tailscaled` starts — no separate systemd service is needed.

Verify it is running:

```bash
sudo tailscale serve status
```

Expected output:

```
https://your-machine.tail1234.ts.net (tailnet only)
|-- / proxy http://localhost:80
```

---

## Step 10: Clear Nextcloud cache

```bash
sudo -u www-data php /var/www/nextcloud/occ maintenance:repair
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
sudo tailscale cert your-machine.tail1234.ts.net
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
sudo a2dismod ssl
sudo apachectl configtest
sudo systemctl restart apache2
```

### "Access through untrusted domain" error in Nextcloud

The hostname used in the browser is not in `trusted_domains` in `config.php`. Add it:

```php
'trusted_domains' =>
array (
  // ... add the missing hostname here
),
```

### 404 Not Found when accessing `/nextcloud/`

Confirm the `alias` module is enabled and Apache was restarted after enabling it:

```bash
sudo a2enmod alias
sudo systemctl restart apache2
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
rm ~/.config/chromium/Default/TransportSecurity
# or if ungoogled-chromium uses its own profile directory:
rm ~/.config/ungoogled-chromium/Default/TransportSecurity
```

**Firefox:**
Close the browser, then delete `SiteSecurityServiceState.txt` from your Firefox profile folder.

After clearing, `http://computername.local/nextcloud/` should load over plain HTTP without redirect loops.

### Blank page or no styling on local HTTP access

Likely cause: `overwriteprotocol` is applying to local requests and Nextcloud is generating asset URLs with `https://your-machine.tail1234.ts.net/...`. Check the browser console (F12) for failed requests and verify `overwritecondaddr` is correctly set in `config.php`.

Also check logs while loading the page:

```bash
sudo tail -f /var/log/apache2/nextcloud_error.log
sudo tail -f /var/www/nextcloud/data/nextcloud.log
```

Check what REMOTE_ADDR Apache sees for your local request:

```bash
sudo tail -f /var/log/apache2/nextcloud_access.log
# Load the page in the browser and check the IP shown — should be your LAN IP, not 127.0.0.1
```

### Tailscale Serve command gives a syntax error

The Tailscale Serve CLI syntax changed in v1.52. Use the updated command:

```bash
# Old syntax (pre-1.52) — no longer works:
# sudo tailscale serve --bg https / http://localhost:80

# New syntax (v1.52+):
sudo tailscale serve --bg http://localhost:80
```

### Tailscale Serve does not resume after reboot

Ensure the `--bg` flag was used when starting Serve, and that `tailscaled` is enabled at boot:

```bash
sudo systemctl enable tailscaled
sudo tailscale serve --bg http://localhost:80   # re-run with --bg if it was started without it
sudo tailscale serve status
```
