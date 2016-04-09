# CiviCRM + Docker
This application was built for [Snowdrift.coop](https://snowdrift.coop/), it is heavily based on previous work by [djcf](https://github.com/djcf/civicrm-docker). However, it differs from djcf's version in that it focuses on [Drupal](https://www.drupal.org/) and uses [Drush](http://www.drush.org/) instead of [civicrm-buildkit](https://github.com/civicrm/civicrm-buildkit) for installation and configuration.

The current implementation keeps with the Docker design principles of being:

* **simple** - installs only what is needed

* **composable** - web server and database in separate containers

* **automateable** - requires no manual build steps

Everything should be well documented and straightforward. In addition, I have tried to rely on official builds as much as possible, all of which currently run on Debian Jessie.

# Architecture
The composition is made up of three separate containers:

* **Application** - based on official [Drupal:7-fpm](https://hub.docker.com/_/drupal) image. Modified to load additional PHP extensions, install Drush, download CiviCRM, and run a post-build initialization script.

* **Database** - linked from official [MariaDB:latest](https://hub.docker.com/_/mariadb/) image.

* **Web Server** - based on official [nginx:latest](https://hub.docker.com/_/nginx/) image. Modified to load CiviCRM specific configuration.

In theory, the database and web server containers could be swapped for any variants which CiviCRM supports.

# How to Use
```
$ git clone https://github.com/altsalt/civicrm-docker && cd civicrm-docker
```

Update the environment variable files located underneath /env with your preferences.

Update the email configuration file located at /app/ssmtp.conf with your preferences.

Update the docker-compose.yml file with the ports you plan on using (if non-standard).

When you are ready, installation is as easy as:
```
$ docker-compose build
$ docker-compose up
```

You will also probably want to run the secure installation script on the database container:
```
$ docker exec -it civicrmdocker_db_1 bash
$ mysql_secure_installation
```

Enjoy!

# Acknowledgements
* Docker for providing official packages for [Drupal](https://hub.docker.com/_/drupal/), [MariaDB](https://hub.docker.com/_/mariadb/), [nginx](https://hub.docker.com/_/nginx/), and all others that went to building these.
* djcf for their [civicrm-docker](https://github.com/djcf/civicrm-docker) project and related questions floating around the Internet.
* Josh Lockhart for their [blog post](http://www.newmediacampaigns.com/blog/docker-for-php-developers) which maps a three container Docker image.
* William Mortada for their  [explaination](https://civicrm.stackexchange.com/questions/4829/is-it-easy-to-upgrade-civicrm-using-drush) of the update procedure via Drush.
* the Drupal community for [documentation](https://www.drupal.org/node/244924) about hardening an install.
* md5 for their [gist](https://gist.github.com/md5/d9206eacb5a0ff5d6be0) demonstrating nginx+php-fpm.
* wsargent for the [Docker Cheat Sheet](https://github.com/wsargent/docker-cheat-sheet).
* and the many giants who have come before me, this world would not be possible without you!
