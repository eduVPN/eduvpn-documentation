# Deploying on Enterprise Linux

For simple one server deployments and tests, we have a deploy script available 
you can run on a fresh EL installation. It will configure all components 
and will be ready for use after running!

Additional scripts are available after deployment:

* Use [Let's Encrypt](https://letsencrypt.org/) for automatic web server 
  certificate management;

## Requirements

* Clean EL installation with all updates installed and rebooted after 
  updates;
* SELinux MUST be enabled;
* You SHOULD use static IPv4 and IPv6 address configured on your external 
  interface;
* Network equipment/VM platform allows access to the very least `tcp/80`, 
  `tcp/443`, `udp/1194`, `tcp/1194` and `udp/51820` for basic functionality, 
  the deploy script will take care of the host firewall;
* Working DNS entry for your VPN server, e.g. `vpn.example.org`.
* Have the correct hostname configured on your system. Use 
  `hostnamectl set-hostname vpn.example.org` (as root) to set your hostname. If 
  you need to change the hostname, reboot after to make sure it "sticks".

If you have a more complicated setup, we recommend to manually walk through 
the deploy script and follow the steps.

**NOTE**: we only test with relatively clean and unmodified installations of 
Enterprise Linux. If you, or your organization (heavily) modified the OS 
installation the VPN deployment MAY not work...

## Base Deploy

**NOTE**: make sure you have `tar` installed, the EL "minimal" image does
not have `tar`:

    $ sudo dnf -y install tar

Perform these steps on the host where you want to deploy:

    $ curl -L -O https://codeberg.org/eduVPN/documentation/archive/v3.tar.gz
    $ tar -xzf v3.tar.gz
    $ cd documentation

Run the script (as root):

    $ sudo -s
    # ./deploy_el.sh

**NOTE**: if the script does NOT suggest the actual hostname you want to use 
on your system, make sure you configure your hostname first, see above.

**NOTE**: you can NOT use `localhost` as a hostname, nor an IP address!

**NOTE**: by default there is **NO** firewall for the traffic between VPN 
client and VPN server. So if you have SSH running on your server, the clients
will be able to connect to it when you don't take additional steps! Look 
[here](FIREWALL.md).

**NOTE**: if you want to use the [Development Repository](DEVELOPMENT_REPO.md) 
for your installation, which has development releases and supports additional 
OSes/architectures, use:

```bash
# USE_DEV_REPO=y ./deploy_el.sh
```

## Update

During the deployment you are asked whether to enable automatic updates. If you
choose `y`, the default, a _cronjob_ is installed in 
`/etc/cron.weekly/vpn-maint-update-system`.

For manual installation, see [INSTALL_UPDATES](INSTALL_UPDATES.md).

## Configuration

### VPN

See [PROFILE_CONFIG](PROFILE_CONFIG.md) on how to update the VPN server 
settings.

### Authentication 

#### Username & Password

By default there is a user `demo` and `admin` with a generated password for 
portal access. Those are printed at the end of the deploy script.

If you want to update/add users you can use `vpn-user-portal-account`. 
Provide an existing account to _update_ the password:

    $ sudo vpn-user-portal-account --add foo
    Setting password for user "foo"
    Password: 
    Password (repeat): 

You can configure which user(s) is/are an administrator by setting the 
`adminUserIdList` option in `/etc/vpn-user-portal/config.php`, e.g.:

    'adminUserIdList' => ['foo'],

#### LDAP

It is easy to enable LDAP authentication. This is documented separately. See
[LDAP](LDAP.md).

#### SAML

It is easy to enable SAML authentication for identity federations, this is 
documented separately. See [SAML](SAML.md).

### ACLs

If you want to restrict the use of the VPN a bit more than on whether someone
has an account or not, e.g. to limit certain profiles to certain (groups of)
users, see [ACL](ACL.md).

## Optional

### Web Server Certificates

By default a self-signed certificate is used for the web server. You can 
install your own certificates, and tweak 
`/etc/httpd/conf.d/vpn.example.org.conf` to point to them, or use Let's Encrypt 
using the script mentioned below.

#### Let's Encrypt

Run the script (as root) from the documentation folder, on EL you can also use
the "Fedora" script:

    $ sudo -s
    # ./lets_encrypt_fedora.sh

Make sure you use the exact same DNS name you used when running 
`deploy_el.sh`! 

After completing the script, the certificate will be installed and the system 
will automatically replace the certificate before it expires.

### Theme

You can apply a [theme](BRANDING.md) to the portal if you want.

### Port Sharing

If you also want to allow clients to connect with the VPN over `tcp/443`, see 
[Port Sharing](PORT_SHARING.md).
