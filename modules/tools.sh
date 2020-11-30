#!/bin/bash

# instalacja nextclouda
# https://upcloud.com/community/tutorials/install-nextcloud-centos/
function function_install_nextcloud() {
  require_nginx
  require_php74_remi

  # użytkownik lokalny
  local -r nextcloud_user="nextcloud"
  local -r nextcloud_password="123abc456def1121"

  # użytkownik lokalny do postgresql
  local -r postgres_user="postgres"
  local -r postgres_password="123abc456def1121"

  # użytkownik do logowania się do bazy danych
  local -r nextcloud_db_user="nextclouddbuser"
  local -r nextcloud_db_password="123abc456def1121"
  local -r nextcloud_db_name="nextclouddb"

  # użytkownik/administrator do zarządzania samym nextcloudem
  local -r admin_login="admin"
  local -r admin_password="123abc456def1121"

  local -r pg_hba="/var/lib/pgsql/12/data/pg_hba.conf"
  local -r install_dir="/var/www/nextcloud"
  local -r data_dir="/usr/share/nginx/data"
  local -r php_conf_file="/etc/opt/remi/php74/php-fpm.d/www.conf"
  local -r nextcloud_config_file="${install_dir}/config/config.php"

  # tworzenie użytkownika
  adduser "${nextcloud_user}"
  (echo "${nextcloud_password}"; echo "${nextcloud_password}") | passwd "${nextcloud_user}"
  usermod -aG wheel "${nextcloud_user}"

  # dodanie repo i instalacja postgresql
  sudo dnf -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm

  sudo dnf -qy module disable postgresql
  sudo dnf -y install postgresql12 postgresql12-server
  sudo /usr/pgsql-12/bin/postgresql-12-setup initdb
  sudo systemctl enable postgresql-12
  sudo systemctl start postgresql-12
  (echo "${postgres_password}"; echo "${postgres_password}") | passwd "${postgres_user}"

  # tworzymy bazę i użytkownika nextcloudowego
  sudo -u "${postgres_user}" psql -c "CREATE USER ${nextcloud_db_user} WITH PASSWORD '${nextcloud_db_password}';"
  sudo -u "${postgres_user}" psql -c "CREATE DATABASE ${nextcloud_db_name};"
  sudo -u "${postgres_user}" psql -c "GRANT ALL PRIVILEGES ON DATABASE ${nextcloud_db_name} TO ${nextcloud_db_user};"
  sudo -u "${postgres_user}" psql -c "ALTER DATABASE ${nextcloud_db_name} OWNER TO ${nextcloud_db_user};"

  replace_in_file "host \{1,\}all \{1,\}all \{1,\}127.0.0.1/32 \{1,\}ident" "host all all 127.0.0.1/32 md5" "$pg_hba"
  replace_in_file "host \{1,\}all \{1,\}all \{1,\}::1/128 \{1,\}ident" "host all all ::1/128 md5" "$pg_hba"

  sudo systemctl restart postgresql-12

  # instalujemy redisa i uruchamiamy usługę
  install_via_dns_service "redis"

  # zmieniamy konfigurację www.conf dla wersji 7.4
  replace_in_file ";env[HOSTNAME]" "env[HOSTNAME]" "$php_conf_file"
  replace_in_file ";env[PATH]" "env[PATH]" "$php_conf_file"
  replace_in_file ";env[TMP]" "env[TMP]" "$php_conf_file"
  replace_in_file ";env[TMPDIR]" "env[TMPDIR]" "$php_conf_file"
  replace_in_file ";env[TEMP]" "env[TEMP]" "$php_conf_file"
  replace_in_file ";php_admin_value[memory_limit] = 128M" "php_admin_value[memory_limit] = 512M" "$php_conf_file"
  replace_in_file ";php_value[opcache.file_cache]" "php_value[opcache.file_cache]" "$php_conf_file"

  # tworzymy strukturę katalogów
  sudo mkdir -p /var/lib/php/{session,opcache,wsdlcache}
  sudo chown -R root:nginx /var/lib/php/{opcache,wsdlcache}
  sudo chown -R nginx:nginx /var/lib/php/session

  cd /tmp/ || exit

  # pobieramy nextclouda jeśli paczka nie istnieje.
  if [ ! -f "nextcloud-18.0.7.tar.bz2" ];
  then
    wget https://download.nextcloud.com/server/releases/nextcloud-18.0.7.tar.bz2
  fi

  # pobieramy klucze do weryfikacji
  wget https://download.nextcloud.com/server/releases/nextcloud-18.0.7.tar.bz2.sha256
  wget https://download.nextcloud.com/server/releases/nextcloud-18.0.7.tar.bz2.asc
  wget https://nextcloud.com/nextcloud.asc

  # weryfikujemy paczkę
  sha256sum -c nextcloud-18.0.7.tar.bz2.sha256 < nextcloud-18.0.7.tar.bz2
  gpg --import nextcloud.asc
  gpg --verify nextcloud-18.0.7.tar.bz2.asc nextcloud-18.0.7.tar.bz2
  tar -xvf nextcloud-18.0.7.tar.bz2

  ask_for_remove_dir_if_exists "$install_dir"

  sudo cp -r nextcloud "$install_dir"

  mkdir -p "$install_dir/data"
  sudo chown -R nginx:nginx "$install_dir"

  # konfigurujemy ses linux aby nextcloud
  # miał dostęp do tych folderów
  sudo mkdir -p "${data_dir}"
  sudo semanage fcontext -a -t httpd_sys_rw_content_t "${data_dir}(/.*)?"
  sudo semanage fcontext -a -t httpd_sys_rw_content_t "${install_dir}/config(/.*)?"
  sudo semanage fcontext -a -t httpd_sys_rw_content_t "${install_dir}/apps(/.*)?"
  sudo semanage fcontext -a -t httpd_sys_rw_content_t "${install_dir}/.htaccess"
  sudo semanage fcontext -a -t httpd_sys_rw_content_t "${install_dir}/.user.ini"
  sudo semanage fcontext -a -t httpd_sys_rw_content_t "${install_dir}/3rdparty/aws/aws-sdk-php/src/data/logs(/.*)?"

  sudo restorecon -R "${install_dir}/"
  sudo restorecon -R "${data_dir}/"
  sudo setsebool -P httpd_can_network_connect on

  sudo chown -R nginx:nginx "${data_dir}"
  sudo chown -R nginx:nginx "${install_dir}"
  # określamy domenę dla konfiguracji nginxa
  _read "nextcloud_domain" "Podaj nazwę domeny (bez www i http/s np. cloud.domena.pl)"

  # shellcheck disable=SC2154
  local -r target_copy_path="/etc/nginx/sites-available/$var_nextcloud_domain.conf"
  # na wszelki wypadek usuwamy plik jeśli istnieje
  rm -rf "${target_copy_path}"
  sudo cp "${base}/templates/nextcloud.conf" "$target_copy_path"

  local -r sites_enabled_dir="/etc/nginx/sites-enabled/"

  # na wszelki wypadek usuwamy dowiązanie
  rm -rf "${sites_enabled_dir}${var_nextcloud_domain}.conf"
  sudo ln -s "$target_copy_path" "${sites_enabled_dir}"

  replace_in_file "{{domain}}" "$var_nextcloud_domain" "$target_copy_path"
  replace_in_file "{{fastcgi_pass}}" "127.0.0.1:9074" "$target_copy_path"

  # zagadnienia SSL
  _read "nextcloud_ssl" "Czy instalujemy SSL?" "y/n"

  # przechodzimy proces generowania SSL
  # shellcheck disable=SC2154
  if [[ "$var_nextcloud_ssl" == "y" ]];
  then
    _cloudflare_ssl

    # jeśli proces tworzenia certyfiaktu przebiegnie pomyślnie
    # wtedy ustawiamy ścieżkę do "partu z konfiguracją ssl"
    replace_in_file "{{security_part}}" "include ${output_conf_path};" "$target_copy_path"
  fi

  # jeśłi nie ma być generowany certyfikat wtedy zakładamy
  # że został już wygenerowany i trzeba podać ścieżkę
  if [[ "$var_nextcloud_ssl" == "n" ]];
  then
    _read "ssl_domain_name_ssl" "Podaj nazwę pliku .conf z ustawieniami certyfikatu (/etc/nginx/ssl/< ssl_domain_ssl_path >.conf)"
    # shellcheck disable=SC2154
    local -r ssl_domain_path_full="/etc/nginx/ssl/${var_ssl_domain_name_ssl}.conf"
    replace_in_file "{{security_part}}" "include ${ssl_domain_path_full};" "${target_copy_path}"
  fi


  cd "${install_dir}" || exit

  echo "Rozpoczynam instalację Nextcloud"
  sudo -u nginx php74 occ maintenance:install \
  --data-dir "${data_dir}" \
  --database "pgsql" \
  --database-name "${nextcloud_db_name}" \
  --database-user "${nextcloud_db_user}" \
  --database-pass "${nextcloud_db_password}" \
  --admin-user "${admin_login}" \
  --admin-pass "${admin_password}"

  sudo -u nginx php74 occ db:add-missing-indices
  sudo -u nginx php74 occ maintenance:mode --on
  sudo -u nginx php74 occ db:convert-filecache-bigint
  sudo -u nginx php74 occ maintenance:mode --off

  # dodajemy host zaufany
  replace_in_file "0 => 'localhost'," "0 => 'localhost', 1 => '${var_nextcloud_domain}'," "${nextcloud_config_file}"

  restart_nginx

  return 0
}

