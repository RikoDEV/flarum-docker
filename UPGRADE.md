# Guide to upgrading a flarum container

:warning: Backup your database, config.php, composer.lock and assets folder  
:warning: Disable all 3rd party extensions prior to upgrading in panel admin.

1 - Pull the last docker images

```sh
docker-compose stop
docker-compose pull
docker-compose up -d
```

2 - Updating your database and removing old assets & extensions

```sh
docker exec -ti flarum php /flarum/app/flarum migrate
docker exec -ti flarum php /flarum/app/flarum cache:clear
```

3 - Open your flarum website and enter the database password to complete the upgrade.

After that, the upgrade is completed. :tada: :tada:
