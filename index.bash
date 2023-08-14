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
# 	- Archive is suported (.zip .rar .tar.gz .cbz ...)
# 	- Dual page mode is supported.
# - Watch movies.
# - Listen musics.
# - Trash files.
# - Bookmark archive, page and status link.
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
# - unar/lsar (for unarchiving)
# - trash-cli
# - iconv, nkf (for detecting and converting character set)
# - locale (for searching file)
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
# w_pix=<num>
#     Resize image width to <num> from original size.
#     This option is used to reduce data.
# quality=<0-100>
#     Reduce quality of image to reduce data.
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
# - `--help` or `-h`            : Generate markdown document from this script.
# - `--generate-readme` or `-g` : Generate README.md from `-h` option's output.
# - `-c`                        : Print default configure file.
# - otherwise                   : Ignored.
# ```
#
# If options are set, this script run as non-CGI mode.
#

if [[ "$#" -ne 0 ]]; then
	while [[ "$#" -ne 0 ]]; do
		case "$1" in
		--help | -h)
			grep "^\s*#" "$0" | tail -n+3 | sed -e 's/^\s*#\+[ ]\{0,1\}//'
			;;
		--generate-readme | -g)
			bash "$0" -h >"README.md"
			;;
		-c)
			PrintConfig
			;;
		*)
			echo "Such option do not allowed."
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

<!-- If you run as bash, type Ctrl-D. -->
EOF

FBVVWB_CONFIG="/home/$(whoami)/.fbvvwb/config"

function PrintConfig() {
	cat <<EOF >"${FBVVWB_CONFIG}"
# Default top directory is defined by TOP_DIRECTORY
#
TOP_DIRECTORY="/home/\$(whoami)"

# Set "true" if you want to disable trash link.
#
DISABLE_TRASH="false"

# You can add your own directory to MOVE_DIRS.
# If you add pathes to MOVE_DIRS, new links are created. 
# Each name of links is basename of path. It will be directory name.
# If you click the link, that archive is move to the corresponding directory.
# This link lead you to ask page, move or cancel.
# trash is special command for trashing a file.
# If you add empty string "", it is means new row.
MOVE_DIRS=("trash")

# You can add your own function
MENU_LINKS=()
EOF
}

function AddConfig() {
	if [[ ! -f "${FBVVWB_CONFIG}" ]]; then
		echo "#!/bin/bash" >"${FBVVWB_CONFIG}"
	else
		echo "########## Add New Config ##########"
	fi
	PrintConfig >>"${FBVVWB_CONFIG}"
}

if [[ ! -f "${FBVVWB_CONFIG}" ]]; then
	AddConfig
fi

TOP_DIRECTORY=""
FBVVWB_DIRECTORY="/home/$(whoami)/.fbvvwb"
FBVVWB_IMG_DIRECTORY="${FBVVWB_DIRECTORY}/imgs"
FBVVWB_CURRENT_DIR_FILES="${FBVVWB_DIRECTORY}/dir_files"
FBVVWB_SEARCH_LIST="${FBVVWB_DIRECTORY}/search"
FBVVWB_BOOKMARK="${FBVVWB_DIRECTORY}/bookmark"

[[ ! -d "${FBVVWB_DIRECTORY}" ]] && mkdir -p "${FBVVWB_DIRECTORY}"
[[ ! -d "${FBVVWB_IMG_DIRECTORY}" ]] && mkdir -p "${FBVVWB_IMG_DIRECTORY}"
if [[ $(find "${FBVVWB_IMG_DIRECTORY}" -type f | wc -l) -ge 10 ]]; then
	rm -f "${FBVVWB_IMG_DIRECTORY}/"*
fi

DISABLE_TRASH="false"

source "${FBVVWB_CONFIG}"

[[ ! -d "${TOP_DIRECTORY}" ]] && TOP_DIRECTORY="/home/$(whoami)"

#
# FBVVWB save image list for image viewer mode.
# This list is saved as `${FBVVWB_DIRECTORY}/img_list`.
#
FBVVWB_IMG_LIST="${FBVVWB_DIRECTORY}/img_list"

