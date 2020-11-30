# ***Manually*** installing nextcloud server on Lubuntu 20.04 (64bit) for use within the intranet (home network)
1. Data to be stored on a separate disk partition
2. Using Self-signed certificate 
3. Not using any DNS lookup

## Useful references
1. https://www.linuxbabe.com/ubuntu/install-lamp-stack-ubuntu-20-04-server-desktop
2. https://www.linuxbabe.com/ubuntu/install-nextcloud-ubuntu-20-04-apache-lamp-stack
3. https://www.techrepublic.com/article/how-to-install-nextcloud-20-on-ubuntu-server-20-04/
4. https://docs.nextcloud.com/server/latest/admin_manual/installation/source_installation.html

## Why install manually? ***(why not install via snap)***
1. snapd creates loop devices for each application / package installed with it. It mounts each of those loop devices separately during boot up, slowing down the boot up itself.
2. Disabled (unused) snap packages continue to linger around and hog disk space unless purged explicitly. Over time, on systems with smaller root partitions, these even block the booting itself.

### Recommendation
1. Stay away from snaps as much as you can. Or maintain them (by removing disabled snaps) regularly.

## Software Versions
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

`sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT` - this is also covered in ufw rules


The ufw rule is added with `sudo ufw allow from 192.168.254.0/24 to any port 22 proto tcp`

UFW is then refreshed with `sudo ufw disable && sudo ufw enable`

`sudo ufw status`

`sudo iptables -L -n`

Continuing with apache installation - setting web root (www-data) as the owner and group for document root (/var/www/html/)

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
   

## Installing the nextcloud server - Part 1: terminal (command line) activities

The following is based on https://www.linuxbabe.com/ubuntu/install-nextcloud-ubuntu-20-04-apache-lamp-stack
After downloading and verifying the nextcloud installable file, executed the following

`sudo unzip ./nextcloud-installable/zip/nextcloud-20.0.2.zip -d /var/www`

`sudo chown www-data:www-data /var/www/nextcloud/ -R`

`sudo mysql`

`sudo nano /etc/apache2/sites-available/nextcloud.conf`

The below is slightly different from https://www.linuxbabe.com/ubuntu/install-nextcloud-ubuntu-20-04-apache-lamp-stack as this nextcloud installation will NOT be using a DNS look up. These lines below necessary changes based on both https://www.techrepublic.com/article/how-to-install-nextcloud-20-on-ubuntu-server-20-04/
and https://docs.nextcloud.com/server/latest/admin_manual/installation/source_installation.html


"""
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
"""

`sudo a2ensite nextcloud.conf`

`sudo a2enmod rewrite headers env dir mime setenvif ssl`

`sudo apache2ctl -t`

`sudo systemctl restart apache2`

`sudo apt install php-imagick php7.4-common php7.4-mysql php7.4-fpm php7.4-gd php7.4-json php7.4-curl  php7.4-zip php7.4-xml php7.4-mbstring php7.4-bz2 php7.4-intl php7.4-bcmath php7.4-gmp`

`sudo systemctl reload apache2`

`sudo iptables -I INPUT -p tcp --dport 443 -j ACCEPT  - this is also covered in ufw rules`

The ufw rules are added as below

`sudo ufw allow from 192.168.254.0/24 to any port 22 proto tcp`

`sudo ufw allow from 192.168.254.0/24 to any port 80 proto tcp`

`sudo ufw allow from 192.168.254.0/24 to any port 443 proto tcp`

`sudo ufw disable && sudo ufw enable`

`sudo ufw status`



The below is slightly different from https://www.linuxbabe.com/ubuntu/install-nextcloud-ubuntu-20-04-apache-lamp-stack as this nextcloud installation does NOT use TLS certificates from Let's encrypt, and instead uses self-signed certificates like in https://docs.nextcloud.com/server/latest/admin_manual/installation/source_installation.html 

`sudo a2enmod ssl`

`sudo a2ensite default-ssl`
  
`sudo systemctl reload apache2`

## Installing the nextcloud server - Part 2: Preparing the dedicated partition to save nextclound server's data files 
1. Create a separte disk partition of desired size and format it as `ext4` using GParted or KDE Partition Manager 
2. Create a directory to mount that partition commonly for all users using
`sudo mkdir /media/all-users-nextcloud-data`
3. Give the ownership of that directory (to-be partition mount point) to the web-root
`sudo chown www-data:www-data /media/all-users-nextcloud-data/ -R`
4. Get the UUID of the partition using one of the below
`ls -l /media/`
`sudo blkid | grep UUID=`
5. Edit fstab to include information to mount the partition at the directory
`sudo nano /etc/fstab`

add the line 
'UUID=<UUID of the partition><tab>/media/all-users-nextcloud-data<tab>ext4<tab>noauto,nosuid,nodev,nofail<tab>0<tab>0' at the end


6. Mount the partition now
`sudo mount -a`


7. Increase PHP Memory Limit to 512M
  
`cat /etc/php/7.4/apache2/php.ini | grep 128`

`sudo sed -i 's/memory_limit = 128M/memory_limit = 512M/g' /etc/php/7.4/apache2/php.ini`

   
## Installing the nextcloud server - Part 3: Completing the installation in the Web Browser by accessing https://localhost/nextcloud/ 
1. Accept the Potential Security Risk Ahead from self signed security certificates that the browser warns about, and Continue

2. Give the path to the data folder as /media/all-users-nextcloud-data/ along with credentials for mariaDB, new username and password for nextclound e.t.c. 
