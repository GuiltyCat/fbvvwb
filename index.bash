#!/bin/bash
# set -e
#
# File Browser and Viewer Via Web Browser (FBVVWB)
# ================================================
#
# ```
#      _________________________________
#     //___// _ \| V /| V /| V  V // _ \\
#    //___// // /|  //|  //|  /  // // //
#   ///   / // \\| // | // | /| // // \\
#  ///   /____// |//  |//  |//|//____//
# ```
#
# Motivation
# -----------
#
# I want to read manga(comics) zip file saved in my PC from iPad.
# However, I cannot find any good free app that support stream reading.
# Some apps are paid, some apps are with advertisement and
# some apps require file downloading.
# I do not want to pay money for software.
#
# Thus I implement this script.
# Now I can browse file and read manga in my PC via web browser.
# And more I can do more things.
# For example, see videos, listen to musics, search files...
#
# Description
# -----------
#
# This script is a simple file browser and viewer that works on a web server as CGI.
# It is like file browsing app with simple viewer.
#
# You can
#
# - Browse files under your home directory (default setting).
# - View manga and images.
# 	- Archive is suported (.zip .rar .tar.gz ...)
# 	- Dual page mode is supported.
# - Watch movies.
# - Listen musics.
# - Trash files.
#
# This script is supported to work in Local Area Network (LAN).
# ***NEVER ALLOW ACCESS TO THIS SCRIPT WITHOUT YOU!***
# You must deny all accesses from others.
# See security section for more information.
#
# Requirements
# ---------------
#
# - Web server software that can run bash as CGI
# 	- Apache,....
# - Bash
# 	- grep, sed, cut, whoami, :,
# - unar/lsar
# - trash-cli
# - locale
#
# Security
# --------
#
# This script is very dangerous.
# Never allow access to this CGI without you.
#
# At Least, you should enable `suexec` and `Digest Authentication` if you use Apache.
# And more, you should enable TLS and use HTTPS if you can do,
#
# ### sample setting
#
# `/etc/httpd/conf/httpd.conf`
#
# ```
# LoadModule suexec_module modules/mod_suexec.so
# ...
# # I use cgid not cgi.
# LoadModule cgid_module modules/mod_cgid.so
# # LoadModule cgi_module modules/mod_cgi.so
# ...
# SuexecUserGroup <user name> <user name>
# <Directory "/srv/http/cgi-bin">
#    AllowOverride None
#    Options None
#    AuthType Digest
#    AuthName "<authentication name>"
#    AuthUserFile "<file path created by htdigest>"
#    Require valid-user
# </Directory>
# ...
# # I have only one directory in home thus I use *.
# # <Directory "/home/<user name>">
# <Directory "/home/*">
#     AllowOverride None
#     Options FollowSymLinks Indexes
#     AuthType Digest
#     AuthName "<authentication name"
#     AuthUserFile "<file path created by htdigest"
#     Require valid-user
# </Directory>
# ...
# <IfModule userdir_module>
#     UserDir disabled
#     UserDir enabled <user name>
#     UserDir ./
# </IfModule>
#
# ```
#
# If you need more security,
# you should add some codes.
#
# Installation
# --------------
#
# - Put this CGI script on your web server.
# 	- For example, `/srv/http/cgi-bin/index.bash`.
# - Wake up your web server.
# 	- For example, `sudo systemctl start httpd.service`
# 	- For example, `sudo systemctl start httpd.service`
# - Access to this CGI script by browser.
#
# I put this script in `/srv/http/cgi-bin` as `/srv/http/cgi-bin/index.bash`
# I access by `http://localhost/cgi-bin/index.bash`.
# Or from other device `http://192.168.1.<num>/cgi-bin/index.bash`.
#
# Avairable Query
# ------
# ```
# http://<address>?<query>
# <query> := <query>&<query>
# <query> := <key>=<value>
# ```
#
# Query is automatically passed to next page
# except for some dangerous query like trash.
#
# You can manually add queries in order to change setting.
#
# Sample
#     http://localhost?page=1&cp=/home/bob/file.zip
#
# Query Key List
#
# ```
# cp=<path>
#    current path. You can set absolute path.
# 	 For example, cp=/home/bob/
#    For security, it must start with /home/$(whoami),
#    and must not contain .. (to upper directory).
#
# mode=<history>
#    If you want to see history.
#    set mode=history.
#    In other case, you should not set.
#    This script automatically use this option.
#    Some options are used to trash a file.
#
#    For example, if you set mode=trash.
#    The file of cp is trashed.
#
# File Browse Mode
#
# Photo View and Manga View mode
#
# percent=<percent>
#     This percent is used to set <img width=percent%> tag.
#     Default is 80.
# page=<num>
#     Select manga page.
#     In dual page mode, it means smaller page.
#     If negative or over max page is set,
#     it will automatically fixed to 1 and max.
# view_mode=<dual or single>
#     If dual, dual image is showedd in one page.
#     Otherwise single page.
# order=<lr or lr>
#     In dual mode, reading page left to right or right to left.
# ```
#
# _________________________________________
#
#
# Program Description
# ===================
#
# Parsing options
# ---------------
#
# This CGI script is written in bash.
# Thus you can run this from terminal.
#
# If there is no options are passed.
#
# Avairable options are
#
# ```
# - `-h`      : Generate markdown document from this script.
# - `--generate-readme` or `-g`
#             : Generate README.md from `-h` option's output.
# - otherwise : Ignored.
# ```
#
# If options are set, this script run as non-CGI mode.
#
if [[ "$#" -ne 0 ]]; then
	while [[ "$#" -ne 0 ]]; do
		case "$1" in
		-h)
			grep "^#" "$0" | tail -n+3 | sed -e 's/^[ \t]*[#]\+[ ]\{0,1\}//'
			;;
		--generate-readme | -g)
			bash "$0" -h >"README.md"
			;;
		*)
			echo "Such option is not allowed."
			;;
		esac
		shift
	done
	exit