# FVVWB saves opened file name as history.
# Default name is `${FBVVWB_DIRECTORY}/history`
#
FBVVWB_MANGA_HISTORY="${FBVVWB_DIRECTORY}/history"
[[ ! -f "${FBVVWB_MANGA_HISTORY}" ]] && touch "${FBVVWB_MANGA_HISTORY}"

#
# ## Parsing query
#
# This CGI script works by passing query.
# Each query is separated by &.
# Each key and value combination is combined by =.
# For example, path=abc&page=3
#
# Query is passed as percent encoded string.
# Thus you have to decode to utf-8 to treat as file path.
#
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

# ORIGINAL_CP="${QUERY[cp]}"
[[ "${QUERY[cp]}" =~ \.\. ]] || [[ "${QUERY[cp]}" = "" ]] && QUERY["cp"]="${TOP_DIRECTORY}/"

# This two hyphen is not equal.
# 95 is true path.
# Maybe nkf convert 95 to 94.
# —:E2,80,94,
# ―:E2,80,95,
#QUERY["cp"]=$(sed -e 's/—/―/g' <<<"${QUERY[cp]}")
QUERY["cp"]="${QUERY[cp]//—//}"

function SetDefaultOption() {
	[[ "${QUERY[mode]}" = "" ]] && QUERY["mode"]="default"
	[[ "${QUERY[view_mode]}" != "dual" ]] && [[ "${QUERY[view_mode]}" != "single" ]] && QUERY["view_mode"]="dual"
	[[ "${QUERY[page]}" = "" ]] || [[ "${QUERY[page]}" -le 0 ]] && QUERY["page"]=1
	[[ "${QUERY[percent]}" = "" ]] && QUERY["percent"]="80"
	[[ "${QUERY[order]}" = "" ]] && QUERY["order"]="rl"
	[[ "${QUERY[w_pix]}" = "" ]] && QUERY["w_pix"]=800
	[[ "${QUERY[quality]}" = "" ]] && QUERY["quality"]=20
}

SetDefaultOption

CURRENT_PATH=${QUERY[cp]%/}

#
# Prepare functions
# -----------------
###################

function PushUpLinkNum() {
	QUERY["uplink"]=${QUERY["uplink"]}_${1}
}

function PopUpLinkNum() {
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
	local UPLINK_NUM
	local CURRENT_PATH
	UPLINK_NUM="${QUERY[uplink]##*_}"
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
	echo -n "<span><a href=\"$(QueryLink)${HASH}\">../</a></span>"
	PushUpLinkNum "${UPLINK_NUM}"
	QUERY["cp"]=${CURRENT_PATH}
	QUERY["keyword"]=${KEYWORD}
}

function QueryLink() {
	local LINK
	LINK="$0?"
	# QUERY["cp"]=$(echo "${QUERY[cp]}" | nkf -WwMQ | sed 's/=$//g' | tr '=' '%' | tr -d '\n')
	QUERY["cp"]=$(printf '%b\n' "${QUERY[cp]//%/\\x}")
	QUERY["cp"]="${QUERY[cp]//#/%23}"
	for KEY in "${!QUERY[@]}"; do
		VALUE=${QUERY[${KEY}]}
		LINK="${LINK}&${KEY}=${VALUE}"
	done
	echo "${LINK}"
}

function UrlPath() {
	echo "${@/\/home\//\/\~}" | sed -e 's/#/%23/g'
}

# ## Trash functions
#

function TrashCommand() {
	if [[ "${DISABLE_TRASH}" != "true" ]]; then
		FILE="$1"
		if [[ -f "${FILE}" ]]; then
			env XDG_DATA_HOME="/home/$(whoami)/.local/share/" trash "${FILE}"
		else
			echo -n "<p>${FILE} is not exist.</p><p>Trash failed.</p>"
		fi
	fi
}

# File Browser
# ------------
##############

