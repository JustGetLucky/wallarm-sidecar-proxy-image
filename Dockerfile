ARG UPSTREAM_TAG

FROM wallarm/ingress-collectd:${UPSTREAM_TAG} as collectd
FROM wallarm/ingress-ruby:${UPSTREAM_TAG} as ruby
FROM wallarm/ingress-nginx:${UPSTREAM_TAG} as nginx
RUN apk add binutils upx \
    && find /usr/local -maxdepth 3 -type f -size +1024k -name '*.so*' -exec objcopy --strip-debug {} \; \
    && find /usr/local/bin -type f -size +1024k -executable -exec upx {} \;

FROM alpine:3.14.4

# Copy files and set env vars for Nginx
COPY --from=nginx /usr/local /usr/local
COPY --from=nginx /opt /opt
COPY --from=nginx /etc/nginx /etc/nginx
COPY --from=nginx /usr/share/nginx/html/wallarm_blocked.html /usr/share/nginx/html/
ENV LUA_PATH="/usr/local/share/luajit-2.1.0-beta3/?.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/lib/lua/?.lua;;"
ENV LUA_CPATH="/usr/local/lib/lua/?/?.so;/usr/local/lib/lua/?.so;;"

# Copy scripts and set env for collectd
COPY --from=collectd /opt/wallarm/collectd /opt/wallarm/collectd
ENV PYTHONPATH=/opt/wallarm/collectd/usr/lib/python3.9 \
    PYTHONHOME=/opt/wallarm/collectd/usr/ \
    WALLARM_DONT_READ_ETC_ENV=true \
    SSL_CERT_DIR=/opt/wallarm/collectd/etc/ssl/certs

# Copy scripts and set env for Ruby
COPY --from=ruby /opt/wallarm/ruby /opt/wallarm/ruby
COPY --from=ruby /bin/supercronic /usr/bin/supercronic
ENV GEM_PATH="/opt/wallarm/ruby/var/lib/gems/2.7.0:/opt/wallarm/ruby/usr/local/lib/ruby/gems/2.7.0:/opt/wallarm/ruby/usr/lib/ruby/gems/2.7.0:/opt/wallarm/ruby/usr/lib/x86_64-linux-gnu/ruby/gems/2.7.0:/opt/wallarm/ruby/usr/share/rubygems-integration/2.7.0:/opt/wallarm/ruby/usr/share/rubygems-integration/all:/opt/wallarm/ruby/usr/lib/x86_64-linux-gnu/rubygems-integration/2.7.0" \
    RUBYLIB="/opt/wallarm/ruby/usr/local/lib/site_ruby/2.7.0:/opt/wallarm/ruby/usr/local/lib/x86_64-linux-gnu/site_ruby:/opt/wallarm/ruby/usr/local/lib/site_ruby:/opt/wallarm/ruby/usr/lib/ruby/vendor_ruby/2.7.0:/opt/wallarm/ruby/usr/lib/x86_64-linux-gnu/ruby/vendor_ruby/2.7.0:/opt/wallarm/ruby/usr/lib/ruby/vendor_ruby:/opt/wallarm/ruby/usr/lib/ruby/2.7.0:/opt/wallarm/ruby/usr/lib/x86_64-linux-gnu/ruby/2.7.0"

# Create ww-data user
RUN adduser -S -D -H -u 101 -h /usr/local/nginx -s /sbin/nologin -G www-data -g www-data www-data

# Copy local scripts
COPY --chown=www-data:www-data conf/nginx.tmpl /etc/nginx/nginx.tmpl
COPY --chown=www-data:www-data conf/crontab.tmpl /etc/supercronic/crontab.tmpl
COPY --chown=www-data:www-data conf/supervisord.node.conf /etc/supervisor/supervisord.node.conf
COPY --chown=www-data:www-data conf/supervisord.helper.conf /etc/supervisor/supervisord.helper.conf
COPY  scripts /usr/local

RUN chmod +x /usr/local/run-*.sh \
  && apk update \
  && apk upgrade \
  && apk add --no-cache \
  upx \
  libcap \
  tar \
  iptables \
  bash \
  openssl \
  pcre \
  zlib \
  geoip \
  curl \
  ca-certificates \
  patch \
  yajl \
  lmdb \
  libxml2 \
  libmaxminddb \
  yaml-cpp \
  tzdata \
  && setcap cap_net_bind_service=+ep /usr/local/nginx/sbin/nginx \
  && setcap -v cap_net_bind_service=+ep /usr/local/nginx/sbin/nginx \
  && upx /usr/bin/supercronic \
  && curl -sL https://github.com/hairyhenderson/gomplate/releases/download/v3.10.0/gomplate_linux-amd64-slim -o /usr/bin/gomplate \
  && chmod 555 /usr/bin/gomplate \
  && curl -sL https://github.com/ochinchina/supervisord/releases/download/v0.7.3/supervisord_0.7.3_Linux_64-bit.tar.gz -o /tmp/supervisord.tar.gz \
  && tar -xf /tmp/supervisord.tar.gz -C /usr/bin --wildcards --no-anchored 'supervisord' --strip-components 1 && rm /tmp/supervisord.tar.gz \
  && chmod 555 /usr/bin/supervisord && chown root:root /usr/bin/supervisord \
  && apk del libcap tar upx \
  && rm -rf /var/cache/apk/* \
  && ln -s /usr/local/nginx/sbin/nginx /sbin/nginx \
  && bash -eu -c ' \
  writeDirs=( \
  /var/log/nginx \
  /var/lib/nginx/body \
  /var/lib/nginx/fastcgi \
  /var/lib/nginx/proxy \
  /var/lib/nginx/scgi \
  /var/lib/nginx/uwsgi \
  /var/log/audit \
  /var/log/wallarm \
  ); \
  for dir in "${writeDirs[@]}"; do \
  mkdir -p ${dir}; \
  chown -R www-data.www-data ${dir}; \
  done'


