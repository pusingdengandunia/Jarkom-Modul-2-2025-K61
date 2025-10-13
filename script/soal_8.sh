#Buat file reverse zone di Tirion (ns1/master)
#Masuk ke direktori zona:

cd /etc/bind/zones

#Buat file reverse, misal:

nano db.reverse
$TTL 604800
@   IN  SOA ns1.k61.com. root.k61.com. (
        2025101203 ; Serial
        604800     ; Refresh
        86400      ; Retry
        2419200    ; Expire
        604800 )   ; Negative Cache TTL

; NS records
@       IN  NS  ns1.k61.com.
@       IN  NS  ns2.k61.com.

; PTR records
2       IN  PTR sirion.k61.com.
6       IN  PTR lindon.k61.com.
7       IN  PTR vingilot.k61.com.

#Angka 2, 6, 7 adalah oktet terakhir IP masing-masing host.
#Tambahkan reverse zone di named.conf.local Tirion

zone "2.94.10.in-addr.arpa" {
    type master;
    file "/etc/bind/zones/db.reverse";
    allow-transfer { 10.94.2.5; };  # IP Valmar
};
#Buat slave reverse zone di Valmar (ns2)

#Buat file konfigurasi di /etc/bind/named.conf.local:
#Valmar
zone "2.94.10.in-addr.arpa" {
    type slave;
    masters { 10.94.2.4; };  # IP Tirion
    file "/var/lib/bind/db.reverse";
};
#Reload BIND di kedua node
#Tirion:
rndc reload

#Valmar:
rndc reload
#Verifikasi PTR query
#Dari klien (misal Earendil/Maglor):
dig @10.94.2.4 -x 10.94.2.2  # harus jawaban sirion.k61.com
dig @10.94.2.5 -x 10.94.2.8  # harus jawaban lindon.k61.com
dig @10.94.2.5 -x 10.94.2.9  # harus jawaban vingilot.k61.com

#Pastikan authoritative (aa flag) muncul di response.