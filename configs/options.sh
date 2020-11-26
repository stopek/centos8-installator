#!/bin/bash

# lista wersji php, które można zainstalować
# uwaga! dodanie 7.1 nie spowoduje, że będzie
# można zainstalować tą wersję
# ta lista wykorzystywana jest dodatkowo jako
# weryfikacja poprawności wyboru użytkownika
function php_versions() {
  echo '7.2/7.3/7.4/8.0'
}