fi

# ## MIME type
#
# Apache requires MIME type.
# `Content-Type: text/html\n\n`
#
cat <<EOF
Content-Type: text/html

EOF

#
# ## Read Config File
#
# Yet implemented
#
# ```
# FBVVWB_CONFIG="/home/$(whoami)/.fbvvwb_conf"
# if [[ ! -f "${FBVVWB_CONFIG}" ]]; then
# fi
# ```
#

# ## Prepare files
#
# Default top directory is defined by`TOP_DIRECTORY`.
# You can change by your self
#
TOP_DIRECTORY="/home/$(whoami)"

# If you want to disable trash link.
# make DISABLE_TRASH="true"
#
DISABLE_TRASH="false"

# # FBWWB's temporary directory and files.
#
# FBWWB use several temporary directory and files.
# Default directory is `/home/<usr>/.fbvvwb`
# defined byu `FBVVWB_DIRECTORY`.
#
FBVVWB_DIRECTORY="/home/$(whoami)/.fbvvwb"
if [[ ! -d "${FBVVWB_DIRECTORY}" ]]; then
	mkdir -p "${FBVVWB_DIRECTORY}"
fi

# FBVVWB save image list for image viewer mode.
# This list is saved as `${FBVVWB_DIRECTORY}/img_list`.
#
FBVVWB_IMG_LIST="${FBVVWB_DIRECTORY}/img_list"
if [[ ! -f "${FBVVWB_IMG_LIST}" ]]; then
	: >"${FBVVWB_IMG_LIST}"
fi

# For future use, FVVWB saves opened file name as history.
# Default name is `${FBVVWB_DIRECTORY}/history`
#
FBVVWB_MANGA_HISTORY="${FBVVWB_DIRECTORY}/history"
if [[ ! -f "${FBVVWB_MANGA_HISTORY}" ]]; then
	: >"${FBVVWB_MANGA_HISTORY}"
