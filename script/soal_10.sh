#Vingilot
apt install nginx php-fpm -y
start service
/usr/sbin/nginx
/usr/sbin/php-fpm8.4 -D
mkdir -p /var/www/app.k61.com
cd /var/www/app.k61.com
#buat file index.php dan about.php
nano /etc/nginx/sites-available/app.k61.com
server {
    listen 80;
    server_name app.k61.com;

    root /var/www/app.k61.com;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /$uri.php?$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}

ln -s /etc/nginx/sites-available/app.k61.com /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default
nginx -t (output : harus OK)
nginx -s reload

#Tirion
nano /etc/bind/db.k61.com
$TTL 604800
@   IN  SOA ns1.k61.com. root.k61.com. (
        2025101203 ; Serial
        604800     ; Refresh
        86400      ; Retry
        2419200    ; Expire
        604800 )   ; Negative Cache TTL

; =========================
;  ZONE: k61.com
; =========================
@       IN  NS  ns1.k61.com.
@       IN  NS  ns2.k61.com.
@       IN  A   10.94.2.2          ; Sirion (front door)
ns1     IN  A   10.94.2.4          ; Tirion (ns1)
ns2     IN  A   10.94.2.5          ; Valmar (ns2)
www     IN  A   10.94.2.2          ; IP Sirion
static  IN  A   10.94.2.6          ; IP Lindon
app   IN   A   10.94.2.7

#TEST (HARUS SATU SUBNET)
apt install php-fpm
nginx -t
php-fpm8.4 -D
echo nameserver 10.94.2.4 > /etc/resolv.conf
dig @(ip ns1 atau ns2) app.k61.com
curl http://app.k61.com/about
curl http://app.k61.com
