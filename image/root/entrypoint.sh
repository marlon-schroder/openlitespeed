#!/usr/bin/env bash

set -e

WP_CONFIG="/var/www/vhosts/localhost/html/wp-config.php"

DB_NAME="${WORDPRESS_DB_NAME:-wordpress}"
DB_USER="${WORDPRESS_DB_USER:-wordpress}"
DB_PASSWORD="${WORDPRESS_DB_PASSWORD:-wordpress}"
DB_HOST="${WORDPRESS_DB_HOST:-mariadb:3306}"

WP_HOME="${WORDPRESS_HOME:-http://localhost}"
WP_SITEURL="${WORDPRESS_SITEURL:-http://localhost}"

WP_MEMORY_LIMIT="${WORDPRESS_MEMORY_LIMIT=:-256M}"
WP_DEBUG="${WORDPRESS_DEBUG:-false}"

REDIS_PORT="${WORDPRESS_REDIS_PORT:-6379}"

AUTH_KEY="${WORDPRESS_AUTH_KEY:-$(openssl rand -base64 32)}"
SECURE_AUTH_KEY="${WORDPRESS_SECURE_AUTH_KEY:-$(openssl rand -base64 32)}"
LOGGED_IN_KEY="${WORDPRESS_LOGGED_IN_KEY:-$(openssl rand -base64 32)}"
NONCE_KEY="${WORDPRESS_NONCE_KEY:-$(openssl rand -base64 32)}"
AUTH_SALT="${WORDPRESS_AUTH_SALT:-$(openssl rand -base64 32)}"
SECURE_AUTH_SALT="${WORDPRESS_SECURE_AUTH_SALT:-$(openssl rand -base64 32)}"
LOGGED_IN_SALT="${WORDPRESS_LOGGED_IN_SALT:-$(openssl rand -base64 32)}"
NONCE_SALT="${WORDPRESS_NONCE_SALT:-$(openssl rand -base64 32)}"

cat >"$WP_CONFIG" <<EOL
<?php
define('DB_NAME', '${DB_NAME}');
define('DB_USER', '${DB_USER}');
define('DB_PASSWORD', '${DB_PASSWORD}');
define('DB_HOST', '${DB_HOST}');
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');

define('WP_HOME', '${WP_HOME}');
define('WP_SITEURL', '${WP_SITEURL}');

define('WP_MEMORY_LIMIT', '${WP_MEMORY_LIMIT}');
define('WP_DEBUG', ${WP_DEBUG});

define('AUTH_KEY', '${AUTH_KEY}');
define('SECURE_AUTH_KEY', '${SECURE_AUTH_KEY}');
define('LOGGED_IN_KEY', '${LOGGED_IN_KEY}');
define('NONCE_KEY', '${NONCE_KEY}');
define('AUTH_SALT', '${AUTH_SALT}');
define('SECURE_AUTH_SALT', '${SECURE_AUTH_SALT}');
define('LOGGED_IN_SALT', '${LOGGED_IN_SALT}');
define('NONCE_SALT', '${NONCE_SALT}');

\$table_prefix = 'wp_';
EOL

if [ -n "${WORDPRESS_REDIS_HOST}" ]; then
  cat >>"$WP_CONFIG" <<EOL
define('WP_CACHE', true);
define('WORDPRESS_REDIS_HOST', '${WORDPRESS_REDIS_HOST}');
define('WORDPRESS_REDIS_PORT', '${REDIS_PORT}');
EOL
fi

cat >>"$WP_CONFIG" <<'EOL'
if (!defined('ABSPATH')) {
  define('ABSPATH', __DIR__ . '/');
}

require_once ABSPATH . 'wp-settings.php';
EOL

chown www-data:www-data "$WP_CONFIG"
chmod 644 "$WP_CONFIG"

#################################
## Default image entrypoint.sh ##
#################################
if [ -z "$(ls -A -- "/usr/local/lsws/conf/")" ]; then
  cp -R /usr/local/lsws/.conf/* /usr/local/lsws/conf/
fi
if [ -z "$(ls -A -- "/usr/local/lsws/admin/conf/")" ]; then
  cp -R /usr/local/lsws/admin/.conf/* /usr/local/lsws/admin/conf/
fi

chown 994:994 /usr/local/lsws/conf -R
chown 994:1001 /usr/local/lsws/admin/conf -R

/usr/local/lsws/bin/lswsctrl start "$@"

while true; do
  if ! /usr/local/lsws/bin/lswsctrl status | grep 'litespeed is running with PID *' >/dev/null; then
    break
  fi
  sleep 60
done
