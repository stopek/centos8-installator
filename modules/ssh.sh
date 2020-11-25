#!/bin/bash

source ./utils/common.sh

function function_create_ssh() {
  _read "create_ssh_key" "Rozpocząć proces tworzenia klucza?" "y/n"

  if [[ "$var_create_ssh_key" == "y" ]]; then
    ip=$(curl -s https://api.ipify.org)
    _read "ssh_user_email" "Podaj adres email"
    ssh-keygen -t rsa -b 4096 -C "$var_ssh_user_email"

    _read "ssh_user_name" "Podaj nazwę użytkownika"
    ssh-copy-id "$var_ssh_user_name"@"$ip"

    local auth_file="/etc/ssh/sshd_config"
    replace_in_file "PasswordAuthentication yes" "PasswordAuthentication no" "$auth_file"
    replace_in_file "ChallengeResponseAuthentication yes" "ChallengeResponseAuthentication no" "$auth_file"
    replace_in_file "UsePAM yes" "UsePAM no" "$auth_file"

    sudo systemctl restart sshd.service

    echo -e "Klucz został wygenerowany"
    public=$(cat ~/.ssh/id_rsa.pub)
    echo -e "\e[97m\e[104m$public\e[0m"
  fi
}


#fragment odpowiedzialny za określenie nowego portu i ustawienie
# $1 - ścieżka do pliku: sshd_config
# $2 - wartość z któej zamieniamy np. (#Port 22) lub (Port 12345) - bez nawiasów
# $3 - stary port do usunięcia
function function_ssh_set_port() {
  _read "new_port_number" "Podaj nowy port"
  replace_in_file "$2" "Port $var_new_port_number" "$1"
  echo "Port został zmieniony z domyślnego na $var_new_port_number"

  sudo semanage port -a -t ssh_port_t -p tcp "$var_new_port_number"
  sudo systemctl enable firewalld
  sudo systemctl start firewalld
  sudo firewall-cmd --add-port="$var_new_port_number/tcp" --permanent
  sudo firewall-cmd --remove-service=ssh --permanent
  sudo firewall-cmd --reload
  sudo systemctl restart sshd

  netstat -tunl | grep "$var_new_port_number"
}

#fragment prosi o podanie prawidłowego aktualnego adresu portu
function function_ssh_change_port() {
  _read "old_port_number" "Podaj stary port ssh"

  #jeśli w pliku znaleziono zapis: Port <port> wtedy
  if string_exists_in_file "Port $var_old_port_number";
  then
      function_ssh_set_port "$1" "Port $var_old_port_number" "$var_old_port_number"
  else
    echo "Nie mogę znaleźć, chyba ustawiłeś wcześniej inny port";
    function_ssh_change_port "$1"
  fi
}


function function_ssh_port() {
  _read "change_ssh_port" "Rozpocząć proces zmiany portu SSH?" "y/n"

  if [[ "$var_change_ssh_port" == "y" ]]; then
    #tworzymy kopię
    local sh_file="/etc/ssh/sshd_config"
    local date_format=$(date +%Y_%m_%d:%H:%M:%S)

    sudo cp "$sh_file" "${sh_file}_${date_format}"

    #znaleziono domyślną wartość czyli jeszcze nie został zmieniany port
    if string_exists_in_file "#Port 22" "$sh_file";
    then
      function_ssh_set_port $sh_file "#Port 22"
    #nie znaleziono, zakładamy, że była zmiana
    else
      function_ssh_change_port $sh_file
    fi

    semanage port -l | grep ssh
  fi
}