#!/usr/bin/env bash

APP_CONTAINER=$(sudo docker ps -a -q --filter="name=app")
NEW_CONTAINER="app`date '+%y%m%d%H%M%S'`"
REGISTRY="registry.hanlingo.com/jinseokoh/laravel-app"
DANGLING_IMGS=$(sudo docker image ls -f "dangling=true" -q)
RUNNING_IMG=$(sudo docker inspect $(sudo docker ps -a -q --filter="name=app") | grep -m 1 -o 'sha256[^"]*')
CURRENT_IMG=$(sudo docker image inspect $REGISTRY | grep -m 1 -o 'sha256[^"]*')

# 1) pull the latest image
sudo docker pull $REGISTRY

# avoid deployment if running image is latest
if [ "$CURRENT_IMG" == "$RUNNING_IMG" ]; then
    echo "The latest image is already in use."
    exit 0
fi

# 2) spin off new instance
NEW_APP_CONTAINER=$(sudo docker run -d --network=app-network --restart=unless-stopped --name="$NEW_CONTAINER" $REGISTRY)

# wait for processes to boot up
sleep 5
echo "Started new container $NEW_APP_CONTAINER"

# 3) update nginx
sudo sed -i "s/server app.*/server $NEW_CONTAINER:80;/" /opt/conf.d/proxy.conf

# config test
sudo docker exec nginx nginx -t
NGINX_STABLE=$?

if [ $NGINX_STABLE -eq 0 ]; then
    # reload nginx
    sudo docker kill -s HUP nginx

    # 4) stop older instance
    sudo docker stop $APP_CONTAINER
    sudo docker rm -v $APP_CONTAINER
    echo "Removed old container $APP_CONTAINER"

    # cleanup
    if [ ! -z "$DANGLING_IMGS" ]; then
        sudo docker image rm $DANGLING_IMGS
    fi
else
    echo "ERROR: nginx config test failed."
    exit 1
fi