# wordpress-installer

* The following script configure wordpress site on the host.
* First followin packages are installed(php,mysql-server,php-mysql,nginx,unzip).
* The user is prompted for hostname. After getting the hostname entry is made in /etc/hostname file.
* nginx configuration file is created for wordpress site.
* Contents for wordpress is downloaded and extracted in root directory.
* User is prompted for mysql root password and database name.
* After this wp-config.php file is created and set up is completed.
* Error Log file is created as /tmp/script.log
```
Configuration file : /etc/nginx/sites-enabled/hostname 
Root Directory     : /usr/share/nginx/hostname
(Where hostname may be ubuntu.example.com, linux.example.com) 

database-user      : root
database-password  : provided by user
database-name      : Provided by user
```
For root user
Usage:
```
bash wordpress.sh
./wordpress.sh
```
For normal user
Usage: 
```
sudo bash wordpress.sh
sudo ./wordpress.sh
```
* Please make sure no other installations are running.
* Make sure Internet is up and running.
* Make sure apache2 service is not running. apache2 and nginx service may conflict.
* Choose a new database name for wordpress. Do not use existing one.
