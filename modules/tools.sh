#!/bin/bash

function function_install_nextcloud() {
  #sprawdzamy czy nginx jest zainstalowany
  if ! command_exists nginx; then
    echo "Nginx nie jest zainstalowany"
    call_module_function "server" "function_install_nginx"
  fi

  #tworzenie użytkownika
  adduser nextcloud
  passwd nextcloud
  usermod -aG wheel nextcloud

  #dodanie repo i instalacja postgresql
  sudo dnf -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm

  local pg_hba="/var/lib/pgsql/12/data/pg_hba.conf"
  local install_dir="/var/www/nextcloud"

  sudo dnf -qy module disable postgresql
  sudo dnf -y install postgresql12 postgresql12-server
  sudo /usr/pgsql-12/bin/postgresql-12-setup initdb
  sudo systemctl enable postgresql-12
  sudo systemctl start postgresql-12
  sudo passwd postgres
  su -l postgres
    psql
      CREATE USER nextclouddbuser WITH PASSWORD 'nextclouddbuserpassword';
      CREATE DATABASE nextclouddb;
      GRANT ALL PRIVILEGES ON DATABASE nextclouddb TO nextclouddbuser;
      \q
    exit

  replace_in_file "host \{1,\}all \{1,\}all \{1,\}127.0.0.1\/32 \{1,\}ident" "host all all 127.0.0.1\/32 md5" "$pg_hba"
  replace_in_file "host \{1,\}replication \{1,\}all \{1,\}::1\/128 \{1,\}ident" "host all all ::1\/128 md5" "$pg_hba"

  sudo systemctl restart postgresql-12

  #instalujemy redisa
  sudo dnf install -y redis
  sudo systemctl enable redis.service
  sudo systemctl start redis.service

  #instalujemy php7.4 wraz z wymaganymi rozszerzeniami
  call_module_function "php" "_base_install" "7.4" "php php-gd php-mbstring php-intl php-pecl-apcu php-opcache php-json php-pecl-zip php-pear php-pecl-imagick php-fpm php-pecl-redis5 php-intl php-pgsql php-common php-pdo php-xml php-lz4 php-xml php-pecl-crypto php-pecl-rar php-pecl-pq php-pecl-lzf php-cli php-pecl-apcu-bc -y"

  #zmieniamy konfigurację www.conf dla wersji 7.4
  local php_conf_file="/etc/opt/remi/php74/php-fpm.d/www.conf"
  replace_in_file ";env[HOSTNAME]" "env[HOSTNAME]" "$php_conf_file"
  replace_in_file ";env[PATH]" "env[PATH]" "$php_conf_file"
  replace_in_file ";env[TMP]" "env[TMP]" "$php_conf_file"
  replace_in_file ";env[TMPDIR]" "env[TMPDIR]" "$php_conf_file"
  replace_in_file ";env[TEMP]" "env[TEMP]" "$php_conf_file"
  replace_in_file ";php_admin_value[memory_limit] = 128M" "php_admin_value[memory_limit] = 512M" "$php_conf_file"
  replace_in_file ";php_value[opcache.file_cache]" "php_value[opcache.file_cache]" "$php_conf_file"

  #tworzymy strukturę katalogów
  sudo mkdir -p /var/lib/php/{session,opcache,wsdlcache}
  sudo chown -R root:nginx /var/lib/php/{opcache,wsdlcache}
  sudo chown -R nginx:nginx /var/lib/php/session

  #pobieramy nextclouda
  cd /tmp || exit
  wget https://download.nextcloud.com/server/releases/nextcloud-18.0.7.tar.bz2

  #pobieramy klucze do weryfikacji
  wget https://download.nextcloud.com/server/releases/nextcloud-18.0.7.tar.bz2.sha256
  wget https://download.nextcloud.com/server/releases/nextcloud-18.0.7.tar.bz2.asc
  wget https://nextcloud.com/nextcloud.asc

  #weryfikujemy paczkę
  sha256sum -c nextcloud-18.0.7.tar.bz2.sha256 < nextcloud-18.0.7.tar.bz2
  gpg --import nextcloud.asc
  gpg --verify nextcloud-18.0.7.tar.bz2.asc nextcloud-18.0.7.tar.bz2
  tar -xvf nextcloud-18.0.7.tar.bz2

  sudo rm -rf "$install_dir"
  sudo cp -r nextcloud "$install_dir"

  mkdir -p "$install_dir/data"
  sudo chown -R nginx:nginx "$install_dir"

  restart_nginx

  #określamy domenę dla konfiguracji nginxa
  _read "nextcloud_domain" "Podaj nazwę domeny (bez www i http/s)"
  local target_copy_path="/etc/nginx/sites-available/$var_nextcloud_domain.conf"
  sudo cp "./templates/nextcloud.conf" "$target_copy_path"
  replace_in_file "{{domain}}" "$var_nextcloud_domain" "$php_conf_file"

  #zagadnienia SSL
  _read "nextcloud_ssl" "Czy instalujemy SSL?" "y/n"

  #przechodzimy proces generowania SSL
  if [[ "$var_nextcloud_ssl" == "y" ]];
  then
    _cloudflare_ssl

    #jeśli proces tworzenia certyfiaktu przebiegnie pomyślnie
    #wtedy ustawiamy ścieżkę do "partu z konfiguracją ssl"
    replace_in_file "#{{security_part}}" "$output_conf_path" "$output_conf_path"
  fi

  #jeśłi nie ma być generowany certyfikat wtedy zakładamy
  #że został już wygenerowany i trzeba podać ścieżkę
  if [[ "$var_nextcloud_ssl" == "n" ]];
  then
    _read "ssl_domain_name_ssl" "Podaj nazwę pliku .conf z ustawieniami certyfikatu (/etc/nginx/ssl/< ssl_domain_ssl_path >.conf)"
    local ssl_domain_path_full="/etc/nginx/ssl/$var_ssl_domain_name_ssl.conf"
    replace_in_file "#{{security_part}}" "$ssl_domain_path_full" "$output_conf_path"
  fi
  #https://upcloud.com/community/tutorials/install-nextcloud-centos/
}


