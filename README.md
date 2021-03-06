# site-create
RU: Скрипт для создания сайтов <br>
ENG: This script create settings files for nginx, php-fpm, apache2.
```
OPTIONS:
   -n | --host      Host name without www (Example: --host=myhost.com)
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
$ bash site-create.sh --host=yii2-eav.ztc --redirect=www-site -7
```

### Вывод

```
--------------------------------------------------------
User: mts.ztc
Login: mts.ztc
Password: ODE4N2UzMTNhMDJj
Path: /home/mts.ztc/
SSH Private file: /home/mts.ztc/.ssh/id_rsa
SSH Public file: /home/mts.ztc/.ssh/id_rsa.pub
Servers:
Site name: mts.ztc (192.168.1.131:80)
Use redirect from mts.ztc to mts.ztc
Site root: /home/mts.ztc/httpdocs/web
Site logs path: /home/mts.ztc/logs
Back-end server: PHP-FPM
NGINX: /etc/nginx/conf.d/mts.ztc.conf
PHP-FPM: /etc/php/7.0/fpm/pool.d/mts.ztc.conf
unixsock: /var/run/php-fpm-7-mts.ztc.sock
--------------------------------------------------------
```

### Для подключения PHP 5.x

``` sh
$ bash site-create.sh --host=yii2-eav.ztc --redirect=www-site -5
```

### Вывод

```
--------------------------------------------------------
User: mts.ztc
Login: mts.ztc
Password: MDIxZDcxMTk4YjY3
Path: /home/mts.ztc/
SSH Private file: /home/mts.ztc/.ssh/id_rsa
SSH Public file: /home/mts.ztc/.ssh/id_rsa.pub
Servers:
Site name: mts.ztc (192.168.1.131:80)
Use redirect from mts.ztc to mts.ztc
Site root: /home/mts.ztc/httpdocs/web
Site logs path: /home/mts.ztc/logs
Back-end server: PHP-FPM
NGINX: /etc/nginx/conf.d/mts.ztc.conf
PHP-FPM: /etc/php5/fpm/pool.d/mts.ztc.conf
unixsock: /var/run/php-fpm-5-mts.ztc.sock
--------------------------------------------------------
```
