# This script will be sitting in /home/deploy directory, and is for setting up directories and pulling required files for docker deployment
# This script should be either rsynced or copied to the UAT server when setting up fresh server. 
# For more information, please see the documentation: https://github.com/ualbertalib/di_internal/blob/master/System-Adminstration/UAT-Environment.md

BRANCH='master'
DIR=/home/deploy/jupiter
mkdir -p $DIR
mkdir -p $DIR/config
curl -o $DIR/deploy.sh https://raw.githubusercontent.com/ualbertalib/jupiter/$BRANCH/deploy.sh
curl -o $DIR/docker-compose.deployment.yml https://raw.githubusercontent.com/ualbertalib/jupiter/$BRANCH/docker-compose.deployment.yml
curl -o $DIR/config/nginx.conf https://raw.githubusercontent.com/ualbertalib/jupiter/$BRANCH/config/nginx.conf
if [[ ! -e .env_deployment ]]; then
curl -o $DIR/.env_deployment https://raw.githubusercontent.com/ualbertalib/jupiter/$BRANCH/.env_deployment_sample
fi
source $DIR/deploy.sh
