#!/usr/bin/env bash
############################################################################
# hidethatbanner.sh - (C)opyright 2018 OneCD [one.cd.only@gmail.com]
#
# This script is part of the 'HideThatBanner' package
#
# For more info: [https://forum.qnap.com/viewtopic.php?f=320&t=140215]
# Available in the Qnapclub Store: [https://qnapclub.eu/en/qpkg/560]
# Project source: [https://github.com/OneCDOnly/HideThatBanner]
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see http://www.gnu.org/licenses/.
############################################################################

Init()
    {

    THIS_QPKG_NAME=HideThatBanner
    FIRMWARE_VERSION="$(getcfg System Version -f /etc/config/uLinux.conf)"
    SOURCE_PATHFILE=/home/httpd/cgi-bin/apps/qpkg/css/qpkg.css
    BACKUP_PATHFILE="${SOURCE_PATHFILE}.bak"

    if [[ ${FIRMWARE_VERSION//.} -lt 434 ]]; then
        SUBSTR='s|.store_banner_area{margin-top:20px;height:180px;}|.store_banner_area{margin-top:20px;height:0px;}|;s|.banner_area .banner_img{height:175px;width:400px;}|.banner_area .banner_img{height:0px;width:400px;}|'
    else
        SUBSTR='s|.store_banner_area{height:200px;|.store_banner_area{height:0px;|;s|.banner_area .banner_img{height:174px;width:399px;}|.banner_area .banner_img{height:0px;width:399px;}|'
    fi

    }

LogWrite()
    {

    # $1 = message to write into NAS system log
    # $2 = event type:
    #    0 : Information
    #    1 : Warning
    #    2 : Error

    log_tool --append "[$THIS_QPKG_NAME] $1" --type "$2"

    }

Init

case "$1" in
    start)
        [[ ! -e $BACKUP_PATHFILE ]] && cp "$SOURCE_PATHFILE" "$BACKUP_PATHFILE"
        sed -i "$SUBSTR" "$SOURCE_PATHFILE"
        if ! (/bin/cmp -s "$SOURCE_PATHFILE" "$BACKUP_PATHFILE"); then
            LogWrite "App Center was patched successfully" 0
        else
            LogWrite "App Center was not patched! (QTS $FIRMWARE_VERSION)" 2
        fi
        ;;
    stop)
        [[ -e $BACKUP_PATHFILE ]] && cp "$BACKUP_PATHFILE" "$SOURCE_PATHFILE"
        ;;
    restart)
        $0 stop
        $0 start
        ;;
esac
