FROM wordpress:6.8.3-php8.2-apache

# Installiere erforderliche Pakete und PHP-Erweiterungen
RUN apt-get update && apt-get install -y \
    libgmp-dev \
    git \
    unzip \
    wget \
    curl \
    default-mysql-client \
    && docker-php-ext-install bcmath gmp \
    && rm -rf /var/lib/apt/lists/*

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Install Composer (/usr/local/bin)
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Create wp-content directory if it doesn't exist
RUN mkdir -p /var/www/html/wp-content/plugins

# Custom plugin initialization script
COPY init-plugins.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init-plugins.sh

# Custom entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]