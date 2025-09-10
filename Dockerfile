FROM docker.io/litespeedtech/openlitespeed:1.8.4-lsphp84

ENV WP_ROOT=/var/www/vhosts/localhost/html

ADD https://wordpress.org/wordpress-6.8.2.tar.gz /tmp/wordpress.tar.gz

COPY root/ /

RUN tar -xzf /tmp/wordpress.tar.gz -C ${WP_ROOT} --strip-components=1 \
  && mkdir -p ${WP_ROOT}/wp-content \
  && chown -R www-data:www-data ${WP_ROOT} \
  && chown root:root /entrypoint.sh \
  && chmod +x /entrypoint.sh \
  && find ${WP_ROOT} -type d -exec chmod 0775 {} \; \
  && find ${WP_ROOT} -type f -exec chmod 0664 {} \;

WORKDIR /usr/local/lsws
ENV HOME=/usr/local/lsws