function FileBrowser() {
	CURRENT_PATH=${QUERY[cp]}
	# I want to add link in each folder separated by /
	# /home/bob/hello/world.txt
	#   link to each directory
	
	echo -n "<h2>${CURRENT_PATH}</h2>"
	if [[ "${CURRENT_PATH}" != "${TOP_DIRECTORY}" ]]; then
		BackLink
		echo -n "<br>"
	fi
	Menu
	COUNTER=0

	FILE_LIST="<div><ul>"
	for t in "d" "f"; do
		# if you pipe this.
		# sub process  is created,
		# thus you cannot update COUNTER.
		while read -r i; do
			QUERY["cp"]=${i}
			NAME=$(basename "${i}")
			[[ "${t}" == "d" ]] && NAME="${NAME}/"
			PushUpLinkNum "${COUNTER}"
			FILE_LIST="${FILE_LIST}<li><a id=\"${COUNTER}\" href=\"$(QueryLink)\">${NAME}</a></li>\n"
			PopUpLinkNum
			COUNTER=$((COUNTER + 1))
		done < <(find -L "${CURRENT_PATH}" -mindepth 1 -maxdepth 1 -type "${t}" -not -name ".*" | sort -V)
		FILE_LIST="${FILE_LIST}<hr>"
	done
	echo -e "${FILE_LIST}</ul></div>"
}

#
# ImageViewer's functions
# --------------------
#

function MoveFileLink() {
	local TMP=${QUERY["mode"]}
	QUERY["mode"]="move_ask"
	QUERY["move"]=$1
	echo -n "<a href=\"$(QueryLink)\">$(basename "${1}")</a>"
	unset QUERY["move"]
	QUERY["mode"]="${TMP}"
}

function MoveLinks() {
	echo -n "<table width=100%><tr><td>Move to:</td>"
	for NAME in "${MOVE_DIRS[@]}"; do
		if [[ "${NAME}" = "" ]]; then
			echo -n "</tr><tr></tr><tr><td>Move to :</td>"
			continue
		fi
		echo -n "<td>$(MoveFileLink "${NAME}")</td>"
	done
	echo -n "</tr></table>"
}

function AppendToHistory() {
	LINK=$1
	if [[ "$(tail -n 1 "${FBVVWB_MANGA_HISTORY}")" != "${LINK}" ]]; then
		echo "${LINK}" >>"${FBVVWB_MANGA_HISTORY}"
	fi
}

