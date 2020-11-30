#!/bin/bash

function epel_repository() {
    sudo dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
    sudo dnf install https://rpms.remirepo.net/enterprise/remi-release-8.rpm
    sudo dnf install yum-utils
}

# zamienia tablicę z rozszerzeniami
# na postać z wersją php tzn
# php-pfm -> php72-php-fpm
# $1 - wersja php (np. 72)
# $2 - tablica z rozszerzeniami (np. [php-fpm, php-json])
function array_to_php_version() {
  local array
  IFS=' ' read -r -a array <<< "$2"

  for index in "${!array[@]}"
  do
      printf "php%s-%s " "$1" "${array[index]}"
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
  epel_repository

  local php_version="$1"
  local without_dot="${php_version/./}"
  local -r php_list=$(array_to_php_version "$without_dot" "${2}")

  sudo dnf module reset php
  sudo dnf module enable "php:remi-$php_version"


  sudo dnf install --enablerepo=remi-test "php$without_dot" -y
  sudo dnf install --enablerepo=remi-test ${php_list} -y

  sudo systemctl start "php$without_dot-php-fpm"
  sudo systemctl enable "php$without_dot-php-fpm"
}

#restart
# $1 - wersja php (np. 74)
function _restart() {
  #taktyczny restart
  if service_exists 'php-fpm';
  then
    sudo systemctl restart php-fpm
  fi

  sudo systemctl restart "php$1-php-fpm"

  restart_nginx
}

function install_php72() {
    #instalacja
    _base_install "7.2" "php-fpm php-mysqli php-mysql php-pdo php-common php-cli php-gd php-json php-mbstring php-mysqlnd php-xml php-xmlrpc php-opcache php-apcu php-xdebug"

    #zmiana w konfiguracjach www.conf
    _conf_update "72"

    #restart
    _restart "72"
}

function install_php73() {
    #instalacja
    _base_install "7.3" "php-fpm php-mysqli php-mysql php-pdo php-common php-cli php-gd php-json php-mbstring php-mysqlnd php-xml php-xmlrpc php-opcache php-apcu php-xdebug"

    #zmiana w konfiguracjach www.conf
    _conf_update "73"

    #restart
    _restart "73"
}

function install_php74() {
    #instalacja
    _base_install "7.4" "php-fpm php-gd php-curl php-mysqlnd php-mbstring php-intl php-pecl-apcu php-opcache php-process php-zip php-json php-pecl-zip php-pear php-pecl-imagick php-pecl-redis5 php-pgsql php-common php-pdo php-lz4 php-xml php-pecl-crypto php-pecl-rar php-pecl-pq php-pecl-lzf php-cli php-pecl-apcu-bc"

    #zmiana w konfiguracjach www.conf
    _conf_update "74"

    #restart
    _restart "74"
}

function install_php80() {
    #instalacja
    _base_install "8.0" "php-fpm php-mysqli php-pdo php-common php-cli php-gd php-json php-mbstring php-mysqlnd php-xml php-xmlrpc php-opcache php-apcu php-xdebug"

    #zmiana w konfiguracjach www.conf
    _conf_update "80"

    #restart
    _restart "80"
}

#instalacja php 7.2
function function_install_php72() {
  _read "install_php72" "Czy instalować PHP 7.2" "y/n"

  # shellcheck disable=SC2154
  if [[ "$var_install_php72" == "y" ]];
  then
    install_php72
  fi
}


#instalacja php 7.3
function function_install_php73() {
  _read "install_php73" "Czy instalować PHP 7.3" "y/n"

  # shellcheck disable=SC2154
  if [[ "$var_install_php73" == "y" ]];
  then
    install_php73
  fi
}

#instalacja php 7.4
function function_install_php74() {
  _read "install_php74" "Czy instalować PHP 7.4" "y/n"

  # shellcheck disable=SC2154
  if [[ "$var_install_php74" == "y" ]];
  then
    install_php74
  fi
}

#instalacja php 8.0
function function_install_php80() {
  _read "install_php80" "Czy instalować PHP 8.0" "y/n"

  # shellcheck disable=SC2154
  if [[ "$var_install_php80" == "y" ]];
  then
    install_php80
  fi
}

# do danej wersji php dodajemy nowe rozszerzenie
function function_add_extension_to_php() {
  local -r php_versions=$(get_config "options" "php_versions")
  _read "install_to_php" "Do której wersji?" "${php_versions}/n"

  # shellcheck disable=SC2154
  if [[ "$var_install_to_php" != "n" ]];
  then
    #sprawdzamy to ta wersja php jest zainstalowana
    local command_php="php${var_install_to_php/./}"
    if ! command_exists "${command_php}";
    then
      echo "Wersja ${command_php} nie istnieje. Zainstaluj ją napierw"
      return 1
    fi


    _read "type_add_extension" "Gdzie dodajemy rozszerzenie? (remi[R], default[D])" "r/d"

    sudo dnf module reset php
    sudo dnf module enable php:remi-"$var_install_to_php"

    _read "install_to_php_extension" "Wprowadź jedno rozszerzenie (dla; php72-php-json będzie to: php-json)"

    if [[ "$var_type_add_extension" != "r" ]];
    then
      local -r php_without_dot="${var_install_to_php//./}"
      # shellcheck disable=SC2154
      sudo dnf install --enablerepo=remi-test "php$php_without_dot-$var_install_to_php_extension" -y
      sudo systemctl restart "php${php_without_dot}-php-fpm"
    fi

    if [[ "$var_type_add_extension" != "d" ]];
    then
      # shellcheck disable=SC2154
      sudo dnf install "$var_install_to_php_extension" -y
      sudo systemctl restart php-fpm
    fi
  fi
}

# instalacja domyślnej wersji php
function function_install_default_php() {
  local -r php_versions=$(get_config "options" "php_versions")
  _read "install_default_php" "Jaką domyślną wersję zainstalować?" "${php_versions}/n"

  # shellcheck disable=SC2154
  if [[ "$var_install_default_php" != "n" ]];
  then
    epel_repository

    sudo dnf module reset php
    sudo dnf module enable php:remi-"$var_install_default_php"
    sudo dnf install php \
    php-gd php-curl php-mysqlnd \
    php-mbstring php-intl php-pecl-apcu php-opcache \
    php-process php-zip php-json php-pecl-zip \
    php-pear php-pecl-imagick php-fpm php-pecl-redis5 \
    php-pgsql php-common php-pdo  \
    php-lz4 php-xml php-pecl-crypto php-pecl-rar \
    php-pecl-pq php-pecl-lzf php-cli php-pecl-apcu-bc

    cd "/etc/php-fpm.d/" || exit
    sudo sed -i -e 's/user = apache/user = nginx/gi' www.conf
    sudo sed -i -e 's/group = apache/group = nginx/gi' www.conf
    sudo sed -i -e "s/listen = \/run\/php-fpm\/www.sock/listen = 127.0.0.1:9000/gi" www.conf

    sudo systemctl restart php-fpm
  fi
}