#!/bin/bash

USER="chbrandt"

URL="https://api.github.com/users/$USER/repos"

REPOS=$(curl --silent https://api.github.com/users/chbrandt/repos | grep 'ssh_url' | cut -d'"' -f4)

is_null_arg(){
    # Return True(=0) if argument ($1) exist, False(=1) otherwise
    test -z "$1"
}

status(){
    # Just verify repo status
    # Args:
    # - $1 : repository's dir (name without the ".git" extension)
    is_null_arg $1 && exit 1 
    reponame="$1"
    echo "#=================================="
    echo "#=== $reponame"
    echo "#--- status"
    (cd $reponame && git status) || return $?
    echo "#----------------------------------"
    echo "#=================================="
    return 0
}

clone(){
    # Clone a repo
    # Args:
    # - $1 : repository url
    is_null_arg $1 && exit 1
    repourl="$1"
    git clone $repourl || return $?
    return 0
}

fetch(){
    # Fetch repo
    # Args:
    # - $1 : repository's dir
    is_null_arg $1 && exit 1
    reponame="$1"
    echo "#=================================="
    echo "#=== $reponame"
    echo "#--- fetch"
    (cd $reponame && git fetch) || return $?
    echo "#----------------------------------"
    echo "#=================================="
    return 0
}

pull(){
    # Pull repo
    # Args:
    # - $1 : repository's dir
    is_null_arg $1 && exit 1
    reponame="$1"
    echo "#=================================="
    echo "#=== $reponame"
    echo "#--- pull"
    (cd $reponame && git pull) || return $?
    echo "#----------------------------------"
    echo "#=================================="
    return 0
}

for repourl in ${REPOS[@]};
do
    repogit=$(basename $repourl)
    reponame=${repogit%%.git}

    [[ ! -d "$reponame" ]] && continue

    # Fetch is always done!!!
    fetch $reponame
    status $reponame
done

