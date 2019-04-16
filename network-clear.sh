docker rm -f $(docker ps -aq)
docker volume rm $(docker volume ls -q)
docker system prune -f
docker rmi -f $(docker images|awk '($1 ~ /dev-peer.*.mycc.*/) {print $3}')
