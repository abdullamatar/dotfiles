#!/bin/sh
# Symlink dotfiles into $HOME. Existing targets are moved to <target>.bak.<timestamp>.
# Usage: ./install.sh [nvim] [vim] [bash]      default: nvim vim
set -eu

DOT=$(cd "$(dirname "$0")" && pwd)
STAMP=$(date +%Y%m%d-%H%M%S)

link() { # link <src> <dst>
  src=$1 dst=$2
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    echo "ok      $dst"
    return
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mv "$dst" "$dst.bak.$STAMP"
    echo "backup  $dst -> $dst.bak.$STAMP"
  fi
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  echo "link    $dst -> $src"
}

[ $# -gt 0 ] || set -- nvim vim
for t in "$@"; do
  case $t in
  nvim) link "$DOT/nvim" "${XDG_CONFIG_HOME:-$HOME/.config}/nvim" ;;
  vim) link "$DOT/.vimrc" "$HOME/.vimrc" ;;
  bash) link "$DOT/.bashrc" "$HOME/.bashrc" ;;
  *)
    echo "unknown target: $t (nvim|vim|bash)" >&2
    exit 1
    ;;
  esac
done

case " $* " in *" nvim "*)
  if command -v nvim >/dev/null 2>&1; then
    echo "restoring plugins pinned in nvim/lazy-lock.json ..."
    nvim --headless "+Lazy! restore" +qa
    echo "done. First interactive launch installs treesitter parsers and mason tools."
  else
    echo "nvim not found. Install nvim >= 0.11.2, then run: nvim --headless '+Lazy! restore' +qa" >&2
  fi
  ;;
esac
