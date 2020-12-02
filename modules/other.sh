#!/bin/bash

# animacja generująca proste
# intro disneya
function animation() {
  if ! command_exists pv; then
    install_via_dnf "epel-release"
    install_via_dnf "pv"
  fi

  curl -s http://artscene.textfiles.com/vt100/castle.vt | pv -q -L 9600
}

# animacja generująca Star Wars
# nie wiadomo jak długi jest pokaz
# twórca nie odpowiada za zbyt
# małą ilość przygotowoanego
# popcornu i coli!
function star_wars() {
  require_simple_dnf "telnet"

  telnet towel.blinkenlights.nl
}
