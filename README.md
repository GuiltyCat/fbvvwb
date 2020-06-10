!/bin/bash
set -e

File Browser and Viewer Via Web Browser (FBVVWB)
================================================

```
     _________________________________
    //___// _ \| V /| V /| V  V // _ \\
   //___// // /|  //|  //|  /  // // //
  ///   / // \\| // | // | /| // // \\
 ///   /____// |//  |//  |//|//____//
```

Description
-----------

This script is a simple file browser and viewer that works on a web server as CGI.

You can

- Browse files under your home directory (default setting).
- View manga and images.
	- Archive is suported (.zip .rar .tar.gz ...)
	- Dual page mode is supported.
- Watch movies.
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
- unar/lsar
- trash-cli

Security
--------

This script is very dangerous.
Never allow access to this CGI without you.

At Least, you should enable `suexec` and `Digest Authentication` if you use Apache.
And more, you should enable TLS and use HTTPS if you can do,

### sample setting

`/etc/httpd/conf/httpd.conf`

```
LoadModule suexec_module modules/mod_suexec.so
...
# I use cgid not cgi.
LoadModule cgid_module modules/mod_cgid.so
# LoadModule cgi_module modules/mod_cgi.so
...
SuexecUserGroup <user name> <user name>
<Directory "/srv/http/cgi-bin">
   AllowOverride None
   Options None
   AuthType Digest
   AuthName "<authentication name>"
   AuthUserFile "<file path created by htdigest>"
   Require valid-user
</Directory>
...
# I have only one directory in home thus I use *.
# <Directory "/home/<user name>">
<Directory "/home/*">
    AllowOverride None
    Options FollowSymLinks Indexes
    AuthType Digest
    AuthName "<authentication name"
    AuthUserFile "<file path created by htdigest"
    Require valid-user
</Directory>
...
<IfModule userdir_module>
    UserDir disabled
    UserDir enabled <user name>
    UserDir ./
</IfModule>

```

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

http://<address>?<query>
<query> := <query>&<query>
<query> := <key>=<value>

Query is automatically passed to next page
except for some dangerous query like trash.

You can manually add queries in order to change setting.

Sample
    http://localhost?page=1&cp=/home/bob/file.zip

Query Key List

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

_________________________________________


Program Description
===================

Parsing options
---------------

This CGI script is written in bash.
Thus you can run this from terminal.

If there is no options are passed.

Avairable options are

- `-h`      : Generate markdown document from this script.
= `--generate-readme`
            : Generate README.md from `-h` option's output.
- otherwise : Ignored.

If options are set, this script run as non-CGI mode.

## MIME type

Apache requires MIME type.
`Content-Type: text/html\n\n`


## Read Config File

Yet implemented

```
FBVVWB_CONFIG="/home/$(whoami)/.fbvvwb_conf"
if [[ ! -f "${FBVVWB_CONFIG}" ]]; then
fi
``

## Prepare files

Default top directory is defined by`TOP_DIRECTORY`.
You can change by your self

If you want to disable trash link.
make DISABLE_TRASH="true"

# FBWWB's temporary directory and files.

FBWWB use several temporary directory and files.
Default directory is `/home/<usr>/.fbvvwb`
defined byu `FBVVWB_DIRECTORY`.

FBVVWB save image list for image viewer mode.
This list is saved as `${FBVVWB_DIRECTORY}/img_list`.

For future use, FVVWB saves opened file name as history.
Default name is `${FBVVWB_DIRECTORY}/history`

## Parsing query

All functions are called by passing query.
If query is omitted, this script automatically complete by default value.
And you can manually change query options.

Unavailable options are ignored.

## For Security

This script reject access without your home directory.
And also reject link to upper directory or contain keyword /root/.

But if symbolic link exists under your home directory.
This script cannot prevent access to some dangerous place.

## Set default query (key and value) if empty
If page is not set or negative.
page is automatically set as 1.

Prepare functions
-----------------

## Trash functions

File Browser
------------


ImageViewer's functions
--------------------

FileViewer
--------------

Select how to open a selected file.


main
----

print header
Mode selecter for special page.
print footer
