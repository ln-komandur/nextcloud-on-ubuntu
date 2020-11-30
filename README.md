# ***Manually*** installed nextcloud server on Lubuntu 20.04 (64bit) for limited use within the intranet / home network


## Useful references - Courtesy credits and Gratitude
1. https://www.linuxbabe.com/ubuntu/install-lamp-stack-ubuntu-20-04-server-desktop
2. https://www.linuxbabe.com/ubuntu/install-nextcloud-ubuntu-20-04-apache-lamp-stack
3. https://www.techrepublic.com/article/how-to-install-nextcloud-20-on-ubuntu-server-20-04/
4. https://docs.nextcloud.com/server/latest/admin_manual/installation/source_installation.html

***This write up is based on the actual `history` of commands executed by following a blend of the above references 

## What is different about this installation?
Unlike the installations in the above references, the modifications in this installation assume all nextcloud client devices to be in the home intranet, and simplifies the foot print as below

1. Data is stored on a separate and dedicated disk partition on the machine where nextcloud server is running
2. A self-signed security certificate is used
3. DNS lookups are not used

## Why install manually? ***(why not install via snap)***
1. snapd creates loop devices for each application / package it installs. Each of those loop devices are mounted separately during boot up, slowing down the boot up itself.
2. Disabled (unused) snap packages continue to linger around and hog disk space in the root partition unless they are purged explicitly. Over time, on systems with smaller root partitions, these even block the booting itself.

### Recommendation on snapd
1. Stay away from snaps as much as you can on low end systems. Or maintain them regularly (by removing disabled snaps e.t.c) if the system configuration can afford the inefficiences.

## Software and Versions used in this installation
1. Lubuntu 20.04.1 - Linux kernel 5.4.0-54-generic (64 bit)
2. nextcloud-20.0.2 (64 bit)

## Prerequisite 1 - Installing the LAMP stack

The following are based on https://www.linuxbabe.com/ubuntu/install-lamp-stack-ubuntu-20-04-server-desktop


`sudo apt update && sudo apt-get update && sudo apt upgrade && sudo apt-get upgrade`

`sudo apt install -y apache2 apache2-utils`

`systemctl status apache2`

`#sudo systemctl start apache2`

`sudo systemctl enable apache2`

`apache2 -v`

`sudo ufw status`

`sudo iptables -L -n`

`sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT` - this is also included in UFW rules as below

`sudo ufw allow from 192.168.254.0/24 to any port 22 proto tcp`

Refreshed UFW with `sudo ufw disable && sudo ufw enable && sudo ufw status`

`sudo iptables -L -n`

Continued with apache installation - assigned web root (www-data) as the owner and group for document root (/var/www/html/)

`sudo chown www-data:www-data /var/www/html/ -R`

`sudo apache2ctl -t`

`sudo nano /etc/apache2/conf-available/servername.conf`   and added the line 'ServerName localhost' in this file

`sudo a2enconf servername.conf`

`sudo systemctl reload apache2`

`sudo apache2ctl -t`

`sudo apt install mariadb-server mariadb-client`

`systemctl status mariadb`

`sudo systemctl start mariadb`

`sudo systemctl enable mariadb`

`sudo mysql_secure_installation`

`sudo mariadb -u root`

`mariadb --version`

`sudo apt install php7.4 libapache2-mod-php7.4 php7.4-mysql php-common php7.4-cli php7.4-common php7.4-json php7.4-opcache php7.4-readline`

`sudo a2enmod php7.4`

`sudo systemctl restart apache2`

`php --version`

`sudo nano /var/www/html/info.php and pasted the line '<?php phpinfo(); ?>' into this file to see the server's PHP information in localhost/info.php`

`sudo rm /var/www/html/info.php`
   

## Installed nextcloud-20.0.2 server - Part 1: terminal (command line) activities

The following is based on https://www.linuxbabe.com/ubuntu/install-nextcloud-ubuntu-20-04-apache-lamp-stack
After downloading and verifying the nextcloud installable file, executed the following

`sudo unzip ./nextcloud-installable/zip/nextcloud-20.0.2.zip -d /var/www`

`sudo chown www-data:www-data /var/www/nextcloud/ -R`

`sudo mysql`

