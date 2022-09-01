# ***Manually*** install nextcloud server on Lubuntu 20.04 (64bit) or Raspbian (buster) for limited use within the intranet / home network
---

## Useful references - Courtesy credits and Gratitude
1. [How to Install LAMP Stack on Ubuntu 20.04 Server/Desktop](https://www.linuxbabe.com/ubuntu/install-lamp-stack-ubuntu-20-04-server-desktop)
2. [Install NextCloud on Ubuntu 20.04 with Apache (LAMP Stack)](https://www.linuxbabe.com/ubuntu/install-nextcloud-ubuntu-20-04-apache-lamp-stack)
3. [How to install Nextcloud 20 on Ubuntu Server 20.04](https://www.techrepublic.com/article/how-to-install-nextcloud-20-on-ubuntu-server-20-04/)
4. [Installation on Linux — Nextcloud latest Administration Manual latest documentation](https://docs.nextcloud.com/server/latest/admin_manual/installation/source_installation.html)
5. [How To Install MariaDB 10.5 on Ubuntu 20.04 (Focal Fossa)](https://computingforgeeks.com/how-to-install-mariadb-on-ubuntu-focal-fossa/)

---

## What is different about this installation?
Unlike the installations in the above references, the modifications in this installation assume all nextcloud client devices to be in the home intranet, and simplifies the foot print as below

1. Data is stored locally on a **separate and dedicated disk partition** on the machine where the nextcloud server is running
2. A **self-signed security certificate** is used
3. **No DNS lookups** are used. However **mDNS lookups** from avahi.service are leveraged as clients are within the intranet

This write up is based on the actual `history` of commands executed by following a blend of the above references

---

## Why install manually? ***(why not install via snap?)***
1. snapd creates loop devices for each application / package it installs. Each of those loop devices are mounted separately during boot up, slowing down the boot up itself.
2. Disabled (unused) snap packages continue to linger around and hog disk space in the root partition unless they are purged explicitly. Over time, on systems with smaller root partitions, these even block the booting itself.

### Recommendation on snapd
1. Stay away from snaps as much as possible on low end systems. Or maintain them regularly (by removing disabled snaps e.t.c) if the system configuration can afford the inefficiences.

---

## Software and Versions used in this installation

### On Lubuntu 20.04.2 
1. Linux kernel 5.8.0-63-generic (64 bit)
2. nextcloud-20.0.11
3. mariadb  Ver 15.1 Distrib 10.5.11-MariaDB, for debian-linux-gnu (x86_64) using readline 5.2
4. OpenJDK version "16.0.1" 2021-04-20, JRE build 16.0.1+9-Ubuntu-120.04
5. apache2 Server version: Apache/2.4.41 (Ubuntu)

### On Raspbian GNU/Linux 10 (buster)
1. Linux raspberrypi 5.10.52-v7+ armv7l GNU/Linux
2. nextcloud-20.0.11
3. mariadb  Ver 15.1 Distrib 10.3.29-MariaDB, for debian-linux-gnueabihf (armv7l) using readline 5.2
4. OpenJDK version "11.0.12" 2021-07-20, JRE build 11.0.12+7-post-Raspbian-2deb10u1
5. apache2 Server version: Apache/2.4.38 (Raspbian)



---

## Install the LAMP stack

Refer [How to Install LAMP Stack on Ubuntu 20.04 Server/Desktop](https://www.linuxbabe.com/ubuntu/install-lamp-stack-ubuntu-20-04-server-desktop)

### Install Apache
This section is identical for **both Lubuntu and Raspbian**.

`sudo apt update && sudo apt-get update && sudo apt upgrade && sudo apt-get upgrade`

`sudo apt install -y apache2 apache2-utils`

`systemctl status apache2`

`sudo systemctl start apache2`

`apache2 -v`

Assign web root (www-data) as the owner and group for document root (/var/www/html/)

`ls -l /var/www/html/`

`sudo chown www-data:www-data /var/www/html/ -R`

### Configure apache to use self signed SSL certificate
This section is identical for **both Lubuntu and Raspbian**.

`sudo nano /etc/apache2/conf-available/servername.conf`   # And added the line `ServerName localhost` in this file

`sudo a2enconf servername.conf`

The below is slightly different from [Install NextCloud on Ubuntu 20.04 with Apache (LAMP Stack)](https://www.linuxbabe.com/ubuntu/install-nextcloud-ubuntu-20-04-apache-lamp-stack) as this nextcloud installation does NOT use TLS certificates from Let's encrypt, and instead uses self-signed certificates like described in [Installation on Linux — Nextcloud latest Administration Manual latest documentation](https://docs.nextcloud.com/server/latest/admin_manual/installation/source_installation.html)

`sudo a2enmod ssl`

`sudo a2ensite default-ssl`

`sudo systemctl reload apache2`

`sudo apache2ctl -t`

### Configure Apache to redirect to https, and to use alias wherever supported by avahi.service
This section is identical for **both Lubuntu and Raspbian**.

**Note:** Though apache is being configured for these, there may be some errors until the installation is fully complete.

`sudo nano /etc/apache2/sites-available/nextcloud.conf`

The below is slightly different from [Install NextCloud on Ubuntu 20.04 with Apache (LAMP Stack)](https://www.linuxbabe.com/ubuntu/install-nextcloud-ubuntu-20-04-apache-lamp-stack) as this nextcloud installation DOES NOT choose to use a DNS look up. These lines below are based on both [How to install Nextcloud 20 on Ubuntu Server 20.04](https://www.techrepublic.com/article/how-to-install-nextcloud-20-on-ubuntu-server-20-04/) and [Installation on Linux — Nextcloud latest Administration Manual latest documentation](https://docs.nextcloud.com/server/latest/admin_manual/installation/source_installation.html)


```
<VirtualHost *:80>
   ServerName 192.168.254.56
   ServerAlias computername.local
   # Redirects any request to http://192.168.254.56/nextcloud or http://computername.local/nextcloud to https
   Redirect permanent /nextcloud https://computername.local/nextcloud
</VirtualHost>

<VirtualHost *:443>
    ServerName 192.168.254.56
    ServerAlias computername.local
    Alias /nextcloud "/var/www/nextcloud/"
    ErrorLog ${APACHE_LOG_DIR}/nextcloud.error
    CustomLog ${APACHE_LOG_DIR}/nextcloud.access combined
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
</VirtualHost>

```
Refer [Configure to redirect to HTTPS site](https://help.nextcloud.com/t/configure-to-redirect-to-https-site/89135/4) , [Redirect SSLD](https://cwiki.apache.org/confluence/display/HTTPD/RedirectSSL) and [Hardening and Security Guidance](https://docs.nextcloud.com/server/latest/admin_manual/installation/harden_server.html) for details about ```<VirtualHost>``` items in the above conf file. 

**Note:** Even when the installation is complete Firefox may report an error as `The page isn’t redirecting properly  Firefox has detected that the server is redirecting the request for this address in a way that will never complete. This problem can sometimes be caused by disabling or refusing to accept cookies.` . Clicking the `Try Again` button would solve the problem (redirect to https)

Providing `ServerAlias computername.local` helps to use the server url as `https://computername.local/nextcloud` from Linux laptops and iOS devices on the intranet if `avahi-daemon.service` is running on your server. Since Android devices do not support mDNS (Refer https://raspberrypi.stackexchange.com/questions/91154/raspberry-pis-local-hostname-doesnt-work-on-android-phones ), the `ServerName` has to remain as the IP address to make it accessible from those devices.


`sudo a2ensite nextcloud.conf`

`sudo a2enmod rewrite headers env dir mime setenvif ssl`

`sudo apache2ctl -t`

`sudo systemctl restart apache2`

### Configure Uncomplicated Firewall (UFW)
This section is identical for **both Lubuntu and Raspbian**.

`sudo ufw status`

`sudo ufw allow from 192.168.254.0/24 to any port 22 proto tcp`

`sudo ufw allow from 192.168.254.0/24 to any port 80 proto tcp`

`sudo ufw allow from 192.168.254.0/24 to any port 443 proto tcp`

`sudo ufw allow in from 192.168.254.1 to 224.0.0.0/24` # To allow multicast packets from the router

Refresh UFW with `sudo ufw disable && sudo ufw enable && sudo ufw status`



## Install MariaDB 10.5 
All commands are needed for **Lubuntu**. Refer comments for those that do not apply for **Raspbian**.

These commands will NOT install MariaDB 10.5.11 on Raspbian. They will most likely install MariaDB 10.3.29 (from defaults)

Refer [How To Install MariaDB 10.5 on Ubuntu 20.04 (Focal Fossa)](https://computingforgeeks.com/how-to-install-mariadb-on-ubuntu-focal-fossa/) for screenshots

`sudo apt install software-properties-common` # Applies for **both Lubuntu and Raspbian**.

`sudo apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'` # Applies **ONLY for Lubuntu**.

`sudo add-apt-repository 'deb [arch=amd64] http://mariadb.mirror.globo.tech/repo/10.5/ubuntu focal main'` # Applies **ONLY for Lubuntu**.

`sudo apt update` # Applies for **both Lubuntu and Raspbian**.

`sudo apt install mariadb-server mariadb-client` # Applies for **both Lubuntu and Raspbian**.

`mariadb --version` or `mysql --version` # Applies for **both Lubuntu and Raspbian**. Raspbian is most likely to show "mariadb  Ver 15.1 Distrib 10.3.29-MariaDB"

### Configure Mariadb
This section is identical for **both Lubuntu and Raspbian**.

Refer [How to Install LAMP Stack on Ubuntu 20.04 Server/Desktop](https://www.linuxbabe.com/ubuntu/install-lamp-stack-ubuntu-20-04-server-desktop) for screenshots

`systemctl status mariadb`

`sudo systemctl start mariadb`

`sudo mysql_secure_installation` ## Set up root password, remove anonymous users, disallow remote login, remove test database, reload privilege tables

`sudo mariadb -u root` or `mysql -u root -p` ## These are just to test. The second command will prompt for mariadb root password you just set-up. Type exit at "MariaDB [(none)]>" prompt

### Create nextcloud user account (username and password) on mysql DB
This section is identical for **both Lubuntu and Raspbian**.

Refer [Install NextCloud on Ubuntu 20.04 with Apache (LAMP Stack)](https://www.linuxbabe.com/ubuntu/install-nextcloud-ubuntu-20-04-apache-lamp-stack) for screenshots

`sudo mysql` ## Fill out YOUR custom values

```
MariaDB [(none)]> create database NameForNextCloudDatabase;
MariaDB [(none)]> create user YOURNextCloudUser@localhost identified by 'your-password';
MariaDB [(none)]> grant all privileges on NameForNextCloudDatabase.* to YOURNextCloudUser@localhost identified by 'your-password';
MariaDB [(none)]> flush privileges;
MariaDB [(none)]> exit;
```

## Prepare the dedicated partition to save nextcloud server's data (user) files 
This section is identical for **both Lubuntu and Raspbian**.

1. Create a separte disk partition of desired size and format it as `ext4` using GParted / KDE Partition Manager 
2. Create a directory to mount that partition agnostic of users logged on the PC on which the nextcloud server is running
`sudo mkdir /media/all-users-nextcloud-data`
3. Gave the ownership of that directory (to-be partition mount point for nextcloud server's data (user) files) to the web-root
`sudo chown www-data:www-data /media/all-users-nextcloud-data/ -R`
4. Got the UUID of the partition at its current mount point using one of the below
`ls -l /media/`
`sudo blkid | grep UUID=`
5. Edit `/etc/fstab` to include information to mount the partition at the `/media/all-users-nextcloud-data` directory

`sudo nano /etc/fstab`
and add the line 
`UUID=<UUID of the partition><tab>/media/all-users-nextcloud-data<tab>ext4<tab>noauto,nosuid,nodev,noexec,nouser,nofail<tab>0<tab>0` at the end of the fstab file

The options at the end of this line mean the following 
* `noauto` - do not mount this partition at boot time
* `nosuid` - ignore / disregard the setguid (sticky bit) if set
* `nodev` - cannot contain special devices as a security precaution
* `noexec` - binaries cannot be executed in this partition
* `nouser` - only root can mount this partition. In the current context, this setting is intentional to act like a server switch to make the data folder available to nextcloud clients only if root mounts it
* `nofail` - ignore device errors if any

6. Check if the partition can be mounted at the new mount point by
`sudo mount -a`

## Install and Enable PHP Modules

***ONLY for Raspbian:*** Refer "Second method" in [PHP 7.4 on raspbian](https://raspberrypi.stackexchange.com/questions/108149/php-7-4-on-raspbian) and execute the following 5 commands before proceeding with the rest of the commands common to Lubuntu and Raspbian

  1. `sudo apt -y install lsb-release apt-transport-https ca-certificates`
  2. `sudo wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg`
  3. `echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list`
  4. `sudo apt update`
  5. `sudo apt -y install php7.4`  

Refer Step 4: Install and Enable PHP Modules in [Install NextCloud on Ubuntu 20.04 with Apache (LAMP Stack)](https://www.linuxbabe.com/ubuntu/install-nextcloud-ubuntu-20-04-apache-lamp-stack)

The following are identical for **both Lubuntu and Raspbian**.

`sudo apt install imagemagick php-imagick libapache2-mod-php7.4 php7.4-common php7.4-mysql php7.4-fpm php7.4-gd php7.4-json php7.4-curl php7.4-zip php7.4-xml php7.4-mbstring php7.4-bz2 php7.4-intl php7.4-bcmath php7.4-gmp`

`php --version`

`sudo systemctl restart apache2`

Refer [How to Install LAMP Stack on Ubuntu 20.04 Server/Desktop](https://www.linuxbabe.com/ubuntu/install-lamp-stack-ubuntu-20-04-server-desktop) for the below test

`sudo nano /var/www/html/info.php` # Paste ```'<?php phpinfo(); ?>'``` into this file to see the server's PHP information in localhost/info.php

`sudo rm /var/www/html/info.php` # Remove the file after testing

### Configuring PHP
This section is identical for **both Lubuntu and Raspbian**.

Refer [Uploading big files > 512MB — Nextcloud latest Administration Manual](https://docs.nextcloud.com/server/stable/admin_manual/configuration_files/big_file_upload_configuration.html?highlight=big%20files#configuring-php) 

#### Increase PHP Memory Limit to 512M after checking its current size **in 2 php.ini files**

In /etc/php/7.4/fpm/php.ini file 

`cat /etc/php/7.4/fpm/php.ini | grep memory_limit` # Get the current value to use in sed command

`sudo sed -i 's/memory_limit = 128M/memory_limit = 512M/g' /etc/php/7.4/fpm/php.ini`

Repeat this with /etc/php/7.4/apache2/php.ini

`cat /etc/php/7.4/apache2/php.ini | grep memory_limit` # Get the current value to use in sed command

`sudo sed -i 's/memory_limit = 128M/memory_limit = 512M/g' /etc/php/7.4/apache2/php.ini`

#### Increase Upload File Size Limit to 2G **in 2 php.ini files in 2 places each**

In /etc/php/7.4/fpm/php.ini file 

`cat /etc/php/7.4/fpm/php.ini | grep upload_max_filesize` # Get the current value to use in sed command

`sudo sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 2G/g' /etc/php/7.4/fpm/php.ini`

`cat /etc/php/7.4/fpm/php.ini | grep post_max_size` # Get the current value to use in sed command

`sudo sed -i 's/post_max_size = 8M/post_max_size = 2G/g' /etc/php/7.4/fpm/php.ini`

Repeat this with /etc/php/7.4/apache2/php.ini

`cat /etc/php/7.4/apache2/php.ini | grep upload_max_filesize` # Get the current value to use in sed command

`sudo sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 2G/g' /etc/php/7.4/apache2/php.ini`

`cat /etc/php/7.4/apache2/php.ini | grep post_max_size` # Get the current value to use in sed command

`sudo sed -i 's/post_max_size = 8M/post_max_size = 2G/g' /etc/php/7.4/apache2/php.ini`

#### Disable output_buffering **in 2 php.ini files**

In /etc/php/7.4/fpm/php.ini file 

`cat /etc/php/7.4/fpm/php.ini | grep output_buffering` # Get the current value to use in sed command

`sudo sed -i 's/output_buffering = 4096/output_buffering = 0/g' /etc/php/7.4/fpm/php.ini`

Repeat this with /etc/php/7.4/apache2/php.ini

`cat /etc/php/7.4/apache2/php.ini | grep output_buffering` # Get the current value to use in sed command

`sudo sed -i 's/output_buffering = 4096/output_buffering = 0/g' /etc/php/7.4/apache2/php.ini`

`sudo systemctl reload apache2` # Reload (or restart if needed) 

---   

## Install nextcloud-20.0.11 server - Part 1: terminal (command line) activities
This section is identical for **both Lubuntu and Raspbian**.

The following is based on [Install NextCloud on Ubuntu 20.04 with Apache (LAMP Stack)](https://www.linuxbabe.com/ubuntu/install-nextcloud-ubuntu-20-04-apache-lamp-stack)

[Download nextcloud 20.0.11](https://nextcloud.com/changelog/#latest20). 

Verify the installable file with `sha256sum ./Downloads/nextcloud-20.0.11.zip` against the [checksum for the file](https://download.nextcloud.com/server/releases/nextcloud-20.0.11.zip.sha256) 

`sudo unzip ./Downloads/nextcloud-20.0.11.zip  -d /var/www/` # Extract the installable

`sudo chown www-data:www-data /var/www/nextcloud/ -R` # Change owner and group from root to www-data

`sudo systemctl reload apache2` # Reload (or restart if needed) apache before completing the installation through the web browser.

## Install the nextcloud server - Part 2: Complete the installation in the Web Browser by accessing https://192.168.254.56/nextcloud/ 
This section is identical for **both Lubuntu and Raspbian**.

1. Accept the "Potential Security Risk Ahead" from self signed security certificates that the browser warns about, and Continue

2. Create an admin user account (and the first user account) for your nextcloud server

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
         The above helps to use the server url as `https://computername.local/nextcloud` from Linux laptops and iOS devices on the intranet if `avahi-daemon.service` is running on your server. Since Android devices do support mDNS (Refer https://raspberrypi.stackexchange.com/questions/91154/raspberry-pis-local-hostname-doesnt-work-on-android-phones ), the URL based on the IP address must also be given to use on those devices.
4. Restart apache `sudo systemctl restart apache2`         

---

### Your nextcloud-20.0.11 installation on Lubuntu 20.04.2 (64 bit) or Raspbian GNU/Linux 10 (buster) is not complete
### Post installation Upgrade 
Log in to your nextcloud server with admin user previlleges and upgrade to nextcloud 21 from "Settings -> Administration -> Overview" if prompted


---

## Appendix


### Unable to access nextcloud server after it's IP address changed

---

The nextcloud server's IP address could change for several reasons including, but not limited to the following
1. if it is not static or bound to the mac address,  
2. connecting it to a different network, a new router, 
3. change in DHCP range of the existing router
4. connecting the nextcloud server to the same network / router through a different network card (e.g. Wired / Wireless, new network card) 
5. etc. 

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
5. Execute [start-nextcloud.sh](start-nextcloud.sh) and [stop-nextcloud.sh](stop-nextcloud.sh) with `su` credentials as needed



## Upgrading php7.4 to php8.1 after upgrading to nextcloud 24.0.4 in Lubuntu 20.04(.1?)

1. `sudo apt update && sudo apt upgrade -y`
2. `sudo add-apt-repository ppa:ondrej/php -y`
3. `sudo apt update && sudo apt upgrade -y`
4. `php -v`
5. `sudo update-alternatives --list php`
6. `sudo apt remove libapache2-mod-php7.4 php7.4-common php7.4-mysql php7.4-fpm php7.4-gd php7.4-json php7.4-curl php7.4-zip php7.4-xml php7.4-mbstring php7.4-bz2 php7.4-intl php7.4-bcmath php7.4-gmp`
7. `sudo apt install php8.1`
8. `sudo apt install imagemagick php-imagick libapache2-mod-php8.1 php8.1-common php8.1-mysql php8.1-fpm php8.1-gd  php8.1-curl php8.1-zip php8.1-xml php8.1-mbstring php8.1-bz2 php8.1-intl php8.1-bcmath php8.1-gmp`
`sudo service apache2 restart`
9. `sudo a2enmod php8.1`

### Configuring PHP8.1


1. `cat /etc/php/8.1/fpm/php.ini | grep memory_limit`
2. `sudo sed -i 's/memory_limit = 128M/memory_limit = 512M/g' /etc/php/8.1/fpm/php.ini`
3. `cat /etc/php/8.1/apache2/php.ini | grep memory_limit`
4. `sudo sed -i 's/memory_limit = 128M/memory_limit = 512M/g' /etc/php/8.1/apache2/php.ini`


1. `cat /etc/php/8.1/fpm/php.ini | grep upload_max_filesize`
2. `sudo sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 2G/g' /etc/php/8.1/fpm/php.ini`
3. `cat /etc/php/8.1/fpm/php.ini | grep post_max_size # Get the current value to use in sed command`
4. `sudo sed -i 's/post_max_size = 8M/post_max_size = 2G/g' /etc/php/8.1/fpm/php.ini`


1. `cat /etc/php/8.1/apache2/php.ini | grep upload_max_filesize # Get the current value to use in sed command`
2. `sudo sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 2G/g' /etc/php/8.1/apache2/php.ini`
3. `cat /etc/php/8.1/apache2/php.ini | grep post_max_size # Get the current value to use in sed command`
4. `sudo sed -i 's/post_max_size = 8M/post_max_size = 2G/g' /etc/php/8.1/apache2/php.ini`


1. `cat /etc/php/8.1/fpm/php.ini | grep output_buffering # Get the current value to use in sed command`
2. `sudo sed -i 's/output_buffering = 4096/output_buffering = 0/g' /etc/php/8.1/fpm/php.ini`
3. `cat /etc/php/8.1/apache2/php.ini | grep output_buffering # Get the current value to use in sed command`
4. `sudo sed -i 's/output_buffering = 4096/output_buffering = 0/g' /etc/php/8.1/apache2/php.ini`

1. `sudo systemctl restart apache2 # Reload (or restart if needed)`

