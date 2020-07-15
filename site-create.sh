#!/bin/bash

if [ ! -n "$BASH" ] ;then echo Please run this script $0 with bash; exit 1; fi

function trim()
{
  echo "$1" | awk '{gsub(/^ +| +$/,"")} {print $0}'
}

function create_site()
{

		site_name=$HOST
		site_alias=$ALIAS
		site_addr=$IP
		password=$(date +%s | sha256sum | base64 | head -c 16 ; echo)

    if [ -d /home/${site_name} ]; then
				if [ $SET_PASSWORD -eq 1 ]; then
						echo ${site_name}:${password} | chpasswd
						usermod  -s /bin/bash ${site_name}
				else
						password='[without changes]'
						echo "User's password is not updated"
				fi						
		else
				mkdir /home/${site_name}
				mkdir /home/${site_name}/logs
				mkdir /home/${site_name}/httpdocs
				mkdir /home/${site_name}/httpdocs/web
				useradd -d /home/${site_name} -s /bin/bash ${site_name}
				usermod -G www-data ${site_name}
				echo ${site_name}:${password} | chpasswd
				mkdir /home/${site_name}/.ssh
				chmod 0700 /home/${site_name}/.ssh
				ssh-keygen -b 4096 -t rsa -N "${site_name}" -f /home/${site_name}/.ssh/id_rsa
				chmod 0600 /home/${site_name}/.ssh/id_rsa
				ssh-keygen -b 4096 -t dsa -N "${site_name}" -f /home/${site_name}/.ssh/id_dsa
				chmod 0600 /home/${site_name}/.ssh/id_dsa
				echo  "<?php phpinfo();" > /home/${site_name}/httpdocs/web/index.php
				if [ $LOCK -eq 1 ]; then
						authpassword=$(date +%s | sha256sum | base64 | head -c 6 ; echo)
						php -r "echo 'admin:' . crypt('${authpassword}', 'salt') . ': Web auth for ${site_name}';" > /home/${site_name}/authfile
				fi
				chown ${site_name}:www-data -R /home/${site_name}
		fi

		if [ $APACHE -eq 1 ]; then

        echo "
<VirtualHost 127.0.0.1:8080>
                ServerName ${site_name}
                ServerAlias www.${site_name}
                ServerAdmin info@reklamu.ru
                DocumentRoot /home/${site_name}/httpdocs/web
                <Directory /home/${site_name}/httpdocs/web>
                                Options Indexes FollowSymLinks MultiViews
                                Options FollowSymLinks
                                AllowOverride All
                                Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
                                Order allow,deny
                                Allow from all
                </Directory>

                ErrorLog \${APACHE_LOG_DIR}/${site_name}-error.log

                # Possible values include: debug, info, notice, warn, error, crit,
                # alert, emerg.
                LogLevel warn

                CustomLog \${APACHE_LOG_DIR}/${site_name}-access.log combined
</VirtualHost>
" > /etc/apache2/sites-enabled/${site_name}.conf

main="
                                # Apache back-end
                                location / {
                                                proxy_pass  http://127.0.0.1:8080;
                                                proxy_ignore_headers   Expires Cache-Control;
                                                proxy_set_header        Host            \$host;
                                                proxy_set_header        X-Real-IP       \$remote_addr;
                                                proxy_set_header        X-Forwarded-For \$proxy_add_x_forwarded_for;
                                }
                                location ~* \.(js|css|png|jpg|jpeg|gif|ico|swf)\$ {
                                                expires 1y;
                                                log_not_found off;
                                                proxy_pass  http://127.0.0.1:8080;
                                                proxy_ignore_headers   Expires Cache-Control;
                                                proxy_set_header        Host            \$host;
                                                proxy_set_header        X-Real-IP       \$remote_addr;
                                                proxy_set_header        X-Forwarded-For \$proxy_add_x_forwarded_for;
                                }
                                location ~* \.(html|htm)\$ {
                                                expires 1h;
                                                proxy_pass  http://127.0.0.1:8080;
                                                proxy_ignore_headers   Expires Cache-Control;
                                                proxy_set_header        Host            \$host;
                                                proxy_set_header        X-Real-IP       \$remote_addr;
                                                proxy_set_header        X-Forwarded-For \$proxy_add_x_forwarded_for;
                                }
"

		else

        php_config=";; php-fpm config for ${site_name}
[${site_name}]

user = ${site_name}
group = www-data

listen = /var/run/php-fpm-${PHP}-${site_name}.sock
listen.owner = ${site_name}
listen.group = www-data
listen.mode = 0666

pm = dynamic
pm.max_children = 250
pm.start_servers = 8
pm.min_spare_servers = 8
pm.max_spare_servers = 16

chdir = /
security.limit_extensions = false
php_flag[display_errors] = on
php_admin_value[error_log] = /home/${site_name}/logs/fpm-php-${PHP}-${site_name}.log
php_admin_flag[log_errors] = on

; Documentation: http://php.net/manual/ru/opcache.configuration.php
php_flag[opcache.enable] = $PHP_OPCACHE
php_flag[opcache.enable_cli] = $PHP_OPCACHE
"

echo "$php_config" > "/etc/php/${PHP}/fpm/pool.d/${site_name}.conf"

if [ $LOCK -eq 1 ]; then
    lock="
auth_basic \"Website development\";
auth_basic_user_file /home/${site_name}/authfile;
"
else
    lock=''
fi

    main="
                                # With PHP-FPM
                                location / {
                                                index index.php;
                                                try_files \$uri \$uri/ /index.php?\$query_string;
                                }

                                # PHP fastcgi
                                location ~ \.php {
                                                #try_files \$uri =404;
                                                include fastcgi_params;
                                                # Use your own port of fastcgi here
                                                #fastcgi_pass 127.0.0.1:9000;
                                                ${lock}
                                                fastcgi_pass unix:/var/run/php-fpm-${PHP}-${site_name}.sock;
                                                fastcgi_index index.php;
                                                fastcgi_split_path_info ^(.+\.php)(/.+)$;
                                                fastcgi_param PATH_INFO \$fastcgi_path_info;
                                                fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
                                }
"
		fi

if [ $AWSTATS -eq 1 ]; then
        awstats="# Awstats
                                server {
                                listen ${site_addr};
                                server_name  awstats.${site_name};

                                auth_basic            \"Restricted\";
                                auth_basic_user_file  /home/${site_name}/authfile;

                                access_log /var/log/nginx/access.awstats.${site_name}.log;
                                error_log /var/log/nginx/error.awstats.${site_name}.log;

                                location / {
                                                root   /home/${site_name}/awstats/;
                                                index  awstats.html;
                                                access_log off;
                                }

                                location  /awstats-icon/ {
                                                alias  /usr/share/awstats/icon/;
                                                access_log off;
                                }

                                # apt-get awstats install
                                location ~ ^/cgi-bin {
                                                access_log off;
                                                fastcgi_pass   unix:/var/run/fcgiwrap.socket;
                                                include /etc/nginx/fastcgi_params;
                                                fastcgi_param  SCRIPT_FILENAME  /usr/lib\$fastcgi_script_name;
                                }
                                }
"
else
        awstats=''
fi

if [ $REDIRECT = 'site-www' ]; then
        redirect="
                                # Rerirect ${site_name}
                                server {
                                                listen ${site_addr};
                                                server_name ${site_name};
                                                return 301 http://www.${site_name}\$request_uri;
                                }
"
        server_name="www.${site_name}"
fi				
				
if [ $REDIRECT = 'www-site' ]; then
        redirect="
# Rerirect www.${site_name}
server {
                                listen ${site_addr};
                                server_name www.${site_name};
                                return 301 http://${site_name}\$request_uri;
}
"
        server_name="${site_name}"
fi
				
if [ $REDIRECT = 'off' ]; then
        redirect=''
        server_name="${site_name}"
fi

echo "
${awstats}

${redirect}

# Site ${server_name}
server {
                                listen ${site_addr};
                                server_name ${server_name} ${site_alias};
                                root /home/${site_name}/httpdocs/web;
                                index index.php;
                                access_log /home/${site_name}/logs/access.log;
                                error_log  /home/${site_name}/logs/error.log error;
                                charset utf-8;
                                #charset        windows-1251;
                                location = /favicon.ico {
                                                log_not_found off;
                                                access_log off;
                                                break;
                                }
                                location = /robots.txt {
                                                allow all;
                                                log_not_found off;
                                                access_log off;
                                }
                                ${main}
                                location ~ /(protected|themes/\w+/views)/ {
                                                access_log off;
                                                log_not_found off;
                                                return 404;
                                }
                                #
                                location ~ \.(xml)\$ {
                                                expires 24h;
                                                charset windows-1251;
                                                #log_not_found off;
                                                #try_files \$uri =404;
                                                #try_files \$uri \$uri/ /index.php?\$query_string;
                                }
                                #
                                location ~ \.(js|css|png|jpg|gif|swf|ico|pdf|mov|fla|zip|rar)\$ {
                                                expires 24h;
                                                #log_not_found off;
                                                #try_files \$uri =404;
                                                try_files \$uri \$uri/ /index.php?\$query_string;
                                }

                                # Hide all system files
                                location  ~ /\. {
                                                deny  all;
                                                access_log off;
                                                log_not_found off;
                                }
}
" > /etc/nginx/conf.d/${site_name}.conf

				service php${PHP}-fpm reload
	
        if [ $APACHE -eq 1 ]; then
          service apache2 reload
        fi

        service nginx reload

        echo ""
        echo "--------------------------------------------------------"
        echo "User: ${site_name}"
        echo "Login: ${site_name}"
        echo "Password: ${password}"
        echo "Path: /home/${site_name}/"
        echo "SSH Private file: /home/${site_name}/.ssh/id_rsa"
        echo "SSH Public file: /home/${site_name}/.ssh/id_rsa.pub"
        echo "Servers:"
        echo "Site name: ${site_name} (${IP})"

        if [ ! -z $site_alias ]; then
          echo "Site alias: ${site_alias}"
        fi

        if [ $REDIRECT = 'site-www' ]; then
          echo "Use redirect from ${site_name} to ${server_name}"
        fi				
        if [ $REDIRECT = 'www-site' ]; then
          echo "Use redirect from ${site_name} to ${server_name}"
        fi
        if [ $REDIRECT = 'off' ]; then
          echo "Redirect disabled. use only ${server_name}"
        fi

        echo "Site root: /home/${site_name}/httpdocs/web"
        echo "Site logs path: /home/${site_name}/logs"

        if [ $APACHE -eq 1 ]; then
          echo "Back-end server: Apache 2"
          echo "NGINX: /etc/nginx/conf.d/${site_name}.conf"
          echo "APACHE: /etc/apache2/sites-enabled/${site_name}.conf"
        else
          echo "Back-end server: PHP-FPM"
          echo "NGINX: /etc/nginx/conf.d/${site_name}.conf"
          echo "PHP-FPM: /etc/php/${PHP}/fpm/pool.d/${site_name}.conf"  
          echo "unixsock: /var/run/php-fpm-${PHP}-${site_name}.sock"
        fi

        if [ $LOCK -eq 1 ]; then
          echo "Web auth: admin ${authpassword}"
        fi

        if [ $AWSTATS -eq 1 ]; then
          echo "Statistic:"
          echo "awstats.${site_name}"
          echo "Add crontab task: */20 * * * * /usr/lib/cgi-bin/awstats.pl -config=${site_name} -update > /dev/null"
        fi

        echo "--------------------------------------------------------"
        echo ""

}