`sudo nano /etc/apache2/sites-available/nextcloud.conf`

The below is slightly different from https://www.linuxbabe.com/ubuntu/install-nextcloud-ubuntu-20-04-apache-lamp-stack as this nextcloud installation DID NOT choose to use a DNS look up / Virtual host. These lines below necessary changes based on both https://www.techrepublic.com/article/how-to-install-nextcloud-20-on-ubuntu-server-20-04/ and https://docs.nextcloud.com/server/latest/admin_manual/installation/source_installation.html


```
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
```

`sudo a2ensite nextcloud.conf`

`sudo a2enmod rewrite headers env dir mime setenvif ssl`

`sudo apache2ctl -t`

`sudo systemctl restart apache2`

`sudo apt install php-imagick php7.4-common php7.4-mysql php7.4-fpm php7.4-gd php7.4-json php7.4-curl  php7.4-zip php7.4-xml php7.4-mbstring php7.4-bz2 php7.4-intl php7.4-bcmath php7.4-gmp`

`sudo systemctl reload apache2`

`sudo iptables -I INPUT -p tcp --dport 443 -j ACCEPT  - this is also covered in ufw rules`

The ufw rules were added as below

`sudo ufw allow from 192.168.254.0/24 to any port 22 proto tcp`

`sudo ufw allow from 192.168.254.0/24 to any port 80 proto tcp`

`sudo ufw allow from 192.168.254.0/24 to any port 443 proto tcp`

`sudo ufw disable && sudo ufw enable`

`sudo ufw status`



The below is slightly different from https://www.linuxbabe.com/ubuntu/install-nextcloud-ubuntu-20-04-apache-lamp-stack as this nextcloud installation did NOT use TLS certificates from Let's encrypt, and instead used self-signed certificates like described in https://docs.nextcloud.com/server/latest/admin_manual/installation/source_installation.html 

`sudo a2enmod ssl`

`sudo a2ensite default-ssl`
  
`sudo systemctl reload apache2`

## Installed the nextcloud server - Part 2: Prepared the dedicated partition to save nextclound server's data (user) files 
1. Created a separte disk partition of desired size and formated it as `ext4` using GParted / KDE Partition Manager 
2. Created a directory to mount that partition agnostic of users logged on the PC on which the nextcloud server is running
`sudo mkdir /media/all-users-nextcloud-data`
3. Gave the ownership of that directory (to-be partition mount point for nextclound server's data (user) files) to the web-root
`sudo chown www-data:www-data /media/all-users-nextcloud-data/ -R`
4. Got the UUID of the partition at its current mount point using one of the below
`ls -l /media/`
`sudo blkid | grep UUID=`
5. Edited `/etc/fstab` to include information to mount the partition at the `/media/all-users-nextcloud-data` directory
`sudo nano /etc/fstab`

and added the line 
`UUID=<UUID of the partition><tab>/media/all-users-nextcloud-data<tab>ext4<tab>noauto,nosuid,nodev,noexec,nouser,nofail<tab>0<tab>0` at the end of the fstab file

The options at the end of this line mean the following 
* `noauto` - do not mount this partition at boot time
* `nosuid` - ignore / disregard the setguid (sticky bit) if set
* `nodev` - cannot contain special devices as a security precaution
* `noexec` - binaries cannot be executed in this partition
* `nouser` - only root can mount this partition. In the current context, this setting is intentional to act like a server switch to make the data folder available to nextcloud clients only if root mounts it
* `nofail` - ignore device errors if any

6. Mounted the partition at the new mount point by
`sudo mount -a`

7. Increased PHP Memory Limit to 512M after checking its current size to be 128M
`cat /etc/php/7.4/apache2/php.ini | grep 128`

`sudo sed -i 's/memory_limit = 128M/memory_limit = 512M/g' /etc/php/7.4/apache2/php.ini`
   
## Installed the nextcloud server - Part 3: Completed the installation in the Web Browser by accessing https://localhost/nextcloud/ 
1. Accepted the Potential Security Risk Ahead from self signed security certificates that the browser warned about, and Continued

2. Gave the path to the data folder as /media/all-users-nextcloud-data/ along with credentials for mariaDB, and also entered new username and password for nextclound

### Successfully completed the server installation
