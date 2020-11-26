#!/bin/bash

#instalacja nginx
function function_install_nginx() {
  _read "install_nginx" "Czy instalować NGINX?" "y/n"

  if [[ "$var_install_nginx" == "y" ]]; then
    #instalacja nginx
    sudo dnf install nginx
    sudo systemctl enable nginx
    sudo systemctl start nginx

    mkdir -p /etc/nginx/sites-enabled
    mkdir -p /etc/nginx/sites-available
  fi
}

#instalacja mysql
function function_install_mysql() {
  _read "install_mysql" "Czy instalować MYSQL?" "y/n"

  if [[ "$var_install_mysql" == "y" ]]; then
    sudo dnf install mysql-server
    sudo systemctl start mysqld.service
    sudo systemctl enable mysqld

    _read "secure_installation" "Czy wykonać mysql_secure_installation?" "y/n"
    if [[ "$var_secure_installation" == "y" ]]; then
      sudo mysql_secure_installation
    fi

    restart_nginx
  fi
}

#instalacja phpmyadmina w katalogu /usr/share/phpmyadmin
function function_install_phpmyadmin() {
  _read "install_phpmyadmin" "Czy instalować phpmyadmin?" "y/n"

  if [[ "$var_install_phpmyadmin" == "y" ]]; then
    local php_my_admin_dir="/usr/share/phpmyadmin/"

    if [ -d "$php_my_admin_dir" ];
    then
      echo "Katalog $php_my_admin_dir istnieje."
      _read "delete_phpmyadmin" "Czy usunąć phpmyadmin?" "y/n"

      if [[ "$var_delete_phpmyadmin" == "y" ]];
      then
        rm -rf "$php_my_admin_dir"
      else
        return 1
      fi
    fi

    cd /tmp/ || exit
    wget https://files.phpmyadmin.net/phpMyAdmin/4.9.4/phpMyAdmin-4.9.4-all-languages.zip
    unzip phpMyAdmin-4.9.4-all-languages.zip
    mkdir -p "$php_my_admin_dir"
    unzip phpMyAdmin-4.9.4-all-languages.zip -d "$php_my_admin_dir"
    cd "$php_my_admin_dir" || exit
    mv phpMyAdmin-4.9.4-all-languages/* .
    rm -rf phpMyAdmin-4.9.4-all-languages
    sudo mv config.sample.inc.php config.inc.php

    local base64hash=$(openssl rand -base64 32)
    sudo sed -i "s/$cfg\['blowfish_secret'\] = '';/$cfg\['blowfish_secret'\] = '$base64hash';/gi" config.inc.php

    mkdir -p "${php_my_admin_dir}tmp/"
    sudo chown -R nginx:nginx "$php_my_admin_dir"
    sudo chmod 0777 "${php_my_admin_dir}tmp"
  fi
}