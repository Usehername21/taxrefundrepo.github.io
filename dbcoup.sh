#!/usr/bin/env sh
# On Ubuntu 23.04

# Update/Upgrade Essentials
sudo apt update && sudo apt upgrade --force-yes
sudo apt install git curl unzip  --force-yes
# Install/Start Apache2
    sudo apt install apache2 fail2ban --force-yes
    sudo systemctl enable apache2.service
    sudo systemctl start apache2.service
## Configure UFW/Fail2ban/Apache2
    sudo ufw allow in "Apache FUll"
    sudo ufw allow http && sudo ufw allow https
    sudo systemctl enable ufw && sudo systemctl start ufw
### MPM Prefork settings
    sudo a2dismod mpm_event && sudo a2enmod mpm_prefork
    sed -ie "s/KeepAlive Off/KeepAlive On/g" /etc/apache2/apache2.conf
    #### Drupal.conf VirtualHosts
    touch /var/log/apache2/drupal-error_log
    touch /var/log/apache2/drupal-access_log
    cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/drupal.conf
    cat <<END > /etc/apache2/sites-available/drupal.conf
    <VirtualHost *:80>
    ServerName taxre.store
    ServerAlias www.taxre.store
    ServerAdmin itsme@taxre.store
    DocumentRoot /var/www/html/drupal

    <Directory /var/www/html/drupal>
     Options FollowSymLinks
     AllowOverride All
     Order allow,deny
     allow from all
     RewriteEngine on
     RewriteBase /
     RewriteCond %{REQUEST_FILENAME} !-f
     RewriteCond %{REQUEST_FILENAME} !-d
     RewriteCond %{REQUEST_URI} !=/favicon.ico
     RewriteRule ^ index.php [L]
    </Directory>
        ErrorLog /var/log/apache2/drupal-error_log
        CustomLog /var/log/apache2/drupal-access_log common
</VirtualHost>
END

sudo a2enmod rewrite
sudo a2dissite 000-default.conf
sudo a2ensite drupal.conf
sudo systemctl restart apache2

##### PHP Install/Config
sudo apt install php8.1 php8.1-cli 1.php8-common php8.1-imap php8.1-redis php8.1-snmp php8.1-xml php8.1-zip php8.1-mbstring php8.1-curl libapache2-mod-php php8.1-gd php8.1-bcmath php8.1-mysql php8.1-zip php8.1-memcached php8.1-memcache php8.1-imagick php8.1-libvirt-php  php8.1-fpm php8.1-bz2 php8.1-tidy php8.1-smbclient php8.1-intl php-cli php-mbstring php-curl --force-yes
cat <<END > /etc/php/8.1/apache2/php.ini
error_reporting = E_COMPILE_ERROR|E_RECOVERABLE_ERROR|E_ERROR|E_CORE_ERROR
error_log = /var/log/php/error.log
max_input_time = 30
END
sudo mkdir /var/log/php
sudo chown www-data /var/log/php

sed -i 's/memory_limit = -1/memory_limit = 512M/g' /etc/php/8.1/cli/php.ini
sed -i 's/;date.timezone =/date.timezone = UTC/g' /etc/php/8.1/cli/php.ini
sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/8.1/cli/php.ini
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 100M/g' /etc/php/8.1/cli/php.ini
sed -i 's/post_max_size = 8M/post_max_size = 100M/g' /etc/php/8.1/cli/php.ini

##### Mysql Install/Start
sudo apt install mariadb-server mariadb-client --force-yes
sudo systemctl start mariadb
sudo systemctl enable mariadb
sudo myql --user=root <<_EOF_
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
_EOF_
mysql -uroot -p"$DBROOT_PASSWORD" -e "CREATE DATABASE dbcoup"
mysql -uroot -p"$DBROOT_PASSWORD" -e "CREATE USER dbcooper"
mysql -uroot -p"$DBROOT_PASSWORD" -e "GRANT ALL ON dbcoup.* TO 'dbcooper@localhost' IDENTIFIED BY '$DB_PASSWORD'";
mysql -uroot -p"$DBROOT_PASSWORD" -e "FLUSH PRIVILEGES";
##### WorldWide Composer Install
cd ~
curl -sS https://getcomposer.org/installer -o composer-setup.php
sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer
composer install
###### Create Drupal Demo Project
cd /var/www/html
composer create-project -s dev centarro/commerce-kickstart-project drupal
cd drupal
composer require drupal/commerce_demo

