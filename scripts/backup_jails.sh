#!/usr/bin/env bash

date=$(date +%Y%m%d%H%M%S)
jails=/mnt/jails/iocage/jails
backup=/mnt/media/backup/jails

function cleanup {
    local jail=$1
    local destination=$2
    printf "Failed backing up %s\n" "$jail" >&2
    if [[ -n $destination ]]; then
        rm -rf "$destination"
    fi
    return 1
}

function backup {
    local jail=$1
    shift
    local destination=$backup/$jail
    local jail_root=$jails/$jail/root
    local start
    local end
    start=$(date +%s)
    # shellcheck disable=SC2064
    trap "cleanup $jail" EXIT
    if [[ ! -e $destination ]]; then
        mkdir "$destination"
        mkdir "$destination/current"
    fi
    mkdir "$destination/$date"
    # shellcheck disable=SC2064
    trap "cleanup $jail $destination/$date" EXIT
    (
        cd "$jail_root"
        rsync \
            --archive \
            --link-dest="$destination/current" \
            --log-file="$destination/$date/rsync.log" \
            "$@" \
            "$destination/$date"
    )
    rm -r "$destination/current"
    ln -s "$date" "$destination/current"
    trap EXIT
    printf "Successfully backed up %s\n" "$jail"
    end=$(date +%s)
    printf "Backup took %d seconds\n" "$((end-start))" >> "$destination/$date/rsync.log"
}

(set -e; backup rtorrent usr/local/libdata/rtorrent/.rtorrent.session usr/local/www/rutorrent/share)
(set -e; backup sabnzbd usr/local/sabnzbd/sabnzbd.ini)
(set -e; backup sonarr usr/local/sonarr/{nzbdrone.db,nzbdrone.db-shm,nzbdrone.db-wal,config.xml})
(set -e; backup radarr usr/local/radarr/{nzbdrone.db,nzbdrone.db-shm,nzbdrone.db-wal,config.xml})
(set -e; backup plex "usr/local/plexdata/Plex Media Server/Preferences.xml" "usr/local/plexdata/Plex Media Server/Plug-in Support/Databases")
(set -e; backup stats var/db/grafana/grafana.db var/db/influxdb)