function CreateArcImgIdPath() {
	if [[ ! -e "${FBVVWB_IMG_LIST}" ]] || [[ $(head -n 1 "${FBVVWB_IMG_LIST}") != "${CURRENT_PATH}" ]]; then
		AppendToHistory "${CURRENT_PATH}"
		echo -e "unar\n${CURRENT_PATH}" >"${FBVVWB_IMG_LIST}"
		lsar "${CURRENT_PATH}" | grep -i -n -e ".jpg" -e ".jpeg" -e ".png" -e ".bmp" | sort -V -k2 -t ":" >>"${FBVVWB_IMG_LIST}"
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
	DIR=$(head -n 1 "${FBVVWB_IMG_LIST}")
	if [[ ! -e "${FBVVWB_IMG_LIST}" ]] || [[ "${DIR}" != "${C_DIR}" ]]; then
		echo -e "img\n${C_DIR}" >"${FBVVWB_IMG_LIST}"
		find -L "${C_DIR}" -type f -mindepth 1 -maxdepth 1 -not -name ".*" | grep -n -i -e ".jpg" -e ".jpeg" -e ".png" -e ".gif" -e ".bmp" | sort -V -k2 -t':' >>"${FBVVWB_IMG_LIST}"
	fi
	PAGE=$(grep -n "${CURRENT_PATH}" "${FBVVWB_IMG_LIST}" | cut -d':' -f1)
	# Because, first line is directory name.
	PAGE=$((PAGE - 2))
	QUERY["page"]=${PAGE}
}

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

	TARGET="$(head -n 2 "${FBVVWB_IMG_LIST}" | tail -n 1)"

	case "$(head -n 1 "${FBVVWB_IMG_LIST}")" in
	unar)
		IMG_ID_PATH=$(GetImgIdPath "${PAGE}")
		IMG_ID=$(cut -d':' -f1 <<<"${IMG_ID_PATH}")
		IMG_PATH=$(cut -d':' -f2 <<<"${IMG_ID_PATH}")
		EXT=${IMG_PATH##*.}
		IMG_NAME="$(mktemp -p "${FBVVWB_IMG_DIRECTORY}" --suffix=".${EXT}")"
		chmod a+r "${IMG_NAME}"
		IMG_ID=$((IMG_ID - 2))
		unar "${TARGET}" -i "${IMG_ID}" -q -o - >"${IMG_NAME}"
		convert -resize "${QUERY[w_pix]}x>" -quality "${QUERY[quality]}%" "${IMG_NAME}" "${IMG_NAME}.jpg"
		echo "${IMG_NAME}.jpg"
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

function JumpLink() {
	local OFFSET=$1
	PageLink "$((QUERY[page] + OFFSET))" "${OFFSET}"
}

function NextLink() {
	#local PLACE=$1
	#echo -n "<span style=\"float:${PLACE}\">"
	if [[ "${QUERY[view_mode]}" = "dual" ]]; then
		OFFSET=2
	else
		OFFSET=1
	fi
	PageLink "$((QUERY[page] + OFFSET))" "Next"
	#echo -n "</span>"
}

function PrevLink() {
	#local PLACE=$1
	#echo -n "<span style=\"float:${PLACE}\">"
	if [[ "${QUERY[view_mode]}" = "dual" ]]; then
		OFFSET=2
	else
		OFFSET=1
	fi
	PageLink "$((QUERY[page] - OFFSET))" "Prev"
	#echo -n "</span>"
}

function PercentChange() {
	local OFFSET=$1
	local PLACE=$2
	local PERCENT
	PERCENT=$((QUERY[percent] + OFFSET))
	if [[ "${PERCENT}" -ge 0 ]]; then
		local SAVE_PERCENT
		SAVE_PERCENT=${QUERY["percent"]}
		QUERY["percent"]=${PERCENT}
		echo -n "<a href=\"$(QueryLink)\">${OFFSET}%</a>"
		QUERY["percent"]=${SAVE_PERCENT}
	else
		echo -n "${OFFSET}%"
	fi
}

function CreateCurrentPathFiles() {
	DIR_NAME="$(dirname "${QUERY[cp]}")"
	if [[ ! -e "${FBVVWB_CURRENT_DIR_FILES}" ]] || [[ "${DIR_NAME}" != $(head -n 1 "${FBVVWB_CURRENT_DIR_FILES}") ]]; then
		echo "${DIR_NAME}" >"${FBVVWB_CURRENT_DIR_FILES}"
		find -L "${DIR_NAME}" -mindepth 1 -maxdepth 1 -type f -not -name ".*" | sort -V >>"${FBVVWB_CURRENT_DIR_FILES}"
	fi
}

function PrevArchiveLink() {
	CreateCurrentPathFiles
	if [[ ! -e "${FBVVWB_CURRENT_DIR_FILES}" ]]; then
		echo "PreArc"
		return
	fi
	TMP_CP=${QUERY["cp"]}
	TMP_PAGE="${QUERY["page"]}"

	QUERY["page"]="0"
	QUERY["cp"]=$(fgrep -B 1 "${QUERY[cp]}" "${FBVVWB_CURRENT_DIR_FILES}" | head -n 1)
	local NAME
	NAME="$(basename "${QUERY[cp]}")"
	echo -n "<a href=\"$(QueryLink)\">PreArc(${NAME})</a>"
	QUERY["page"]="${TMP_PAGE}"
	QUERY["cp"]="${TMP_CP}"
}

function NextArchiveLink() {
	CreateCurrentPathFiles
	if [[ ! -e "${FBVVWB_CURRENT_DIR_FILES}" ]]; then
		echo "NexArc"
		return
	fi
	TMP_CP=${QUERY["cp"]}
	TMP_PAGE="${QUERY["page"]}"

	QUERY["page"]="0"
	QUERY["cp"]=$(fgrep -A 1 "${QUERY[cp]}" "${FBVVWB_CURRENT_DIR_FILES}" | tail -n 1)

	local NAME
	NAME=$(basename "${QUERY[cp]}")
	echo -n "<a href=\"$(QueryLink)\">NexArc(${NAME})</a>"

	QUERY["page"]="${TMP_PAGE}"
	QUERY["cp"]="${TMP_CP}"
}

function AppendToBookmark() {
	MODE="${QUERY[mode]}"
	QUERY["mode"]="append_bookmark"
	echo -n "<a href=\"$(QueryLink)\">Bookmark this page</a>"
	QUERY["mode"]="${MODE}"
}

function NavigationBar() {
	local NUM=5
	NAV_BAR="<table width=100%><tr>"
	if [[ "${QUERY[order]}" = "rl" ]]; then
		NAV_BAR="${NAV_BAR}<td>$(NextLink "left")</td>"
		for i in $(seq "${NUM}"); do
			NAV_BAR="${NAV_BAR}<td>$(JumpLink "+$((2 ** i))")</td>"
		done
		NAV_BAR="${NAV_BAR}<td>$(TailLink)</td><td>(${QUERY[page]}/$(GetImgListMax))</td><td>$(HeadLink)</td>"
		for i in $(seq "${NUM}" | tac); do
			NAV_BAR="${NAV_BAR}<td>$(JumpLink "-$((2 ** i))")</td>"
		done
		NAV_BAR="${NAV_BAR}<td>$(PrevLink "right")</td>"
	else
		NAV_BAR="${NAV_BAR}<td>$(PrevLink "left")</td>"
		for i in $(seq "${NUM}"); do
			NAV_BAR="${NAV_BAR}<td>$(JumpLink "-$((2 ** i))")</td>"
		done
		NAV_BAR="${NAV_BAR}<td>$(HeadLink)</td><td>(${QUERY[page]}/$(GetImgListMax))</td><td>$(TailLink)</td>"
		for i in $(seq "${NUM}" | tac); do
			NAV_BAR="${NAV_BAR}<td>$(JumpLink "+$((2 ** i))")</td>"
		done
		NAV_BAR="${NAV_BAR}</td><td>$(NextLink "right")</td>"
	fi
	NAV_BAR="${NAV_BAR}</tr></table><table width=100%><tr>"
	for i in "+1" "+5" "+10"; do
		NAV_BAR="${NAV_BAR}<td>$(PercentChange "${i}")</td>"
	done
	local SAVE_PERCENT
	SAVE_PERCENT=${QUERY["percent"]}
	QUERY["percent"]="100"
	NAV_BAR="${NAV_BAR}<td><a href=\"$(QueryLink)\">100%</a></td>"
	QUERY["percent"]=${SAVE_PERCENT}
	for i in "-10" "-5" "-1"; do
		NAV_BAR="${NAV_BAR}<td>$(PercentChange "${i}")</td>"
	done
	NAV_BAR="${NAV_BAR}</tr></table>"

	# For next and prev archive
	NAV_BAR="${NAV_BAR}<table width=100%><tr> <td>$(PrevArchiveLink)</td> <td>$(AppendToBookmark)</td> <td>$(NextArchiveLink)</td> </tr></table>"
	echo -n "${NAV_BAR}"
}

function ImgSrc() {
	local PAGE=$1
	local NUM=$2
	local PERCENT=$3

	local IMG_PATH=$(GetImgPath "${PAGE}" "${NUM}")
	echo "<!--  ${IMG_PATH}  -->"
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
		QUERY["view_mode"]="dual"
	else
		QUERY["view_mode"]="dual"
		echo "<a href=\"$(QueryLink)\">Dual Page</a>"
		QUERY["view_mode"]="single"
	fi

}

function FileSize() {
	local BYTE
	BYTE=$(stat -c %s "${QUERY["cp"]}")
	if [[ "${BYTE}" -le $((2 ** 10)) ]]; then
		echo -n "${BYTE}[byte]"
	elif [[ "${BYTE}" -le $((2 ** 20)) ]]; then
		echo -n "$((BYTE / (2 ** 10))))[KB]"
	elif [[ "${BYTE}" -le $((2 ** 30)) ]]; then
		echo -n "$((BYTE / (2 ** 20)))[MB]"
	else
		echo -n "$((BYTE / (2 ** 30)))[GB]"
	fi
}

function ImageViewer() {
	PAGE="${QUERY[page]}"
	if [[ "${PAGE}" -ge "$(GetImgListMax)" ]]; then
		PAGE=$(GetImgListMax)
		if [[ "${QUERY[view_mode]}" = "dual" ]]; then
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
		echo "<!-- IV =  -->"
		IMG_SRC=$(ImgSrc "${QUERY[page]}" "0" "${PERCENT}")
		PageLink "$((QUERY[page] + 1))" "${IMG_SRC}"
	fi
	cat <<EOF
<br>
$(NavigationBar)
</div>
<hr>
<div style="text-align:center">
$(ViewerSetting)
<hr>
EOF
	# If you go to upper directory.
	# page is reset to empty.
	unset QUERY["page"]
	cat <<EOF
$(MoveLinks)
<hr>
${QUERY[cp]}
$(FileSize)
<hr>
</div>
$(BackLink)
<br>
$(Menu)
EOF
}

function VideoPlayer() {
	cat <<EOF
$(basename "${QUERY[cp]}")<br>
<div style="text-align:center">
<video width=100% muted controls autoplay playinline>
<source src="$(UrlPath "${QUERY[cp]}")" type="video/mp4">
</video>
</div>
<p>$(BackLink)</p>
EOF
}

function AudioPlayer() {
	cat <<EOF
$(basename "${QUERY[cp]}")<br>
<div style="text-align:center">
<audio style="width:100%" src="$(UrlPath "${QUERY[cp]}")" controls autoplay align="center"></audio>
</div>
<p>$(BackLink)</p>
EOF
}

#
# FileViewer
# --------------
#
# Select how to open a selected file.
#

function FileViewer() {
	case "${CURRENT_PATH}" in
	*.mp4 | *.avi | *.wmv | *.mkv)
		VideoPlayer
		;;
	*.zip | *.rar | *.tar | *.tar.* | *.ZIP | *.cbz)
		QUERY["mode"]="manga_viewer"
		CreateArcImgIdPath
		ImageViewer
		;;
	*.jpg | *.png | *.jpeg | *.gif | *.bmp)
		CreateDirImgIdPath
		QUERY["mode"]="image_viewer"
		ImageViewer
		;;
	*.mp3 | *.flac | *.wav | *.m4a)
		AudioPlayer
		;;
	*.pdf | *.PDF)
		echo -e "pdf\n${CURRENT_PATH}" >"${FBVVWB_IMG_LIST}"
		seq "$(pdfinfo "${CURRENT_PATH}" | grep "Pages" | tr -d ' ' | cut -d':' -f2)" >>"${FBVVWB_IMG_LIST}"
		ImageViewer
		;;
	*\.txt | *\.TXT | *\.html | *\.md | *\.MD)

		echo "<pre>"
		iconv -f $(nkf --guess "${CURRENT_PATH}") -t UTF8 "${CURRENT_PATH}"
		echo "</pre>"
		BackLink
		;;
	*)
		echo "Yet implemented to open this file.<br>"
		echo "${CURRENT_PATH}<br>$(BackLink)<br>$(Menu)"
		;;
	esac
}

