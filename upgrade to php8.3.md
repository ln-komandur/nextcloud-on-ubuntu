# Installs php8.3 for nextcloud server installation, and remove php8.1 if installed


### Reference [How to Upgrade PHP Version from 8.2 to 8.3 in Ubuntu](https://techvblogs.com/blog/upgrade-php-version-from-8-2-to-8-3-ubuntu)

## Remove php8.1

`sudo nala remove php8.1-curl libapache2-mod-php8.1 php-imagick php8.1-bcmath php8.1-bz2 php8.1-common php8.1-fpm php8.1-gd php8.1-gmp php8.1-intl php8.1-mbstring php8.1-mysql php8.1-xml php8.1-zip `

`dpkg-query -l | grep "^rc" | cut -d " " -f 3 | xargs sudo dpkg --purge #Remove php8.1 config files if they are marked "rc"`

## Add repo for php8.3

`sudo apt install software-properties-common #May have already been installed`

`sudo add-apt-repository ppa:ondrej/php #Add the repo for php8.3`

`sudo apt-get update #Update repos`

## Install php8.3 and modules

`sudo nala install imagemagick #May have already been installed`

`sudo apt install php8.3 #Install php8.3`
This will additionally and automatically install `libapache2-mod-php8.3 php-common php8.3-cli php8.3-common php8.3-opcache php8.3-readline` like below

```
:~$ sudo apt install php8.3 #Install php8.3
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following additional packages will be installed:
  libapache2-mod-php8.3 php-common php8.3-cli php8.3-common php8.3-opcache php8.3-readline
Suggested packages:
  php-pear
The following NEW packages will be installed:
  libapache2-mod-php8.3 php-common php8.3 php8.3-cli php8.3-common php8.3-opcache php8.3-readline
0 upgraded, 7 newly installed, 0 to remove and 3 not upgraded.
Need to get 4,984 kB of archives.
After this operation, 22.4 MB of additional disk space will be used.
Do you want to continue? [Y/n] 
```

`sudo nala install php8.3-curl  php8.3-imagick  php8.3-mbstring  php8.3-mysql  php8.3-xml  php8.3-zip php8.3-bcmath php8.3-bz2 php8.3-fpm php8.3-gd php8.3-gmp php8.3-intl #Install more 8.3 modules`

`php -v #Check the current version of php enabled in alternatives if any`

`sudo update-alternatives --config php #Check that there are no php alternatives`

## Update configurations to php8.3

`sudo a2enmod php8.3 #Enable 8.3 for apache`

`sudo nano 4-Configure-php-settings.sh #Update folder names to 8.3`

`./4-Configure-php-settings.sh #Update 8.3 configurations`

`sudo nano start-nextcloud.sh #Update to php8.3`

`sudo nano stop-nextcloud.sh  #Update to php8.3`

`./start-nextcloud.sh #Login as admin and check the php version in Administration settings`
