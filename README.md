# Introduction
CIAX-xml is a name of a software bundle for device control on Linux which contains environment, script, and configuration files. 
# Requirement
* ruby2.1 or later (for using JSON)
* ruby-libxml (XML instead of REXML)
* libxml2-utils (xmllint)
* apache(http server) + php
* libxml-xpath-perl (xpath command)
* coreutils
* xmllint (XML validator)
* socat (communication for UDP/TCP/..., that has more features than 'nc')
* sqlite3 (light weight sql server for logging, not for access from multiple processes)

# Installation
CIAX-xml is installed by using ''git''. Do the following command in the home directory. It will be done on a user account.
```
$ git clone https://github.com/ciax/ciax-xml.git
```
And run the setup script.
```
$ ~/ciax-xml/utils/setup-ciax.sh
```
## Client Server Mode
It is recommended to set the user as a ''sudo'' user. If you want to use client server mode, a HTTP server should be set up for export the status.
### Sudo setting
CIAX-xml has a several administration tools for setting up. While you can do it on account of the super user also, it is recommended to make ''sudo'' use on the user account. To set up the sudo user, you assume to be the root user. The name of ''sudo'' user on Debian is different on CentOS (will be ''wheel''). 
#### Join your account to ''sudo'' group
```
# vi /etc/group
...
sudo:x:27:(add user name)
...
```
#### Set ''no password execution'' to shortcut the input (Do not set up on a shared PC.)
```
 # visudo
 ...
 %sudo  ALL=(ALL) ALL  ---> NOPASSWD: ALL
 ...
```
### Web setting
The set up script is provided.
```
$ setup-www
```
It exports the CIAX-v2 status dir (~/.var/json) via web pages. Following links are 
* http://servername/json
* http://servername/log
* http://servername/record

## Device Setting
There are some preset of device setting for communication protocol, primitive command list and response frame storage.
These are provided for each device.
(/ciax-xml/fdb-*.xml)

To use it, you need to provide the device assignment file including some information like IP address, TCP port number and ID.
(/ciax-xml/ddb-*.xml)

For details of the xml file setting, see "XML Schema" in the Wiki.
