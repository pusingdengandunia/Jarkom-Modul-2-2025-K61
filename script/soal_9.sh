#LANGKAH 9 (klien harus berada di subnet yang sama dengan lindon)

#Valmar dan Trilion
nano /etc/bind/named.conf.local
#Valmar
zone "k61.com" {
    type slave;
    masters { 10.94.2.4; };     #IP ns1 (Tirion)
    file "/var/lib/bind/db.k61.com";
};

#Trilion
zone "k61.com" {
    type master;
    file "/etc/bind/db.k61.com";
    allow-transfer { 10.94.2.5; };  #IP Valmar (ns2)
};

#Trilion
nano /etc/bind/db.k61.com
$TTL 604800
@   IN  SOA ns1.k61.com. root.k61.com. (
        2025101202 ; Serial
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

#CEK apakah benar (Valmar dan Tirion)
named-checkzone k61.com /etc/bind/db.k61.com
#harapan output : OK
rndc reload k61.com

#Lindon
apt install nginx -y
mkdir -p /var/www/static.k61.com/annals
echo "Halo dari Lindon (static.k61.com)!" > /var/www/static.k61.com/annals/index.html
nano /etc/nginx/sites-available/static.k61.com
server {
    listen 80;
    server_name static.k61.com;

    root /var/www/static.k61.com;
    index index.html;

    location /annals/ {
        autoindex on;
    }
}

ln -s /etc/nginx/sites-available/static.k61.com /etc/nginx/sites-enabled/
nginx -t
nginx -s reload

#CLIENT TEST (di subnet yang sama dengan lindon)
apt install bind9 -y
/usr/sbin/named -u bind -c /etc/bind/named.conf
echo nameserver 10.94.2.4 > /etc/resolv.conf
dig static.k61.com
curl http://static.k61.com/annals/
#Harapan Output
#Halo dari Lindon (static.k61.com)