#
# Menu
# -----------
#
function Menu() {
	QUERY["mode"]="search"
	#<span style="float:left">
	cat <<EOF
<span>
<form style="display:inline" action="$(QueryLink)" method="post">
<input type="text" name="keyword">
<input type="submit" value="Search">
</form>
EOF
	QUERY["mode"]=${MODE}
	MODE=${QUERY["mode"]}
	QUERY["mode"]="history"
	echo "<a href=\"$(QueryLink)\">History</a>"

	QUERY["mode"]=${MODE}
	MODE=${QUERY["mode"]}
	QUERY["mode"]="bookmark"
	echo "<a href=\"$(QueryLink)\">Bookmark</a>"

	QUERY["mode"]="links"
	KEYWORD=${QUERY["keyword"]}
	unset QUERY["keyword"]
	echo "<a href=\"$(QueryLink)\">Links</a>"
	unset QUERY["mode"]
	QUERY["keyword"]=${KEYWORD}

	#
	# You can add your own Menu Link.
	# Add function name to MENU_LINKS in config file.
	# See CreateConfig for more detail.
	#
	for NAME in "${MENU_LINKS[@]}"; do
		if [[ "$(type -t "${NAME}")" = "function" ]]; then
			# Create sub-process to prevent variable from changing.
			echo "$(eval "${NAME}")"
		fi
	done
	echo "</span>"
}

