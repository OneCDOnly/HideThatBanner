#!/usr/bin/env bash
###############################################################################
# hidethatbanner.sh
# 	Copyright 2018-2025 OneCD
#
# Contact:
#	one.cd.only@gmail.com
#
# Description:
#   This script is part of the 'HideThatBanner' package
#
# Available in the MyQNAP store:
#   https://www.myqnap.org/product/hidethatbanner
#
# And via the sherpa package manager:
#	https://git.io/sherpa
#
# Project source:
#   https://github.com/OneCDOnly/HideThatBanner
#
# Community forum:
#   https://community.qnap.com/t/qpkg-hidethatbanner/1098
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
[[ -L /dev/fd ]] || ln -fns /proc/self/fd /dev/fd		# KLUDGE: `/dev/fd` isn't always created by QTS.
readonly r_user_args_raw=$*

Init()
    {

    readonly r_qpkg_name=HideThatBanner

    # KLUDGE: mark QPKG installation as complete.

    /sbin/setcfg $r_qpkg_name Status complete -f /etc/config/qpkg.conf

    # KLUDGE: 'clean' the QTS 4.5.1+ App Center notifier status.

    [[ -e /sbin/qpkg_cli ]] && /sbin/qpkg_cli --clean $r_qpkg_name &> /dev/null

    readonly r_nas_firmware=$(/sbin/getcfg System Version -f /etc/config/uLinux.conf)
    readonly r_qpkg_version=$(/sbin/getcfg $r_qpkg_name Version -f /etc/config/qpkg.conf)
	readonly r_service_action_pathfile=/var/log/$r_qpkg_name.action
	readonly r_service_result_pathfile=/var/log/$r_qpkg_name.result
    readonly r_source_pathfile=/home/httpd/cgi-bin/apps/qpkg/css/qpkg.css
        readonly r_backup_pathfile=$r_source_pathfile.bak

    }

StartQPKG()
    {

    [[ ! -e $r_backup_pathfile ]] && cp "$r_source_pathfile" "$r_backup_pathfile"

    if [[ ${r_nas_firmware//.} -lt 451 ]]; then
        /bin/sed -i 's|.store_banner_area{|.store_banner_area{display:none;|' "$r_source_pathfile"
    elif [[ ${r_nas_firmware//.} -lt 500 ]]; then
        /bin/sed -i 's|.store_banner_area,.banner_area{|.store_banner_area,.banner_area{display:none;|' "$r_source_pathfile"
    else
        /bin/sed -i 's|.store_banner_area,.banner_area{|.store_banner_area,.banner_area{display:none;|' "$r_source_pathfile"
        /bin/sed -i 's| .banner_show{| .banner_show{display:none;|' "$r_source_pathfile"
    fi

    if ! (/bin/cmp -s "$r_source_pathfile" "$r_backup_pathfile"); then
        LogWrite 'App Center UI was patched successfully.' 0
        return 0
    else
        LogWrite "App Center UI was not patched ($(GetQnapOS) $r_nas_firmware)." 2
        return 1
    fi

    }

StopQPKG()
    {

    [[ -e $r_backup_pathfile ]] && mv "$r_backup_pathfile" "$r_source_pathfile"
    return 0

    }

StatusQPKG()
    {

    if [[ -e $r_backup_pathfile ]] && ! (/bin/cmp -s "$r_source_pathfile" "$r_backup_pathfile"); then
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

	TextBrightWhite $r_qpkg_name

	}

ShowAsVersion()
	{

	printf '%s' "v$r_qpkg_version"

	}

ShowAsUsage()
    {

    echo -e "\nUsage: $0 {start|stop|restart|status}"

	}

LogWrite()
    {

    # Inputs: (local)
    #   $1 = message to write into NAS system log
    #   $2 = event type:
    #       0 = Information
    #       1 = Warning
    #       2 = Error

    /sbin/log_tool --append "[$r_qpkg_name] ${1:-}" --type "${2:-}"

    }

GetQnapOS()
	{

	if /bin/grep zfs /proc/filesystems &> /dev/null; then
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

    echo "$service_action" > "$r_service_action_pathfile"

	}

CommitServiceResult()
	{

    echo "$service_result" > "$r_service_result_pathfile"

	}

TextBrightWhite()
	{

	[[ -n ${1:-} ]] || return

    printf '\033[1;97m%s\033[0m' "${1:-}"

	}

Init

user_arg=${r_user_args_raw%% *}		# Only process first argument.

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
