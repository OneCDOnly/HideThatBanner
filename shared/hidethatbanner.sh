#!/usr/bin/env bash
############################################################################
# sort-my-qpkgs.sh - (C)opyright 2018 OneCD [one.cd.only@gmail.com]
#
# This script is part of the 'HideThatBanner' package
#
# For more info: [https://forum.qnap.com/viewtopic.php?f=320&t=133132]
#
# Available in the Qnapclub Store: [https://qnapclub.eu/en/qpkg/508]
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

SOURCE_PATHFILE="/home/httpd/cgi-bin/apps/qpkg/css/qpkg.css"
BACKUP_PATHFILE="${SOURCE_PATHFILE}.bak"

case "$1" in
    start)
		cp "$SOURCE_PATHFILE" "$BACKUP_PATHFILE"
		sed -i 's|.store_banner_area{margin-top:20px;height:180px;}|.store_banner_area{margin-top:20px;height:0px;}|;s|.banner_area .banner_img{height:175px;width:400px;}|.banner_area .banner_img{height:0px;width:400px;}|' "$SOURCE_PATHFILE"
        ;;
    stop)
		cp "$BACKUP_PATHFILE" "$SOURCE_PATHFILE"
        ;;
	restart)
		$0 stop
		$0 start
		;;
esac
