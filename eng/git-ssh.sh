#!/bin/sh
# Usar las claves de WSL al sincronizar desde Git para Windows.
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) exec wsl.exe --exec ssh "$@" ;;
  *) exec ssh "$@" ;;
esac
