#ikut config atasnya
#cek error : 
#(TIRION)
named-checkzone k61.com /etc/bind/zones/db.k61.com
#kalau OK (aman)

nano /etc/bind/zones/db.k61.com                                                         
$TTL 604800
@   IN  SOA ns1.k61.com. root.k61.com. (
        2025101204 ; Serial
        604800     ; Refresh
        86400      ; Retry
        2419200    ; Expire
        604800 )   ; Negative Cache TTL

; =========================
;  ZONE: k61.com
; =========================
@       IN  NS  ns1.k61.com.
@       IN  NS  ns2.k61.com.

; A records
sirion  IN  A   10.94.2.2
ns1     IN  A   10.94.2.4          ; Tirion (ns1)
ns2     IN  A   10.94.2.5          ; Valmar (ns2)
lindon  IN  A   10.94.2.6          ; Web statis
vingilot IN A   10.94.2.7          ; Web dinamis

; ===== CNAMEs =====
www     IN  CNAME  sirion.k61.com.
static  IN  CNAME  lindon.k61.com.
app     IN  CNAME  vingilot.k61.com.

#/usr/sbin/named -u bind -c /etc/bind/named.conf 
#(untuk reload)
#rdnc reload (untuk reload, jika bind sudah jalan)
