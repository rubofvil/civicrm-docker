#!/bin/bash

LOCK=/var/www/civi_install.lock

# Only initialize once
if [ -f $LOCK ]; then
  echo "App container: CiviCRM already installed."
  exit 0
fi

echo "Waiting for Database container..."
while ! mysqladmin ping --host=db --silent; do
  sleep 1
done

echo "Database container ready."

echo "Installing Drupal..."

drush -y site-install minimal \
  --account-name=${DEFAULT_ACCOUNT} \
  --account-pass=${DEFAULT_ACCOUNT_PASS} \
  --account-mail=${DEFAULT_ACCOUNT_MAIL} \
  --db-url="mysql://${MYSQL_USER}:${MYSQL_PASSWORD}@db/${MYSQL_DATABASE}" \
  --site-name=${SITE_NAME} \
  --site-mail=${SITE_MAIL}

# Harden Drupal file/folder permissions
chown -R root:www-data ${WEB_ROOT}
# Based on https://www.drupal.org/node/244924
# find ${WEB_ROOT} -type d -exec chmod u=rwx,g=rx,o= '{}' \;
# find ${WEB_ROOT} -type f -exec chmod u=rw,g=r,o= '{}' \;
# find ${WEB_ROOT}/sites -type d -name files -exec chmod ug=rwx,o= '{}' \;
# find ${WEB_ROOT}/sites/default/files -type d -exec chmod ug=rwx,o= '{}' \;
# find ${WEB_ROOT}/sites/default/files -type f -exec chmod ug=rw,o= '{}' \;
#
# From https://www.drupal.org/node/244924
# cd ${WEB_ROOT}
# chown -R root:www-data .
# find . -type d -exec chmod u=rwx,g=rx,o= '{}' \;
# find . -type f -exec chmod u=rw,g=r,o= '{}' \;
# cd ./sites/
# find . -type d -name files -exec chmod ug=rwx,o= '{}' \;
# for d in ./*/files
# do
#   find $d -type d -exec chmod ug=rwx,o= '{}' \;
#   find $d -type f -exec chmod ug=rw,o= '{}' \;
# done
#
# Based on https://civicrm.stackexchange.com/questions/168/are-there-recommended-directory-ownership-and-permission-settings-for-civicrm-fi
# find ${WEB_ROOT}/sites/default -type d -exec chmod ugo=rx '{}' \;
# find ${WEB_ROOT}/sites/default -type f -name default.settings.php -exec chmod u=rw,go=r '{}' \;
# find ${WEB_ROOT}/sites/default -type f -name civicrm.settings.php -exec chmod u=rw,go=r '{}' \;
# find ${WEB_ROOT}/sites/default/files -type d -exec chmod ug=rwx,o= '{}' \;
# find ${WEB_ROOT}/sites/default/files/civicrm -type d -exec chmod u=rwx,go=rx '{}' \;
# find ${WEB_ROOT}/sites/default/files/civicrm -type f -exec chmod u=rwx,go=rx '{}' \;
#
# From https://civicrm.stackexchange.com/questions/168/are-there-recommended-directory-ownership-and-permission-settings-for-civicrm-fi
#
# chmod 555 ${WEB_ROOT}/sites/default
# chmod 644 ${WEB_ROOT}/sites/default/default.settings.php
# chmod 644 ${WEB_ROOT}/sites/default/civicrm.settings.php
# chmod 770 ${WEB_ROOT}/sites/default/files
# chmod 755 ${WEB_ROOT}/sites/default/files/civicrm
#
# Insecure
# find ${WEB_ROOT}/sites/default/files -type d -exec chmod ugo=rwx '{}' \;
# find ${WEB_ROOT}/sites/default/files -type f -exec chmod ugo=rwx '{}' \;

echo "Finished installing Drupal."

echo "Installing CiviCRM..."

# TODO: there must be a better way...
mysql \
  --host=db \
  --user=root \
  --password=${MYSQL_ROOT_PASSWORD} \
  --execute="CREATE DATABASE ${MYSQL_DATABASE_CIVICRM};"
mysql \
  --host=db \
  --user=root \
  --password=${MYSQL_ROOT_PASSWORD} \
  --execute="GRANT ALL ON ${MYSQL_DATABASE_CIVICRM}.* TO '${MYSQL_USER}'@'%';"

drush -y civicrm-install \
  --dbuser=${MYSQL_USER} \
  --dbpass=${MYSQL_PASSWORD} \
  --dbhost=db \
  --dbname=${MYSQL_DATABASE_CIVICRM} \
  --tarfile=/var/www/civicrm.tar.gz \
  --destination=sites/all/modules \
  --site_url=${VIRTUAL_HOST} \
  --ssl=on \
  --load_generated_data=0

rm /var/www/civicrm.tar.gz

# TODO: there must be a better way....
chown -R root:www-data ${WEB_ROOT}/sites/all/modules/civicrm
chown -R root:www-data ${WEB_ROOT}/sites/default/files/civicrm
find ${WEB_ROOT}/sites/default/files/civicrm -type d -exec chmod ug=rwx,o=rx '{}' \;
find ${WEB_ROOT}/sites/default/files/civicrm -type f -exec chmod ug=rwx,o=rx '{}' \;

echo "Finished installing CiviCRM."

echo "Cleaning up..."

# TODO: verify environment is clean on next startup
unset DEFAULT_ACCOUNT
unset DEFAULT_ACCOUNT_PASS
unset DEFAULT_ACCOUNT_MAIL
unset SITE_NAME
unset SITE_MAIL
unset MYSQL_USER
unset MYSQL_PASSWORD
unset MYSQL_ROOT_PASSWORD
unset MYSQL_DATABASE
unset MYSQL_DATABASE_CIVICRM
unset WEB_ROOT
unset VIRTUAL_HOST

echo "Done!"

touch $LOCK
