#!/bin/bash -uex

_echo_color() {
  local color="$1"
  local text="${@:2}"
  #echo -e "\[\033[${color}m\]${text}\[\033[0m\]"
  echo -e "[\033[${color}m${text}\033[0m]"
}

_blue() {
  local blue='34'
  local text="$*"
  _echo_color $blue $text
}

_green() {
  local green='1;32'
  local text="$*"
  _echo_color $green $text
}

_yellow() {
  local yellow='1;33'
  local text="$*"
  _echo_color $yellow $text
}

_purple() {
  local purple='0;35'
  local text="$*"
  _echo_color $purple $text
}

_red() {
  local red='31'
  local text="$*"
  _echo_color $red $text
}

_git_check(){
  NAME=$(basename `git rev-parse --show-toplevel`)
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  printf "%-30s" "Fetching $NAME"
  printf "%-20s" "[$BRANCH] .. "

  git remote update > /dev/null 2>&1 || { _red "Failed remote (repository)"; exit 1; }
  git rev-parse @{u} > /dev/null 2>&1|| { _red "Failed remote (branch)"; exit 1; }

  LOCAL=$(git rev-parse @)
  REMOTE=$(git rev-parse @{u})
  BASE=$(git merge-base @ @{u})

  if [ $LOCAL = $REMOTE ]; then
    text='Up-to-date'
    _blue "$text"
  elif [ $LOCAL = $BASE ]; then
    text='Pull updates'
    _purple "$text"
  elif [ $REMOTE = $BASE ]; then
    text='Push changes'
    _yellow "$text"
  else
    text='Diverged'
    _red "$text"
  fi
}

_git_check_repo() {
  local REPODIR="$1"
  [[ -d $REPODIR ]] || return 1
  [[ -d "${REPODIR}/.git" ]] || return 1
  (
    cd $REPODIR && _git_check
  )
}

_git_check_repos() {
  #local REPOS="$1"
  local REPOS=$([ $# -gt 0 ] && echo "$1" || echo "$PWD")
  echo "Checking status of repositories in '$REPOS'"
  for d in `ls -1 $REPOS`
  do
    local REPO="${REPOS}/$d"
    [[ ! -d $REPO  ]] && continue
    [[ ! -d "${REPO}/.git" ]] && continue
    _git_check_repo "$REPO"
  done
}

git-check() {
  _git_check_repos "$@"
}

