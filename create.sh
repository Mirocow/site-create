#!/bin/bash

site_name=$1

if [$2]; then
  site_addr="$2:80"
else
  site_addr="80"
fi

password=$(date +%s | sha256sum | base64 | head -c 16 ; echo)

service php5-fpm stop
service nginx stop

deluser ${site_name}

rm -r /home/${site_name}
mkdir /home/${site_name}
#rmdir /home/${site_name}/.ssh
mkdir /home/${site_name}/.ssh
#rmdir /home/${site_name}/httpdocs
mkdir /home/${site_name}/httpdocs

useradd -d /home/${site_name} ${site_name}
usermod -G www-data ${site_name} -p ${password}

chown ${site_name}:www-data -R /home/${site_name}

echo "## php-fpm config for ${site_name}
[${site_name}]

user = ${site_name}
group = www-data
listen = /var/run/php-fpm-${site_name}.sock
listen.mode = 0666
pm = dynamic
pm.max_children = 250
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
chdir = /
security.limit_extensions = false
php_flag[display_errors] = on
php_admin_value[error_log] = /var/log/nginx/fpm-php.${site_name}.log
php_admin_flag[log_errors] = on
" > /etc/php5/fpm/pool.d/${site_name}.conf


echo  "<?php print 'It\`s work on ${site_name} PHP v' . phpversion(); echo '<pre>'; print_r(get_loaded_extensions()); echo '</pre>';" > /home/${site_name}/httpdocs/index.php

echo "
server {

                listen ${site_addr};
                server_name ${site_name};
                root /home/${site_name}/httpdocs;
                index index.php;

                access_log /var/log/nginx/${site_name}.access.log;
                error_log  /var/log/nginx/${site_name}.error.log error;

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


                location / {
                        index index.php;
                        try_files \$uri \$uri/ /index.php?\$query_string;
                }


                location ~ /(protected|themes/\w+/views)/ {
                        access_log off;
                        log_not_found off;
                        return 404;
                }

                #
                location ~ \.(xml)$ {
                        expires 24h;
                        charset windows-1251;
                        #log_not_found off;
                        #try_files $uri =404;
                        #try_files $uri $uri/ /index.php?$query_string;
                }


                #��������� ��������� �������� ����������� � �������������� ��������� ������
                location ~ \.(js|css|png|jpg|gif|swf|ico|pdf|mov|fla|zip|rar)$ {
                        expires 24h;
                        #log_not_found off;
                        #try_files $uri =404;
                        try_files \$uri \$uri/ /index.php?\$query_string;
                }

                # ���������� ����������
                location ~ \.php {
                        #try_files $uri =404;
                        include fastcgi_params;

                        # Use your own port of fastcgi here
                        #fastcgi_pass 127.0.0.1:9000;
                        fastcgi_pass unix:/var/run/php-fpm-${site_name}.sock;
                        fastcgi_index index.php;
                        fastcgi_split_path_info ^(.+\.php)(/.+)$;
                        fastcgi_param PATH_INFO \$fastcgi_path_info;
                        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
                }

                # ������ ��� ��������� �����
                location  ~ /\. {
                        deny  all;
                        access_log off;
                        log_not_found off;
                }

}
" > /etc/nginx/conf.d/${site_name}.conf

service php5-fpm restart
service nginx restart

echo "Login: ${site_name}"
echo "Password: ${password}"

echo "Please run site ${site_name} with password"