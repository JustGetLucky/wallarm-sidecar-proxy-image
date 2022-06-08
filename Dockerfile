ARG UPSTREAM_TAG

FROM wallarm/ingress-collectd:${UPSTREAM_TAG} as collectd
FROM wallarm/ingress-ruby:${UPSTREAM_TAG} as ruby
FROM wallarm/ingress-nginx:${UPSTREAM_TAG}

COPY --chown=www-data:www-data conf/nginx.tmpl /etc/nginx/nginx.tmpl
COPY --chown=www-data:www-data conf/crontab /etc/supercronic/crontab
COPY --chown=www-data:www-data conf/supervisord.node.conf /etc/supervisor/supervisord.node.conf
COPY --chown=www-data:www-data conf/supervisord.helper.conf /etc/supervisor/supervisord.helper.conf
COPY  scripts /usr/local

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

RUN chmod +x /usr/local/run-nginx.sh /usr/local/run-addnode.sh /usr/local/run-node.sh \
  && apk update \
  && apk upgrade \
  && apk add --no-cache upx libcap tar iptables \
  && setcap cap_net_bind_service=+ep /usr/local/nginx/sbin/nginx \
  && setcap -v cap_net_bind_service=+ep /usr/local/nginx/sbin/nginx \
  && upx /usr/bin/supercronic \
  && curl -sL https://github.com/hairyhenderson/gomplate/releases/download/v3.10.0/gomplate_linux-amd64-slim -o /usr/bin/gomplate \
  && chmod 555 /usr/bin/gomplate \
  && curl -sL https://github.com/ochinchina/supervisord/releases/download/v0.7.3/supervisord_0.7.3_Linux_64-bit.tar.gz -o /tmp/supervisord.tar.gz \
  && tar -xf /tmp/supervisord.tar.gz -C /usr/bin --wildcards --no-anchored 'supervisord' --strip-components 1 && rm /tmp/supervisord.tar.gz \
  && chmod 555 /usr/bin/supervisord && chown root:root /usr/bin/supervisord \
  && apk del libcap tar upx curl \
  && rm -rf /var/cache/apk/* \
  && mkdir /var/log/wallarm \
  && chown www-data:www-data /var/log/wallarm