#
# History Mode
# --------------
#
function History() {
	echo "<h2>History</h2>"
	BackLink
	HIST="<ul>"
	local COUNTER
	COUNTER=0
	while read -r line; do
		QUERY["cp"]=${line}
		HIST="${HIST}<li><a href=\"$(QueryLink)\">$(basename "${line}")</a></li>"
	done < <(tac "${FBVVWB_MANGA_HISTORY}")
	echo -n "${HIST}</ul>"
	Menu
}

#
# Link Mode
# ---------------
#
function MoveDirLinks() {
	echo "<h2>Links</h2>"
	BackLink
	DATA="<ul>"
	for NAME in "${MOVE_DIRS[@]}"; do
		QUERY["cp"]=${NAME}
		DATA="${DATA}<li><a href=\"$(QueryLink)\">${NAME}</a></li>"
	done
	echo -n "${DATA}</ul>"
	Menu
}

#
# Search mode
# --------------
#
function Search() {
	unset QUERY["mode"]
	echo "<h2>Search results</h2>"
	Menu
	KEYWORD=$(sed -e "s/+/ /g" <<<${QUERY["keyword"]})
	if [[ "${KEYWORD}" == "" ]]; then
		BackLink
		return
	fi
	cat <<EOF
Keyword:${KEYWORD}
<br>$(BackLink)<br>
EOF
	echo "<ul>"
	if [[ ! -e "${FBVVWB_SEARCH_LIST}" ]] || [[ "$(head -n 1 "${FBVVWB_SEARCH_LIST}")" != "${KEYWORD}" ]]; then
		echo "${KEYWORD}" >"${FBVVWB_SEARCH_LIST}"
		locate -i "${KEYWORD}" >>"${FBVVWB_SEARCH_LIST}"
	fi
	while read -r line; do
		QUERY["cp"]=${line}
		echo "<li><a href=\"$(QueryLink)\">${line}</a></li>"
	done < <(tail -n +2 "${FBVVWB_SEARCH_LIST}")
	echo "</ul>"
}

