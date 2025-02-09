# ***Manually*** install nextcloud server on Ubuntu 22.04 (64 bit) for limited use within the intranet / home network
---

## Useful references - Courtesy credits and Gratitude
1. [How to Install LAMP Stack on Ubuntu 20.04 Server/Desktop](https://www.linuxbabe.com/ubuntu/install-lamp-stack-ubuntu-20-04-server-desktop)
2. [Install NextCloud on Ubuntu 20.04 with Apache (LAMP Stack)](https://www.linuxbabe.com/ubuntu/install-nextcloud-ubuntu-20-04-apache-lamp-stack)
3. [How to install Nextcloud 20 on Ubuntu Server 20.04](https://www.techrepublic.com/article/how-to-install-nextcloud-20-on-ubuntu-server-20-04/)
4. [Installation on Linux — Nextcloud latest Administration Manual latest documentation](https://docs.nextcloud.com/server/latest/admin_manual/installation/source_installation.html)
5. [How To Install MariaDB 10.5 on Ubuntu 20.04 (Focal Fossa)](https://computingforgeeks.com/how-to-install-mariadb-on-ubuntu-focal-fossa/)

  **Note:** - Though almost all references use Ubuntu 20.04, the procedure has worked **perfectly well on Ubuntu 22.04**, Lubuntu 20.04 and Raspbian buster as detailed in earlier versions of this write-up. 

---

## What is different about this installation?
Unlike the installations in the above references, the modifications in this installation assume all nextcloud client devices to be in the home intranet, and simplifies the foot print as below

1. Files are stored locally on a **separate and dedicated disk partition** on the machine where the nextcloud server is running
2. A **self-signed security certificate** is used
3. **No DNS lookups** are used. However **mDNS lookups** from avahi.service are leveraged as clients are within the intranet

This write up is based on the actual `history` of commands executed by following a blend of the above references. 192.168.254.56 is the example ip address.

---

## Why install manually?
[Why not install via snap?](https://github.com/ln-komandur/linux-utils/blob/master/why-not-snapd.md)

---

## Software and Versions used in this installation

### On Ubuntu 22.04.2 
1. Linux kernel 5.19.0-35-generic (64 bit) - ***the latest as of March 2023***
2. [nextcloud-26.0.0 server](https://nextcloud.com/changelog/) - ***the latest as of April 2023***
3. mariadb  Ver 15.1 Distrib 10.11.2-MariaDB, for debian-linux-gnu (x86_64) using  EditLine wrapper - ***mariadb 10.11 is LTS, maintained until Feb 2028***
4. OpenJDK version "19.0.2" 2023-01-17, JRE build 19.0.2+7-Ubuntu-0ubuntu322.04 - ***the latest as of March 2023***
5. apache2 Server version: Apache/2.4.52 (Ubuntu), Server built:   2023-01-23T18:34:42 - ***from Ubuntu 22.04 defaults***
6. PHP
   1. PHP 8.1.2-1ubuntu2.11 (cli) (built: Feb 22 2023 22:56:18) (NTS) - ***[php8.1 is recommended for Nextcloud 25 per the system requirements](https://docs.nextcloud.com/server/25/admin_manual/installation/system_requirements.html), and it is also available from Ubuntu 22.04 defaults. [Nextcloud 25 will not run on php8.2 or later](https://help.nextcloud.com/t/php8-2-with-nextcloud-25-0-2/151769).***
   2. PHP 8.3.11 (cli) (built: Aug 30 2024 09:27:49) (NTS) - ***[php8.3 is recommended for Nextcloud 30 per the system requirements](https://docs.nextcloud.com/server/30/admin_manual/installation/system_requirements.html).***

---

## Install the LAMP stack

Refer [How to Install LAMP Stack on Ubuntu 20.04 Server/Desktop](https://www.linuxbabe.com/ubuntu/install-lamp-stack-ubuntu-20-04-server-desktop)

### Install Apache and do basic set-up

`sudo apt update && sudo apt-get update && sudo apt upgrade && sudo apt-get upgrade`

**Run [1-install-and-setup-apache2.sh](1-install-and-setup-apache2.sh)**. It will prompt and authenticate for `sudo` privilege 

### Configure Apache to redirect to https, and to use alias wherever supported by avahi.service

Providing `ServerAlias computername.local` helps to use the server url as _https://computername.local/nextcloud_ from Linux laptops and iOS devices on the intranet if _avahi-daemon.service_ is running on the server. Since Android devices do not support mDNS (Refer [...local hostname doesn't work on Android phones](https://raspberrypi.stackexchange.com/questions/91154/raspberry-pis-local-hostname-doesnt-work-on-android-phones) ), the `ServerName` has to remain as the IP address to make it accessible from those devices.

**Run [2-configure-https-and-alias.sh](2-configure-https-and-alias.sh)**. It will prompt and authenticate for `sudo` privilege 

The script configures slightly different from [Install NextCloud on Ubuntu 20.04 with Apache (LAMP Stack)](https://www.linuxbabe.com/ubuntu/install-nextcloud-ubuntu-20-04-apache-lamp-stack) as this nextcloud installation **DOES NOT** choose to use a DNS look up. It is based on both [How to install Nextcloud 20 on Ubuntu Server 20.04](https://www.techrepublic.com/article/how-to-install-nextcloud-20-on-ubuntu-server-20-04/) and [Installation on Linux — Nextcloud latest Administration Manual latest documentation](https://docs.nextcloud.com/server/latest/admin_manual/installation/source_installation.html)

Refer [Configure to redirect to HTTPS site](https://help.nextcloud.com/t/configure-to-redirect-to-https-site/89135/4) , [Redirect SSLD](https://cwiki.apache.org/confluence/display/HTTPD/RedirectSSL) and [Hardening and Security Guidance](https://docs.nextcloud.com/server/latest/admin_manual/installation/harden_server.html) for details about ```<VirtualHost>``` items in the conf file created by the script. 

**Note:** 
1.  Despite these configurations, there may be some errors until the installation is _**fully complete**_.
2.  Even when the installation is complete Firefox may report an error as ***The page isn’t redirecting properly  Firefox has detected that the server is redirecting the request for this address in a way that will never complete. This problem can sometimes be caused by disabling or refusing to accept cookies*** . Clicking the **Try Again** button would solve the problem (redirect to https)


### Configure Uncomplicated Firewall (UFW)

**Run [3-configure-ufw.sh](3-configure-ufw.sh)**. It will prompt and authenticate for `sudo` privilege

## Install MariaDB

Refer [How To Install MariaDB 10.5 on Ubuntu 20.04 (Focal Fossa)](https://computingforgeeks.com/how-to-install-mariadb-on-ubuntu-focal-fossa/) for screenshots

`sudo apt install software-properties-common`

`sudo apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'`

`sudo add-apt-repository 'deb [arch=amd64] http://mirror.mariadb.org/repo/10.11/ubuntu/ jammy main'`

`sudo apt update` 

`sudo apt install mariadb-server mariadb-client` 

`mariadb --version` or `mysql --version` #Verify if the version intended is installed

### Configure Mariadb

Refer [How To Install MariaDB 10.5 on Ubuntu 20.04 (Focal Fossa)](https://computingforgeeks.com/how-to-install-mariadb-on-ubuntu-focal-fossa/) or [How to Install LAMP Stack on Ubuntu 20.04 Server/Desktop](https://www.linuxbabe.com/ubuntu/install-lamp-stack-ubuntu-20-04-server-desktop) for screenshots

`systemctl status mariadb`

`sudo systemctl start mariadb`

`sudo mysql_secure_installation` # Set up root password, remove anonymous users, disallow remote login, remove test database, reload privilege tables

`sudo mariadb -u root` or `mysql -u root -p` #These are just to test. The second command will prompt for mariadb root password you just set-up. Type exit at "MariaDB [(none)]>" prompt

### Create nextcloud user account (username and password) on mysql DB

Refer [Install NextCloud on Ubuntu 20.04 with Apache (LAMP Stack)](https://www.linuxbabe.com/ubuntu/install-nextcloud-ubuntu-20-04-apache-lamp-stack) for screenshots

`sudo mysql` 

**Use *YOUR* custom values below**

```
MariaDB [(none)]> create database NameForNextCloudDatabase;
MariaDB [(none)]> create user YOURNextCloudUser@localhost identified by 'your-password';
MariaDB [(none)]> grant all privileges on NameForNextCloudDatabase.* to YOURNextCloudUser@localhost identified by 'your-password';
MariaDB [(none)]> flush privileges;
MariaDB [(none)]> exit;
```

## Prepare the dedicated partition to save nextcloud server's data (user) files 

1. Create a separate partition of desired size and format it as `ext4` using GParted / KDE Partition Manager 
2. Follow the steps in [Create common mount points for partitions shared by all users and include them in fstab](https://github.com/ln-komandur/linux-utils/blob/master/common-mountpoints.md)
3. `sudo chown www-data:www-data /media/all-users-nextcloud/ -R` #**Assign the ownership of the mount point for the nextcloud server's data partition** to the web-root
   1.  There is no need for other users need to share this partition with the web-root. Therefore, files and directories in this partition need not inherit the group id. So, ensure that the setgid bit is **not** set by listing the permissions of the partition with `ls -l /media/all-users-nextcloud/`
   1.  In any case, unset the setgid bit with `sudo chmod -R g-s /media/all-users-nextcloud/` # [Unset the setgid bit](https://linuxconfig.org/how-to-use-special-permissions-the-setuid-setgid-and-sticky-bits)


## Install and Enable PHP Modules

Refer Step 4: Install and Enable PHP Modules in [Install NextCloud on Ubuntu 20.04 with Apache (LAMP Stack)](https://www.linuxbabe.com/ubuntu/install-nextcloud-ubuntu-20-04-apache-lamp-stack)

For Nextcloud 30, [upgrade to php8.3](upgrade%20to%20php8.3.md) as it is recommended per the [System requirements](https://docs.nextcloud.com/server/30/admin_manual/installation/system_requirements.html)

For Nextcloud 25, use the following commands

---

`sudo apt install php8.1 #The default php version in Ubuntu 22.04`

`php -v #Verify the version`

`sudo apt install imagemagick php-imagick libapache2-mod-php8.1 php8.1-common php8.1-mysql php8.1-fpm php8.1-gd  php8.1-curl php8.1-zip php8.1-xml php8.1-mbstring php8.1-bz2 php8.1-intl php8.1-bcmath php8.1-gmp #Install more php8.1 modules`

`sudo a2enmod php8.1 #Enable php8.1 with apache2 to take effect `

`sudo service apache2 restart #[Optional step]. Restart apache2 to use php8.1 modules. Also try reloading instead of restarting as an alternative option`

### Configuring PHP8.1

Refer [Uploading big files > 512MB — Nextcloud latest Administration Manual](https://docs.nextcloud.com/server/stable/admin_manual/configuration_files/big_file_upload_configuration.html?highlight=big%20files#configuring-php) 

**Run [4-Configure-php-settings.sh](4-Configure-php-settings.sh)** (it will prompt and authenticate for `sudo` privilege) to 
1. Increase PHP Memory Limit to 512M in /etc/php/8.1/fpm/php.ini file and /etc/php/8.1/apache2/php.ini ***if it is 128M***
2. Increase Upload File Size Limit to 2G in /etc/php/8.1/fpm/php.ini file and /etc/php/8.1/apache2/php.ini  in 2 places each ***if it is 2M***
3. Disable output_buffering in /etc/php/8.1/fpm/php.ini file and /etc/php/8.1/apache2/php.ini ***if it is set to any values (i.e. enabled)***
4. Restart apache
5. Create a test file (/var/www/html/info.php) to review the server's PHP information  
6. Allow the user to review the server's PHP information in a browser through http://localhost/info.php. _Refer [How to Install LAMP Stack on Ubuntu 20.04 Server/Desktop](https://www.linuxbabe.com/ubuntu/install-lamp-stack-ubuntu-20-04-server-desktop)_
7. Delete the test file after waiting for the user to press the enter key

Login as admin and [check PHP under Administration Settings](https://192.168.254.56/nextcloud/index.php/settings/admin/serverinfo) for the following

-   Version: 8.1.2
-   Memory limit: 512 MB
-   Upload max size: 2 GB 
---   

## Install nextcloud server - Part 1: terminal (command line) activities

The following is based on [Install NextCloud on Ubuntu 20.04 with Apache (LAMP Stack)](https://www.linuxbabe.com/ubuntu/install-nextcloud-ubuntu-20-04-apache-lamp-stack)

[Download the latest compatible version from nextcloud changelog](https://nextcloud.com/changelog/)

Verify the installable file with `sha256sum ./Downloads/nextcloud-*.zip` against the [respective checksum in the sha256 file](https://nextcloud.com/changelog/) 

`sudo unzip ./Downloads/nextcloud-*.zip  -d /var/www/` # Extract the installable

`sudo chown www-data:www-data /var/www/nextcloud/ -R` # Change owner and group from root to www-data

`sudo systemctl reload apache2` # Reload (or restart if needed) apache before completing the installation through the web browser.

## Install the nextcloud server - Part 2: Complete the installation in a Browser
...by accessing https://192.168.254.56/nextcloud/
1. Accept the "Potential Security Risk Ahead" from self signed security certificates that the browser warns about, and Continue

2. Create an admin user account (and the first user account) for the nextcloud server

3. Give the path to the data folder as /media/all-users-nextcloud-data/ along with credentials for mariaDB, and also enter the new username and password for the nextcloud database. **Note:** The browser WILL show errors because of trusted domains as 
      1. apache is already configured to redirect `ServerName 192.168.254.56` to `ServerAlias computername.local` http to https
      2. config.php is created only in this step and does not have `192.168.254.56` and `computername.local` listed as trusted_domains yet

3. **Fix:** Open the config.php file with `sudo nano /var/www/nextcloud/config/config.php` and edit the following to have both the IP address `192.168.254.56` and alias `computername.local`
      1. trusted domains
         ```
         'trusted_domains' =>
            array (
               0 => 'computername.local','192.168.254.56',
         ),
         ```
      2. the overwrite.cli.url 
         ```
         'overwrite.cli.url' =>  'https://computername.local/nextcloud','https://192.168.254.56/nextcloud',
         ```
      3. Include the line just below the above
         ```
         'overwriteprotocol' => 'https',
         ``` 
         The above helps to use the server url as `https://computername.local/nextcloud` from Linux laptops and iOS devices on the intranet if `avahi-daemon.service` is running on the server. Since Android devices do support mDNS (Refer [...local hostname doesn't work on Android phones](https://Gaveerrypi.stackexchange.com/questions/91154/raspberry-pis-local-hostname-doesnt-work-on-android-phones) ), the URL based on the IP address must also be given to use on those devices.
4. Restart apache `sudo systemctl restart apache2`         

---

### The nextcloud installation is now complete

---

### Post installation upgrades

Log in to the nextcloud server with admin user previlleges and upgrade to nextcloud from "Settings -> Administration -> Overview" if prompted

---

## Appendix


### Unable to access nextcloud server after its IP address changed

---

The nextcloud server's IP address could change for several reasons including, but not limited to the following
1. if it is not static or bound to the mac address,  
2. connecting it to a different network, a new router, 
3. change in DHCP range of the existing router
4. connecting the nextcloud server to the same network / router through a different network card (e.g. Wired / Wireless, new network card) 
5. SSD / HDD on which nextcloud is installed is moved to a different PC
6. etc. 

Imagine the nextcloud server's IP address changed from `192.168.254.56` to `192.168.0.27`. After this change, when nextcloud is accessed using the old IP address in the browser (i.e. https://192.168.254.56/nextcloud), an "Access through untrusted domain" page is most likely to be displayed.

Do the following to put the nextcloud server back on track.

1. Log onto the nextcloud server box (Physically / Virtually e.t.c)
2. Open the config.php file with `sudo nano /var/www/nextcloud/config/config.php` and edit the following with the new IP address
      1. the trusted domains from
         ```
         'trusted_domains' =>
            array (
               0 => 'computername.local','192.168.254.56',
         ),
         ```
         to
      
         ```   
         'trusted_domains' =>
            array (
               0 => 'computername.local','192.168.0.27',
         ),
         ```
      2. the overwrite.cli.url from
         ```
         'overwrite.cli.url' =>  'https://computername.local/nextcloud','https://192.168.254.56/nextcloud',
         ```
         to
         ```
         'overwrite.cli.url' => 'https://computername.local/nextcloud','https://192.168.0.27/nextcloud',
         ```         
3. Edit the new IP address in `/etc/apache2/sites-available/nextcloud.conf` after the `ServerName` fields
4. Restart apache server with `sudo systemctl restart apache2` and also reload it with `sudo systemctl reload apache2`
5. It's quite possible that the problem is still not resolved, and even the "Access through untrusted domain" page does not show up when accessing `https://192.168.0.27/nextcloud` through the browser.
6. In that case, try to access `https://192.168.0.27` and see if the apache default welcome page is shown with the configuration overview. If not, the problem is very likely that the server's `ufw` rules need to be updated.
7. Add new UFW rules as below and repeat the step 5 (first) and 4 (after 5) above. 
      1. `sudo ufw allow from 192.168.0.0/24 to any port 22 proto tcp`
      2. `sudo ufw allow from 192.168.0.0/24 to any port 80 proto tcp`
      3. `sudo ufw allow from 192.168.0.0/24 to any port 443 proto tcp`
      4. `sudo ufw allow in from 192.168.0.1 to 224.0.0.0/24`
8. Remove the old `ufw` rules as appropriate after executing `sudo ufw status numbered` and deleting numbered rules with `sudo ufw delete #` (replace # with the rule number)

### Manually stop and start nextcloud server (Avoiding autostarts to speed up boot-up)

1. Download [start-nextcloud.sh](start-nextcloud.sh) and [stop-nextcloud.sh](stop-nextcloud.sh) to super user's home directory
2. Give execute permissions to both scrips with `chmod +x <script-name.sh>`
3. Disable the 4 services `sudo systemctl disable phpsessionclean.timer php7.4-fpm.service mariadb.service apache2.service` so that they can be manually stopped and started by these scripts
4. In `/etc/fstab` make sure to have `noauto` in the line `UID=<UUID of the partition><tab>/media/all-users-nextcloud-data<tab>ext4<tab>noauto,nosuid,nodev,noexec,nouser,nofail<tab>0<tab>0`. Also make sure the line ends with "0" (i.e. fsck will not be run on this partition at boot
5. Execute [start-nextcloud.sh](start-nextcloud.sh) and [stop-nextcloud.sh](stop-nextcloud.sh) with `sudo` credentials as needed

### Add missing indices manually while the instance continues to run

`cd /var/www/nextcloud`

`sudo -u www-data php occ db:add-missing-indices`

### Delete older versions of all files for all users while the instance continues to run

`cd /var/www/nextcloud`

`sudo -u www-data php occ versions:cleanup`

# Exposing the nextcloud server outside your LAN through tailscale

1. Create a tailscale account and add your devices to it.
1. Take a fun name for your tailnet
1. Connect the device that hosts the nextcloud server to your tailnet and change its name
1. Generate TLS certificate for the device using the following command

`sudo tailscale cert --cert-file=/etc/ssl/certs/tls-cert-<whatever_name-devicename_tailnetname>.ts.net.pem --key-file=/etc/ssl/private/tls-cert--<whatever_name-devicename_tailnetname>.ts.net.key <device_name>.<tailnet_name>.ts.net # Reference https://tailscale.com/kb/1080/cli`

Edit nextcloud.conf as below


Edit config.php for trusted domains as below



