# remove all containers
alias docker_rm_all='for c in `docker ps -a | grep -v "^CONTAINER" | cut -d" " -f1`; do docker rm $c; done'

