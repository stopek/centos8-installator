#!/bin/bash

source ./utils/common.sh



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
  simple_via_dnf "git"

  _read "git_user_email" "Podaj wartość git user.email"
  _read "git_user_name" "Podaj wartość git user.name"

  git config --global user.email "$var_git_user_email"
  git config --global user.name "$var_git_user_name"
}

#instaluje certyfikat wilcard z cloudflare
function function_create_cloudflare_ssl() {
  _read "create_ssl" "Uruchomić proces instalacji certyfikatu?" "y/n"

  if [[ "$var_create_ssl" == "y" ]];
  then
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
      simple_via_dnf "socat"
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
  fi
}
