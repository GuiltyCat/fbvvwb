
File Browser and Viewer Via Web Browser (FBVVWB)
================================================

```
     _________________________________
    //___// _ \| V /| V /| V  V // _ \\
   //___// // /|  //|  //|  /  // // //
  ///   / // \\| // | // | /| // // \\
 ///   /____// |//  |//  |//|//____//
```

Motivation
-----------

I want to read manga(comics) zip file saved in my PC from iPad.
However, I cannot find any good free app that support stream reading.
Some apps are paid, some apps are with advertisement and
some apps require file downloading.
I do not want to pay money for software.

Thus I implement this script.
Now I can browse file and read manga in my PC via web browser.
And more I can do more things.
For example, see videos, listen to musics, search files...

Description
-----------

This script is a simple file browser and viewer that works on a web server as CGI.
It is like file browsing app with simple viewer.

You can

- Browse files under your home directory (default setting).
- View manga and images.
	- Archive is suported (.zip .rar .tar.gz .cbz ...)
	- Dual page mode is supported.
- Watch movies.
- Listen musics.
- Trash files.

This script is supported to work in Local Area Network (LAN).
***NEVER ALLOW ACCESS TO THIS SCRIPT WITHOUT YOU!***
You must deny all accesses from others.
See security section for more information.

Requirements
---------------

- Web server software that can run bash as CGI
	- Apache,....
- Bash
	- grep, sed, cut, whoami, :,
- unar/lsar (for unarchiving)
- trash-cli
- iconv, nkf (for detecting and converting character set)
- locale (for searching file)

Security
--------

This script is very dangerous.
Never allow access to this CGI without you.

At Least, you should enable `suexec` and `Digest Authentication` if you use Apache.
And more, you should enable TLS and use HTTPS if you can do,

Installation
--------------

- Put this CGI script on your web server.
	- For example, `/srv/http/cgi-bin/index.bash`.
- Wake up your web server.
	- For example, `sudo systemctl start httpd.service`
	- For example, `sudo systemctl start httpd.service`
- Access to this CGI script by browser.

I put this script in `/srv/http/cgi-bin` as `/srv/http/cgi-bin/index.bash`
I access by `http://localhost/cgi-bin/index.bash`.
Or from other device `http://192.168.1.<num>/cgi-bin/index.bash`.

Avairable Query
------
```
http://<address>?<query>
<query> := <query>&<query>
<query> := <key>=<value>
```

Query is automatically passed to next page
except for some dangerous query like trash.

You can manually add queries in order to change setting.

Sample
    http://localhost?page=1&cp=/home/bob/file.zip

Query Key List

```
cp=<path>
   current path. You can set absolute path.
	 For example, cp=/home/bob/
   For security, it must start with /home/$(whoami),
   and must not contain .. (to upper directory).

mode=<history>
   If you want to see history.
   set mode=history.
   In other case, you should not set.
   This script automatically use this option.
   Some options are used to trash a file.

   For example, if you set mode=trash.
   The file of cp is trashed.

File Browse Mode

Photo View and Manga View mode

percent=<percent>
    This percent is used to set <img width=percent%> tag.
    Default is 80.
page=<num>
    Select manga page.
    In dual page mode, it means smaller page.
    If negative or over max page is set,
    it will automatically fixed to 1 and max.
view_mode=<dual or single>
    If dual, dual image is showedd in one page.
    Otherwise single page.
order=<lr or lr>
    In dual mode, reading page left to right or right to left.
```

_________________________________________


Program Description
===================

Parsing options
---------------

This CGI script is written in bash.
Thus you can run this from terminal.

If there is no options are passed.

Avairable options are

```
- `--help` or `-h`            : Generate markdown document from this script.
- `--generate-readme` or `-g` : Generate README.md from `-h` option's output.
- `-c`                        : Print default configure file.
- otherwise                   : Ignored.
```

If options are set, this script run as non-CGI mode.

## MIME type

Apache requires MIME type.
`Content-Type: text/html\n\n`

Default top directory is defined by TOP_DIRECTORY

Set "true" if you want to disable trash link.

You can add your own directory to MOVE_DIRS.
If you add pathes to MOVE_DIRS, new links are created. 
Each name of links is basename of path. It will be directory name.
If you click the link, that archive is move to the corresponding directory.
This link lead you to ask page, move or cancel.
trash is special command for trashing a file.
If you add empty string "", it is means new row.
You can add your own function

