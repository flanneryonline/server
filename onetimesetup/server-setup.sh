#!/usr/bin/env bash

exec 2> >(logger -s -t $(basename $0))

set -e

#####

# add to conf
#
# lxc.apparmor.profile = unconfined
# lxc.cgroup.devices.allow: a
# lxc.cap.drop:

####

#root login
#/etc/ssh/sshd_config
#permitrootlogin yes

#git
#apt install git curl gnupg2 vim

#clone
#git clone https://github.com/flanneryonline/server

#exe
#chmod +x /opt/server/system/onetimesetup/server-setup.sh
#/opt/server/system/onetimesetup/server-setup.sh

#vim
#PlugInstall

SERVER_INSTALL=${SERVER_INSTALL:-/opt/server}
. "$SERVER_INSTALL/environment"

server_setup() {

    #timezone
    echo "linking timezone info to /etc/localtime"
    [ -f "/etc/localtime" ] && rm "/etc/localtime"
    [ -h "/etc/localtime" ] && rm "/etc/localtime"
    ln -s "/usr/share/zoneinfo/$SERVER_TIMEZONE" /etc/localtime
    echo "creating /etc/timezone"
    echo $SERVER_TIMEZONE > /etc/timezone

    #apt
    echo "setting up system package management"
    [ -f "/etc/apt/sources.list" ] && rm "/etc/apt/sources.list"
    touch "/etc/apt/sources.list"
    [ "$(ls -A "/etc/apt/sources.list.d")" ] && \
        rm "/etc/apt/sources.list.d/"*

    echo "deb [arch=amd64] $SERVER_DIST_URL $SERVER_DIST_RELEASE main universe" \
        >>  "/etc/apt/sources.list.d/$SERVER_DIST.$SERVER_DIST_RELEASE.list"
    echo "deb [arch=amd64] $SERVER_DIST_URL $SERVER_DIST_RELEASE-updates main universe" \
        >>  "/etc/apt/sources.list.d/$SERVER_DIST.$SERVER_DIST_RELEASE.updates.list"
    echo "deb [arch=amd64] $SERVER_DIST_URL $SERVER_DIST_RELEASE-security main universe" \
        >>  "/etc/apt/sources.list.d/$SERVER_DIST.$SERVER_DIST_RELEASE.security.list"

    curl -fsSL https://download.docker.com/linux/$SERVER_DIST/gpg | apt-key add -
    [ -f /etc/apt/sources.list.d/$SERVER_DIST.$SERVER_DIST_RELEASE.docker.list ] && \
        rm /etc/apt/sources.list.d/$SERVER_DIST.$SERVER_DIST_RELEASE.docker.list
    echo "deb [arch=amd64] https://download.docker.com/linux/$SERVER_DIST $SERVER_DIST_RELEASE stable" \
        >  /etc/apt/sources.list.d/$SERVER_DIST.$SERVER_DIST_RELEASE.docker.list

    echo "App updates"
    apt-get update -qq
    apt-get upgrade -qq --no-install-recommends
    apt-get dist-upgrade -qq --no-install-recommends
    apt-get autoremove -qq
    apt-get install docker-ce -qq --no-install-recommends

    echo "installing docker compose"
    curl -L "https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    groupadd -g $DOCKER_PGID doc
    useradd -r -u $DOCKER_PUID -g doc -s /sbin/nologin doc

    return 0
}

server_setup