# instalacja composera
function function_install_composer() {
  _read "install_composer" "Czy instalować composera?" "y/n"

  # shellcheck disable=SC2154
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
    local -r hash="$(wget -q -O - https://composer.github.io/installer.sig)"
    php -r "if (hash_file('SHA384', 'composer-setup.php') === '$hash') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
    sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer
  fi
}

# instalacja yarna
function function_install_yarn() {
  cd /tmp/ || exit
  sudo dnf install @nodejs
  curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo
  sudo rpm --import https://dl.yarnpkg.com/rpm/pubkey.gpg
  sudo dnf install yarn
}

# instaluje cli symfony
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
  require_nginx
  require_git
  require_socat

  # instalacja właściwa
  rm -rf /tmp/acme.sh
  cd /tmp/ || exit
  git clone https://github.com/Neilpang/acme.sh.git
  touch /root/.bashrc
  cd /tmp/acme.sh/ || exit

  # wprowadzamy adres email przypisany do cloudflare lub pobieramy z configu
  local var_account_email=$(get_config "data" "cloudflare_email")
  echo "$var_account_email"
  if [[ -z "$var_account_email" ]];
  then
    _read "account_email" "Podaj adres email"
    echo "$var_account_email"
  fi
  sh acme.sh --install --accountemail "$var_account_email"

  # wprowadzamy wygenerowany token lub pobieramy z configu
  local var_account_token=$(get_config "data" "cloudflare_token")
  if [[ -z "$var_account_token" ]];
  then
    _read "account_token" "Podaj token (https://dash.cloudflare.com/profile/api-tokens)"
  fi
  export CF_Token="$var_account_token"

  # wprowadzamy nazwę domeny i generujemy certyfikat
  _read "installed_domain" "Wprowadź nazwę domeny w postaci: domena.pl"
  sh acme.sh --issue --dns dns_cf --ocsp-must-staple --keylength 4096 -d "$var_installed_domain" -d "*.$var_installed_domain" --force

  # miejsce gdzie przenosimy pliki certyfikatu
  local new_dir="/etc/nginx/ssl/$var_installed_domain/"
  mkdir -p "$new_dir"

  # generujemy dhparam
  openssl dhparam -out "$new_dir"dhparams.pem -dsaparam 4096

  # instalujemy wilcarda
  cd /tmp/acme.sh/ || exit
  sh acme.sh -d "$var_installed_domain" --install-cert \
    --reloadcmd "systemctl reload nginx" \
    --fullchain-file "${new_dir}/fullchain.cer" \
    --key-file "${new_dir}${var_installed_domain}.key" \
    --cert-file "${new_dir}${var_installed_domain}.cer"

  # przenosimy .conf dla tej domeny
  local target_conf_path=/etc/nginx/ssl/"$var_installed_domain.conf"
  cp "${base}/templates/cloudflare.ssl.conf" "$target_conf_path"
  sudo sed -i -e "s/{{domain}}/$var_installed_domain/gi" "$target_conf_path"

  # przenosimy wygenerowane
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
