#!/bin/bash

function animation() {
  if ! command_exists pv; then
    install_via_dnf "epel-release"
    install_via_dnf "pv"
  fi

  curl -s http://artscene.textfiles.com/vt100/castle.vt | pv -q -L 9600
}

function star_wars() {
  telnet towel.blinkenlights.nl
}
