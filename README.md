# nextcloud-on-lubuntu-20.04
nextcloud-on-lubuntu-20.04


# Installing nextcloud server on Lubuntu 20.04 (64bit) for use within the intranet (home network) with
1. Data to be stored on a separate disk partition
2. Using Self-signed certificate 
3. Not using any DNS lookup

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


The ufw rule is as below

`sudo ufw allow from 192.168.254.0/24 to any port 22 proto tcp`

`sudo ufw disable && sudo ufw enable`

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
   
   
   
The following is based on https://www.linuxbabe.com/ubuntu/install-nextcloud-ubuntu-20-04-apache-lamp-stack
After downloading and verifying the nextcloud installable file, executed the following

`sudo unzip ./nextcloud-installable/zip/nextcloud-20.0.2.zip -d /var/www`

`sudo chown www-data:www-data /var/www/nextcloud/ -R`

`sudo mysql`

`sudo nano /etc/apache2/sites-available/nextcloud.conf`

The below is slight different from https://www.linuxbabe.com/ubuntu/install-nextcloud-ubuntu-20-04-apache-lamp-stack as this nextcloud installation will NOT be using a DNS look up. These lines below necessary changes based on both https://www.techrepublic.com/article/how-to-install-nextcloud-20-on-ubuntu-server-20-04/
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

The ufw rules are as below

`sudo ufw allow from 192.168.254.0/24 to any port 22 proto tcp`

`sudo ufw allow from 192.168.254.0/24 to any port 80 proto tcp`

`sudo ufw allow from 192.168.254.0/24 to any port 443 proto tcp`

`sudo ufw disable && sudo ufw enable`

`sudo ufw status`



The below is slight different from https://www.linuxbabe.com/ubuntu/install-nextcloud-ubuntu-20-04-apache-lamp-stack as this nextcloud installation does NOT use TLS certificates from Let's encrypt, and instead uses self-signed certificates like in https://docs.nextcloud.com/server/latest/admin_manual/installation/source_installation.html 

`sudo a2enmod ssl`

`sudo a2ensite default-ssl`
  
`sudo systemctl reload apache2`


Before completing the installation through the browser, prepare the dedicated partition where nextcloud files will be saved as below

`sudo mkdir /media/all-users-nextcloud-data`

`sudo chown www-data:www-data /media/all-users-nextcloud-data/ -R`

`ls -l /media/`

`sudo blkid | grep UUID=`

`sudo nano /etc/fstab`

added the line 'UUID=<UUID of the partition><tab>/media/all-users-nextcloud-data<tab>ext4<tab>noauto,nosuid,nodev,nofail<tab>0<tab>0' at the end

`sudo mount -a`
   
Completed the Installation in the Web Browser by accessing https://localhost/nextcloud/ and a

Warning: Potential Security Risk Ahead
Advanced
Accept the Risk and Continue

Gave the path to the data folder as /media/all-users-nextcloud-data/ 


Increased PHP Memory Limit
  
  
`cat /etc/php/7.4/apache2/php.ini | grep 128`

`sudo sed -i 's/memory_limit = 128M/memory_limit = 512M/g' /etc/php/7.4/apache2/php.ini`