function SearchBackLink() {
	QUERY["mode"]="search"
	cat <<EOF
<span style="float:left">"
<a href="$(QueryLink)">Back</a>"
</span>"
EOF
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
<body bgcolor="black" text="gray" link="gray" vlink="gray" alink="gray" style="font-size:30px;">
EOF

# Mode selecter for special page.
case "${QUERY[mode]}" in
history)
	unset QUERY["mode"]
	History
	;;
links)
	unset QUERY["mode"]
	unset QUERY["keyword"]
	MoveDirLinks
	;;
append_bookmark)
	echo "<div style=\"text-align:center\">"
	echo "Append ${QUERY[cp]}, Page ${QUERY[page]} to Bookmark."
	QUERY["mode"]="default"
	LINK=$(QueryLink)
	DATE=$(date +'%Y/%m/%d %H:%M:%S')
	PAGE=$(sed -e 's/.*page=\([^\&]*\)\&.*/\1/' <<<"${LINK}")
	NAME=$(sed -e 's/.*cp=\([^\&]*\)\&.*/\1/' <<<"${LINK}")
	sed -i "/${NAME}/d" "${FBVVWB_BOOKMARK}"
	echo "${DATE},${NAME},${PAGE},${LINK}" >>"${FBVVWB_BOOKMARK}"
	echo "<p>"
	BackLink
	Menu
	echo "<p></div>"
	;;
bookmark)
	echo "<h2>Bookmark</h2>"
	BackLink
	echo "<br>"
	Menu
	echo "<ul>"
	while IFS=, read -r DATE NAME PAGE LINK; do
		echo "<li><a href=\"${LINK}\">${DATE}, Page${PAGE}, ${NAME}</a></li>"
	done <<<"$(tac "${FBVVWB_BOOKMARK}")"
	echo "</ul>"
	;;
search)
	Search
	;;
move_ask)
	echo "<div style=\"text-align:center\">"
	BUTTON_NAME="Move"
	if [[ "${QUERY[move]}" = "trash" ]]; then
		echo -n "<p>Trash</p><p>${QUERY[cp]} "
		FileSize
		echo ".<p>"
		BUTTON_NAME="Trash"
	else
		echo -n "<p>${QUERY[cp]} "
		FileSize
		"</p>"
		echo -n "<p>|</p><p>V</p><p>${QUERY[move]}</p>"
		echo -n "<p>Move $(basename "${QUERY[cp]}") to ${QUERY[move]} "
		FileSize
		echo -n "<p>"
	fi
	echo -n "<p>Are you sure?</p><table width=100%><tr><td>"
	QUERY["mode"]='move'
	echo -n "<a href=\"$(QueryLink)\">${BUTTON_NAME}</a></td><td>"
	unset QUERY["mode"]
	unset QUERY["move"]
	echo -n "<a href=\"$(QueryLink)\">Cancel</a></td></tr></table></div>"
	;;
