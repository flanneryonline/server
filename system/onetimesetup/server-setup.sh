#!/usr/bin/env bash

exec 2> >(logger -s -t $(basename $0))

set -e

SERVER_INSTALL=${SERVER_INSTALL:-/opt/server}
. "$SERVER_INSTALL/environment"
. "$SERVER_INSTALL/include"

server_setup() {
    #locale
    locale-gen --purge en_US.UTF-8
    errorcheck && return 1
    update-locale LANG=en_US.UTF-8
    errorcheck && return 1

    #timezone
    echo "linking timezone info to /etc/localtime"
    [ -f "/etc/localtime" ] && rm "/etc/localtime"
    [ -h "/etc/localtime" ] && rm "/etc/localtime"
    ln -s "/usr/share/zoneinfo/$SERVER_TIMEZONE" /etc/localtime
    errorcheck && return 1
    echo "creating /etc/timezone"
    echo $SERVER_TIMEZONE > /etc/timezone
    errorcheck && return 1

    #hostname
    echo "setting hostname file"
    [ -f "/etc/hostname" ] && rm "/etc/hostname"
    [ -h "/etc/hostname" ] && rm "/etc/hostname"
    echo $SERVER_HOSTNAME > "/etc/hostname"
    echo "setting hosts file"
    [ -f "/etc/hosts" ] && rm "/etc/hosts"
    [ -h "/etc/hosts" ] && rm "/etc/hosts"
    echo "127.0.0.1 localhost" > "/etc/hosts"
    echo "127.0.0.1 $SERVER_FQDN $SERVER_HOSTNAME" >> "/etc/hosts"

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

    apt-get update -qq
    errorcheck && echoerr "error during apt-get update" && return 1
    apt-get upgrade -qq --no-install-recommends
    errorcheck && echoerr "error during apt-get upgrade" && return 1
    apt-get dist-upgrade -qq --no-install-recommends
    errorcheck && echoerr "error during apt-get dist-upgrade" && return 1

    apt-get update -qq
    apt-get install -qq --no-install-recommends docker-ce

    #syslog
    echo "setting syslog to remote host $SYSLOG_ADDRESS:$SYSLOG_PORT"
    rm "/etc/rsyslog.d/"*
    echo "*.* @$SYSLOG_ADDRESS:$SYSLOG_PORT" > "/etc/rsyslog.d/50-default.conf"

    admin_password=$(/opt/server/bin/fo-getsetting "password")

    #users
    groupadd -g $ADMIN_GROUP_ID $ADMIN_USERNAME
    errorcheck && return 1
    groupadd -g $DOCKER_PGID doc
    errorcheck && return 1
    useradd -m -u $ADMIN_USER_ID -g $ADMIN_USERNAME \
        -G plugdev,sudo,doc -s /bin/bash $ADMIN_USERNAME
    errorcheck && return 1
    useradd -r -u $DOCKER_PUID -g doc -s /sbin/nologin doc
    errorcheck && return 1
    echo "$ADMIN_USERNAME:$admin_password" | chpasswd
    errorcheck && return 1

    usermod -g docker $ADMIN_USERNAME

    return 0
}
