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
echo "This script Configures php settings for nextcloud server installation"
# MEMORY_LIMIT
echo
echo
echo "Current memory_limit in /etc/php/8.1/fpm/php.ini is: "
cat /etc/php/8.1/fpm/php.ini | grep memory_limit # Get the current value to use in sed command
#
echo "Setting it to 512M"
sed -i 's/memory_limit = 128M/memory_limit = 512M/g' /etc/php/8.1/fpm/php.ini
#
echo
echo
echo "Current memory_limit in /etc/php/8.1/apache2/php.ini is: "
cat /etc/php/8.1/apache2/php.ini | grep memory_limit # Get the current value to use in sed command
#
echo "Setting it to 512M"
sed -i 's/memory_limit = 128M/memory_limit = 512M/g' /etc/php/8.1/apache2/php.ini
#
# UPLOAD_MAX_FILESIZE
echo
echo
echo "Current upload_max_filesize in /etc/php/8.1/fpm/php.ini is: "
cat /etc/php/8.1/fpm/php.ini | grep upload_max_filesize # Get the current value to use in sed command
#
echo "Setting it to 2G"
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 2G/g' /etc/php/8.1/fpm/php.ini
#
echo
echo
echo "Current upload_max_filesize in /etc/php/8.1/apache2/php.ini is: "
cat /etc/php/8.1/apache2/php.ini | grep upload_max_filesize # Get the current value to use in sed command
#
echo "Setting it to 2G"
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 2G/g' /etc/php/8.1/apache2/php.ini
#
# POST_MAX_SIZE
echo
echo
echo "Current post_max_size in /etc/php/8.1/fpm/php.ini is: "
cat /etc/php/8.1/fpm/php.ini | grep post_max_size # Get the current value to use in sed command
#
echo "Setting it to 2G"
sed -i 's/post_max_size = 8M/post_max_size = 2G/g' /etc/php/8.1/fpm/php.ini
#
echo
echo
echo "Current post_max_size in /etc/php/8.1/apache2/php.ini is: "
cat /etc/php/8.1/apache2/php.ini | grep post_max_size # Get the current value to use in sed command
#
echo "Setting it to 2G"
sed -i 's/post_max_size = 8M/post_max_size = 2G/g' /etc/php/8.1/apache2/php.ini
#
# OUTPUT_BUFFERING
echo
echo
echo "Current output_buffering in /etc/php/8.1/fpm/php.ini is: "
cat /etc/php/8.1/fpm/php.ini | grep output_buffering # Get the current value to use in sed command
#
echo "Setting it to 0"
sed -i 's/output_buffering = 4096/output_buffering = 0/g' /etc/php/8.1/fpm/php.ini
#
echo
echo
echo "Current output_buffering in /etc/php/8.1/apache2/php.ini is: "
cat /etc/php/8.1/apache2/php.ini | grep output_buffering # Get the current value to use in sed command
#
echo "Setting it to 0"
sed -i 's/output_buffering = 4096/output_buffering = 0/g' /etc/php/8.1/apache2/php.ini
#
# RESTART APACHE
echo "RESTARTING APACHE for settings to take effect"
systemctl restart apache2 # Reload (or restart if needed)
#
echo
echo
echo "Exit"
exit
