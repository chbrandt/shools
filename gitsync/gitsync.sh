#!/bin/bash

USER="chbrandt"

URL="https://api.github.com/users/$USER/repos"

repos=$(curl --silent https://api.github.com/users/chbrandt/repos | grep 'ssh_url' | cut -d'"' -f4)

for repourl in ${repos[@]};
do
    repogit=$(basename $repourl)
    reponame=${repogit%%.git}
    echo $reponame $repogit $repourl
done

