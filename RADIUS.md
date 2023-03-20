# Radius

This document describes how to configure RADIUS for deployed systems. We assume 
you used the `deploy_${DIST}.sh` script to deploy the software. Below we assume 
you use `vpn.example`, but modify this domain to your own domain name!

RADIUS integration can currently only be used to _authenticate_ users, not for 
authorization/ACL purposes.

In order to make a particular user an "administrator" in the portal, see 
[PORTAL_ADMIN](PORTAL_ADMIN.md).

**NOTE**: you absolutely MUST make sure the communication between the VPN 
server and the RADIUS server is secure! Without additional steps the 
credentials will be transmitted as _plain text_ between the VPN server and the
RADIUS server! 

**NOTE**: RADIUS integration does NOT support PEAP/TTLS, plain text 
authentication ONLY!, RADIUS servers used for _eduroam_ authentication will 
typically be configured with PEAP/TTLS, as plain text authentication is not 
supported for 802.1X.

**NOTE**: If you have the choice between LDAP and RADIUS, always choose LDAP! 
LDAP is supported by all common IdMs, even Active Directory. Go [here](LDAP.md)
for instructions on how to configure LDAP.

**NOTE**: RADIUS authentication is no longer supported on PHP 8.x so it will
only work on Debian 11 as of this moment and not on Fedora or Ubuntu.

## Configuration

First install the PHP module for RADIUS:

```bash
$ sudo apt install php-radius
```

Restart PHP to activate the RADIUS module:

```bash
$ sudo systemctl restart php$(/usr/sbin/phpquery -V)-fpm
```

You can configure the portal to use RADIUS. This is configured in the file 
`/etc/vpn-user-portal/config.php`.

You have to set `authMethod` first:

```php
'authMethod' => 'RadiusAuthModule',

// ...

'RadiusAuthModule' => [
    'serverList' => [
        // Format: HOST:PORT:SECRET
        'radius.example.org:1812:testing123',
    ],
    'addRealm' => 'example.org',
    'nasIdentifier' => 'vpn.example.org',
    // 'permissionAttribute' => RADIUS_REPLY_MESSAGE,
    // 'permissionAttribute' => 16,
],
```

Here `serverList` is an array of server configurations where you can add 
multiple RADIUS servers to be used for user authentication. The format is 
`HOST:PORT:SECRET`, see the example above.

You can also configure whether or not to add a "realm" to the identifier the 
user provides. If for example the user provides `foo` as a user ID, the 
`addRealm` option when set to `example.org` modifies the user ID to 
`foo@example.org` and uses that to authenticate to the RADIUS server.

It is also possible to specify an attribute for user authorization using the 
`permissionAttribute` configuration option. For now only officially registered 
attributes are supported, so NO vendor specific attributes. See the list 
[here](https://www.iana.org/assignments/radius-types/radius-types.xhtml) for a 
complete list. Make sure you use a "text" or "string" type. Not all attributes
are registered in the PHP RADIUS plugin, so you can also use the integer value, 
e.g. `16` instead of `RADIUS_REPLY_MESSAGE`. For the PHP list look 
[here](https://www.php.net/manual/en/radius.constants.attributes.php).
