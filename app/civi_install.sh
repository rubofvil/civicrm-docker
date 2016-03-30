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
cd ${WEB_ROOT}
chown -R root:www-data .
find . -type d -exec chmod u=rwx,g=rx,o= '{}' \;
find . -type f -exec chmod u=rw,g=r,o= '{}' \;
cd ./sites/
find . -type d -name files -exec chmod ug=rwx,o= '{}' \;
for d in ./*/files
do
  find $d -type d -exec chmod ug=rwx,o= '{}' \;
  find $d -type f -exec chmod ug=rw,o= '{}' \;
done

echo "Finished installing Drupal."

echo "Installing CiviCRM..."

drush variable-set maintenance_mode 1
drush cache-clear all

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

drush variable-set maintenance_mode 0
drush cache-clear all

echo "Finished installing CiviCRM."

echo "Cleaning up."

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
