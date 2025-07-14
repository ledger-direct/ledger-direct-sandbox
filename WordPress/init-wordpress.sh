#!/bin/bash

# Wait for the database
echo "Waiting for the database..."
while ! mysqladmin ping -h"$WORDPRESS_DB_HOST" -u"$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_PASSWORD" --silent; do
    sleep 1
done

echo "Database is ready!"

# Start Apache in the background
apache2-foreground &

# Wait until WordPress is available
echo "Waiting for WordPress..."
while ! curl -f http://localhost/wp-admin/install.php >/dev/null 2>&1; do
    sleep 2
done

echo "WordPress is ready!"

# WordPress setup (if not already installed)
if ! wp core is-installed --path=/var/www/html --allow-root 2>/dev/null; then
    echo "Installing WordPress..."
    wp core install \
        --path=/var/www/html \
        --url=http://localhost:8080 \
        --title="WordPress Development Site" \
        --admin_user=admin \
        --admin_password=admin \
        --admin_email=admin@example.com \
        --allow-root
fi

# Install WooCommerce if not already installed
if ! wp plugin is-installed woocommerce --path=/var/www/html --allow-root; then
    echo "Installing WooCommerce..."
    wp plugin install woocommerce --activate --path=/var/www/html --allow-root
fi

# Install Ledger Direct Plugin
PLUGIN_DIR="/var/www/html/wp-content/plugins/ledger-direct-woocommerce"
if [ ! -d "$PLUGIN_DIR" ]; then
    echo "Installing Ledger Direct Plugin..."
    cd /var/www/html/wp-content/plugins/
    git clone https://github.com/ledger-direct/ledger-direct-woocommerce.git
    chown -R www-data:www-data ledger-direct-woocommerce/
fi

# Activate the plugin
echo "Activating Ledger Direct Plugin..."
wp plugin activate ledger-direct-woocommerce --path=/var/www/html --allow-root

# Basic configuration for Ledger Direct (adjust as needed)
echo "Configuring Ledger Direct Plugin..."
wp option update ledger_direct_enabled 1 --path=/var/www/html --allow-root
wp option update ledger_direct_test_mode 1 --path=/var/www/html --allow-root

echo "Setup completed!"

# Wait for Apache
wait