#instalacja composera
function function_install_composer() {
  _read "install_composer" "Czy instalować composera?" "y/n"

  if [[ "$var_install_composer" == "y" ]];
  then
    #wymuszamy instalację php
    if ! command_exists php;
    then
      _read "install_default_php" "Czy zainstalować domyślną wersję php?" "y/n"

      if [[ "$var_install_default_php" == "y" ]];
      then
        call_module_function "php" "function_install_default_php"
      else
        return 1
      fi
    fi

    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    local HASH="$(wget -q -O - https://composer.github.io/installer.sig)"
    php -r "if (hash_file('SHA384', 'composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
    sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer
  fi
}

#instalacja yarna
function function_install_yarn() {
  cd /tmp/ || exit
  sudo dnf install @nodejs
  curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo
  sudo rpm --import https://dl.yarnpkg.com/rpm/pubkey.gpg
  sudo dnf install yarn
}

#instaluje narzędzie symfony
function function_install_symfony() {
  _read "install_symfony" "Zainstalować CLI Symfony?" "y/n"

  if [[ "$var_install_symfony" == "y" ]];
  then
    wget https://get.symfony.com/cli/installer -O - | bash
    mv /root/.symfony/bin/symfony /usr/local/bin/symfony
  fi
}

function function_install_git() {
  install_via_dnf "git"

  _read "git_user_email" "Podaj wartość git user.email"
  _read "git_user_name" "Podaj wartość git user.name"

  git config --global user.email "$var_git_user_email"
  git config --global user.name "$var_git_user_name"
}

function _cloudflare_ssl() {
  if ! command_exists nginx; then
    _read "install_nginx" "Czy zainstalować nginx?" "y/n"

    if [[ "$var_install_nginx" == "y" ]];
    then
      call_module_function "server" "function_install_nginx"
    else
      return 1
    fi
  fi

  #instalacja właściwa
  rm -rf /tmp/acme.sh
  cd /tmp/ || exit
  git clone https://github.com/Neilpang/acme.sh.git
  touch /root/.bashrc
  cd /tmp/acme.sh/ || exit

  if ! command_exists socat;
  then
    install_via_dnf "socat"
  fi

  #wprowadzamy adres email przypisany do cloudflare
  _read "account_email" "Podaj adres email"
  sh acme.sh --install --accountemail "$var_account_email"

  #wprowadzamy wygenerowany token
  _read "account_token" "Podaj token"
  export CF_Token="$var_account_token"

  #wprowadzamy nazwę domeny i generujemy certyfikat
  _read "installed_domain" "Wprowadź nazwę domeny w postaci: domena.pl"
  sh acme.sh --issue --dns dns_cf --ocsp-must-staple --keylength 4096 -d "$var_installed_domain" -d "*.$var_installed_domain" --force

  #miejsce gdzie przenosimy pliki certyfikatu
  local new_dir="/etc/nginx/ssl/$var_installed_domain/"
  mkdir -p "$new_dir"

  #generujemy dhparam
  openssl dhparam -out "$new_dir"dhparams.pem -dsaparam 4096

  #instalujemy wilcarda
  cd /tmp/acme.sh/ || exit
  sh acme.sh -d "$var_installed_domain" --install-cert \
    --reloadcmd "systemctl reload nginx" \
    --fullchain-file "${new_dir}/fullchain.cer" \
    --key-file "${new_dir}${var_installed_domain}.key" \
    --cert-file "${new_dir}${var_installed_domain}.cer"

  #przenosimy .conf dla tej domeny
  local target_conf_path=/etc/nginx/ssl/"$var_installed_domain.conf"
  cp ./templates/base-ssl.conf "$target_conf_path"
  sudo sed -i -e "s/{{domain}}/$var_installed_domain/gi" "$target_conf_path"

  #przenosimy wygenerowane
  mv /root/.acme.sh/"$var_installed_domain"/* "$new_dir"
  cd "$new_dir" || exit

  rm -rf /tmp/acme.sh

  output_conf_path="$target_conf_path"
}

#instaluje certyfikat wilcard z cloudflare
function function_create_cloudflare_ssl() {
  _read "create_ssl" "Uruchomić proces instalacji certyfikatu?" "y/n"

  if [[ "$var_create_ssl" == "y" ]];
  then
    _cloudflare_ssl
  fi
}
