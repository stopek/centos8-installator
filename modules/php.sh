#!/bin/bash

source ./utils/common.sh

function _repo_install() {
    sudo dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
    sudo dnf install https://rpms.remirepo.net/enterprise/remi-release-8.rpm
    sudo dnf install yum-utils
}

function _array_to_php_version() {
  local array="$2"
  for index in "${!array[@]}"
  do
      printf "php$1-${array[index]} "
  done
}

#aktualizacjapliku z ustawieniami konfiguracyjnymi
# $1 - wersja php (np. 72, 73, 80)
function _conf_update() {
    cd "/etc/opt/remi/php$1/php-fpm.d/" || exit
    sudo sed -i -e 's/user = apache/user = nginx/gi' www.conf
    sudo sed -i -e 's/group = apache/group = nginx/gi' www.conf
    sudo sed -i -e "s/listen = \/var\/opt\/remi\/php$1\/run\/php-fpm\/www.sock/listen = 127.0.0.1:90$1/gi" www.conf
}

#aktualizacjapliku z ustawieniami konfiguracyjnymi
# $1 - wersja php (np. 7.2, 7.3, 8.0)
# $2 - rozszerzenia bez wersji (np. php-fpm php-mysqli)
function _base_install() {
    local php_version="$1"
    local without_dot="${php_version/./}"

    sudo dnf module reset php
    sudo dnf module enable "php:remi-$php_version"

    IFS=' ' read -r -a array <<< "$2"
    local php_list=$(_array_to_php_version "$without_dot" "$array")
    sudo dnf install --enablerepo=remi-test "php$without_dot" $php_list -y

    sudo systemctl start "php$without_dot-php-fpm"
    sudo systemctl enable "php$without_dot-php-fpm"
}

#restart
# $1 - wersja php (np. 74)
function _restart() {
    #taktyczny restart
    sudo systemctl restart php-fpm

    sudo systemctl restart "php$1-php-fpm"

    restart_nginx
}

#instalacja php 7.2
function function_install_php72() {
  _read "install_php72" "Czy instalować PHP 7.2" "y/n"

  if [[ "$var_install_php72" == "y" ]]; then
    _repo_install

    #instalacja
    _base_install "7.2" "php-fpm php-mysqli php-mysql php-pdo php-common php-cli php-gd php-json php-mbstring php-mysqlnd php-xml php-xmlrpc php-opcache php-apcu php-xdebug"

    #zmiana w konfiguracjach www.conf
    _conf_update "72"

    #restart
    _restart "72"
  fi
}

#instalacja php 7.3
function function_install_php73() {
  _read "install_php73" "Czy instalować PHP 7.3" "y/n"

  if [[ "$var_install_php73" == "y" ]]; then
    _repo_install

    #instalacja
    _base_install "7.3" "php-fpm php-mysqli php-mysql php-pdo php-common php-cli php-gd php-json php-mbstring php-mysqlnd php-xml php-xmlrpc php-opcache php-apcu php-xdebug"

    #zmiana w konfiguracjach www.conf
    _conf_update "73"

    #restart
    _restart "73"
  fi
}

#instalacja php 7.4
function function_install_php74() {
  _read "install_php74" "Czy instalować PHP 7.4" "y/n"

  if [[ "$var_install_php74" == "y" ]]; then
    _repo_install

    #instalacja
    _base_install "7.4" "php-fpm php-mysqli php-mysql php-pdo php-common php-cli php-gd php-json php-mbstring php-mysqlnd php-xml php-xmlrpc php-opcache php-apcu php-xdebug"

    #zmiana w konfiguracjach www.conf
    _conf_update "74"

    #restart
    _restart "74"
  fi
}

#instalacja php 8.0
function function_install_php80() {
  _read "install_php80" "Czy instalować PHP 8.0" "y/n"

  if [[ "$var_install_php80" == "y" ]]; then
    #instalacja
    _base_install "8.0" "php-fpm php-mysqli php-pdo php-common php-cli php-gd php-json php-mbstring php-mysqlnd php-xml php-xmlrpc php-opcache php-apcu php-xdebug"

    #zmiana w konfiguracjach www.conf
    _conf_update "80"

    #restart
    _restart "80"
  fi
}

#do danej wersji php dodajemy nowe rozszerzenie
function function_add_extension_to_php() {
  _read "install_to_php" "Do której wersji?" "7.2/7.3/7.4/8.0/n"

  if [[ "$var_install_to_php" != "n" ]]; then
    _read "install_to_php_extension" "Wprowadź jedno rozszerzenie"
    local php_without_dot="${var_install_to_php//./}"

    sudo dnf module reset php
    sudo dnf module enable php:remi-"$var_install_to_php"
    sudo dnf install "php$php_without_dot-$var_install_to_php_extension"

    sudo systemctl restart "php${php_without_dot}-php-fpm"
  fi
}

#instalacja domyślnej wersji php
function function_install_default_php() {
  _read "install_default_php" "Czy instalować phpmyadmin?" "7.2/7.3/7.4/8.0/n"

  if [[ "$var_install_default_php" != "n" ]]; then
    sudo dnf module reset php
    sudo dnf module enable php:remi-"$var_install_default_php"
    sudo dnf install php php-opcache php-gd php-curl php-mysqlnd
  fi
}