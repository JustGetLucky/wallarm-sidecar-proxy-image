#!/bin/sh
gomplate -f "/etc/nginx/nginx.tmpl" -o "/etc/nginx/nginx.conf" --verbose
ln -sf /dev/stdout /var/log/nginx/access.log
ln -sf /dev/stderr /var/log/nginx/error.log
exec nginx -g 'daemon off;'