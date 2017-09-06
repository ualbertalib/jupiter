cd /home/deploy/jupiter && git fetch --all && git reset --hard origin/master
docker-compose -f /home/deploy/jupiter/docker-compose.deployment.yml stop web
docker rmi $(docker images -f "dangling=true" -q)
docker-compose -f /home/deploy/jupiter/docker-compose.deployment.yml build web
docker-compose -f /home/deploy/jupiter/docker-compose.deployment.yml up -d
