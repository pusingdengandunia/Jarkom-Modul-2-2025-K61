#Langkah 4 : 
#Tirion (ns1/master)
#install bind9
1. nano /etc/bind/named.conf.options
options {
    directory "/var/cache/bind";

    #DNS luar untuk forward query 
        192.168.122.1;
    };

    allow-query { any; };

    # Izinkan transfer zona hanya ke slave (ns2)
    allow-transfer { 10.94.2.5; };

    notify yes;

    # Default recursion untuk klien internal
    recursion yes;
};

2. root@Tirion:~# nano /etc/bind/named.conf.local
zone "k61.com" {
    type master;
    file "/etc/bind/zones/db.k61.com";
    allow-transfer { 10.94.2.5; }; # ke Valmar
    notify yes;
};

3. mkdir /etc/bind/zones
4. nano /etc/bind/zones/db.k61.com
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
	
5. restart bind

#Valmar (ns2/slave)
apt install bind9 -y
nano /etc/bind/named.conf.local
zone "k61.com" {
    type slave;
    masters { 10.94.2.4; };
    file "/var/lib/bind/db.k61.com";
};
restart bind #(bisa dengan rndc reload)
#Output yang diharapkan : 
root@Valmar:~# rndc zonestatus k61.com
name: k61.com
type: secondary
files: /var/lib/bind/db.k61.com
serial: 2025101202
nodes: 4
last loaded: Sun, 12 Oct 2025 22:18:52 GMT
next refresh: Sat, 18 Oct 2025 19:52:31 GMT
expires: Sun, 09 Nov 2025 22:18:52 GMT
secure: no
dynamic: no
reconfigurable via modzone: no

#UNTUK START KONEKSI (jalankan di kedua node)
/usr/sbin/named -u bind -c /etc/bind/named.conf

#CEK DI NODE LAIN 
dig @10.94.2.5(IP address valmar/tirion) k61.com