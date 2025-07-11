#!/bin/bash
#ref: https://unix.stackexchange.com/questions/28791/prompt-for-sudo-password-and-programmatically-elevate-privilege-in-bash-script
#ref: https://askubuntu.com/a/30157/8698
#
if (($EUID != 0)); then
  if [[ -t 1 ]]; then
#https://unix.stackexchange.com/questions/218715/what-does-t-1-do
    sudo "$0" "$@"
  else
    exec 1>output_file
    gksu "$0 $@"
  fi
  exit
fi
echo "This script installs php8.3 for nextcloud server installation"
echo "##############################################################"
echo

echo
echo
echo "install software-properties-common. This may have already been installed"
echo "########################################################################"
echo
nala install software-properties-common #May have already been installed

echo
echo
echo "Add the repo for php8.3"
echo "##############################################################"
echo
add-apt-repository ppa:ondrej/php #Add the repo for php8.3

echo
echo
echo "Update repos"
echo "##############################################################"
echo
apt-get update #Update repos

echo
echo
echo "install imagemagick. This may have already been installed"
echo "##############################################################"
echo
nala install imagemagick #May have already been installed

echo
echo
echo "Install php8.3. This will additionally and automatically install"
echo "libapache2-mod-php8.3 php-common php8.3-cli php8.3-common php8.3-opcache php8.3-readline" 
echo "This can be checked by trying to remove php8.3, BUT ABORTING it with sudo nala remove php8.3"
echo "############################################################################################"
echo
nala install php8.3 #Install php8.3. This will additionally and automatically install libapache2-mod-php8.3 php-common php8.3-cli php8.3-common php8.3-opcache php8.3-readline. This can be checked by trying to remove php8.3, BUT ABORTING it like

echo
echo
echo "Install more 8.3 modules"
echo "##############################################################"
echo
nala install php8.3-curl  php8.3-imagick  php8.3-mbstring  php8.3-mysql  php8.3-xml  php8.3-zip php8.3-bcmath php8.3-bz2 php8.3-fpm php8.3-gd php8.3-gmp php8.3-intl #Install more 8.3 modules

echo
echo
echo "Check the current version of php enabled from amongst alternatives if any"
echo "##########################################################################"
echo
php -v #Check the current version of php enabled from amongst alternatives if any

echo
echo
echo "Check that there are no php alternatives or enable 8.3"
echo "##############################################################"
echo
update-alternatives --config php #Check that there are no php alternatives 

echo
echo
echo "Enable php8.3 for apache. This may already be true"
echo "##############################################################"
echo
a2enmod php8.3 #Enable php8.3 for apache. This may already be true
