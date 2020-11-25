#!/bin/bash

source ./utils/common.sh

function animation() {
  if ! command_exists pv; then
    dnf install pv
  fi

  curl -s http://artscene.textfiles.com/vt100/castle.vt | pv -q -L 9600
}

function star_wars() {
  telnet towel.blinkenlights.nl
}
