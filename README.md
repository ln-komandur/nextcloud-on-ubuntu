# ***Manually*** install nextcloud server on Ubuntu 22.04

---

## Useful references - Courtesy credits and Gratitude

1. [How to Install LAMP Stack on Ubuntu 20.04 Server/Desktop](https://www.linuxbabe.com/ubuntu/install-lamp-stack-ubuntu-20-04-server-desktop)
2. [Install NextCloud on Ubuntu 20.04 with Apache (LAMP Stack)](https://www.linuxbabe.com/ubuntu/install-nextcloud-ubuntu-20-04-apache-lamp-stack)
3. [How to install Nextcloud 20 on Ubuntu Server 20.04](https://www.techrepublic.com/article/how-to-install-nextcloud-20-on-ubuntu-server-20-04/)
4. [Installation on Linux — Nextcloud latest Administration Manual latest documentation](https://docs.nextcloud.com/server/latest/admin_manual/installation/source_installation.html)
5. [How To Install MariaDB 10.5 on Ubuntu 20.04 (Focal Fossa)](https://computingforgeeks.com/how-to-install-mariadb-on-ubuntu-focal-fossa/)
6. Apache on Ubuntu Linux For Beginners [Part 1](https://www.linux.com/audience/devops/apache-ubuntu-linux-beginners/) and [Part 2](https://www.linux.com/training-tutorials/apache-ubuntu-linux-beginners-part-2/)
7. [systemd.service and its options](https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html)

**Note:** Though almost all references use Ubuntu 20.04, the procedure has worked **perfectly well on Ubuntu 22.04**, Lubuntu 20.04 and Raspbian buster as detailed in earlier versions of this write-up.

---

## What's different about this installation?

1. Files are stored locally on a **separate and dedicated disk partition** on the machine where the nextcloud server is running
2. There are 2 different approaches described here
   1. A completely **intranet only** installation that uses
      1. No SSL on Apache — plain HTTP on port 80 only
      2. **No DNS lookups**. However **mDNS lookups** from avahi.service are leveraged for clients within the intranet
   2. *Additional steps* that combine **Tailscale Serve** to [expose the nextcloud server outside your LAN](#exposing-the-nextcloud-server-outside-the-lan-with-tailscale-serve) that uses
      1. **TLS certificates automatically provisioned and renewed by Tailscale Serve** — no manual certificate management needed
      2. A DNS name from Tailscale VPN with the **device name** and **tailnet name**

This write up is based on the actual `history` of commands executed by following a blend of the above references. 192.168.254.56 is the example ip address.

---

## Why install manually?

[Why not install via snap?](https://github.com/ln-komandur/linux-utils/blob/master/why-not-snapd.md)

---

## Software and Versions used in this installation

### On Ubuntu 22.04.5 LTS

1. Linux kernel 6.8.0-60-generic (64 bit) - ***the latest as of June 2025***
2. [nextcloud-31.0.6 server](https://nextcloud.com/changelog/) - ***the latest as of June 2025***
3. mariadb Ver 15.1 Distrib 10.11.13-MariaDB, for debian-linux-gnu (x86_64) using EditLine wrapper - ***mariadb 10.11 is LTS, maintained until Feb 2028***
4. OpenJDK version "19.0.2" 2023-01-17, JRE build 19.0.2+7-Ubuntu-0ubuntu322.04
5. apache2 Server version: Apache/2.4.52 (Ubuntu), Server built: 2025-04-03T09:05:48 - ***from Ubuntu 22.04 defaults***
6. PHP 8.3.22 (cli) (built: Jun 9 2025 14:03:11) (NTS) - ***[php8.3 is recommended for Nextcloud 30 per the system requirements](https://docs.nextcloud.com/server/30/admin_manual/installation/system_requirements.html). php8.1 is available from Ubuntu 22.04 defaults and should be [upgraded to php8.3](https://github.com/ln-komandur/nextcloud-on-ubuntu/blob/main/upgrade%20to%20php8.3.md)***

---

## Install the LAMP stack

Refer [How to Install LAMP Stack on Ubuntu 20.04 Server/Desktop](https://www.linuxbabe.com/ubuntu/install-lamp-stack-ubuntu-20-04-server-desktop)

### Install Apache and do basic set-up

`sudo apt update && sudo apt-get update && sudo apt upgrade && sudo apt-get upgrade` # *Update and upgrade all apt package repos and installed packages before starting*

**Run [1-install-and-setup-apache2.sh](https://github.com/ln-komandur/nextcloud-on-ubuntu/blob/main/1-install-and-setup-apache2.sh)**. It will prompt and authenticate for `sudo` privilege

### Configure Apache to use alias wherever supported by avahi.service

Providing `ServerAlias computername.local` helps to use the server url as *http://computername.local/nextcloud* from Linux laptops and iOS devices on the intranet if *avahi-daemon.service* is running on the server. Since Android devices do not support mDNS (Refer [...local hostname doesn't work on Android phones](https://raspberrypi.stackexchange.com/questions/91154/raspberry-pis-local-hostname-doesnt-work-on-android-phones)), the `ServerName` has to remain as the IP address to make it accessible from those devices.

**Run [2-configure-https-and-alias.sh](https://github.com/ln-komandur/nextcloud-on-ubuntu/blob/main/2-configure-https-and-alias.sh)**. It will prompt and authenticate for `sudo` privilege

The script configures Apache to serve Nextcloud on **port 80 only** (plain HTTP for the local network). HTTPS is handled by Tailscale Serve, not Apache. See [Using Tailscale Serve.md](https://github.com/ln-komandur/nextcloud-on-ubuntu/blob/main/Using%20Tailscale%20Serve.md) for the full Tailscale setup guide.

**Note:** Despite these configurations, there may be some errors until the installation is ***fully complete***.

### Configure Uncomplicated Firewall (UFW)

**Run [3-configure-ufw.sh](https://github.com/ln-komandur/nextcloud-on-ubuntu/blob/main/3-configure-ufw.sh)**. It will prompt and authenticate for `sudo` privilege

---

## Install MariaDB

Refer [How To Install MariaDB 10.5 on Ubuntu 20.04 (Focal Fossa)](https://computingforgeeks.com/how-to-install-mariadb-on-ubuntu-focal-fossa/) or [How to Install LAMP Stack on Ubuntu 20.04 Server/Desktop](https://www.linuxbabe.com/ubuntu/install-lamp-stack-ubuntu-20-04-server-desktop) for screenshots

**Run [4-install-MariaDB.sh](https://github.com/ln-komandur/nextcloud-on-ubuntu/blob/main/4-install-MariaDB.sh)** to install and start mariadb for configuring it. It will prompt and authenticate for `sudo` privilege

### Configure Mariadb

`sudo mysql_secure_installation` # *Set up root password, remove anonymous users, disallow remote login, remove test database, reload privilege tables*

`sudo mariadb -u root` # *Test that the root login works using the unix socket (no password prompt)*

or

`mysql -u root -p` # *Alternative test — will prompt for the mariadb root password you just set. Type exit at the `MariaDB [(none)]>` prompt*

### Create nextcloud user account (database, username and password) on mysql DB

Refer [Install NextCloud on Ubuntu 20.04 with Apache (LAMP Stack)](https://www.linuxbabe.com/ubuntu/install-nextcloud-ubuntu-20-04-apache-lamp-stack) for screenshots

`sudo mysql` # *Open a MariaDB root session to create the Nextcloud database, user, and password*

**Use *YOUR* custom values below**

```sql
MariaDB [(none)]> create database NameForNextCloudDatabase; -- Create the dedicated Nextcloud database
MariaDB [(none)]> create user YOURNextCloudUser@localhost identified by 'your-password'; -- Create the Nextcloud DB user
MariaDB [(none)]> grant all privileges on NameForNextCloudDatabase.* to YOURNextCloudUser@localhost identified by 'your-password'; -- Grant full access to the Nextcloud database
MariaDB [(none)]> flush privileges; -- Apply the privilege changes immediately
MariaDB [(none)]> exit;
```

---

## Prepare the dedicated partition to save nextcloud server's data (user) files

1. Create a separate partition of desired size and format it as `ext4` using GParted / KDE Partition Manager
   1. Strongly consider [creating a LUKS encrypted partition](https://github.com/ln-komandur/linux-utils/blob/luks/ReadMe.md) and mounting it at `/media/nextcloud-data`
2. Follow the steps in [Create common mount points for partitions shared by all users and include them in fstab](https://github.com/ln-komandur/linux-utils/blob/master/common-mountpoints.md)
3. `sudo chown www-data:www-data /media/nextcloud-data/ -R` # *Assign ownership of the Nextcloud data partition to the Apache web-root user*
   1. `ls -l /media/nextcloud-data/` # *Verify the setgid bit is not set — other users do not need to share this partition with www-data*
   2. `sudo chmod -R g-s /media/nextcloud-data/` # *[Unset the setgid bit](https://linuxconfig.org/how-to-use-special-permissions-the-setuid-setgid-and-sticky-bits) to prevent group inheritance*

---

## Install and Enable PHP Modules

Refer Step 4: Install and Enable PHP Modules in [Install NextCloud on Ubuntu 20.04 with Apache (LAMP Stack)](https://www.linuxbabe.com/ubuntu/install-nextcloud-ubuntu-20-04-apache-lamp-stack)

For Nextcloud 30 or above, **Run [5-install-php8_3.sh](https://github.com/ln-komandur/nextcloud-on-ubuntu/blob/main/5-install-php8_3.sh)**. It will prompt and authenticate for `sudo` privilege. Or [upgrade to php8.3](https://github.com/ln-komandur/nextcloud-on-ubuntu/blob/main/upgrade%20to%20php8.3.md) as it is recommended per the [System requirements](https://docs.nextcloud.com/server/30/admin_manual/installation/system_requirements.html)

`sudo service apache2 restart` # *Restart Apache so it picks up the newly installed PHP modules*

Also try `sudo service apache2 reload` # *Reload Apache config without dropping connections — use if restart seems heavy*

### Configuring PHP8.x

Refer [Uploading big files > 512MB — Nextcloud latest Administration Manual](https://docs.nextcloud.com/server/stable/admin_manual/configuration_files/big_file_upload_configuration.html?highlight=big%20files#configuring-php)

**Run [6-Configure-php-settings.sh](https://github.com/ln-komandur/nextcloud-on-ubuntu/blob/main/6-Configure-php-settings.sh)** (it will prompt and authenticate for `sudo` privilege) to

1. Increase PHP Memory Limit to 512M in `/etc/php/8.x/fpm/php.ini` and `/etc/php/8.x/apache2/php.ini` ***if it is 128M***
2. Increase Upload File Size Limit to 2G in the same files ***if it is 2M***
3. Disable output_buffering in both files ***if it is enabled***
4. Restart Apache
5. Create a test file (`/var/www/html/info.php`) to review PHP configuration in a browser
6. Delete the test file after review

`sudo systemctl restart apache2` # *Restart Apache to apply the PHP ini changes*

Login as admin and check PHP under Administration Settings for:

- Version: 8.x.y
- Memory limit: 512 MB
- Upload max size: 2 GB

---

## Install nextcloud server - Part 1: terminal (command line) activities

The following is based on [Install NextCloud on Ubuntu 20.04 with Apache (LAMP Stack)](https://www.linuxbabe.com/ubuntu/install-nextcloud-ubuntu-20-04-apache-lamp-stack)

[Download the latest compatible version from nextcloud changelog](https://nextcloud.com/changelog/)

`sha256sum ./Downloads/nextcloud-*.zip` # *Verify the downloaded file's integrity against the [sha256 checksum](https://nextcloud.com/changelog/) before installing*

`sudo unzip ./Downloads/nextcloud-*.zip  -d /var/www/` # *Extract Nextcloud into the web directory*

`sudo chown www-data:www-data /var/www/nextcloud/ -R` # *Transfer ownership of all Nextcloud files to the Apache web-root user*

`sudo systemctl reload apache2` # *Reload Apache before completing the installation in the browser*

---

## Install the nextcloud server - Part 2: Complete the installation in a Browser

...by accessing http://192.168.254.56/nextcloud/ (or http://computername.local/nextcloud/)

1. Create an admin user account for the nextcloud server
2. Give the path to the data folder as `/media/nextcloud-data/` along with MariaDB credentials. **Note:** The browser may show errors because `config.php` is created only in this step and does not yet list all hostnames as `trusted_domains`
3. **Fix:** Open `config.php` and add all hostnames:

```bash
sudo nano /var/www/nextcloud/config/config.php # Add trusted_domains and overwrite.cli.url for all hostnames used to access Nextcloud
```

```php
'trusted_domains' =>
array (
  0 => 'localhost',
  1 => 'computername.local',
  2 => '192.168.254.56',
),

'overwrite.cli.url' => 'http://computername.local/nextcloud', # Base URL used by CLI tools and cron jobs
```

4. `sudo systemctl restart apache2` # *Restart Apache to apply the config.php changes*

### The nextcloud installation is now complete

### Post installation upgrades

Log in as admin and upgrade Nextcloud from "Settings → Administration → Overview" if prompted

---

## Appendix

### Exposing the nextcloud server outside the LAN with Tailscale Serve

---

Tailscale Serve acts as a reverse proxy that terminates HTTPS on your tailnet and forwards plain HTTP to Apache on port 80. TLS certificates are automatically provisioned and renewed by Tailscale — no manual certificate management is needed.

For the full step-by-step guide, refer to **[Using Tailscale Serve.md](https://github.com/ln-komandur/nextcloud-on-ubuntu/blob/main/Using%20Tailscale%20Serve.md)**.

**Summary of steps:**

1. Create a Tailscale account and add devices to it
2. Take a fun name for the `<tailnet_name>`
3. Connect the device that hosts the nextcloud server to the tailnet and optionally rename it
4. Enable HTTPS certificates in the Tailscale admin console:
   > **Tailscale Admin Console → DNS → HTTPS Certificates → Enable**
5. `sudo systemctl enable tailscaled` # *Ensure Tailscale daemon starts automatically at every boot*
6. Start Tailscale Serve (syntax changed in v1.52+):

```bash
sudo tailscale serve --bg http://localhost:80 # Proxy HTTPS on tailnet to Apache on port 80. --bg saves this config persistently — Tailscale Serve resumes automatically after every reboot with no manual intervention needed
```

Verify it is running:

```bash
sudo tailscale serve status # Confirm Tailscale Serve is active and forwarding to localhost:80
# Expected output:
# https://your-machine.tail1234.ts.net (tailnet only)
# |-- / proxy http://localhost:80
```

#### `nextcloud.conf` for Tailscale Serve

```apache
<VirtualHost *:80>
    ServerName  your-machine.tail1234.ts.net
    ServerAlias computername.local 192.168.254.56 localhost

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

    # Strip HSTS for local network requests to prevent browsers caching
    # HTTPS enforcement for the local hostname
    <If "%{REMOTE_ADDR} != '127.0.0.1'">
        Header always unset Strict-Transport-Security
    </If>

    ErrorLog  ${APACHE_LOG_DIR}/nextcloud_error.log
    CustomLog ${APACHE_LOG_DIR}/nextcloud_access.log combined

</VirtualHost>
```

#### `config.php` key settings for Tailscale Serve

```php
'trusted_domains' =>
array (
  0 => 'localhost',
  1 => 'your-machine.tail1234.ts.net',
  2 => 'computername.local',
  3 => '192.168.254.56',
),

'overwrite.cli.url' => 'https://your-machine.tail1234.ts.net/nextcloud', # Base URL for CLI and cron — must use HTTPS and Tailscale hostname

'overwriteprotocol' => 'https',   # Tell Nextcloud that Tailscale Serve is delivering requests over HTTPS
'overwritehost'     => 'your-machine.tail1234.ts.net', # Tell Nextcloud the public hostname used by Tailscale Serve
'overwritecondaddr' => '^127\\.0\\.0\\.1$', # Only apply the above overrides when request comes from 127.0.0.1 (Tailscale Serve) — prevents redirect loops on local HTTP access

'trusted_proxies' =>
array (
  0 => '127.0.0.1', # Trust Tailscale Serve's proxy address so Nextcloud reads X-Forwarded-* headers from it
  1 => '::1',
),
'forwarded_for_headers' =>
array (
  0 => 'HTTP_X_FORWARDED_FOR', # Read the real client IP from the header set by Tailscale Serve
),
```

#### Tailscale certificate storage

```bash
sudo tailscale cert your-machine.tail1234.ts.net # Explicitly generate certificate files on disk if needed by another service
# Stored at:
#   /var/lib/tailscale/your-machine.tail1234.ts.net.crt
#   /var/lib/tailscale/your-machine.tail1234.ts.net.key
# Note: Tailscale Serve manages and renews these automatically — you do not need to run this for normal Nextcloud use
```

#### iOS NextCloud Client App permissions

Ensure that the iOS NextCloud Client App has permissions to use cellular data.

---

### Unable to access nextcloud server after its IP address changed

---

The nextcloud server's IP address could change for several reasons including, but not limited to:

1. It is not static or bound to the MAC address
2. Connecting to a different network or new router
3. Change in DHCP range of the existing router
4. Connecting through a different network card
5. SSD / HDD moved to a different PC

Imagine the IP changed from `192.168.254.56` to `192.168.0.27`. An "Access through untrusted domain" page will likely appear.

1. Log onto the nextcloud server box physically or remotely
2. Update `config.php` with the new IP:

```bash
sudo nano /var/www/nextcloud/config/config.php # Update trusted_domains with the new IP address
```

```php
'trusted_domains' =>
array (
  0 => 'localhost',
  1 => 'your-machine.tail1234.ts.net',
  2 => 'computername.local',
  3 => '192.168.0.27',   // ← updated from old IP
),
```

3. `sudo nano /etc/apache2/sites-available/nextcloud.conf` # *Update the ServerAlias line with the new IP address*
4. `sudo systemctl restart apache2` # *Restart Apache to apply the hostname changes*
5. If still not resolved, update UFW rules for the new subnet:
   1. `sudo ufw allow from 192.168.0.0/24 to any port 22 proto tcp` # *Allow SSH from new subnet*
   2. `sudo ufw allow from 192.168.0.0/24 to any port 80 proto tcp` # *Allow HTTP from new subnet*
   3. `sudo ufw allow from 192.168.0.0/24 to any port 443 proto tcp` # *Allow HTTPS from new subnet (used by Tailscale)*
   4. `sudo ufw allow in from 192.168.0.1 to 224.0.0.0/24` # *Allow mDNS multicast from the new router*
6. `sudo ufw status numbered` # *List all rules with numbers so old rules can be identified and removed*
7. `sudo ufw delete #` # *Delete old subnet rules by number — replace # with the rule number from step 6*

---

### Manually stop and start nextcloud server

Use this method to avoid autostarts on older hardware to speed up boot-up

1. `sudo systemctl disable phpsessionclean.timer php8.3-fpm.service mariadb.service apache2.service` # *Disable these services from autostarting so they can be manually controlled via scripts*
2. In `/etc/fstab` make sure to have **`noauto`** in the line for the nextcloud data partition so it is mounted manually
3. Download [start-nextcloud.sh](https://github.com/ln-komandur/nextcloud-on-ubuntu/blob/main/start-nextcloud.sh) and [stop-nextcloud.sh](https://github.com/ln-komandur/nextcloud-on-ubuntu/blob/main/stop-nextcloud.sh) to super user's home directory
4. `chmod +x start-nextcloud.sh stop-nextcloud.sh` # *Give execute permissions to both scripts*
5. `sudo ./start-nextcloud.sh` # *Start all Nextcloud services and mount the data partition manually*
6. `sudo ./stop-nextcloud.sh` # *Stop all Nextcloud services and safely unmount the data partition*

> **Note:** `tailscaled.service` is intentionally NOT stopped by `stop-nextcloud.sh` — Tailscale connectivity should remain active independently of Nextcloud services. Tailscale Serve resumes automatically when `tailscaled` is running.

### Automatically start nextcloud server

Use this method to avoid the need for any user to login

1. `sudo systemctl enable ufw.service apache2.service mariadb.service php8.3-fpm.service phpsessionclean.timer tailscaled.service` # *Enable all required services to start automatically at boot — including tailscaled so Tailscale Serve resumes*
2. In `/etc/fstab` make sure to have **`auto`** in the line for the nextcloud data partition so it is mounted automatically at boot
3. Tailscale Serve resumes automatically on boot when `tailscaled.service` is enabled — no additional systemd service or certificate renewal job is needed

---

### Add missing indices manually while the instance continues to run

`cd /var/www/nextcloud` # *Navigate to the Nextcloud installation directory*

`sudo -u www-data php occ db:add-missing-indices` # *Add any database indices that Nextcloud requires but are missing — safe to run while Nextcloud is live*

### Delete older versions of all files for all users while the instance continues to run

`cd /var/www/nextcloud` # *Navigate to the Nextcloud installation directory*

`sudo -u www-data php occ versions:cleanup` # *Delete older file versions for all users to free up disk space — safe to run while Nextcloud is live*

### Add user via occ command

`cd /var/www/nextcloud` # *Navigate to the Nextcloud installation directory*

`sudo -E -u www-data php occ user:add --display-name="FNU LNU" --group="group-A" --group="group-B" username` # *Create a new user, assign display name and groups. Will prompt for password. Upon first login the user will be asked to reset their password.*

Refer [the nextcloud admin manual](https://docs.nextcloud.com/server/latest/admin_manual/occ_command.html) for more occ commands
