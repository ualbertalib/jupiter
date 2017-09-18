docker rmi $(docker images -f "dangling=true" -q)
docker-compose -f /home/deploy/jupiter/docker-compose.deployment.yml pull web
docker-compose -f /home/deploy/jupiter/docker-compose.deployment.yml up -d
docker-compose -f /home/deploy/jupiter/docker-compose.deployment.yml run --rm web rake db:migrate
#Recompile assets is optional, and can be commented out if not needed
docker-compose -f /home/deploy/jupiter/docker-compose.deployment.yml run --rm web rake assets:precompile
