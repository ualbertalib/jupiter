cd /home/deploy/jupiter && git pull origin master
docker-compose -f /home/deploy/jupiter/docker-compose.deployment.yml rm -f -s -v
docker rmi $(docker images -f "dangling=true" -q)
docker-compose -f /home/deploy/jupiter/docker-compose.deployment.yml build web
docker-compose -f /home/deploy/jupiter/docker-compose.deployment.yml up -d
