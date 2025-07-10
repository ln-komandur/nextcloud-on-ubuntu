# Nextcloud Desktop - linux client

## References:
1.  [“Nextcloud development” team](https://launchpad.net/~nextcloud-devs)
2.  [PPA for stable releases of the Nextcloud desktop client compiled for Ubuntu.](https://launchpad.net/~nextcloud-devs/+archive/ubuntu/client)


## Installing the Desktop client per link 2 above

`sudo add-apt-repository ppa:nextcloud-devs/client` # **Add the nextcloud client PPA**

`sudo apt update` # **Update apt**

`sudo nala install nextcloud-desktop` # **Install the plain nextcloud desktop client**

`sudo nala install nautilus-nextcloud` # **OR Alternatively install the nautilus nextcloud desktop client**

### Stop security key (gpg file) cross signing

Find the location of the Nextcloud GPG key with `ls -l /etc/apt/trusted.gpg.d/` . Manually find the gpg file from that output similar to the below
```
-rw-r--r-- 1 root root 1176 Sep  6 10:22 /etc/apt/trusted.gpg.d/nextcloud-devs-ubuntu-client.gpg
```

Edit the Nextcloud client source list file `/etc/apt/sources.list.d/nextcloud-devs-ubuntu-client-jammy.list` with `sudo nano /etc/apt/sources.list.d/nextcloud-devs-ubuntu-client-jammy.list` and explicitly state this gpg key file. Include the phrase `[arch=amd64 signed-by=/etc/apt/trusted.gpg.d/nextcloud-devs-ubuntu-client.gpg]` as below
```
deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/nextcloud-devs-ubuntu-client.gpg] https://ppa.launchpadcontent.net/nextcloud-devs/client/ubuntu/ jammy main
```
Save and close `/etc/apt/sources.list.d/nextcloud-devs-ubuntu-client-jammy.list`

Update the package information from all configured sources with `sudo apt update`
