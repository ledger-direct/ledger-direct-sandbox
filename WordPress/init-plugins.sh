#!/bin/bash
set -e

# Wait for database connectivity
until wp db check --allow-root --skip-ssl; do
  sleep 2
done

# Install WooCommerce plugin, if not already installed
if ! wp plugin is-installed woocommerce --allow-root; then
  wp plugin install woocommerce --activate --allow-root
fi

# Install Ledger Direct plugin, if not already installed
if [ ! -d /var/www/html/wp-content/plugins/ledger-direct ]; then
  git clone https://github.com/ledger-direct/ledger-direct-woocommerce.git /var/www/html/wp-content/plugins/ledger-direct
  cd /var/www/html/wp-content/plugins/ledger-direct
  composer install --no-dev --no-scripts --optimize-autoloader
  wp plugin activate ledger-direct --allow-root
fi

echo "Plugin initialization completed successfully!"