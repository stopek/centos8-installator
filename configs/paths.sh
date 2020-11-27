#!/bin/bash

# scieżka gdzie zainstalowane są projekty www
# ścieżka absolutna względem /
function www_dir() {
  echo '/var/www'
}

# zwraca ścieżkę do katalogu z menu
# ścieżka powinna byc bezwzględna względem
# głównego pliku .sh
function menu_dir() {
  echo '/menus'
}

# zwraca ścieżkę do katalogu z narzędziami
# ścieżka powinna byc bezwzględna względem
# głównego pliku .sh
# powinna rozpoczynać się / i nie zawierać
# go na samym końcu
function utils_dir() {
  echo "/utils"
}

# zwraca ścieżkę do katalogu z modułami
# ścieżka powinna byc bezwzględna względem
# głównego pliku .sh
# powinna rozpoczynać się / i nie zawierać
# go na samym końcu
function modules_dir() {
  echo "/modules"
}

# zwraca ścieżkę do katalogu z controllerami
# ścieżka powinna byc bezwzględna względem
# głównego pliku .sh
# powinna rozpoczynać się / i nie zawierać
# go na samym końcu
function controller_dir() {
  echo "/controllers"
}

# zwraca ścieżkę do katalogu z logami
# ścieżka powinna byc bezwzględna względem
# głównego pliku .sh
# powinna rozpoczynać się / i nie zawierać
# go na samym końcu
function logs_dir() {
  echo "/logs"
}

# zwraca ścieżkę do katalogu z ustawieniami
# ścieżka powinna byc bezwzględna względem
# głównego pliku .sh
# powinna rozpoczynać się / i nie zawierać
# go na samym końcu
function configs_dir() {
  echo "/configs"
}