usage()
{
cat << EOF
usage: $0 options

This script create settings files for nginx, php-fpm (ver: 5, 7), apache2, awstats.

OPTIONS:
   --host=                  Host name without www (Example: --host=myhost.com)
   --ip=                    IP address, default usage 80 (Example: --ip=127.0.0.1:8080)
   --redirect=              WWW redirect add (Example: --redirect=www-site or --redirect=site-www or disable redirect --redirect=off)
   --alias=                 Set Nginx alias (Examle: --alias="alias1 alias2 etc")
   --apache                 Usage apache back-end
   --awstats                Usage awstats
   --dont-change-password   Usage for change user password (Default: 1. Usage only for update)
   -5 | --php5              Usage PHP 5.x
   -7 | --php7              Usage PHP 7.0
   -71 | --php71            Usage PHP 7.1
   -72 | --php72            Usage PHP 7.2
   -73 | --php73            Usage PHP 7.3
   -74 | --php74            Usage PHP 7.4         
   -l | --lock              Usage Nginx HTTP Auth basic	 
   -h | --help              Usage

EXAMPLES:
   bash site-create.sh --host="mirocow.com" --ip="192.168.1.131:8082"
   bash site-create.sh --host="mirocow.com" --alias="c1.mirocow.com c2.mirocow.com" --php73

EOF
}