fi

#
# ## Parsing query
#
# This CGI script works by passing query.
# If query is omitted, this script automatically complete by default value.
# And you can manually change query options.
#
# You can use GET and POST method.
# If you use apache.
#
# - GET passes as variable QUERY_STRING
# - POST passes as stdin.
#
# Unavailable options are ignored.
#
declare -A QUERY

function ParseQuery() {
	LINE=$1
	KEY=${LINE%%=*}
	VALUE=${LINE##*=}
	# HASH=${VALUE##*#}
	# if [[ "${HASH}" != "" ]]; then
	# 	QUERY["hash"]=${HASH}
	# fi
	VALUE=${VALUE%%#*}
	QUERY[${KEY}]=$(nkf -w --url-input <<<"${VALUE}")
}

#
# ### Get query
#
for i in $(tr '&' ' ' <<<"${QUERY_STRING}"); do
	ParseQuery "${i}"
done
#
# ### Post query
#
for i in $(cat - | tr '&' ' '); do
	ParseQuery "${i}"
done

# ## For Security
#
# This script reject access without your home and mnt directory.
# And also reject link to upper directory.
# When it comes, cp is regarded as TOP_DIRECTORY.
#
# But this script do not check a destination of a symbolic link.
# If symbolic link that points a dangerous place exists, 
# This script cannot prevent access to that dangerous place.
#
if [[ ! "${QUERY[cp]}" =~ /home/$(whoami)/.*|/mnt/.* ]]; then
	QUERY["cp"]="${TOP_DIRECTORY}/"
fi
if [[ "${QUERY[cp]}" =~ \.\. ]]; then
	QUERY["cp"]="${TOP_DIRECTORY}/"
fi

# ## Set default query (key and value) if empty
if [[ "${QUERY[cp]}" == "" ]]; then
	QUERY["cp"]="${TOP_DIRECTORY}/"
fi

if [[ "${QUERY[mode]}" = "" ]]; then
	QUERY["mode"]="browser"
fi

case "${QUERY[view_mode]}" in
dual | single) ;;
*)
	QUERY["view_mode"]="dual"
	;;
esac

if [[ "${QUERY[percent]}" == "" ]]; then
	QUERY["percent"]="80"
fi

# If page is not set or negative.
# page is automatically set as 1.
if [[ "${QUERY[page]}" == "" ]] || [[ "${QUERY[page]}" -le 0 ]]; then
	QUERY["page"]=1
fi

if [[ "${QUERY[order]}" == "" ]]; then
	QUERY["order"]="rl"
fi

CURRENT_PATH=${QUERY[cp]%/}

#
# Prepare functions
# -----------------
###################

function PushUpLinkNum() {
	NUM=$1
	QUERY["uplink"]=${QUERY["uplink"]}_${NUM}
}

function HeadUpLinkNum() {
	echo "${QUERY[uplink]##*_}"
}

function PopUpLinkNum() {
	# echo "b:${QUERY[uplink]}"
	QUERY["uplink"]="${QUERY[uplink]%_*}"
}

function BackLink() {
	if [[ "${QUERY[keyword]}" = "" ]]; then
		UpLink
	else
		SearchBackLink
	fi
}

function UpLink() {
	local UPLINK
	local UPLINK_NUM
	UPLINK_NUM="$(HeadUpLinkNum)"
	local HASH
	HASH=""
	if [[ "${UPLINK_NUM}" != "" ]]; then
		HASH="#${UPLINK_NUM}"
	fi
	PopUpLinkNum
	local CURRENT_PATH
	CURRENT_PATH=${QUERY[cp]}
	QUERY["cp"]="${QUERY[cp]%/*}"
	local KEYWORD=${QUERY["keyword"]}
	unset QUERY["keyword"]
	echo -n "<span style=\"float:left\">"
	echo -n "<a href=\"$(QueryLink)${HASH}\">../</a>"
	echo -n "</span>"
	PushUpLinkNum "${UPLINK_NUM}"
	QUERY["cp"]=${CURRENT_PATH}
	QUERY["keyword"]=${KEYWORD}
}

