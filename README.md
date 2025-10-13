# Nomor 11 – Sirion sebagai Reverse Proxy (Path-Based Routing)
Di node Sirion, kita diminta mengonfigurasi reverse proxy Nginx dengan:

Domain yang diterima: `www.k61.com dan sirion.k61.com`

Routing berbasis path:

/static diarahkan ke Lindon `(10.94.2.6)`

/app diarahkan ke Vingilot `(10.94.2.7)`

Header Host dan X-Real-IP harus diteruskan ke backend.

Hasil akhirnya: konten dari /static dan /app muncul dari server yang sesuai.

## Langkah Eksekusi / Implementasi

### 1. instalasi Nginx di Sirion
`apt install nginx -y`


### 2.Membuat konfigurasi reverse proxy
`File: /etc/nginx/sites-available/sirion.conf`

```server {
    listen 80;
    server_name www.k61.com sirion.k61.com;

    location /static/ {
        proxy_pass http://10.94.2.6/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /app/ {
        proxy_pass http://10.94.2.7/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 3. Aktifkan konfigurasi dan reload Nginx
```
ln -s /etc/nginx/sites-available/sirion.conf /etc/nginx/sites-enabled/
nginx -t
nginx -s reload
```

### 4. Tambahkan DNS lokal atau hosts

`echo "10.94.2.2 www.k61.com sirion.k61.com" >> /etc/hosts`

## Pengujian
### Tes DNS resolusi
`getent hosts www.k61.com`

### Test Local Connection
```
curl http://10.94.2.6/
curl http://10.94.2.7/
curl http://www.k61.com/static/
curl http://www.k61.com/app/
```

# Soal Nomor 12 — Basic Authentication pada Path /admin
## Tujuan

Menerapkan proteksi akses dengan Basic Authentication pada path /admin yang berada di balik reverse proxy Sirion, agar:
Hanya pengguna dengan kredensial yang benar dapat mengakses halaman /admin.
Akses tanpa autentikasi ditolak (HTTP 401 Unauthorized).
Akses dengan username dan password yang valid diteruskan ke backend (Vingilot).

## Analisis Soal

- Sirion berperan sebagai reverse proxy untuk domain www.k61.com.
- Path /admin harus memiliki lapisan proteksi tambahan berupa Basic Authentication.
- Basic Auth dikonfigurasi di level Nginx (Sirion), bukan di backend.
- File kredensial disimpan di /etc/nginx/.htpasswd.

## Langkah Implementasi
### 1. Membuat File Kredensial

Gunakan tool htpasswd (dari paket apache2-utils):
`apt install apache2-utils -y`]

`htpasswd -c /etc/nginx/.htpasswd admin`


Masukkan password misalnya `admin900900`.

File .htpasswd akan berisi hash terenkripsi dari password admin.

### 2. Mengedit Konfigurasi Nginx di Sirion

Buka file:
`nano /etc/nginx/sites-available/sirion.conf`

Update konfigurasi lengkap:
```
server {
    listen 80;
    server_name www.k61.com sirion.k61.com;

    # Routing untuk Lindon (/static)
    location /static/ {
        proxy_pass http://10.94.2.6/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # Routing untuk Vingilot (/app)
    location /app/ {
        proxy_pass http://10.94.2.7/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # Proteksi Basic Auth untuk /admin
    location /admin/ {
        auth_basic "Restricted Area";
        auth_basic_user_file /etc/nginx/.htpasswd;

        proxy_pass http://10.94.2.7/admin/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```
### 3️. Mengecek dan Reload Konfigurasi

Cek sintaks:
`nginx -t`


Reload service:

`nginx -s reload`

### 4. Pengujian Akses

Tanpa kredensial:

```curl -I http://www.k61.com/admin/```


Output:
```
HTTP/1.1 401 Unauthorized
WWW-Authenticate: Basic realm="Restricted Area"
```

Dengan kredensial (tapi salah wskowksowks):
```
curl -u admin:admin123 http://www.k61.com/admin/
```
Output:
```
HTTP/1.1 401 Unauthorized
WWW-Authenticate: Basic realm="Restricted Area"
```
Dengan kredensial (yang bener):
```
curl -u admin:admin123 http://www.k61.com/admin/
```

Output:
```
<h2>Selamat Datang di Halaman Admin Sound Horeg!</h2>
<p>Server: 10.94.2.7</p>
```


# Soal Nomor 13 - Kanokasi Endpoint

### Permasalahan yang Diberikan:

“Kanonisasikan endpoint, akses melalui IP address Sirion maupun sirion.<xxxx>.com harus redirect 301 ke www
.<xxxx>.com sebagai hostname kanonik.”

### Tujuan:
Menetapkan www.k61.com
 sebagai host kanonik utama.
Semua akses ke:
```
IP (http://10.94.2.5/)
```
Domain non-www `(http://sirion.k61.com/)`
harus otomatis redirect `301` ke `http://www.k61.com/`

### Langkah Implementasi yang Kita Lakukan

### 1, Tambahkan `IP alias 10.94.2.5 ke eth0` agar Sirion bisa menerima koneksi di IP itu:

`ip addr add 10.94.2.5/24 dev eth0`


### 2.Konfigurasi dua blok server di `/etc/nginx/sites-available/sirion.conf`:

Blok redirect (non-kanonik):
```bash
server {
    listen 80;
    server_name 10.94.2.5 sirion.k61.com;
    return 301 http://www.k61.com$request_uri;
}
```


Blok utama (kanonik):
```
server {
    listen 80;
    server_name www.k61.com;
    location / { proxy_pass http://10.94.2.7/; }
}
```

### 3. Reload nginx agar konfigurasi baru aktif:
```bash
nginx -s reload
```

Verifikasi dengan curl:

`curl -I http://10.94.2.5/`


Hasilnya HTTP/1.1 301 Moved Permanently menuju Location: `http://www.k61.com/`.

Hasil Akhir:

`IP 10.94.2.5` → Redirect ke `www.k61.com` 

Domain `sirion.k61.com` → Redirect `ke www.k61.com` 

Hanya `www.k61.com` yang menjadi endpoint kanonik. 


# Soal Nomor 14 - Log Tail
“Catatan Kedatangan Harus Jujur” – Logging IP Asli Klien di Vingilot
### Tujuan

Memastikan bahwa server Vingilot (backend aplikasi) dapat mencatat IP address asli klien pada access log, meskipun trafik masuk melewati reverse proxy Sirion.
Dengan kata lain, log di Vingilot tidak menampilkan IP Sirion (10.94.2.2), melainkan alamat IP pengguna yang sebenarnya.
### Ditanya?

“Pastikan access log aplikasi di Vingilot mencatat IP address klien asli saat lalu lintas melewati Sirion (bukan IP Sirion).”

### Artinya kita harus mengatur:

Sirion sebagai reverse proxy yang meneruskan IP klien lewat header
Vingilot sebagai web server backend yang membaca header tersebut untuk dicatat di access log.

### Langkah Implementasi
### 1.Konfigurasi di Sirion

File: `/etc/nginx/sites-available/sirion.conf`

Sirion sudah berfungsi sebagai reverse proxy untuk `/static, /app, dan /admin.`

Kita tambahkan tiga header penting:

X-Real-IP → membawa IP asli klien

X-Forwarded-For → mendukung proxy chain

Host → agar hostname tetap sama
```
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
```

➡ Ini memastikan informasi IP asli klien dikirim ke backend (Lindon/Vingilot).

### 2. Konfigurasi di Vingilot

File: /etc/nginx/sites-available/vingilot.conf

Buat custom log format bernama main:

log_format main '$http_x_real_ip - $remote_user [$time_local] "$request" '
                '$status $body_bytes_sent "$http_referer" '
                '"$http_user_agent" "$http_x_forwarded_for"';


Gunakan format log tersebut di access log:

access_log /var/log/nginx/access.log main;


Jalankan PHP-FPM untuk aplikasi /app atau /admin.

### 3. Testing

Jalankan:
```
curl http://www.k61.com/app/
```

Lalu di Vingilot cek log:
```
tail -n 5 /var/log/nginx/access.log
```

### Hasil Diharapkan:

#### Kolom IP di log menunjukkan IP asli klien (10.94.2.x atau host luar)
```
Bukan IP Sirion (10.94.2.2)
```
## Kesimpulan

Sirion berhasil meneruskan header IP klien dengan proxy_set_header.

Vingilot mencatat IP asli berkat custom log format.

#### Access log kini jujur, sesuai permintaan soal: IP yang tercatat adalah IP pengguna sebenarnya,bukan IP dari reverse proxy.

### File Terlibat :
```/etc/nginx/sites-available/sirion.conf```

```/etc/nginx/sites-available/vingilot.conf```

```/var/log/nginx/access.log```
### Uji akhir:
```tail -n 5 /var/log/nginx/access.log``` menunjukkan IP asli klien.


