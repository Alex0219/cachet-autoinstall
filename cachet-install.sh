#Install sudo

apt -y install sudo

# Enter your timezone here
sudo timedatectl set-timezone 'Europe/Berlin'

sudo apt update && sudo apt upgrade -y

sudo apt install -y vim git sudo nginx

# Install PHP modules
sudo apt install -y php7.0 php7.0-cli php7.0-fpm php7.0-common php7.0-xml php7.0-gd php7.0-zip php7.0-mbstring php7.0-mysql php7.0-pgsql php7.0-sqlite3 php7.0-mcrypt php-apcu

echo "Checking php version"

php --version
# Install mysql server
sudo apt install -y mariadb-server

# Generate random password for mysql
randPassword=$(date +%s|sha256sum|base64|head -c 32)

# Set mysql password
mysql -uroot << 'EOF'
UPDATE mysql.user SET Password=PASSWORD('$randPassword') WHERE User='root';
DELETE FROM mysql.user WHERE user='root' AND host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM mysql.user WHERE user='';
DROP DATABASE test;
CREATE DATABASE cachet;
GRANT ALL ON cachet.* TO 'cachetuser' IDENTIFIED BY '$randPassword';
FLUSH PRIVILEGES;
EOF

touch /home/cachet-autoinstall.txt

# Write mysql password to file
cat>/home/cachet-autoinstall.txt <<EOL
Cachet has been installed. 

MySQL:

Username: root
Password: $randPassword
EOL


# Write nginx config

cp ./cachet.conf /etc/nginx/sites-available/

# Symlink
sudo ln -s /etc/nginx/sites-available/cachet.conf /etc/nginx/sites-enabled/

# Ensure nginx config is working

sudo nginx -t

systemctl restart nginx

# Install composer

apt -y install composer

# Create directory for cachet

sudo mkdir -p /var/www/cachet

cd /var/www/cachet

git clone https://github.com/cachethq/Cachet.git .

git checkout v2.3.18 # Change this value by checking git tag -l

cp .env.example .env

cat>.env <<EOL
APP_ENV=production
APP_DEBUG=false
APP_URL=https://status.pleasechange.me
APP_KEY=abc

DB_DRIVER=mysql
DB_HOST=localhost
DB_DATABASE=cachet
DB_USERNAME=cachetuser
DB_PASSWORD=$randPassword
DB_PORT=null
DB_PREFIX=null

CACHE_DRIVER=file
SESSION_DRIVER=file
QUEUE_DRIVER=sync
CACHET_EMOJI=false

MAIL_DRIVER=smtp
MAIL_HOST=mailtrap.io
MAIL_PORT=2525
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ADDRESS=null
MAIL_NAME=null
MAIL_ENCRYPTION=tls

REDIS_HOST=null
REDIS_DATABASE=null
REDIS_PORT=null

GITHUB_TOKEN=null
EOL

composer install --no-dev -o

php artisan key:generate

php artisan app:install

sudo chown -R www-data:www-data /var/www/cachet

rm /etc/nginx/sites-enabled/default

service nginx restart