function QueryLink() {
	local LINK
	LINK="$0?"
	for KEY in "${!QUERY[@]}"; do
		LINK="${LINK}&${KEY}=${QUERY[${KEY}]}"
	done
	echo "${LINK}"
}

function UrlPath() {
	echo "${@/\/home\//\/\~}"
}

# ## Trash functions
#

function TrashCommand() {
	if [[ "${DISABLE_TRASH}" != "true" ]]; then
		FILE="$1"
		env XDG_DATA_HOME="/home/$(whoami)/.local/share/" trash "${FILE}"
	fi
}

function TrashAskLink() {
	if [[ "${DISABLE_TRASH}" != "true" ]]; then
		QUERY["mode"]="trash_ask"
		echo "<a href=\"$(QueryLink)\">Trash</a>"
		unset QUERY["mode"]
	fi
}

# File Browser
# ------------
##############

function FileBrowser() {
	# I want to add link in each folder separated by /
	# /home/bob/hello/world.txt
	#   link to each directory
	echo "<h2>${CURRENT_PATH}</h2>"
	if [[ "${CURRENT_PATH}" != "${TOP_DIRECTORY}" ]]; then
		BackLink
	fi
	Menu
	COUNTER=0
	echo "<ul>"
	for t in "d" "f"; do
		# if you pipe this.
		# sub process  is created,
		# thus you cannot update COUNTER.
		while read -r i; do
			QUERY["cp"]=${i}
			NAME=$(basename "${i}")
			if [[ "${t}" == "d" ]]; then
				NAME="${NAME}/"
			fi
			PushUpLinkNum "${COUNTER}"
			echo "<li><a id=\"${COUNTER}\" href=\"$(QueryLink)\">${NAME}</a></li>"
			PopUpLinkNum
			COUNTER=$((COUNTER + 1))
		done < <(find -L "${CURRENT_PATH}" -type "${t}" -mindepth 1 -maxdepth 1 -not -name ".*" | sort -V)
		echo "<hr>"
	done
	echo "</ul>"
}

#
# ImageViewer's functions
# --------------------

function CreateArcImgIdPath() {
	if [[ ! -e "${FBVVWB_IMG_LIST}" ]] || [[ $(head -n 1 "${FBVVWB_IMG_LIST}") != "${CURRENT_PATH}" ]]; then
		echo "${CURRENT_PATH}" >>"${FBVVWB_MANGA_HISTORY}"
		echo "unar" >"${FBVVWB_IMG_LIST}"
		echo "${CURRENT_PATH}" >>"${FBVVWB_IMG_LIST}"
		lsar "${CURRENT_PATH}" | grep -i -n -e ".jpg" -e ".jpeg" -e ".png" | sort -V -k2 -t ":" >>"${FBVVWB_IMG_LIST}"
	fi
}

