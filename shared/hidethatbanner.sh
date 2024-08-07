#!/usr/bin/env bash
###############################################################################
# hidethatbanner.sh
# 	copyright 2018-2024 OneCD
#
# Contact:
#	one.cd.only@gmail.com
#
# This script is part of the 'HideThatBanner' package
#
# Available in the MyQNAP store: https://www.myqnap.org/product/hidethatbanner
# Project source: https://github.com/OneCDOnly/HideThatBanner
# Community forum: https://forum.qnap.com/viewtopic.php?t=140215
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
###############################################################################

set -o nounset -o pipefail
shopt -s extglob
ln -fns /proc/self/fd /dev/fd		# KLUDGE: `/dev/fd` isn't always created by QTS.

readonly USER_ARGS_RAW=$*

Init()
    {

    readonly QPKG_NAME=HideThatBanner

    readonly NAS_FIRMWARE=$(/sbin/getcfg System Version -f /etc/config/uLinux.conf)
    readonly QPKG_VERSION=$(/sbin/getcfg $QPKG_NAME Version -f /etc/config/qpkg.conf)
	readonly SERVICE_ACTION_PATHFILE=/var/log/$QPKG_NAME.action
	readonly SERVICE_RESULT_PATHFILE=/var/log/$QPKG_NAME.result
    readonly SOURCE_PATHFILE=/home/httpd/cgi-bin/apps/qpkg/css/qpkg.css
        readonly BACKUP_PATHFILE=${SOURCE_PATHFILE}.bak

    /sbin/setcfg "$QPKG_NAME" Status complete -f /etc/config/qpkg.conf

    # KLUDGE: 'clean' the QTS 4.5.1 App Center notifier status.
    [[ -e /sbin/qpkg_cli ]] && /sbin/qpkg_cli --clean "$QPKG_NAME" > /dev/null 2>&1

    }

StartQPKG()
    {

    [[ ! -e $BACKUP_PATHFILE ]] && cp "$SOURCE_PATHFILE" "$BACKUP_PATHFILE"

    if [[ ${NAS_FIRMWARE//.} -lt 451 ]]; then
        /bin/sed -i 's|.store_banner_area{|.store_banner_area{display:none;|' "$SOURCE_PATHFILE"
    elif [[ ${NAS_FIRMWARE//.} -lt 500 ]]; then
        /bin/sed -i 's|.store_banner_area,.banner_area{|.store_banner_area,.banner_area{display:none;|' "$SOURCE_PATHFILE"
    else
        /bin/sed -i 's|.store_banner_area,.banner_area{|.store_banner_area,.banner_area{display:none;|' "$SOURCE_PATHFILE"
        /bin/sed -i 's| .banner_show{| .banner_show{display:none;|' "$SOURCE_PATHFILE"
    fi

    if ! (/bin/cmp -s "$SOURCE_PATHFILE" "$BACKUP_PATHFILE"); then
        LogWrite 'App Center UI was patched successfully.' 0
        return 0
    else
        LogWrite "App Center UI was not patched ($(GetQnapOS) $NAS_FIRMWARE)." 2
        return 1
    fi

    }

StopQPKG()
    {

    [[ -e $BACKUP_PATHFILE ]] && mv "$BACKUP_PATHFILE" "$SOURCE_PATHFILE"
    return 0

    }

StatusQPKG()
    {

    if [[ -e $BACKUP_PATHFILE ]] && ! (/bin/cmp -s "$SOURCE_PATHFILE" "$BACKUP_PATHFILE"); then
        echo active
        exit 0
    else
        echo inactive
        exit 1
    fi

    }

ShowTitle()
    {

    echo "$(ShowAsTitleName) $(ShowAsVersion)"

    }

ShowAsTitleName()
	{

	TextBrightWhite $QPKG_NAME

	}

ShowAsVersion()
	{

	printf '%s' "v$QPKG_VERSION"

	}

ShowAsUsage()
    {

    echo -e "\nUsage: $0 {start|stop|restart|status}"

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

GetQnapOS()
	{

	if /bin/grep -q zfs /proc/filesystems; then
		printf 'QuTS hero'
	else
		printf QTS
	fi

	}

SetServiceAction()
	{

	service_action=${1:-none}
	CommitServiceAction
	SetServiceResultAsInProgress

	}

SetServiceResultAsOK()
	{

	service_result=ok
	CommitServiceResult

	}

SetServiceResultAsFailed()
	{

	service_result=failed
	CommitServiceResult

	}

SetServiceResultAsInProgress()
	{

	# Selected action is in-progress and hasn't generated a result yet.

	service_result=in-progress
	CommitServiceResult

	}

CommitServiceAction()
	{

    echo "$service_action" > "$SERVICE_ACTION_PATHFILE"

	}

CommitServiceResult()
	{

    echo "$service_result" > "$SERVICE_RESULT_PATHFILE"

	}

TextBrightWhite()
	{

	[[ -n ${1:-} ]] || return

    printf '\033[1;97m%s\033[0m' "$1"

	}

Init

user_arg=${USER_ARGS_RAW%% *}		# Only process first argument.

case $user_arg in
    ?(--)restart)
        SetServiceAction restart

        if StopQPKG && StartQPKG; then
            SetServiceResultAsOK
        else
            SetServiceResultAsFailed
        fi
        ;;
    ?(--)start)
        SetServiceAction start

        if StartQPKG; then
            SetServiceResultAsOK
        else
            SetServiceResultAsFailed
        fi
        ;;
    ?(-)s|?(--)status)
        StatusQPKG
		;;
    ?(--)stop)
        SetServiceAction stop

        if StopQPKG; then
            SetServiceResultAsOK
        else
            SetServiceResultAsFailed
        fi
        ;;
    *)
        ShowTitle
        ShowAsUsage
esac

exit 0
