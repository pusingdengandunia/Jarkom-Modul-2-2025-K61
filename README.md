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
