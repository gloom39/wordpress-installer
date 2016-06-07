#!/bin/bash
log="/tmp/script.log"
interrupt(){
if [ -d /usr/share/nginx/$domain ]
then
    rm -rf /usr/share/nginx/$domain
fi
if [ -f /tmp/latest.zip ]
then
    rm -f /tmp/latest.zip
fi
if [ -d /tmp/latest ]
then
    rm -rf /tmp/latest
fi

echo -e "\n Installation is interrupted."
echo -e "\nError Log file is at $log."
exit 5
}
trap 'interrupt' SIGINT SIGTSTP SIGQUIT
echo "----------------------------------------" &>> $log
echo -e "Script starts at $(date)\n" &>> $log
echo "----------------------------------------" &>> $log
add-apt-repository ppa:ondrej/php -y 2>> $log
apt-get update 2>> $log
for package in {php7.0,php7.0-fpm,php7.0-cli,php7.0-gd,PHP7.0-mysql,mysql-server,php7.0-json,nginx,unzip}
do
    apt-get install $package -y 2>>  $log
    st=$?
if [ $st -ne 0 ]
then
    echo "There is some problem.Make sure there is no other installation is running.Check your internet connectivity."
    echo -e "\nError Log file is at $log"
    exit 7
fi
done
read -p "Enter your Domain Name :" domain
echo "127.0.0.1  $domain" >> /etc/hosts

cat > /etc/nginx/sites-enabled/$domain <<EOF
    server {
             listen   127.0.0.1:80;
             server_name $domain;
             root /usr/share/nginx/$domain;
             index  index.php;
             
             location /{
                      try_files \$uri \$uri/ =404;
             }
             
             error_page 404 /404.html;
             error_page 500 502 503 504 /50x.html;
             
             location = /50x.html {
                        root /usr/share/nginx/html;
              }

              location ~ \.php$ {
                         try_files \$uri = 404;
                         fastcgi_pass unix:/var/run/php/php7.0-fpm.sock;
                         fastcgi_index index.php;
                         fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
                         include fastcgi_params;
              }
 }
             
EOF
if [ -d /usr/share/nginx/$domain ]
then
   rm -rf /usr/share/nginx/$domain/*
else
   mkdir -p /usr/share/nginx/$domain
fi 
if [ -d /tmp/latest ]
then
   rm -rf /tmp/latest
fi
wget  -O /tmp/latest.zip http://wordpress.org/latest.zip 2>> $log
unzip /tmp/latest.zip -d /tmp/latest/ 2>> $log
cp -arvf /tmp/latest/$(ls /tmp/latest)/* /usr/share/nginx/$domain/ 2>>  $log
flag=0
while [ $flag -ne 1 ]
do
   read -s -p  "Enter Mysql Root Password :" pass
   mysql -u root -p$pass -e "show databases" &> /dev/null
if [ $? -ne 0 ]
then
    echo -e "\nWrong password"
else
    flag=1
fi
done
status=0
while [ $status -ne 1 ]
do
    echo -e "\n"
    read -p "Enter the database name you want to use for wordpress :" db
    mysql -u root -p$pass -e "create database $db" 2>> $log
    if [ $? -ne 0 ]
    then
        echo "Database can not be created.Choose different name"
    else
        status=1     
    fi
done
cat > /usr/share/nginx/$domain/wp-config.php << EOF
<?php
define('DB_NAME', '$db');

define('DB_USER', 'root');

define('DB_PASSWORD', '$pass');

define('DB_HOST', '$domain');

define('DB_CHARSET', 'utf8');

define('DB_COLLATE', '');

define('WP_DEBUG', false);  

\$table_prefix="wp_";

if ( !defined('ABSPATH') )
	define('ABSPATH', dirname(__FILE__) . '/');

require_once(ABSPATH . 'wp-settings.php');

EOF
curl https://api.wordpress.org/secret-key/1.1/salt >> /usr/share/nginx/$domain/wp-config.php
wget -O /tmp/wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar 
mv /tmp/wp-cli.phar /usr/local/bin/wp
chmod +x /usr/local/bin/wp
cd /usr/share/nginx/$domain
read -p "Enter Site Title : " site
read -p "Enter Admin user name : " admin
check=0
while [ $check -ne 1 ]
do
   read -s -p "Enter Admin password : "  pass2
   echo -e "\n"
   read -s -p "Enter password again : "  pass3
   if [ "$pass2" != "$pass3" ]
   then
         echo -e "\n password does not match"
   else
         check=1
   fi
done
   read -p "Enter Admin Email : " email
chown -R www-data:www-data /usr/share/nginx/$domain
chmod -R 755 /usr/share/nginx/$domain
wp core install --title="$site" --admin_user="$admin" --admin_password="$pass2" --admin_email="$email" --allow-root --url="http://$domain" 
rm -rf /tmp/latest/
rm /tmp/latest.zip
service nginx restart
service php7.0-fpm restart
echo -e "Setup complete. Open $domain in browser.\n"
