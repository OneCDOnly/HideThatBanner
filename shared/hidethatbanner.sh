#!/usr/bin/env bash
###############################################################################
# hidethatbanner.sh - (C)opyright 2018-2023 OneCD [one.cd.only@gmail.com]

# This script is part of the 'HideThatBanner' package

# For more info: [https://forum.qnap.com/viewtopic.php?f=320&t=140215]
# Available in the myqnap store: [https://myqnap.org]
# Project source: [https://github.com/OneCDOnly/HideThatBanner]

# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.

# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.

# You should have received a copy of the GNU General Public License along with
# this program. If not, see http://www.gnu.org/licenses/.
###############################################################################

Init()
    {

    readonly QPKG_NAME=HideThatBanner
    readonly CONFIG_PATHFILE=/etc/config/qpkg.conf

    if [[ ! -e $CONFIG_PATHFILE ]]; then
        echo "file not found [$CONFIG_PATHFILE]"
        SetServiceOperationResultFailed
        exit 1
    fi

    readonly SED_CMD=/bin/sed
    local APP_CENTER_NOTIFIER=/sbin/qpkg_cli     # only needed for QTS 4.5.1-and-later
    readonly SOURCE_PATHFILE=/home/httpd/cgi-bin/apps/qpkg/css/qpkg.css
    readonly BACKUP_PATHFILE=${SOURCE_PATHFILE}.bak
    readonly NAS_FIRMWARE=$(/sbin/getcfg System Version -f /etc/config/uLinux.conf)
    readonly SERVICE_STATUS_PATHFILE=/var/run/$QPKG_NAME.last.operation

    /sbin/setcfg "$QPKG_NAME" Status complete -f "$CONFIG_PATHFILE"

    # KLUDGE: force-cancel QTS 4.5.1 App Center notifier status as it's often wrong. :(
    [[ -e $APP_CENTER_NOTIFIER ]] && $APP_CENTER_NOTIFIER -c "$QPKG_NAME" > /dev/null 2>&1

    }

LogWrite()
    {

    # $1 = message to write into NAS system log
    # $2 = event type:
    #   0 = Information
    #   1 = Warning
    #   2 = Error

    /sbin/log_tool --append "[$QPKG_NAME] $1" --type "$2"

    }

SetServiceOperationResultOK()
    {

    SetServiceOperationResult ok

    }

SetServiceOperationResultFailed()
    {

    SetServiceOperationResult failed

    }

SetServiceOperationResult()
    {

    # $1 = result of operation to recorded

    [[ -n $1 && -n $SERVICE_STATUS_PATHFILE ]] && echo "$1" > "$SERVICE_STATUS_PATHFILE"

    }

Init

case "$1" in
    start)
        [[ ! -e $BACKUP_PATHFILE ]] && cp "$SOURCE_PATHFILE" "$BACKUP_PATHFILE"

        if [[ ${NAS_FIRMWARE//.} -lt 451 ]]; then
            $SED_CMD -i 's|.store_banner_area{|.store_banner_area{display:none;|' "$SOURCE_PATHFILE"
        elif [[ ${NAS_FIRMWARE//.} -lt 500 ]]; then
            $SED_CMD -i 's|.store_banner_area,.banner_area{|.store_banner_area,.banner_area{display:none;|' "$SOURCE_PATHFILE"
        else
            $SED_CMD -i 's|.store_banner_area,.banner_area{|.store_banner_area,.banner_area{display:none;|' "$SOURCE_PATHFILE"
            $SED_CMD -i 's| .banner_show{| .banner_show{display:none;|' "$SOURCE_PATHFILE"
        fi

        if ! (/bin/cmp -s "$SOURCE_PATHFILE" "$BACKUP_PATHFILE"); then
            LogWrite 'App Center was patched successfully' 0
            SetServiceOperationResultOK
        else
            LogWrite "App Center was not patched! (QTS $NAS_FIRMWARE)" 2
            SetServiceOperationResultFailed
        fi
        ;;
    stop)
        [[ -e $BACKUP_PATHFILE ]] && cp "$BACKUP_PATHFILE" "$SOURCE_PATHFILE"
        SetServiceOperationResultOK
        ;;
    restart)
        $0 stop
        $0 start
        ;;
    *)
        echo "run as: $0 {start|stop|restart}"
esac
