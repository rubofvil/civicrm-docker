# Docker - Drupal+CiviCRM
#
# copy https://github.com/docker-library/drupal/blob/master/7/fpm/Dockerfile replacing the php , to avoid the upgrade of php
FROM php:5.6-fpm

# install the PHP extensions we need
RUN set -ex \
	&& buildDeps=' \
		libjpeg62-turbo-dev \
		libpng12-dev \
		libpq-dev \
	' \
	&& apt-get update && apt-get install -y --no-install-recommends $buildDeps && rm -rf /var/lib/apt/lists/* \
	&& docker-php-ext-configure gd \
		--with-jpeg-dir=/usr \
		--with-png-dir=/usr \
	&& docker-php-ext-install -j "$(nproc)" gd mbstring pdo pdo_mysql pdo_pgsql zip \
# PHP Warning:  PHP Startup: Unable to load dynamic library '/usr/local/lib/php/extensions/no-debug-non-zts-20151012/gd.so' - libjpeg.so.62: cannot open shared object file: No such file or directory in Unknown on line 0
# PHP Warning:  PHP Startup: Unable to load dynamic library '/usr/local/lib/php/extensions/no-debug-non-zts-20151012/pdo_pgsql.so' - libpq.so.5: cannot open shared object file: No such file or directory in Unknown on line 0
	&& apt-mark manual \
		libjpeg62-turbo \
		libpq5 \
	&& apt-get purge -y --auto-remove $buildDeps

WORKDIR /var/www/html

# https://www.drupal.org/node/3060/release
ENV DRUPAL_VERSION 7.56
ENV DRUPAL_MD5 5d198f40f0f1cbf9cdf1bf3de842e534

RUN curl -fSL "https://ftp.drupal.org/files/projects/drupal-${DRUPAL_VERSION}.tar.gz" -o drupal.tar.gz \
	&& echo "${DRUPAL_MD5} *drupal.tar.gz" | md5sum -c - \
	&& tar -xz --strip-components=1 -f drupal.tar.gz \
	&& rm drupal.tar.gz \
	&& chown -R www-data:www-data sites



# VERSION 0.0.1
MAINTAINER William Hale <salt@snowdrift.coop>

# Disable PHP daemon mode
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /usr/local/etc/php-fpm.conf

# Install Packages
RUN DEBIAN_FRONTEND="noninteractive" apt-get update \
  && apt-get install -y apt-utils \
  && apt-get install -y \
    cron \
    libc-client-dev \
    libkrb5-dev \
    libicu-dev \
    libmcrypt-dev \
    libxml2-dev \
    mariadb-client \
    ssmtp

# Install additional PHP extentions
RUN docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
  && docker-php-ext-install imap intl mcrypt mysqli soap

# Install ssmtp
COPY ssmtp.conf /etc/ssmtp/ssmtp.conf
RUN chown root:mail /etc/ssmtp/ssmtp.conf \
  && chmod 640 /etc/ssmtp/ssmtp.conf \
  && usermod -a -G mail www-data \
  && echo 'sendmail_path = "/usr/sbin/ssmtp -t"' > /usr/local/etc/php/conf.d/mail.ini

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php \
  && mv composer.phar /usr/local/bin/composer

# Install Drush
RUN curl -fSL http://files.drush.org/drush.phar -o /usr/local/bin/drush \
  && chmod +x /usr/local/bin/drush \
  && curl -fSL https://raw.githubusercontent.com/civicrm/civicrm-drupal/7.x-master/drush/civicrm.drush.inc -o /usr/share/drush/commands/civicrm.drush.inc --create-dirs
# COPY civicrm.drush.inc /usr/share/drush/commands/civicrm.drush.inc

# Download CiviCRM
ENV CIVICRM_VERSION 4.7.17
RUN curl -fSL "https://download.civicrm.org/civicrm-${CIVICRM_VERSION}-drupal.tar.gz" -o /var/www/civicrm.tar.gz

# Install default error pages
COPY 404.html /var/www/html/404.html
COPY 50x.html /var/www/html/50x.html

# Install maintenance scripts
COPY civi_install.sh /usr/local/bin/civi_install.sh
COPY civi_run.sh /usr/local/bin/civi_run.sh
COPY civi_upgrade.sh /usr/local/bin/civi_upgrade.sh
RUN chmod +x /usr/local/bin/civi_install.sh \
  && chmod +x /usr/local/bin/civi_run.sh \
  && chmod +x /usr/local/bin/civi_upgrade.sh

# Enable Cron
COPY civi_cron.sh /usr/local/bin/civi_cron.sh
COPY crontab /etc/cron.d/crontab
RUN chmod +x /usr/local/bin/civi_cron.sh \
  && chmod +x /etc/cron.d/crontab \
  && crontab /etc/cron.d/crontab

# Cleanup
RUN apt-get clean \
  && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/*

LABEL Description="Docker for Snowdrift.coop CRM. Debian Jessie+nginx+MariaDB+PHP5.6+Drupal7/Drush+CiviCRM" \
  Version="0.0.1"

CMD ["/usr/local/bin/civi_run.sh"]
