#!/usr/bin/env bash
# This script setups dockerized Redash on macOS 10.14.
set -eu

REDASH_BASE_PATH=/usr/local/var/redash

install_docker(){
    # Install Docker
    brew cask install docker

    # Install Docker Compose
    #sudo curl -L https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
    #sudo chmod +x /usr/local/bin/docker-compose

}

install_tools(){
    # Install pwgen
    brew install pwgen
    brew install wget
}

create_directories() {
    if [[ ! -e $REDASH_BASE_PATH ]]; then
        sudo mkdir -p $REDASH_BASE_PATH
        sudo chown $USER:$USER $REDASH_BASE_PATH
    fi

    if [[ ! -e $REDASH_BASE_PATH/postgres-data ]]; then
        mkdir $REDASH_BASE_PATH/postgres-data
    fi
}

create_config() {
    if [[ -e $REDASH_BASE_PATH/env ]]; then
        rm $REDASH_BASE_PATH/env
        touch $REDASH_BASE_PATH/env
    fi

    COOKIE_SECRET=$(pwgen -1s 32)
    SECRET_KEY=$(pwgen -1s 32)
#   POSTGRES_PASSWORD=$(pwgen -1s 32)
#   REDASH_DATABASE_URL="postgresql://postgres:${POSTGRES_PASSWORD}@postgres:5432/postgres"
   REDASH_DATABASE_URL="postgresql://postgres:postgres@postgres/postgres"


    echo "PYTHONUNBUFFERED=0" >> $REDASH_BASE_PATH/env
    echo "REDASH_LOG_LEVEL=INFO" >> $REDASH_BASE_PATH/env
    echo "REDASH_REDIS_URL=redis://redis:6379/0" >> $REDASH_BASE_PATH/env
#    echo "POSTGRES_PASSWORD=$POSTGRES_PASSWORD" >> $REDASH_BASE_PATH/env
    echo "POSTGRES_PASSWORD=postgres" >> $REDASH_BASE_PATH/env
    echo "REDASH_COOKIE_SECRET=$COOKIE_SECRET" >> $REDASH_BASE_PATH/env
    echo "REDASH_SECRET_KEY=$SECRET_KEY" >> $REDASH_BASE_PATH/env
    echo "REDASH_DATABASE_URL=$REDASH_DATABASE_URL" >> $REDASH_BASE_PATH/env
}

setup_compose() {
    REQUESTED_CHANNEL=stable
    LATEST_VERSION=`curl -s "https://version.redash.io/api/releases?channel=$REQUESTED_CHANNEL"  | json_pp  | grep "docker_image" | head -n 1 | awk 'BEGIN{FS=":"}{print $3}' | awk 'BEGIN{FS="\""}{print $1}'`

#    if [[ -e $REDASH_BASE_PATH/docker-compose.yml ]]; then
#        rm $REDASH_BASE_PATH/docker-compose.yml
        cp ~/projects/redash-setup/data/docker-compose.yml $REDASH_BASE_PATH/docker-compose.yml
#    fi

    cd $REDASH_BASE_PATH
#    GIT_BRANCH="${REDASH_BRANCH:-master}" # Default branch/version to master if not specified in REDASH_BRANCH env var
#    wget https://raw.githubusercontent.com/getredash/setup/${GIT_BRANCH}/data/docker-compose.yml
#    sed -if "s/image: redash\/redash:([A-Za-z0-9.-]*)/image: redash\/redash:$LATEST_VERSION/" docker-compose.yml
    echo "export COMPOSE_PROJECT_NAME=redash" >> ~/.bash_profile
    echo "export COMPOSE_FILE=/usr/local/var/redash/docker-compose.yml" >> ~/.bash_profile
    export COMPOSE_PROJECT_NAME=redash
    export COMPOSE_FILE=/usr/local/var/redash/docker-compose.yml
    docker-compose run --rm server create_db
    docker-compose up -d
}

#install_docker
#install_tools
#create_directories
create_config
setup_compose