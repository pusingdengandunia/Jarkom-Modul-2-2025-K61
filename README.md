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



