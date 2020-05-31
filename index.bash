#!/bin/bash
set -e
declare -A QUERY

QUERY_STRING="abc=012&def=345&ghi=678"
for i in $(tr '&' ' ' <<<${QUERY_STRING}); do
	KEY=${i%%=*}
	VALUE=${i##*=}
	QUERY[${KEY}]=${VALUE}
	echo "${KEY}:${VALUE}"
done

# Current Path
if [[ "${QUERY["cp"]}" = "" ]]; then
	QUERY["cp"]="${HOME}"
fi

# print header
cat <<EOF
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>${QUERY["cp"]}</title>
</head>
<body>
EOF

function FileBrowser() {
	echo "<ul>"
	for i in ${QUERY["cp"]}/*; do
		LINK="$0?cp=${i}"
		echo "<li><a href=\"${LINK}\">${i}</a></li>"
	done
	echo "</ul>"
}

function MangaViewer() {
	TITLE=${QUERY["cp"]}
}

if [[ -d ${QUERY["cp"]} ]]; then
	FileBrowser
elif [[ -f ${QUERY["cp"]} ]]; then
	MangaViewer
else
	echo "Error"
fi

# print footer
cat <<EOF
</body>
</html>
EOF
