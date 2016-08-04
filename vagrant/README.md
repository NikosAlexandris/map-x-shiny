# MAP-X-FULL

## Overview

* Check/Install dependencies: `git`, `Vagrant`, `VirtualBox`.

1. Clone the project

2. Copy `Vagrantfile_Template` as `Vagrantfile`

3. Edit there-in the variables

   - `v.cpus = x`
   - `v.memory = xxxx`
   - `emailrelayhost`
   - `emailrelayport`
   - `pwd_mail_mapx`
   - `emailtonotify`

4. Provision the virtual machine via `vagrant up`

5. Access locally the "MAP-X" application via a web browser, ie at
   `http://localhost:8080/`.

## In Detail

*Vagrantfile*

To begin with,

a template for vagrant's configurations is provided and is named `Vagrantfile_Template`.

For vagrant to perform a provision, a file named `Vagrantfile` is required.
The template file `Vagrantfile_Template` may be copied as `Vagrantfile`.  In
it, important variables have to be set so as to enable for a successful
provision of the "map-x" virtual machine and allow its e-mailing system to
operate without errors.

The variables in question are:

- `v.cpus = x`      # Number of CPUs. Replace `x` as appropriate.
Example: `v.cpus = 2`

- `v.memory = xxxx` # Amount of Memory. Replace `xxxx` as appropriate.
Example: `v.memory = 4096`

- `emailrelayhost`  # SMTP relay *host* server

- `emailrelayport`  # SMTP relay server's *port*

- `pwd_mail_mapx`   # Authentication password 

- `emailtonotify`   # Username 

If familiar with vagrant and its settings, more options can be customised.

*Passwordless SMTP service*

In addition,

there is a variable called `passwordless` which might be used to
set up for a free/public SMTP service that does not require password
authentication.  For such a service, this variable may be set to 
`passwordless = TRUE`.

In which case, the variable `pwd_mail_mapx` will be ignored. **This is not implemented yet.**


*Provision*

The provision may be launched via the command `vagrant up`.  The provision will
fail if any of the above mentioned variables are not set.

The command `vagrant provision` will re-provision the machine after any modifications
(ie to the provisioning scripts).

It is important to make use of the *receipts*. For each successfully installed and configured component, a receipt (file) is created inside the directory `/vagrant/receipts`.  After any modification related to a component, the receipt (file) must be removed before the re-provisioning.  Otherwise, the modifications won't be applied.

# Notes

- In this version of map-x, excluded from git's archive are:

  - the `Vagrantfile`
  - all sql dumps
  - files that contain passwords or other important information

*Postfix*

Here, notes on postfix' settings to send e-mails via Google.  Maybe useful if
emailing isn't working as expected.

A working copy of postfix settings, from a local map-x-full instance, for
sending e-mails via Google's smtp

`/etc/postfix/main.cf`:

```{sh}
# See /usr/share/postfix/main.cf.dist for a commented, more complete version

# Debian specific:  Specifying a file name will cause the first
# line of that file to be used as the name.  The Debian default
# is /etc/mailname.
#myorigin = /etc/mailname

smtpd_banner = $myhostname ESMTP $mail_name (Ubuntu)
biff = no

# appending .domain is the MUA's job.
append_dot_mydomain = no

# Uncomment the next line to generate "delayed mail" warnings
#delay_warning_time = 4h

readme_directory = no

# TLS parameters
smtpd_tls_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
smtpd_tls_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
smtpd_use_tls=yes
smtp_tls_security_level = encrypt
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
smtpd_tls_session_cache_database = btree:${data_directory}/smtpd_scache
smtp_tls_session_cache_database = btree:${data_directory}/smtp_scache

# See /usr/share/doc/postfix/TLS_README.gz in the postfix-doc package for
# information on enabling SSL in the smtp client.

smtpd_relay_restrictions = permit_mynetworks permit_sasl_authenticated defer_unauth_destination
myhostname = map-x-full
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
mydestination = map-x-full, localhost.localdomain, , localhost
# below, replace EmailRelayHost and PORT as appropriate
relayhost = [EmailRelayHost]:PORT  
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
mailbox_size_limit = 0
recipient_delimiter = +
inet_interfaces = all
inet_protocols = all

#smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_sasl_tls_security_options = noanonymous
smtp_sasl_auth_enable = yes
```

and the file `sasl_passwd` should contain:

```{sh}
[smtp.gmail.com]:PORT    Username:PassWord
```
Obviously, the PORT, Username and PassWord should be replaced as appropriate.
Notes

After creating a, for example, `sasl_password` file, do `postmap
/etc/postfix/sasl_passwd`. File permissions for `sasl_password` and
`sasl_password.db` are important!  An example:

```{sh}
-rw------- 1 root root       56 Jun 16 10:12 sasl_passwd
-rw------- 1 root root    12288 Jun 16 09:14 sasl_passwd.db
```

Don't forget to restart postfix after configuration modifications, ie:
`/etc/init.d/postfix restart`.



## Archived Notes

Small tutorial to create a local VM "map-x-full" on mac. 

### Vagrant provisioning


#### Folder tree

```{sh}
.
|-- README.md     %doc source
|-- README.pdf    % this file
|-- Vagrantfile   % vm config
`-- scripts
    |-- Passengerfile.json % Launch pgrestapi with passenger
    |-- exhibitor.txt % exhibitor conf
    |-- pm2_pgrestapi.js % old file. Launch pgrestapi with pm2
    |-- provision.sh % Provisioning file. 
    |-- server.xml % tomcat server config
    |-- settings-map-x.R % map-x database config
    |-- settings-node-proxy.js % shiny-node proxy config
    |-- settings-pgrestapi.js % pgrestapi settings
    `-- tomcat.txt % tomcat defaults
```

#### Provisioning on Mac OS X (create a virtual box machine).


##### Important notice

* Each file can be edited with a text editor like textwrangler; Sublime Text; Vim; or similar. Do NOT use MS word; TextEdit; Pages, etc..
* Please read the Vagrantfile and edit, if needed, accordingly to the host:
    * VM name
    * RAM
    * CPU
    * port forwarding
* Please read the provision script.  scritpts/provision.sh 
* Environment variables fed in to the virtual machine's /etc/profile.d/vagrant.sh as per "https://gist.github.com/bivas/6192d6e422f8ff87c29d"

#### Dependencies

```{sh}
# Dependencies
brew install cask
brew cask install vagrant
```

##### Provisioning

```{sh}
# cd to the project and update
git pull 
vagrant up
```

##### Connect to vm

```{sh}
# ssh
vagrant ssh 
```


##### Connect to postgres.

```{sh}
# pg readonly
psql -h localhost -p 5432 -d mapx -u mapxr 
# pg write 
psql -h localhost -p 5432 -d mapx -u mapxw
# pg admin
psql -h localhost -p 5432 -d mapx -u postgres

```
##### Dump post pg db
as superuser
```{sh}
sudo su postgres
cd $HOME
pg_dump -U postgres -d mapx > mapx.sql
exit
sudo mv /var/lib/postgresql/mapx.sql /vagrant/pgdump/mapx.sql

```
