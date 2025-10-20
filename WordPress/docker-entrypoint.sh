#!/bin/bash
set -euo pipefail

# Start the original WordPress entrypoint in the background
# The original WordPress entrypoint is at /usr/local/bin/docker-entrypoint.sh from the base image
# But since we overwrote it, we need to call the original one differently
# Let's start Apache and WordPress initialization directly

# First, run the original WordPress initialization logic
# This is essentially what the original entrypoint does
if [[ "$1" == apache* ]] || [[ "$1" == php-fpm* ]]; then
    # Initialize WordPress if it's not already done
    if [ ! -e /var/www/html/index.php ] && [ ! -e /var/www/html/wp-includes/version.php ]; then
        # Copy WordPress files
        echo "WordPress not found in /var/www/html - copying now..."
        tar --create --file - --directory /usr/src/wordpress --owner www-data --group www-data . | tar --extract --file -
        echo "Complete! WordPress has been successfully copied to /var/www/html"
    fi

    # Setup wp-config.php if it doesn't exist
    if [ ! -e /var/www/html/wp-config.php ]; then
        awk '
            /^\/\*.*stop editing.*\*\/$/ && c == 0 {
                c = 1
                system("cat")
                system("echo")
            }
            { print }
        ' /var/www/html/wp-config-sample.php > /var/www/html/wp-config.php <<'EOPHP'
// If we're behind a proxy server and using HTTPS, we need to alert WordPress of that fact
// see also https://wordpress.org/support/article/administration-over-ssl/#using-a-reverse-proxy
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    $_SERVER['HTTPS'] = 'on';
}
EOPHP
    fi

    # Set up WordPress database configuration
    set_config() {
        key="$1"
        value="$2"
        php -r "
        \$config = file_get_contents('/var/www/html/wp-config.php');
        \$config = preg_replace(
            '/define\s*\(\s*[\'\"]' . preg_quote(\$argv[1], '/') . '[\'\"].*?\);/i',
            'define(' . var_export(\$argv[1], true) . ', ' . var_export(\$argv[2], true) . ');',
            \$config
        );
        file_put_contents('/var/www/html/wp-config.php', \$config);
        " "$key" "$value"
    }

    # Configure database settings
    if [ "$WORDPRESS_DB_HOST" ]; then
        set_config 'DB_HOST' "$WORDPRESS_DB_HOST"
    fi
    if [ "$WORDPRESS_DB_USER" ]; then
        set_config 'DB_USER' "$WORDPRESS_DB_USER"
    fi
    if [ "$WORDPRESS_DB_PASSWORD" ]; then
        set_config 'DB_PASSWORD' "$WORDPRESS_DB_PASSWORD"
    fi
    if [ "$WORDPRESS_DB_NAME" ]; then
        set_config 'DB_NAME' "$WORDPRESS_DB_NAME"
    fi

    # Fix permissions
    chown -R www-data:www-data /var/www/html
fi

# Start Apache in the background
apache2-foreground &
APACHE_PID=$!

# Wait for WordPress and database to be ready
echo "Waiting for WordPress to initialize..."
while [ ! -f /var/www/html/wp-config.php ]; do
    sleep 2
done

# Wait for database to be ready
echo "Waiting for database connection..."
sleep 10

# Run our initialization script
echo "Running plugin initialization..."
/usr/local/bin/init-plugins.sh

# Wait for Apache to finish
wait $APACHE_PID