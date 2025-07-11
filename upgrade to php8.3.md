# Remove php8.1 if installed, and Install php8.3 packages for nextcloud server installation


### Reference [How to Upgrade PHP Version from 8.2 to 8.3 in Ubuntu](https://techvblogs.com/blog/upgrade-php-version-from-8-2-to-8-3-ubuntu)

## Remove php8.1 if installed

`sudo nala remove php8.1-curl libapache2-mod-php8.1 php-imagick php8.1-bcmath php8.1-bz2 php8.1-common php8.1-fpm php8.1-gd php8.1-gmp php8.1-intl php8.1-mbstring php8.1-mysql php8.1-xml php8.1-zip `

`dpkg-query -l | grep "^rc" | cut -d " " -f 3 | xargs sudo dpkg --purge #Remove php8.1 config files if they are marked "rc"`

## Install php8.3 and modules

Use the [script to install php8.3](4-install-php8_3.sh)

### Sample outputs for some commands are as below. 
***Checking if libapache2-mod-php8.3 php-common php8.3-cli php8.3-common php8.3-opcache php8.3-readline are installed by trying to remove php8.3, BUT ABORTING it***

```
:~$ sudo nala remove php8.3 #Try to remove php8.3, BUT ABORT it
============================================================================================================================================================================================================
 Removing                                                                                                                                                                                                   
============================================================================================================================================================================================================
  Package:                                                            Version:                                                                                                                       Size:  
  php8.3                                                              8.3.11-1+ubuntu22.04.1+deb.sury.org+1                                                                                          69 KB  
                                                                                                                                                                                                            
============================================================================================================================================================================================================
 Auto-Removing                                                                                                                                                                                              
============================================================================================================================================================================================================
  Package:                                                            Version:                                                                                                                       Size:  
  libapache2-mod-php8.3                                               8.3.11-1+ubuntu22.04.1+deb.sury.org+1                                                                                         5.7 MB  
  php-common                                                          2:94+ubuntu22.04.1+deb.sury.org+2                                                                                              77 KB  
  php8.3-cli                                                          8.3.11-1+ubuntu22.04.1+deb.sury.org+1                                                                                         5.8 MB  
  php8.3-common                                                       8.3.11-1+ubuntu22.04.1+deb.sury.org+1                                                                                         9.6 MB  
  php8.3-opcache                                                      8.3.11-1+ubuntu22.04.1+deb.sury.org+1                                                                                         1.0 MB  
  php8.3-readline                                                     8.3.11-1+ubuntu22.04.1+deb.sury.org+1                                                                                          70 KB  
                                                                                                                                                                                                            
============================================================================================================================================================================================================
 Summary                                                                                                                                                                                                    
============================================================================================================================================================================================================
 Remove      1 Packages                                                                                                                                                                                     
 Auto-Remove 6 Packages                                                                                                                                                                                     
                                                                                                                                                                                                            
 Disk space to free  22.4 MB   
                               
Do you want to continue? [Y/n] n
Abort.

```

***Notices that may be of interest when installing more php8.3 modules***, especially that apache2 is enabled for php8.3

```
:~$ sudo nala install php8.3-curl  php8.3-imagick  php8.3-mbstring  php8.3-mysql  php8.3-xml  php8.3-zip php8.3-bcmath php8.3-bz2 php8.3-fpm php8.3-gd php8.3-gmp php8.3-intl #Install more 8.3 modules

Notices:
  Notice: Not enabling PHP 8.3 FPM by default.
  Notice: To enable PHP 8.3 FPM in Apache2 do:
  Notice: a2enmod proxy_fcgi setenvif
  Notice: a2enconf php8.3-fpm
  Notice: You are seeing this message because you have apache2 package installed.
Finished Successfully

```

***php version currently enabled from amongst alternatives if any***

```
:~$ php -v #Check the current version of php enabled from amongst alternatives if any
PHP 8.3.11 (cli) (built: Aug 30 2024 09:27:49) (NTS)
Copyright (c) The PHP Group
Zend Engine v4.3.11, Copyright (c) Zend Technologies
    with Zend OPcache v8.3.11, Copyright (c), by Zend Technologies
```

***Updating php alternatives***

```
:~$ sudo update-alternatives --config php #Check that there are no php alternatives 
There is only one alternative in link group php (providing /usr/bin/php): /usr/bin/php8.3
Nothing to configure.

```

***Updating apache configurations to php8.3***

```
:~$ sudo a2enmod php8.3 #Enable php8.3 for apache. This may already be true
Considering dependency mpm_prefork for php8.3:
Considering conflict mpm_event for mpm_prefork:
Considering conflict mpm_worker for mpm_prefork:
Module mpm_prefork already enabled
Considering conflict php5 for php8.3:
Module php8.3 already enabled
```

## Globally find and replace 8.1 to 8.3 in custom scripts

1. `4-Configure-php-settings.sh` # Update folder names to php8.3
2. `start-nextcloud.sh` # Update names of services to reflect php8.3
3. `stop-nextcloud.sh`  # Update names of services to reflect  php8.3
