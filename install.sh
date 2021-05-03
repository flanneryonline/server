#!/usr/bin/env bash

exec 2> >(logger -s -t $(basename $0))

set -e

SERVER_INSTALL=${SERVER_INSTALL:-/opt/server}
. "$SERVER_INSTALL/environment"
. "$SERVER_INSTALL/include"

[ ! -e /etc/update-motd.d/00-header ] && \
    ln -s /opt/server/bin/motd/00-header /etc/update-motd.d/00-header
[ ! -h /etc/update-motd.d/00-header ] && \
    rm -r /etc/update-motd.d/00-header && \
    ln -s /opt/server/bin/motd/00-header /etc/update-motd.d/00-header

[ ! -e /etc/update-motd.d/10-info ] && \
    ln -s /opt/server/bin/motd/10-info /etc/update-motd.d/10-info
[ ! -h /etc/update-motd.d/10-info ] && \
    rm -r /etc/update-motd.d/10-info && \
    ln -s /opt/server/bin/motd/10-info /etc/update-motd.d/10-info

[ ! -e /etc/update-motd.d/20-services ] && \
    ln -s /opt/server/bin/motd/20-services /etc/update-motd.d/20-services
[ ! -h /etc/update-motd.d/20-services ] && \
    rm -r /etc/update-motd.d/20-services && \
    ln -s /opt/server/bin/motd/20-services /etc/update-motd.d/20-services

[ ! -e /etc/update-motd.d/30-storage ] && \
    ln -s /opt/server/bin/motd/30-storage /etc/update-motd.d/30-storage
[ ! -h /etc/update-motd.d/30-storage ] && \
    rm -r /etc/update-motd.d/30-storage && \
    ln -s /opt/server/bin/motd/30-storage /etc/update-motd.d/30-storage

#echo "\"Samsung SSD 840 EVO 120G B\"                            190  C  \"Samsung SSD 840 EVO 120GB\"" >> /etc/hddtemp.db

systemctl disable motd-news.service
systemctl disable motd-news.timer
systemctl enable /opt/server/systemd/system/foss-motdupdate.timer
systemctl enable /opt/server/systemd/system/foss-motdupdate.service

#FlanneryOnlineSystemServices Symlinks
systemctl enable /opt/server/systemd/FlanneryOnlineSystemServices/foss-diskscrub.service
systemctl enable /opt/server/systemd/FlanneryOnlineSystemServices/foss-diskscrub.timer
systemctl enable /opt/server/systemd/FlanneryOnlineSystemServices/foss-docker-clean.service
systemctl enable /opt/server/systemd/FlanneryOnlineSystemServices/foss-docker-clean.timer
systemctl enable /opt/server/systemd/FlanneryOnlineSystemServices/foss-docker-health.service
systemctl enable /opt/server/systemd/FlanneryOnlineSystemServices/foss-docker-health.timer
systemctl enable /opt/server/systemd/FlanneryOnlineSystemServices/foss-motd-update.service
systemctl enable /opt/server/systemd/FlanneryOnlineSystemServices/foss-motd-update.timer

#FlanneryOnlineDockerServices Symlinks
systemctl enable /opt/server/systemd/FlanneryOnlineDockerServices/fods.target
systemctl enable /opt/server/systemd/FlanneryOnlineDockerServices/media/fods-media.target
systemctl enable /opt/server/systemd/FlanneryOnlineDockerServices/vpn/fods-vpn.target
systemctl enable /opt/server/systemd/FlanneryOnlineDockerServices/fods@.service

for service in /opt/server/docker/games/*
do
    [ -f $service ] && [ $(cat /opt/server/docker/games/$service) != "" ] && systemctl enable /opt/server/systemd/FlanneryOnlineDockerServices/fods@games-default-$service.service
done
for service in /opt/server/docker/games/vpn/*
do
    [ -f $service ] && [ $(cat /opt/server/docker/games/vpn/$service) != "" ] && systemctl enable /opt/server/systemd/FlanneryOnlineDockerServices/fods@games-vpn-$service.service
done

for service in /opt/server/docker/system/*
do
    [ -f $service ] && [ $(cat /opt/server/docker/system/$service) != "" ] && systemctl enable /opt/server/systemd/FlanneryOnlineDockerServices/fods@system-default-$service.service
done
for service in /opt/server/docker/system/vpn/*
do
    [ -f $service ] && [ $(cat /opt/server/docker/system/vpn/$service) != "" ] && systemctl enable /opt/server/systemd/FlanneryOnlineDockerServices/fods@system-vpn-$service.service
done

for service in /opt/server/docker/media/*
do
    [ -f $service ] && [ $(cat /opt/server/docker/media/$service) != "" ] && systemctl enable /opt/server/systemd/FlanneryOnlineDockerServices/fods@media-default-$service.service
done
for service in /opt/server/docker/media/vpn/*
do
    [ -f $service ] && [ $(cat /opt/server/docker/media/vpn/$service) != "" ] && systemctl enable /opt/server/systemd/FlanneryOnlineDockerServices/fods@media-vpn-$service.service
done

systemctl daemon-reload

