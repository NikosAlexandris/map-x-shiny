# Configuration instruction


Three files are mendatory during development :

config-local.R
config-global.R
sshConfig


## configuration files

config-global.R : general configuration file
config-local.R : config file containing local adjustement, such as host, port..

## ssh configuration 
When develppping map-x outside a virtual server, we need interract with processes running on a virtual server. E.g. geoserver, pgrestapi, postgresql. A ssh connection with a key is needed. This is not used at all in production mod, as internal system call can be done. To produce a ssh configuration file, from the same vagrant directory providing the virtual server : type


vagrant ssh-config > sshConfig




