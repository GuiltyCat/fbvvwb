
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
	- Archive is suported (.zip .rar .tar.gz ...)
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
- unar/lsar
- trash-cli
- locale

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
- `-h`      : Generate markdown document from this script.
- `--generate-readme` or `-g`
            : Generate README.md from `-h` option's output.
- otherwise : Ignored.
```

If options are set, this script run as non-CGI mode.

## MIME type

Apache requires MIME type.
`Content-Type: text/html\n\n`

## Prepare files

Default top directory is defined by`TOP_DIRECTORY`.
You can change by your self

If you want to disable trash link.
make DISABLE_TRASH="true"

# FBWWB's temporary directory and files.

FBWWB use several temporary directory and files.
Default directory is `/home/<usr>/.fbvvwb`
defined byu `FBVVWB_DIRECTORY`.


Read Config File

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

## Trash functions

File Browser
------------


ImageViewer's functions
--------------------

FileViewer
--------------

Select how to open a selected file.


Menu
-----------


History Mode
--------------


Search mode
--------------


main
----

print header
Mode selecter for special page.
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
