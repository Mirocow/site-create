# site-create
Скрипт для создания сайтов

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
