#!/bin/sh

LC_BRANCH=v2
BASE_DIR=${HOME}/Projects/LC-${LC_BRANCH}

mkdir -p "${BASE_DIR}"
cd "${BASE_DIR}" || exit

# clone repositories (read-only)
git clone -b "${LC_BRANCH}" https://git.sr.ht/~fkooman/vpn-lib-common
git clone -b "${LC_BRANCH}" https://git.sr.ht/~fkooman/vpn-user-portal
git clone -b "${LC_BRANCH}" https://git.sr.ht/~fkooman/vpn-server-api
git clone -b "${LC_BRANCH}" https://git.sr.ht/~fkooman/vpn-server-node
git clone -b "${LC_BRANCH}" https://git.sr.ht/~fkooman/vpn-documentation
git clone https://git.sr.ht/~fkooman/vpn-portal-artwork-eduVPN
git clone https://git.sr.ht/~fkooman/vpn-portal-artwork-LC
git clone https://git.sr.ht/~fkooman/vpn-ca
git clone https://git.sr.ht/~fkooman/vpn-daemon
git clone https://git.sr.ht/~fkooman/vpn-maint-scripts

## clone all repositories (read/write)
#git clone -b ${LC_BRANCH} git@git.sr.ht:~fkooman/vpn-lib-common.git
#git clone -b ${LC_BRANCH} git@git.sr.ht:~fkooman/vpn-user-portal.git
#git clone -b ${LC_BRANCH} git@git.sr.ht:~fkooman/vpn-server-api.git
#git clone -b ${LC_BRANCH} git@git.sr.ht:~fkooman/vpn-server-node.git
#git clone -b ${LC_BRANCH} git@git.sr.ht:~fkooman/vpn-documentation.git
#git clone git@git.sr.ht:~fkooman/vpn-portal-artwork-eduVPN.git
#git clone git@git.sr.ht:~fkooman/vpn-portal-artwork-LC.git
#git clone git@git.sr.ht:~fkooman/vpn-ca.git
#git clone git@git.sr.ht:~fkooman/vpn-daemon.git
#git clone git@git.sr.ht:~fkooman/vpn-maint-scripts.git

# clone all RPM packages
mkdir -p rpm
for PACKAGE_NAME in vpn-daemon vpn-lib-common php-openvpn-connection-manager php-jwt php-oauth2-server php-otp-verifier php-secookie php-sqlite-migrate vpn-ca vpn-portal-artwork-LC vpn-portal-artwork-eduVPN vpn-server-api vpn-server-node vpn-user-portal vpn-maint-scripts; do
	git clone https://git.sr.ht/~fkooman/"${PACKAGE_NAME}".rpm rpm/"${PACKAGE_NAME}".rpm
	#git clone git@git.sr.ht:~fkooman/${PACKAGE_NAME}.rpm rpm/${PACKAGE_NAME}.rpm
done

# clone all DEB packages
#mkdir -p deb
#for PACKAGE_NAME in php-jwt vpn-user-portal vpn-server-api php-saml-sp vpn-maint-scripts vpn-lib-common php-oauth2-server vpn-server-node php-otp-verifier php-sqlite-migrate vpn-daemon vpn-ca php-secookie vpn-portal-artwork-eduvpn php-openvpn-connection-manager php-saml-sp-artwork-eduvpn vpn-portal-artwork-lc; do
#	git clone https://git.tuxed.net/deb/"${PACKAGE_NAME}" deb/"${PACKAGE_NAME}"
#	#git clone git@git.tuxed.net:deb/${PACKAGE_NAME}.git deb/${PACKAGE_NAME}
#done

######################################
# vpn-user-portal                    #
######################################
cd "${BASE_DIR}/vpn-user-portal" || exit
mkdir -p data
composer update

cat << 'EOF' > config/config.php
<?php
$baseConfig = include __DIR__.'/config.php.example';
$localConfig = [
    //'styleName' => 'eduVPN',
    //'styleName' => 'LC',
    'secureCookie' => false,
    'apiUri' => 'http://localhost:8008/api.php',
];
return array_merge($baseConfig, $localConfig);
EOF

php bin/init.php
php bin/generate-oauth-key.php
php bin/add-user.php --user foo   --pass bar
php bin/add-user.php --user admin --pass secret

# symlink to the official templates we have so we can easily modify and test
# them
mkdir -p web/css web/img web/fonts
for TPL in eduVPN LC
do
    ln -s "${BASE_DIR}/vpn-portal-artwork-${TPL}/views"  "views/${TPL}"
    ln -s "${BASE_DIR}/vpn-portal-artwork-${TPL}/locale" "locale/${TPL}"
    ln -s "${BASE_DIR}/vpn-portal-artwork-${TPL}/css"    "web/css/${TPL}"
    ln -s "${BASE_DIR}/vpn-portal-artwork-${TPL}/img"    "web/img/${TPL}"
    ln -s "${BASE_DIR}/vpn-portal-artwork-${TPL}/fonts"  "web/fonts/${TPL}"
done

######################################
# vpn-ca                             #
######################################
cd "${BASE_DIR}/vpn-ca" || exit
go build -o _bin/vpn-ca vpn-ca/*.go

######################################
# vpn-daemon                         #
######################################
cd "${BASE_DIR}/vpn-daemon" || exit
go build -o _bin/vpn-daemon vpn-daemon/*.go

######################################
# vpn-server-api                     #
######################################
cd "${BASE_DIR}/vpn-server-api" || exit
mkdir -p data
composer update

cat << EOF > config/config.php
<?php
\$baseConfig = include __DIR__.'/config.php.example';
\$localConfig = [
    'vpnCaPath' => '${BASE_DIR}/vpn-ca/_bin/vpn-ca',
];
return array_merge(\$baseConfig, \$localConfig);
EOF

php bin/init.php

######################################
# vpn-server-node                    #
######################################
cd "${BASE_DIR}/vpn-server-node" || exit
mkdir -p data openvpn-config
composer update
cat << 'EOF' > config/config.php
<?php
$baseConfig = include __DIR__.'/config.php.example';
$localConfig = [
    'apiUri' => 'http://localhost:8008/api.php',
];
return array_merge($baseConfig, $localConfig);
EOF

######################################
# launch script                      #
######################################
cat << 'EOF' | tee "${BASE_DIR}/launch.sh" > /dev/null
#!/bin/sh
(
    cd vpn-server-api || exit
    php -S localhost:8008 -t web &
)
(
    cd vpn-user-portal || exit
    php -S localhost:8082 -t web &
)
EOF
chmod +x "${BASE_DIR}/launch.sh"
