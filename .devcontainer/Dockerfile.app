ARG DOCKER_HUB_DOMAIN=docker.io/library
FROM ${DOCKER_HUB_DOMAIN}/php:8.2-apache AS base

# Install system dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    bash \
    git \
    openssh-client \
    procps \
    libpq-dev \
    libzip-dev \
    libicu-dev \
    unzip \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install \
    pdo \
    pdo_pgsql \
    pgsql \
    intl \
    zip \
    opcache

# Install Docker CLI
COPY .devcontainer/_data/docker-ce-cli.deb /tmp/
RUN apt-get update \
    && apt-get install -y /tmp/docker-ce-cli.deb \
    && rm /tmp/docker-ce-cli.deb

# Enable Apache modules
RUN a2enmod rewrite

# Install Composer
COPY .devcontainer/_data/composer.phar /usr/local/bin/composer
RUN chmod +x /usr/local/bin/composer

# Configure Apache DocumentRoot
ENV APACHE_DOCUMENT_ROOT=/app/public
RUN sed -ri -e "s!/var/www/html!${APACHE_DOCUMENT_ROOT}!g" /etc/apache2/sites-available/*.conf
RUN sed -ri -e "s!/var/www/!${APACHE_DOCUMENT_ROOT}!g" /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

CMD ["bash", "/app/.devcontainer/_scripts/cmd-app.sh"]

WORKDIR /app

# scenario-mapped: code is mounted via volume at runtime
FROM base AS mapped

# Install Xdebug (dev only)
COPY .devcontainer/_data/xdebug-3.3.2.tgz /tmp/
RUN cd /tmp \
    && tar -xzf xdebug-3.3.2.tgz \
    && cd xdebug-3.3.2 \
    && phpize \
    && ./configure \
    && make \
    && make install \
    && docker-php-ext-enable xdebug \
    && rm -rf /tmp/xdebug-3.3.2 /tmp/xdebug-3.3.2.tgz

# scenario-embeded: code is baked into the image at build time
FROM base AS embeded
COPY composer.json composer.lock symfony.lock /app/
RUN composer install --no-interaction --prefer-dist --optimize-autoloader --no-dev --no-scripts
COPY . /app
RUN mkdir -p /app/var/cache /app/var/log \
    && php bin/console cache:warmup \
    && chown -R www-data:www-data /app/var
