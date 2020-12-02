#!/bin/bash -x

TRUE=0
FALSE=1

# generuje menu z pliku
# $1 - ścieżka do pliku .txt z wpisami menu bez .txt na końcu
function generate_menu() {
  # shellcheck disable=SC2154
  local menu_filepath="${base}/menus/${1}.txt"

  if file_exists "$menu_filepath";
  then
    cat "$menu_filepath" | sed 's/\t/,|,/g' | column -s ',' -t
  else
    echo "Menu $menu_filepath nie istnieje"
  fi
}

function double_column() {
    echo "$1,$2" | column -s ',' -t
}

# wyświetla błąd
# $1 - treść wiadomości
function warning() {
  local -r message="${1}"
  echo -e "\e[37m\e[41m${message}\e[0m"
}

# to nie jest zwykła linia
# to magiczna linia oddzielająca
# dobro od zła!
# cześć magicznej linii!
function line() {
  echo "+-----------------------------------------------------------------------------+"
}

# sprawdza czy dana usługa jest zainstalowana
# $1 - nazwa usługi (np. nginx)
function service_exists() {
  if service --status-all | grep -Fq "$1";
  then
    return 0
  else
    return 1
  fi
}

# sprawdza czy funkcja istnieje
# $1 - nazwa funkcji
#
# function_exists function_name && echo "Exists" || echo "No such function"
function function_exists() {
    declare -f -F "$1" > /dev/null
    return $?
}

# zwykla funkcja in_array
function array_contains() {
  local seeking=$1
  shift
  local in=1
  for element; do
    if [[ $element == "$seeking" ]]; then
      in=0
      break
    fi
  done
  return $in
}

# formater wproawdzania danych
# $1 - nazwa zmiennej
# $2 - opis/pytanie dot. wprowadzanej wartości
# $3 - dostępne opcje wprowadzone po / (np: y/x). Jeśli puste wtedy tylko wymaga wprowadzenia.
# $4 - parametry do read (domyślnie: "-r -p")
function _read() {
  IFS='/' read -ra my_array <<<"$3"

  echo -e "\e[30m\e[107m"
  line
  echo "| $2 "

  if [[ "$3" != ":allow_empty:" ]];
  then
    if [ -n "$3" ];
    then
      echo "| <dostępne: $3>"
    else
      echo "| <wprowadź dowolnie>"
    fi
  fi

  line

  declare -g var_$1
  local ref=var_$1

  # jeśli parametr $4 nie zostanie przekazany
  # wtedy użytkownik może wprowadzić dowolny
  # tekst i potwierdzić go ENTER'em
  #
  # w przeciwnym razie ustawiamy tak, żeby
  # potwierdzenie było od razu po wciśnięciu
  # pierwszego znaku
  if [ -z "$4" ];
  then
    read -r -p "| " "var_$1"
  else
    local -r escape_char=$(printf "\u1b")
    read -r ${4} " " "var_$1"

    #jeśli znak jest specjalny wtedy potrzebujemy "2" znaków
    if [[ ${!ref} == "$escape_char" ]]; then
      read -r ${5} " " "var_$1"
    fi
  fi

  log "app" "Na pytanie: ${2} wybrał: ${!ref}"

  echo
  line

  if [ -n "$3" ];
  then
    if [[ "$3" != ":allow_empty:" ]];
    then
      if ! array_contains "${!ref}" "${my_array[@]}"; then
        echo -e "\e[37m\e[41mWartość nieprawidłowa, spróbuj ponownie...\e[0m"
        echo ""

        _read "$1" "$2" "$3"
      fi
    fi
  else
    if [ -z "${!ref}" ]; then
      echo -e "\e[37m\e[41mWartość pusta, wprowadź wartość...\e[0m"
      echo ""
      _read "$1" "$2" "$3"
    fi
  fi

  echo -e "\e[0m"
}

# sprawdza czy dana komenda istnieje
# $1 - nazwa komendy (np. nano)
function command_exists() {
  type "$1" &>/dev/null
}

# instalacja z repo yum
# $1 - nazwa paczki do zainstalownia (np. nginx)
function simple_via_yum_modules() {
  sudo yum module install "${1}"
}

# instalacja przez dnf
# $1 - nazwa paczki do zainstalowania (np. nginx)
function install_via_dnf() {
  sudo dnf install "${1}"
}

# instalacja przez dnf
# dodatkowo funkcja uruchamia teraz
# i dodaje usługę do autoloadu
# $1 - nazwa paczki do zainstalowania (np. nginx)
function install_via_dns_service() {
  sudo dnf install -y "${1}"
  sudo systemctl enable "${1}.service"
  sudo systemctl start "${1}.service"
}

# zamienia wszystkie / na \/
# $1 - tekst do zamiany
function escape_forward_slashes() {
  # Validate parameters
  if [ -z "$1" ]
  then
    echo -e "Error - no parameter specified!"
    return 1
  fi

  # Perform replacement
  echo ${1} | sed -e "s#/#\\\/#g"
  return 0
}

# zamienia treść w pliku
# $1 - treść do zamiany
# $2 - treść, na którą będzie zamieniane
# $3 - plik, w którym zamieniamy
function replace_in_file() {
  local -r slashed_from=$(escape_forward_slashes "${1}")
  local -r slashed_to=$(escape_forward_slashes "${2}")

  sudo sed -i -e "s/${slashed_from}/${slashed_to}/gi" "$3"
}

# pyta użytkownika o usunięcie folderu z zawartością
# jeśli folder istnieje
function ask_for_remove_dir_if_exists() {
  local -r dir_to_remove="${1}"
  if [[ -d "${dir_to_remove}" ]];
  then
    #określamy domenę dla konfiguracji nginxa
    _read "remove_existing_dir" "Katalog ${dir_to_remove} istnieje. Usunąć razem z zawartością?" "y/n"

    # shellcheck disable=SC2154
    if [[ "$var_remove_existing_dir" == "y" ]];
    then
      sudo rm -rf "${dir_to_remove}"
    fi
  fi
}

# funkcja pobiera klucze z tablicy asocjacyjnej
# i sortuje je rosnąco zwracając klucze
# $1 - tablica asocjacyjna
function get_and_sort_array_by_keys() {
  local -n data_ref=$1

  for KEY in "${!data_ref[@]}"; do
    echo "$KEY"
  done | sort | awk -F::: '{print $1}'
}

# funkcja koloruje na wskazany kolor
# przekazany string/funkcję
# $1 - tekst do kolorowania
# $2 - zastosowany kolor
# $3 - warunek bool true|false
function conditionally_colorize() {
  local -r text="${1}"
  local -r color="${2}"
  local -r condition=`expr $3`

  if [[ ${condition} = "1" ]];
  then
    printf "${color}"
  fi

  echo "${text}"

  if [[ ${condition} = "1" ]];
  then
      printf "\e[0m"
  fi
}

# sprawdza czy plik istnieje
# $1 - ścieżka do pliku
function file_exists() {
  if [[ -f "$1" ]];
  then
    return $TRUE
  else
    return $FALSE
  fi
}

# restartowanie nginx jeśli zainstalowany
function restart_nginx() {
  if command_exists nginx; then
    sudo systemctl restart nginx.service
  fi
}

# funkcja sprawdza czy w danym pliku znaleziono stringa
# $1 - szukana treść
# $2 - nazwa pliku
function string_exists_in_file() {
  if [[ $(grep "$1" $2) ]];
  then
    return $TRUE
  else
    return $FALSE
  fi
}