move)
	echo "<div style=\"text-align:center\">"
	if [[ -d "${QUERY[move]}" ]]; then
		echo -n "<p>mv ${QUERY[cp]} ${QUERY[move]}</p>"
		mv "${QUERY[cp]}" "${QUERY[move]}"
	elif [[ "${QUERY[move]}" = "trash" ]]; then
		echo "<p>trash ${QUERY[cp]}</p>"
		TrashCommand "${QUERY[cp]}"
	else
		echo "No such directory.<p>${QUERY[move]}</p><p>change config file.</p>"
	fi
	unset QUERY["mode"]
	unset QUERY["move"]
	cat <<EOF
<table width=100%><tr>
<table width=100%><tr>
<td> $(PrevArchiveLink) </td>
<td> $(NextArchiveLink) </td>
</td></tr></table>
$(BackLink)
$(Menu)
</div>
EOF
	;;
default | image_viewer | manga_viewer)
	if [[ -d "${CURRENT_PATH}" ]]; then
		FileBrowser
	elif [[ -f "${CURRENT_PATH}" ]]; then
		FileViewer
	else
		cat <<EOF
-d -f failed<br>
${CURRENT_PATH}
<p>
<table width=100%><tr>
<table width=100%><tr>
<td> $(PrevArchiveLink) </td>
<td> $(NextArchiveLink) </td>
</td></tr></table>
</p>
<p> $(BackLink) </p>
$(Menu)
EOF
	fi
	;;
*)
	echo "No Such Mode. ${QUERY[mode]}"
	;;
esac

# print footer
cat <<EOF
</body>
</html>
EOF

#
# Apache Setting
# =================
#
# You can configure Apache setting in `/etc/httpd/conf/httpd.conf`
#
# Enable CGI
# ---------------
#
# You can use either cgi or cgid.
# I use cgid, thus
#
# In default setting, both of them are commented out.
#
# ```
# LoadModule cgid_module modules/mod_cgid.so
# # LoadModule cgi_module modules/mod_cgi.so
# ...
# ```
#
# Enable ScriptAlias.
#
# ```
# 	ScriptAlias /cgi-bin/ "/srv/http/cgi-bin/"
# ```
#
# And .bash for CGI script.
#
# ```
#    AddHandler cgi-script .cgi .bash
# ```
#
# Enable SuExec
# -----------
#
# ```
# LoadModule suexec_module modules/mod_suexec.so
# SuexecUserGroup <user name> <user name>
# ```
#
# Digest Authentication
# -------------
#
# ```
# <Directory "/srv/http/cgi-bin">
#     AllowOverride None
#     Options None
#     AuthType Digest
#     AuthName "<authentication name"
#     AuthUserFile "<file path created by htdigest"
#     Require valid-user
# </Directory>
# ```
#
# Permit access to home directory
# ----------------
#
# CGI itself can access any where.
# However, if you unzip a image from archive,
# you have to put somewhere that image.
# In this CGI script, the image is located in your home directory.
# Thus you should allow access to your home directory.
#
# ...
# <Directory "/home/<user name>">
# # or
# # <Directory "/home/*">
#     AllowOverride None
#     Options FollowSymLinks Indexes
#     AuthType Digest
#     AuthName "<authentication name"
#     AuthUserFile "<file path created by htdigest"
#     Require valid-user
# </Directory>
# ```
#
# Enable userdir
# ---------------
#
# ```
# LoadModule userdir_module modules/mod_userdir.so
# ```
#
# You can access your home directory like this.
#
# ```
# http://localhost/~<user name>/.fbvvwb
# ```
#
# ```
# <IfModule userdir_module>
#     UserDir disabled
#     UserDir enabled <user name>
#     UserDir ./
# </IfModule>
#
# ```

## TODO
# Some japanese directory or file cannot open.
