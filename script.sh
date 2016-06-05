#!/bin/bash
log="/tmp/script.log"
interrupt(){
if [ -d /var/www/$domain ]
then
    rm -rf /var/www/$domain
fi
if [-f /tmp/latest.zip ]
then
    rm -f /tmp/latest.zip
fi
echo -e "\n Installation is interrupted."
echo -e "\nError Log file is at $log."
exit 5
}
trap 'interrupt' SIGINT SIGTSTP SIGQUIT
echo "----------------------------------------" &>> $log
echo -e "Script starts at $(date)\n" &>> $log
echo "----------------------------------------" &>> $log
apt-get update 2>> $log
for package in {php,mysql-server,nginx,php-mysql,unzip}
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
             root /var/www/$domain;
             index  index.php;
             
             location /{
                      try_files \$uri \$uri/ =404;
             }
             
             error_page 404 /404.html;
             error_page 500 502 503 504 /50x.html;
             
             location = /50x.html {
                        root /var/www/html;
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
if [ -d /var/www/$domain ]
then
   rm -rf /var/www/$domain/*
else
   mkdir /var/www/$domain
fi 
wget  -O /tmp/latest.zip http://wordpress.org/latest.zip 2>> $log
unzip /tmp/latest.zip -d /tmp/latest/ 2>> $log
cp -arvf /tmp/latest/$(ls /tmp/latest)/* /var/www/$domain/ 2>>  $log
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
sed -e "s/database_name_here/$db/" /var/www/$domain/wp-config.php  -e  "s/username_here/root/" -e "s/password_here/$pass/" /var/www/$domain/wp-config-sample.php > /var/www/$domain/wp-config.php


chown -R www-data:www-data /var/www/$domain
chmod -R 755 /var/www/$domain
rm -rf /tmp/latest/
rm /tmp/latest.zip
service nginx restart
echo -e "Setup complete. Open $domain in browser.\n"
