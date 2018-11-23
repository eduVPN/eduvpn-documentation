#!/bin/sh

#
# Use Let's Encrypt to obtain certificates for the Web Server
#

###############################################################################
# VARIABLES
###############################################################################

MACHINE_HOSTNAME=$(hostname -f)

# DNS name of the Web Server
printf "DNS name of the Web Server [${MACHINE_HOSTNAME}]: "; read -r WEB_FQDN
WEB_FQDN=${WEB_FQDN:-${MACHINE_HOSTNAME}}

###############################################################################
# SYSTEM
###############################################################################

if (command -v dnf)
then
    PACKAGE_MANAGER=/usr/bin/dnf
else
    PACKAGE_MANAGER=/usr/bin/yum
fi

${PACKAGE_MANAGER} install -y certbot

# stop httpd
systemctl stop httpd

###############################################################################
# CERTBOT
###############################################################################

certbot certonly --standalone -d "${WEB_FQDN}"

cat << EOF > /etc/sysconfig/certbot
PRE_HOOK="--pre-hook 'systemctl stop httpd'"
POST_HOOK="--post-hook 'systemctl start httpd'"
RENEW_HOOK=""
CERTBOT_ARGS=""
EOF

# enable automatic renewal
systemctl enable --now certbot-renew.timer

###############################################################################
# HTTPD
###############################################################################

sed -i "s|SSLCertificateFile /etc/pki/tls/certs/${WEB_FQDN}|#SSLCertificateFile /etc/pki/tls/certs/${WEB_FQDN}|" "/etc/httpd/conf.d/${WEB_FQDN}.conf"
sed -i "s|SSLCertificateKeyFile /etc/pki/tls/private/${WEB_FQDN}.key|#SSLCertificateKeyFile /etc/pki/tls/private/${WEB_FQDN}.key|" "/etc/httpd/conf.d/${WEB_FQDN}.conf"

sed -i "s|#SSLCertificateFile /etc/letsencrypt/live/${WEB_FQDN}/cert.pem|SSLCertificateFile /etc/letsencrypt/live/${WEB_FQDN}/cert.pem|" "/etc/httpd/conf.d/${WEB_FQDN}.conf"
sed -i "s|#SSLCertificateKeyFile /etc/letsencrypt/live/${WEB_FQDN}/privkey.pem|SSLCertificateKeyFile /etc/letsencrypt/live/${WEB_FQDN}/privkey.pem|" "/etc/httpd/conf.d/${WEB_FQDN}.conf"
sed -i "s|#SSLCertificateChainFile /etc/letsencrypt/live/${WEB_FQDN}/chain.pem|SSLCertificateChainFile /etc/letsencrypt/live/${WEB_FQDN}/chain.pem|" "/etc/httpd/conf.d/${WEB_FQDN}.conf"

###############################################################################
# CLEANUP
###############################################################################

# start httpd
systemctl start httpd

# ALL DONE!
