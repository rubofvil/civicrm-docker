#!/bin/bash

LOCK=/var/www/civi_install.lock

# Only initialize once
if [ ! -f $LOCK ]; then
  /usr/local/bin/civi_install.sh
fi

echo "CiviCRM is now running."

while true; do sleep 1000; done
