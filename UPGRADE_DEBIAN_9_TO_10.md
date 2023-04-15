# Upgrade Debian 9 to Debian 10

We split the migration from Debian 9 to Debian 10 in two parts:

1. Switch to new package repository;
2. Upgrade to Debian 10

We split the upgrade to Debian 10 procedure in two parts that can be scheduled 
at different moments. It is important to FIRST switch to the new repository 
before attempting to upgrade to Debian 10!

The reason for splitting this up in two parts is to avoid having to fight two
battles at the same time, i.e. both potential VPN package upgrade problems AND 
Debian upgrade troubles.

The new repository contains packages for both Debian 9 and Debian 10, they are 
based on the same package descriptions and are officially supported by the 
eduVPN / Let's Connect! project! A little care has to be taken when upgrading 
to the new repository as they use the proper Debian way to handle configuration 
files and various other aspects that were hacked around in the old (Debian 9 
only) packages.

## To New Package Repository

You can very easily upgrade your existing Debian 9 server to use the new 
repository, but pay attention to the instructions below!

**NOTE**: if you have `vpn-daemon` installed, you can check that with 
`dpkg -l vpn-daemon`, check the "VPN Daemon" section below first and then 
come back here!

Let's get started! Switch to the new repository. Remove the file 
`/etc/apt/sources.list.d/LC.list`:

    $ sudo rm /etc/apt/sources.list.d/LC.list

Add the new repository file:

    $ echo "deb https://repo.eduvpn.org/v2/deb stretch main" | sudo tee /etc/apt/sources.list.d/eduVPN.list
    
Add the new PGP key:

    $ curl https://repo.eduvpn.org/v2/deb/debian+20200817@eduvpn.org.asc | sudo tee /etc/apt/trusted.gpg.d/eduVPN.asc
    
Now you can update your system. All eduVPN packages will be replaced by the 
version from the new Debian 9 repository. **NOTE**: the upgrade WILL ask if 
you want to keep your existing configuration files for some packages. Make sure 
you do, i.e. choose **N** on the prompt!

To install the updates:

    $ sudo apt update
    $ sudo apt dist-upgrade

The `dist-upgrade` command will complain about `postrm` scripts not running 
correctly. It is safe to ignore this. This is all fixed in the new packages, 
but the old packages are still in the way during the upgrade to the new 
repository.

Now you can clean up some old dependencies that are no longer necessary:

    $ sudo apt autoremove

Make sure you have `vpn-maint-scripts` installed:

    $ sudo apt install vpn-maint-scripts

Run the following scripts to make sure all is in order:

    $ sudo vpn-maint-apply-changes
    $ sudo vpn-maint-update-system

This should all run without any error and without asking any questions! Reboot 
your server after this and make sure everything still works. Try logging in to 
the portal, connect with a VPN client.

Now you are all done regarding upgrading to the new packages. You can keep 
using Debian 9 until it is officially [EOL](https://wiki.debian.org/LTS), which 
at the very latest is June 30, 2022. We **MAY** discontinue Debian 9 support 
BEFORE this date, please keep a close eye on the 
[mailing list](https://lists.geant.org/sympa/info/eduvpn-deploy) and 
subscribe if you haven't done that yet!

In case you are ready to migrate to Debian 10, which is a bit more involved, 
see the next section.

### VPN Daemon

First you have to remove `vpn-daemon` if it is installed on your Debian 9 
system. If it is not, just ignore this section!

Remove it and clean up the user that was created by the old package install:

    $ sudo apt remove vpn-daemon
    $ sudo userdel vpn-daemon

Now continue with the upgrade to the new packages above. After completing that 
upgrade to the new packages in Debian 9, AND you had vpn-daemon installed, 
continue below here again.

You can now install `vpn-daemon` again:

    $ sudo apt install vpn-daemon

And optional enable it one boot and start it immediately:

    $ sudo systemctl enable --now vpn-daemon

**NOTE**: it may complain about it being masked, am I not sure why/how that 
happens... probably something in the old package that is in the way... In order
to "fix" this uninstall the package again, and install it again. You may need
to reconfigure it, in case you modified the default configuration. Probably 
only in "multi node" setups. You may want to make a copy of 
`/etc/default/vpn-daemon` first and your private key/certificates in 
`/etc/ssl/vpn-daemon` in case you had those.

    $ sudo apt remove --purge vpn-daemon
    $ sudo apt install vpn-daemon
    $ sudo systemctl enable --now vpn-daemon

That should fix it right up!

## To Debian 10

Follow the instructions 
[here](https://www.debian.org/releases/buster/amd64/release-notes/ch-upgrading.en.html). 
These are the official Debian upgrade instructions. You can and SHOULD follow 
that document and read all sections and perform the steps when necessary. Pay 
attention the the cleanup as well (sections 4.7, 4.8). When updating the 
repositories (section 4.3) also make sure you update 
`/etc/apt/sources.list.d/eduVPN.list` and replace `stretch` with `buster`, 
i.e.:

    $ echo "deb https://repo.eduvpn.org/v2/deb buster main" | sudo tee /etc/apt/sources.list.d/eduVPN.list

After the update is complete, PHP will not be properly configured yet, this is 
because the version changed from 7.0 to 7.3 and is part of a different Apache
configuration. You have to manually re-enable PHP:

    $ sudo a2enconf php7.3-fpm

Restart Apache:

    $ sudo systemctl restart apache2

Run the following scripts to make sure all is in order:

    $ sudo vpn-maint-apply-changes
    $ sudo vpn-maint-update-system

This should all run without any error and without asking any questions! Reboot 
your server after this and make sure everything still works. Try logging in to 
the portal, connect with a VPN client.
