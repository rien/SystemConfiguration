server {
    listen 80;
    server_name ebooks.rxn.be;
    access_log /var/log/nginx/ebooks-access.log main;
    root /srv/http/ebooks;

    sendfile on;
    

    location / {
        autoindex on;
        disable_symlinks off;
    }
}