function CreateDirImgIdPath() {
	C_DIR="${CURRENT_PATH}"
	if [[ -f "${CURRENT_PATH}" ]]; then
		C_DIR=${CURRENT_PATH%\/*}
	elif [[ -d "${CURRENT_PATH}" ]]; then
		C_DIR=${CURRENT_PATH}
	else
		return
	fi
	# echo "<!--C_DIR=${C_DIR}-->"
	DIR=$(head -n 1 "${FBVVWB_IMG_LIST}")
	if [[ ! -e "${FBVVWB_IMG_LIST}" ]] || [[ "${DIR}" != "${C_DIR}" ]]; then
		echo "img" >"${FBVVWB_IMG_LIST}"
		echo "${C_DIR}" >>"${FBVVWB_IMG_LIST}"
		find -L "${C_DIR}" -type f -mindepth 1 -maxdepth 1 -not -name ".*" | grep -n -i -e ".jpg" -e ".jpeg" -e ".png" -e ".gif" | sort -V -k2 -t':' >>"${FBVVWB_IMG_LIST}"
	fi
	PAGE=$(grep -n "${CURRENT_PATH}" "${FBVVWB_IMG_LIST}" | cut -d':' -f1)
	# Because, first line is directory name.
	PAGE=$((PAGE - 2))
	QUERY["page"]=${PAGE}
}

#function CreateImgIdPath() {
#	case "${QUERY[mode]}" in
#	manga_viewer)
#		CreateArcImgIdPath
#		;;
#	image_viewer)
#		CreateDirImgIdPath
#		;;
#	*) ;;
#	esac
#}

function GetImgListMax() {
	if [[ ${IMG_MAX} == "" ]]; then
		IMG_MAX=$(($(wc -l "${FBVVWB_IMG_LIST}" | cut -d' ' -f1) - 2))
	fi
	echo "${IMG_MAX}"
}

function GetImgIdPath() {
	local PAGE=$1
	head -n $((PAGE + 2)) "${FBVVWB_IMG_LIST}" | tail -n 1
}

function GetImgPath() {
	local PAGE=$1
	local NUM=$2
	local IMG_NAME
	local IMG_PATH
	local IMG_ID_PATH
	local IMG_ID
	#echo -n "<!- page=${PAGE}->"

	TARGET="$(head -n 2 "${FBVVWB_IMG_LIST}" | tail -n 1)"

	case "$(head -n 1 "${FBVVWB_IMG_LIST}")" in
	unar)
		IMG_ID_PATH=$(GetImgIdPath "${PAGE}")
		IMG_ID=$(cut -d':' -f1 <<<"${IMG_ID_PATH}")
		IMG_PATH=$(cut -d':' -f2 <<<"${IMG_ID_PATH}")
		EXT=${IMG_PATH##*.}
		IMG_NAME="${FBVVWB_DIRECTORY}/img_${NUM}.${EXT}"
		IMG_ID=$((IMG_ID - 2))
		unar "${TARGET}" -i "${IMG_ID}" -q -o - >"${IMG_NAME}"
		echo "${IMG_NAME}"
		;;
	pdf)
		local TMP="${FBVVWB_DIRECTORY}/img_tmp"
		EXT="png"
		pdftoppm -png -f "${PAGE}" -l "${PAGE}" "${TARGET}" "${TMP}" 2>&1
		IMG_NAME="${FBVVWB_DIRECTORY}/img_${NUM}.${EXT}"
		mv "${TMP}-${PAGE}.${EXT}" "${IMG_NAME}"
		echo "${IMG_NAME}"
		;;
	img)
		IMG_ID_PATH=$(GetImgIdPath "${PAGE}")
		IMG_ID=$(cut -d':' -f1 <<<"${IMG_ID_PATH}")
		IMG_PATH=$(cut -d':' -f2 <<<"${IMG_ID_PATH}")
		echo "${IMG_PATH}"
		;;
	*) ;;

	esac
}

function PageLink() {
	local PAGE=$1
	local NAME=$2
	local CURRENT_PATH
	if [[ "${PAGE}" -ge 1 ]] && [[ "${PAGE}" -le "$(GetImgListMax)" ]]; then
		TMP=${QUERY["page"]}
		QUERY["page"]=${PAGE}
		if [[ "${QUERY[mode]}" = "image_viewer" ]]; then
			CURRENT_PATH=${QUERY["cp"]}
			#IMG_PATH=$(cut -d':' -f2 <<<"${IMG_ID_PATH}")
			IMG_PATH=$(GetImgPath "${PAGE}" "0")
			QUERY["cp"]=${IMG_PATH}
		fi
		echo -n "<a href=\"$(QueryLink)\">${NAME}</a>"
		QUERY["page"]=$TMP
		if [[ "${QUERY[mode]}" = "image_viewer" ]]; then
			QUERY["cp"]=${CURRENT_PATH}
		fi
	else
		echo -n "${NAME}"
	fi
}

function HeadLink() {
	if [[ "${QUERY[page]}" -ne 1 ]]; then
		PageLink "1" "Head"
	else
		echo -n "Head"
	fi
}

function TailLink() {
	local PAGE
	PAGE=$(GetImgListMax)
	if [[ "${QUERY[view_mode]}" = "dual" ]]; then
		OFFSET=1
	else
		OFFSET=0
	fi
	if [[ $((QUERY[page] + OFFSET)) -le ${PAGE} ]]; then
		PageLink "${PAGE}" "Tail"
	else
		echo "Tail"
	fi
}

function NextLink() {
	local PLACE=$1
	echo -n "<span style=\"float:${PLACE}\">"
	if [[ "${QUERY[view_mode]}" = "dual" ]]; then
		OFFSET=2
	else
		OFFSET=1
	fi
	PageLink "$((QUERY[page] + OFFSET))" "Next"
	echo -n "</span>"
}

function PrevLink() {
	local PLACE=$1
	echo -n "<span style=\"float:${PLACE}\">"
	if [[ "${QUERY[view_mode]}" = "dual" ]]; then
		OFFSET=2
	else
		OFFSET=1
	fi
	PageLink "$((QUERY[page] - OFFSET))" "Prev"
	echo -n "</span>"
}

function NavigationBar() {
	if [[ "${QUERY[order]}" = "rl" ]]; then
		NextLink "left"
		TailLink
		echo "(${QUERY[page]}/$(GetImgListMax))"
		HeadLink
		PrevLink "right"
	else
		PrevLink "left"
		HeadLink
		echo "(${QUERY[page]}/$(GetImgListMax))"
		TailLink
		NextLink "right"
	fi
}

function ImgSrc() {
	local PAGE=$1
	local NUM=$2
	local PERCENT=$3

	local IMG_PATH=$(GetImgPath "${PAGE}" "${NUM}")
	# echo "<-- IMG_PATH=${IMG_PATH} -->"
	echo "<img src=\"$(UrlPath "${IMG_PATH}")\" width=${PERCENT}%>"
}

function ViewerSetting() {
	local PAGE
	PAGE=${QUERY["page"]}
	if [[ "${QUERY[view_mode]}" == "dual" ]]; then
		QUERY["page"]=$((PAGE - 1))
		echo "<a href=\"$(QueryLink)\">Shift</a>"
		QUERY["page"]=${PAGE}
		ORDER=${QUERY["order"]}
		if [[ "${QUERY[order]}" = "lr" ]]; then
			QUERY["order"]="rl"
			echo "<a href=\"$(QueryLink)\"><--</a>"
		else
			QUERY["order"]="lr"
			echo "<a href=\"$(QueryLink)\">--></a>"
		fi
		QUERY["order"]=${ORDER}
		QUERY["view_mode"]="single"
		echo "<a href=\"$(QueryLink)\">Single Page</a>"
	else
		QUERY["view_mode"]="dual"
		echo "<a href=\"$(QueryLink)\">Dual Page</a>"
		QUERY["view_mode"]="single"
	fi

}

function ImageViewer() {
	#CreateImgIdPath
	PAGE="${QUERY[page]}"
	if [[ "${PAGE}" -ge "$(GetImgListMax)" ]]; then
		PAGE=$(GetImgListMax)
		if [[ "${QUERY[view_mode]}" == "dual" ]]; then
			PAGE=$((PAGE - 1))
		fi
	fi

	PERCENT="${QUERY[percent]}"

	echo "<div style=\"text-align:center\">"
	if [[ "${QUERY[view_mode]}" = "dual" ]]; then
		if [[ "${QUERY[order]}" = "rl" ]]; then
			LIST="1 0"
		else
			LIST="0 1"
		fi
		PERCENT=$((PERCENT / 2))
		for i in ${LIST}; do
			IMG_SRC=$(ImgSrc "$((QUERY[page] + i))" "${i}" "${PERCENT}")
			# 0 -> -2, 1 -> +2
			PageLink "$((QUERY[page] + 2 * (2 * i - 1)))" "${IMG_SRC}"
		done
	else
		IMG_SRC=$(ImgSrc "${QUERY[page]}" "0" "${PERCENT}")
		#echo "<!-page=${QUERY[page]}->"
		PageLink "$((QUERY[page] + 1))" "${IMG_SRC}"
	fi
	echo "<br>"
	NavigationBar
	echo "</div>"
	echo "<hr>"

	echo "<div style=\"text-align:center\">"
	ViewerSetting
	echo "</div>"
	echo "<hr>"
	echo "<div style=\"text-align:center\">"
	# If you go to upper directory.
	# page is reset to empty.
	unset QUERY["page"]
	BackLink
	TrashAskLink
	Menu
	echo "<div>"
}

function VideoPlayer() {
	echo "$(basename "${QUERY[cp]}")<br>"
	HEIGHT=300
	echo "<div style=\"text-align:center\">"
	#echo "<video height=\"${HEIGHT}\" muted controls autoplay>"
	echo "<video muted controls autoplay>"
	echo "<source src=\"$(UrlPath "${QUERY[cp]}")\" type=\"video/mp4\">"
	echo "</video>"

	echo "</div>"
	echo "<p>"
	BackLink
	echo "</p>"
}

function AudioPlayer() {
	echo "$(basename "${QUERY[cp]}")<br>"
	echo "<div style=\"text-align:center\">"
	echo "<audio src=\"$(UrlPath "${QUERY[cp]}")\" controls autoplay align=\"center\"></audio>"
	echo "</div>"
	echo "<p>"
	BackLink
	echo "</p>"
}

#
# FileViewer
# --------------
#
# Select how to open a selected file.
#

function FileViewer() {
	if [[ "${CURRENT_PATH}" =~ .*\.mp4|.*\.avi|.*\.wmv|.*\.mkv ]]; then
		VideoPlayer
	elif [[ "${CURRENT_PATH}" =~ .*\.zip|.*\.rar|.*\.tar|.*\.tar\..* ]]; then
		QUERY["mode"]="manga_viewer"
		CreateArcImgIdPath
		ImageViewer
	elif [[ "${CURRENT_PATH}" =~ .*\.jpg|.*\.png|.*\.jpeg|.*\.gif ]]; then
		CreateDirImgIdPath
		QUERY["mode"]="image_viewer"
		ImageViewer
	elif [[ "${CURRENT_PATH}" =~ .*\.mp3|.*\.flac|.*\.wav ]]; then
		AudioPlayer
	elif [[ "${CURRENT_PATH}" =~ .*\.pdf|.*\.PDF ]]; then
		QUERY["mode"]="pdf_viewer"
		echo "pdf" >"${FBVVWB_IMG_LIST}"
		echo "${CURRENT_PATH}" >>"${FBVVWB_IMG_LIST}"
		#echo "SEQ=$(pdfinfo "${CURRENT_PATH}" | grep -a "Pages" | tr -d ' ' | cut -d':' -f2)"
		seq "$(pdfinfo "${CURRENT_PATH}" | grep "Pages" | tr -d ' ' | cut -d':' -f2)" >>"${FBVVWB_IMG_LIST}"
		ImageViewer
	elif [[ "${CURRENT_PATH}" =~ .*\.txt|.*\.TXT ]]; then
		echo "<pre>"
		cat "${CURRENT_PATH}"
		echo "</pre>"
		BackLink

	else
		echo "Yet implemented to open this file.<br>"
		echo "${CURRENT_PATH}<br>"
		BackLink
		echo "<br>"
		# TrashAskLink
	fi
}

#
# Menu
# -----------
#
function Menu() {
	MODE=${QUERY["mode"]}
	QUERY["mode"]="history"
	echo -n "<span style=\"float:right\">"
	echo -n "<a href=\"$(QueryLink)\">View History</a>"
	QUERY["mode"]="search"
	echo -n "<form style=\"display:inline\" action=\"$(QueryLink)\" method=\"post\">"
	echo -n "<input type=\"text\" name=\"keyword\">"
	echo -n "<input type=\"submit\" value=\"Search\">"
	echo -n "</form>"
	echo "</span>"
	QUERY["mode"]=${MODE}
}

#
# History Mode
# --------------
#
function History() {
	echo "<h2>History</h2>"
	BackLink
	echo "<ul>"
	local COUNTER
	COUNTER=0
	while read -r line; do
		QUERY["cp"]=${line}
		echo "<li><a href=\"$(QueryLink)\">$(basename "${line}")</a></li>"
	done < <(tac "${FBVVWB_MANGA_HISTORY}")
	echo "</ul>"
}

#
# Search mode
# --------------
#
function Search() {
	unset QUERY["mode"]
	echo "<h2>Search results</h2>"
	Menu
	KEYWORD=${QUERY["keyword"]}
	if [[ "${KEYWORD}" == "" ]]; then
		UpLink
		return
	fi
	echo "${KEYWORD}"
	UpLink
	echo "<ul>"
	while read -r line; do
		QUERY["cp"]=${line}
		echo "<li><a href=\"$(QueryLink)\">${line}</a></li>"
	done < <(locate -i "${KEYWORD}")
	echo "</ul>"
}

function SearchBackLink() {
	QUERY["mode"]="search"
	echo -n "<span style=\"float:left\">"
	echo -n "<a href=\"$(QueryLink)\">Back</a>"
	echo -n "</span>"
	unset QUERY["mode"]
}

#
# main
# ----
#

# print header
cat <<EOF
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>${CURRENT_PATH}</title>
</head>
<body bgcolor="black" text="gray" link="gray" vlink="gray" alink="gray">
EOF

# Mode selecter for special page.
case "${QUERY[mode]}" in
history)
	unset QUERY["mode"]
	History
	;;
search)
	Search
	;;
trash_ask)
	echo "<div style=\"text-align:center\">"
	echo "<p>Delete  ${QUERY[cp]}.</p>"
	echo "<p>Are you sure?</p>"
	echo "<p>"
	QUERY["mode"]='trash'
	echo "<a href=\"$(QueryLink)\">Delete</a>"
	unset QUERY["mode"]
	echo "<a href=\"$(QueryLink)\">Cancel</a>"
	echo "</p>"
	echo "</div>"
	;;

trash)
	unset QUERY["mode"]
	echo "<div style=\"text-align:center\">"
	if [[ -f "${QUERY[cp]}" ]]; then
		TrashCommand "${QUERY[cp]}"
		echo "Trash ${QUERY[cp]}"
	elif [[ -d "${QUERY[cp]}" ]]; then
		echo "${QUERY[cp]} is directory.<br>For security, deleteing directory is not allowed."
	else
		echo "${QUERY[cp]}<br> does not exist."
	fi
	echo "</div>"
	UpLink
	;;
*)
	if [[ -d ${CURRENT_PATH} ]]; then
		FileBrowser
	elif [[ -f ${CURRENT_PATH} ]]; then
		FileViewer
	else
		echo "Not file. ${CURRENT_PATH}"
		echo "Error"
		echo "${CURRENT_PATH} does not exist."
		echo "<p>"
		UpLink
		echo "</p>"
	fi
	;;
esac

# print footer
cat <<EOF
</body>
</html>
EOF