FBVVWB save image list for image viewer mode.
This list is saved as `${FBVVWB_DIRECTORY}/img_list`.

For future use, FVVWB saves opened file name as history.
Default name is `${FBVVWB_DIRECTORY}/history`


## Parsing query

This CGI script works by passing query.
If query is omitted, this script automatically complete by default value.
And you can manually change query options.

You can use GET and POST method.
If you use apache.

- GET passes as variable QUERY_STRING
- POST passes as stdin.

Unavailable options are ignored.


### Get query


### Post query

## For Security

This script reject access without your home and mnt directory.
And also reject link to upper directory.
When it comes, cp is regarded as TOP_DIRECTORY.

But this script do not check a destination of a symbolic link.
If symbolic link that points a dangerous place exists,
This script cannot prevent access to that dangerous place.

## Set default query (key and value) if empty
This two hyphen is not equal.
95 is true path.
Maybe nkf convert 95 to 94.
—:E2,80,94,
―:E2,80,95,
If page is not set or negative.
page is automatically set as 1.

Prepare functions
-----------------

echo "b:${QUERY[uplink]}"
## Trash functions

File Browser
------------

I want to add link in each folder separated by /
/home/bob/hello/world.txt
  link to each directory
if you pipe this.
sub process  is created,
thus you cannot update COUNTER.

ImageViewer's functions
--------------------

echo "<!--C_DIR=${C_DIR}-->"
Because, first line is directory name.
echo -n "<!- page=${PAGE}->"
echo "PAGE=${PAGE}"
IMG_NAME="${FBVVWB_DIRECTORY}/img_${NUM}.${EXT}"
"${FBVVWB_IMG_DIRECTORY}/img_${NUM}.${EXT}"
echo "IMGID=${IMG_ID}"
IMG_PATH=$(cut -d':' -f2 <<<"${IMG_ID_PATH}")
local PLACE=$1
echo -n "<span style=\"float:${PLACE}\">"
echo -n "</span>"
local PLACE=$1
echo -n "<span style=\"float:${PLACE}\">"
echo -n "</span>"
echo "<-- IMG_PATH=${IMG_PATH} -->"
0 -> -2, 1 -> +2
echo "<!-page=${QUERY[page]}->"
If you go to upper directory.
page is reset to empty.
echo add size of file here
############################
echo "<video height=\"${HEIGHT}\" muted controls autoplay>"

FileViewer
--------------

Select how to open a selected file.


Menu
-----------


You can add your own Menu Link.
Add function name to MENU_LINKS in config file.
See CreateConfig for more detail.

Create sub-process to prevent variable from changing.

History Mode
--------------


Link Mode
---------------


Search mode
--------------


main
----

print header
Mode selecter for special page.
echo "<p>"
echo "</p>"
print footer

Apache Setting
=================

You can configure Apache setting in `/etc/httpd/conf/httpd.conf`

Enable CGI
---------------

You can use either cgi or cgid.
I use cgid, thus

In default setting, both of them are commented out.

```
LoadModule cgid_module modules/mod_cgid.so
# LoadModule cgi_module modules/mod_cgi.so
...
```

Enable ScriptAlias.

```
	ScriptAlias /cgi-bin/ "/srv/http/cgi-bin/"
```

And .bash for CGI script.

```
   AddHandler cgi-script .cgi .bash
```

Enable SuExec
-----------

```
LoadModule suexec_module modules/mod_suexec.so
SuexecUserGroup <user name> <user name>
```

Digest Authentication
-------------

```
<Directory "/srv/http/cgi-bin">
    AllowOverride None
    Options None
    AuthType Digest
    AuthName "<authentication name"
    AuthUserFile "<file path created by htdigest"
    Require valid-user
</Directory>
```

Permit access to home directory
----------------

CGI itself can access any where.
However, if you unzip a image from archive,
you have to put somewhere that image.
In this CGI script, the image is located in your home directory.
Thus you should allow access to your home directory.

...
<Directory "/home/<user name>">
# or
# <Directory "/home/*">
    AllowOverride None
    Options FollowSymLinks Indexes
    AuthType Digest
    AuthName "<authentication name"
    AuthUserFile "<file path created by htdigest"
    Require valid-user
</Directory>
```

Enable userdir
---------------

```
LoadModule userdir_module modules/mod_userdir.so
```

You can access your home directory like this.

```
http://localhost/~<user name>/.fbvvwb
```

```
<IfModule userdir_module>
    UserDir disabled
    UserDir enabled <user name>
    UserDir ./
</IfModule>

```
