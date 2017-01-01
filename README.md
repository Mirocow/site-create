# site-create
RU: Скрипт для создания сайтов
ENG: This script create settings files for nginx, php-fpm, apache2.
```
OPTIONS:
   -n | --host      Host name (Example: --host=myhost.com)
   -i | --ip        IP address, default usage 80 (Example: --ip=127.0.0.1:8080)
   -r | --redirect  WWW redirect add (Example: --redirect=www-site or --redirect=site-www or disable redirect --redirect=off)
   -a | --apache    Usage apache back-end
   -s | --awstats   Usage awstats
   -5 | --php5      Usage PHP 5.x
   -7 | --php7      Usage PHP 7.x
   -l | --lock      Usage Nginx HTTP Auth basic
   -h | --help      Usage

EXAMPLES:
   bash site-create.sh --host="yii2-eav.ztc" --ip="192.168.1.131:8082
```   

## Для подключения PHP 7.0

``` sh
$ bash site-create.sh --host="yii2-eav.ztc" -7
```

### Вывод

```
--------------------------------------------------------
User: yii2-eav.ztc
Login: yii2-eav.ztc
Password: OTE5MGRhMjMwYTJl
Path: /home/yii2-eav.ztc/
SSH Private file: /home/yii2-eav.ztc/.ssh/id_rsa
SSH Public file: /home/yii2-eav.ztc/.ssh/id_rsa.pub
Servers:
Site name: yii2-eav.ztc (192.168.1.131:80)
Site root: /home/yii2-eav.ztc/httpdocs/web
Site logs path: /home/yii2-eav.ztc/logs
Back-end server: PHP-FPM
NGINX: /etc/nginx/conf.d/yii2-eav.ztc.conf
PHP-FPM: /etc/php/7.0/fpm/pool.d/yii2-eav.ztc.conf
--------------------------------------------------------
```

### Для подключения PHP 5.x

``` sh
$ bash site-create.sh --host="yii2-eav.ztc" -5
```

### Вывод

```
--------------------------------------------------------
User: yii2-eav.ztc
Login: yii2-eav.ztc
Password: OTIxYTU4NzAyZmZl
Path: /home/yii2-eav.ztc/
SSH Private file: /home/yii2-eav.ztc/.ssh/id_rsa
SSH Public file: /home/yii2-eav.ztc/.ssh/id_rsa.pub
Servers:
Site root: /home/yii2-eav.ztc/httpdocs/web
Site logs path: /home/yii2-eav.ztc/logs
Back-end server: PHP-FPM
NGINX: /etc/nginx/conf.d/yii2-eav.ztc.conf
PHP-FPM: /etc/php5/fpm/pool.d/yii2-eav.ztc.conf
--------------------------------------------------------
```
