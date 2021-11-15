#!/usr/bin/env bash

exec 2> >(logger -s -t $(basename $0))

set -e

SERVER_INSTALL=${SERVER_INSTALL:-/opt/server}
. "$SERVER_INSTALL/environment"

services_setup() {
    #FlanneryOnlineSystemServices Symlinks
    systemctl enable $SERVER_INSTALL/systemd/system/foss-docker-clean.service
    systemctl enable $SERVER_INSTALL/systemd/system/foss-docker-clean.timer

    #FlanneryOnlineDockerServices Symlinks
    systemctl enable $SERVER_INSTALL/systemd/docker/fods-proxy.service
    systemctl start fods-proxy.service
    systemctl enable $SERVER_INSTALL/systemd/docker/fods@.service

    for service in $(ls $SERVER_INSTALL/docker/$HOSTNAME)
    do
        systemctl enable fods@$service.service
    done

    systemctl daemon-reload

    $SERVER_INSTALL/bin/sdstart -a

    return 0
}

services_setup