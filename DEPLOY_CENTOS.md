---
title: Deploying on CentOS / Red Hat Enterprise Linux
description: Install and Maintain eduVPN/Let's Connect! on CentOS
category: howto
---

For simple one server deployments and tests, we have a deploy script available 
you can run on a fresh CentOS (or Red Hat Enterprise Linux) 7 installation. It 
will configure all components and will be ready for use after running!

An additional script is available after deployment:

* Use [Let's Encrypt](https://letsencrypt.org/) for automatic web server 
  certificate management;

## Requirements

* Clean CentOS (or Red Hat Enterprise Linux) 7 installation with all updates 
  installed;
* For Red Hat Enterprise Linux the system should be registered at Red Hat 
  with the subscription manager (not required for CentOS);
* SELinux MUST be enabled 
  ([CentOS SELinux](https://wiki.centos.org/HowTos/SELinux));
* Have a **STATIC** IPv4 and IPv6 address configured on your external 
  interface;
* Network equipment/VM platform allows access to the very least `tcp/80`, 
  `tcp/443`, `udp/1194` and `tcp/1194` for basic functionality, the deploy 
  script will take care of the host firewall;
* Working DNS entry for your VPN server, e.g. `vpn.example.org`.

We test only with the official CentOS 
[Minimal ISO](https://centos.org/download/) and the official 
[Cloud](https://wiki.centos.org/Download) images. For Red Hat Enterprise Linux
we test with the official Red Hat Enterprise Linux ISO, e.g. 
`rhel-server-7.5-x86_64-dvd.iso`.

If you have a more complicated setup, we recommend to manually walk through 
the deploy script and follow the steps.

## Base Deploy

Perform these steps on the host where you want to deploy:

    $ curl -L -O https://github.com/eduvpn/documentation/archive/v2.tar.gz
    $ tar -xzf v2.tar.gz
    $ cd documentation-2

Run the script (as root):

    $ sudo -s
    # ./deploy_centos.sh

Specify the hostname you want to use for your VPN server. Both the "Web" and 
"OpenVPN" DNS names can be identical for simple 1 machine setups.

**NOTE**: you can NOT use `localhost` as a hostname, nor an IP address!

**NOTE**: by default there is **NO** firewall for the traffic between VPN 
client and VPN server. So if you have SSH running on your server, the clients
will be able to connect to it when you don't take additional steps! Look 
[here](FIREWALL.md).

**NOTE**: if you want to use the development repository, use:

    # VPN_DEV_REPO=1 ./deploy_centos.sh

## Update

Periodically install [updates](update_system_centos.sh)!

## Configuration

### VPN

See [PROFILE_CONFIG](PROFILE_CONFIG.md) on how to update the VPN server 
settings.

### Authentication 

#### Username & Password

By default there is a user `me` and `admin` with a generated password for 
portal access. Those are printed at the end of the deploy script.

If you want to update/add users you can use the `vpn-user-portal-add-user`. 
Provide an existing account to _update_ the password:

    $ sudo vpn-user-portal-add-user
    User ID: foo
    Setting password for user "foo"
    Password: 
    Password (repeat): 

You can configure which user(s) is/are an administrator by setting the 
`adminUserIdList` option in `/etc/vpn-user-portal/config.php`, e.g.:

    'adminUserIdList' => ['admin'],

#### LDAP

It is easy to enable LDAP authentication. This is documented separately. See
[LDAP](LDAP.md).

#### RADIUS

It is easy to enable RADIUS authentication. This is documented separately. See
[RADIUS](RADIUS.md).

#### SAML

It is easy to enable SAML authentication for identity federations, this is 
documented separately. See [SAML](SAML.md).

#### OpenID Connect (OIDC)

It is even easier to enable OpenID Connect (OIDC) authentication for identity federations, this is 
documented separately. See [OIDC](OIDC.md).

### 2FA

It is possible to enable [2FA](2FA.md) with TOTP.

### ACLs

If you want to restrict the use of the VPN a bit more than on whether someone
has an account or not, e.g. to limit certain profiles to certain (groups of)
users, see [ACL](ACL.md).

## Optional

### Let's Encrypt

Run the script (as root):

    $ sudo -s
    # ./lets_encrypt_centos.sh

Make sure you use the exact same DNS name you used when running 
`deploy_centos.sh`! 

After completing the script, the certificate will be installed and the system 
will automatically replace the certificate before it expires.

### Port Sharing

If you also want to allow clients to connect with the VPN over `tcp/443`, see 
[Port Sharing](PORT_SHARING.md).

### Let's Connect! Branding

See [BRANDING](BRANDING.md).