SET_PASSWORD=1
HTTPS=0
REDIRECT='site-www'
LOCK=0
HOST=''
ALIAS=''
APACHE=0
AWSTATS=0
PHP=7.2
PHP_OPCACHE='Off'
IP=$(trim $(hostname -I)):80

for i in "$@"
do
    case $i in		
        --host=*)
            HOST=( "${i#*=}" )
            shift
        ;;
        --alias=*)
            ALIAS=( "${i#*=}" )
            shift
        ;;				
        --ip=*)
            IP=( "${i#*=}" )
            shift
        ;;
        --redirect=*)
            REDIRECT=( "${i#*=}" )
            shift
        ;;
        --https)
            HTTPS=1
            shift
        ;;
        --apache)
            APACHE=1
            shift
        ;;
        --dont-change-password)
            SET_PASSWORD=0
            shift
        ;;
        -l | --lock)
            LOCK=1
            shift
        ;;
        -5 | --php5)
            PHP=5.6
            shift
        ;;
        -7 | --php7)
            PHP=7.0
            shift
        ;;
        -71 | --php71)
            PHP=7.1
            shift
        ;;
        -72 | --php72)
            PHP=7.2
            shift
        ;;
        -73 | --php73)
            PHP=7.3
            shift
        ;;
        -74 | --php74)
            PHP=7.4
            shift
        ;;        
        -c | --php-opcache)
            PHP_OPCACHE='On'
            shift
        ;;	
        -w | --awstats)
            AWSTATS=1
            shift
        ;;
        -h | --help)
            usage
            exit
        ;;
        *)
        # unknown option
        ;;
    esac
done

# === AUTORUN ===
if [ ! -z "$HOST" ]; then
  create_site
else
  usage
fi
