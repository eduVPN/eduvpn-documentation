#!/bin/sh

#
# Deploy a VPN controller on Fedora
#

if ! [ "root" = "$(id -u -n)" ]; then
    echo "ERROR: ${0} must be run as root!"; exit 1
fi

###############################################################################
# VARIABLES
###############################################################################

MACHINE_HOSTNAME=$(hostname -f)

# DNS name of the Web Server
printf "DNS name of the Web Server [%s]: " "${MACHINE_HOSTNAME}"; read -r WEB_FQDN
WEB_FQDN=${WEB_FQDN:-${MACHINE_HOSTNAME}}
# convert hostname to lowercase
WEB_FQDN=$(echo "${WEB_FQDN}" | tr '[:upper:]' '[:lower:]')

# whether or not to use the "development" repository (for experimental builds 
# or platforms not yet officially supported)
USE_DEV_REPO=${USE_DEV_REPO:-n}

###############################################################################
# SYSTEM
###############################################################################

# SELinux enabled?

if ! /usr/sbin/selinuxenabled
then
    echo "Please **ENABLE** SELinux before running this script!"
    exit 1
fi

# allow Apache to connect to PHP-FPM
# XXX is this still needed?
setsebool -P httpd_can_network_connect=1

###############################################################################
# SOFTWARE
###############################################################################

# disable and stop existing firewalling
systemctl disable --now firewalld >/dev/null 2>/dev/null || true
systemctl disable --now iptables >/dev/null 2>/dev/null || true
systemctl disable --now ip6tables >/dev/null 2>/dev/null || true
systemctl disable --now nftables >/dev/null 2>/dev/null || true

if [ "${USE_DEV_REPO}" = "y" ]; then
    # import PGP key
    rpm --import https://repo.tuxed.net/fkooman+repo@tuxed.net.asc
    cat << EOF > /etc/yum.repos.d/eduVPN_v3-dev.repo
[eduVPN_v3-dev]
name=eduVPN 3.x Development Packages (Fedora \$releasever)
baseurl=https://repo.tuxed.net/eduVPN/v3-dev/rpm/fedora-\$releasever-\$basearch
gpgcheck=1
enabled=1
EOF
else
    # import PGP key
    rpm --import resources/repo+v3@eduvpn.org.asc
    # configure repository
    cat << EOF > /etc/yum.repos.d/eduVPN_v3.repo
[eduVPN_v3]
name=eduVPN 3.x Packages (Fedora \$releasever)
baseurl=https://repo.eduvpn.org/v3/rpm/fedora-\$releasever-\$basearch
gpgcheck=1
enabled=1
EOF
fi

# install software (dependencies)
/usr/bin/dnf -y install mod_ssl php-opcache httpd nftables pwgen php-fpm \
    php-cli policycoreutils-python-utils chrony cronie ipcalc tmux

# install software (VPN packages)
/usr/bin/dnf -y install vpn-user-portal vpn-maint-scripts

###############################################################################
# APACHE
###############################################################################

# Use a hardened ssl.conf instead of the default, gives A+ on
# https://www.ssllabs.com/ssltest/
cp resources/ssl.fedora.conf /etc/httpd/conf.d/ssl.conf
cp resources/localhost.fedora.conf /etc/httpd/conf.d/localhost.conf

# VirtualHost
cp resources/vpn.example.fedora.conf "/etc/httpd/conf.d/${WEB_FQDN}.conf"
sed -i "s/vpn.example/${WEB_FQDN}/" "/etc/httpd/conf.d/${WEB_FQDN}.conf"

###############################################################################
# VPN-USER-PORTAL
###############################################################################

# update hostname of VPN server
sed -i "s/vpn.example/${WEB_FQDN}/" "/etc/vpn-user-portal/config.php"

# DB init
# XXX would be nice if we could avoid this
sudo -u apache /usr/libexec/vpn-user-portal/init

# update the default IP ranges for the profile
# on Debian we can use ipcalc-ng
sed -i "s|10.42.42.0|$(ipcalc -4 -r 24 -n --no-decorate)|" "/etc/vpn-user-portal/config.php"
sed -i "s|fd42::|$(ipcalc -6 -r 64 -n --no-decorate)|" "/etc/vpn-user-portal/config.php"
sed -i "s|10.43.43.0|$(ipcalc -4 -r 24 -n --no-decorate)|" "/etc/vpn-user-portal/config.php"
sed -i "s|fd43::|$(ipcalc -6 -r 64 -n --no-decorate)|" "/etc/vpn-user-portal/config.php"

###############################################################################
# UPDATE SECRETS
###############################################################################

/usr/libexec/vpn-user-portal/generate-secrets

###############################################################################
# CERTIFICATE
###############################################################################

# generate self signed certificate and key
openssl req \
    -nodes \
    -subj "/CN=${WEB_FQDN}" \
    -x509 \
    -sha256 \
    -newkey rsa:2048 \
    -keyout "/etc/pki/tls/private/${WEB_FQDN}.key" \
    -out "/etc/pki/tls/certs/${WEB_FQDN}.crt" \
    -days 90

###############################################################################
# DAEMONS
###############################################################################

systemctl enable --now php-fpm
systemctl enable --now httpd
systemctl enable --now crond

###############################################################################
# FIREWALL
###############################################################################

cp resources/firewall/controller/nftables.conf /etc/sysconfig/nftables.conf
sed -i "s|define EXTERNAL_IF = eth0|define EXTERNAL_IF = ${EXTERNAL_IF}|" /etc/sysconfig/nftables.conf
systemctl enable --now nftables

###############################################################################
# USERS
###############################################################################

USER_NAME="vpn"
USER_PASS=$(pwgen 12 -n 1)

sudo -u apache vpn-user-portal-account --add "${USER_NAME}" --password "${USER_PASS}"

echo "########################################################################"
echo "# Portal"
echo "# ======"
echo "#     https://${WEB_FQDN}/"
echo "#         User Name: ${USER_NAME}"
echo "#         User Pass: ${USER_PASS}"
echo "#"
echo "# Admin"
echo "# ====="
echo "# Add 'vpn' to 'adminUserIdList' in /etc/vpn-user-portal/config.php in"
echo "# order to make yourself an admin in the portal."
echo "########################################################################"
