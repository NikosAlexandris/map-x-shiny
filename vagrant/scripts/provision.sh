#!/bin/bash

# exit on error
set -e

#
# Set variables used INSIDE THE GUEST
#

echo "Setting variables for..."

echo " - vagrant"
dirConfig="/vagrant/config"
dirLogs="/home/vagrant/logs"

echo " - receipts"
dirReceipts="/vagrant/receipts"

echo " - generated passwords"
dirpwd="/vagrant/passwords/generated"


echo " - postfix"
mailmapx=$emailbot

# email to send notification upon provision completion
if [ -z "$emailtonotify" ]; then
    echo "  ! No E-MAIL address supplied! Please provide a valid e-mail in the Vagrantfile!"
    echo "  ! The variable in question is <emailtonotify>."
    exit 1
else
    mailadmin=$emailtonotify
    echo "  i Notifications will be sent to $emailtonotify"
fi

# relay host
if [ -z "$emailrelayhost" ]; then
    echo "  ! No e-mail relay HOST supplied! Please provide a valid e-mail relay host in the Vagrantfile!"
    echo "  ! The variable in question is <emailrelayhost>."

    exit 1
else
    relayhost=$emailrelayhost
    echo "  i E-mail relay host set to $emailrelayhost"
fi

# relay port
if [ -z "$emailrelayport" ]; then
    echo "  ! No e-mail relay PORT supplied! Please provide a valid e-mail relay port in the Vagrantfile!"
    echo "  ! The variable in question is <emailrelayport>."
    exit 1
else
    relayport=$emailrelayport
    echo "  i E-mail relay port set to $emailrelayport"
fi


echo " - tools"
dirDownload="/home/vagrant/downloads"
dirTools="/home/vagrant/tools"

echo " - postgresql"
dirDbInit="/vagrant/data/pginit"
dirDumps="/vagrant/data/pgdump"

echo "  - shiny/-server"
dirShinyApp="/srv/shiny-server/"
dirMapxLanding="/srv/shiny-server/home"

# workers
nMapxWorkers=10
echo ""

# non interactive only
export DEBIAN_FRONTEND=noninteractive;


#
# simple way to add repository (not in a ppa: form) and add corresponding key.
# add-apt-repository can handle custom repo, but the key server option did not always work.
# So, going on with a simple script.
#
function addToAptSource
{
  set -e
  if [ `grep "$1" /etc/apt/sources.list | wc -l` -eq 0 ]
  then
    echo "Add $1 to sources list"
    # add new source to apt source.list
    echo $1 >> /etc/apt/sources.list
    # if a second argument is given (the key url), add it with apt-key
    if [ `echo $2 | wc -l ` -ne 0 ];
    then
      echo "Add $2 to keys"
      wget --quiet -O - "$2" | \
        apt-key add -
    else
      echo "No key given for $1"
    fi
  else
    echo "$1 seems to be already present in sources. skipping"
  fi
}

# print a message to console with 
function printMsg 
{
  printf '%20s\n' | tr ' ' -
  echo $1;
  printf '%20s\n' | tr ' ' -
}

# getPassword
# create or read password in/from a file
# usage getPassword <fileToWrite>
function getPassword
{ 
  if [ -e $1 ]
  then 
    pwd=$(cat $1)
  else
    pwd=$(</dev/urandom tr -dc '{}?!$POIULKJHMNBpoiulkjhmnb0123456789' | head -c10; echo "")
    echo $pwd > $1 
  fi
  echo $pwd;
}



#
# Password generation
#

mkdir -p $dirpwd
pwdmapxw=$(getPassword $dirpwd/psql_mapx_write)
pwdmapxr=$(getPassword $dirpwd/psql_mapx_read)
pwdpostgres=$(getPassword $dirpwd/psql_mapx_admin)
pwdgeoserveradmin=$(getPassword $dirpwd/geoserver_admin)
pwdmapxcrypto=$(getPassword $dirpwd/psql_crypto)

# following are hardcoded in/source from the `Vagrantfile`!
pwdmailmapx=$pwd_mail_mapx

# passwordless handling : smtp with password or not
if [ -z "$passwordless" ] ;then
    echo "  ! The <passwordless> variable is not set."
    echo "    Please set it to either FALSE or TRUE"
    exit 1
else
    if [ $passwordless == "FALSE" ] ;then
        echo "  i Password-less mode is set to FALSE!"
        if [ -z "$pwdmailmapx" ] ;then
            echo "  ! No password supplied nor Password-less mode is TRUE!"
            echo "    Please provide either a password for the e-mailing bot in the Vagrantfile,"
            echo "    or set password-less mode to TRUE for an free/public smtp service."
            exit 1
        else
            echo "  > Password for e-mailing bot provided!"
        fi
    else
        echo "  > Password-less mode is set to TRUE!"
        echo "  > Be sure your SMTP service is one to be used without password authentication."
    fi
fi


pwdTokenGitLabVt=$pwd_Token_GitLab_Vt


echo "Create dirs"
# tools directory : where to install mapx tools..
mkdir -p $dirTools 
# shiny app
mkdir -p $dirShinyApp 
# shiny landing page
mkdir -p $dirMapxLanding
# Installation control directory in Home (remove files here to reinstall parts).
mkdir -p $dirReceipts
# downloaded app to install dir.
mkdir -p $dirDownload
# logs directory.
mkdir -p $dirLogs


# 
# ADD SOURCES
#

if [[ ! -e $dirReceipts/apt_source ]]
then
  printMsg "receipt apt_source not found, adding apt sources "
  # POSTGRES
  addToAptSource \
    "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" \
    "http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc"
  # R
  addToAptSource \
    "deb http://cran.univ-lyon1.fr/bin/linux/ubuntu trusty/" \
    "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0xE084DAB9"

  # PASSENGER
  addToAptSource \
    "deb https://oss-binaries.phusionpassenger.com/apt/passenger trusty main" \
    "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x561F9B9CAC40B2F7"

  # NGINX
  addToAptSource \
    "deb http://ppa.launchpad.net/nginx/stable/ubuntu trusty main" \
    "http://keyserver.ubuntu.com:11371/pks/lookup?op=get&search=0x00A6F0A3C300EE8C"
  touch $dirReceipts/apt_source
else
  printMsg "receipt add_source exists, skipping"
fi

# If aptsource file does not exists, install
if [[ ! -e $dirReceipts/apt_depedencies ]]
then

  echo "no receipt apt_dependencies, clean, update and install packages "
  # Install dependencies:
  echo "check for update and install dependencies"
  # removes all packages from the package cache
  apt-get clean
  # update apt-get
  apt-get -qy update
  # install dependencies
  apt-get -qy install \
    postgresql-9.5 \
    postgresql-client-9.5 \
    postgresql-9.5-postgis-2.2 \
    libpq-dev \
    unzip \
    wget \
    g++ \
    curl \
    libssl-dev \
    git-core \
    r-base \
    r-base-dev \
    libxml2-dev \
    libcurl4-gnutls-dev \
    libv8-dev \
    libgdal-dev \
    libproj-dev \
    nginx-extras \
    apt-transport-https \
    ca-certificates \
    passenger \
    gdebi-core \
    redis-server


  # upgrade
  apt-get -qy upgrade
  # set a reminder
  touch $dirReceipts/apt_depedencies
else
  printMsg "receipt apt_depedencies present, skipping "
fi



#
# postfix
#

if [[ ! -e $dirReceipts/postfix ]]
then 
  printMsg "no receipt for postfix, install it"
  # doc found on
  # https://www.linode.com/docs/email/postfix/postfix-smtp-debian7
  # https://www.howtoforge.com/postfix_relaying_through_another_mailserver
  export DEBIAN_FRONTEND=noninteractive;
  apt-get -qy purge mailutils postfix
  apt-get install -qy postfix mailutils
  # postfix config
  postconf -e "relayhost = [$relayhost]:$relayport"
  postconf -e "smtp_sasl_auth_enable = yes"
  postconf -e "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd"
  postconf -e "smtp_sasl_security_options = noanonymous"
  echo "$relayhost  $mailmapx:$pwdmailmapx" | tee -a /etc/postfix/sasl_passwd
  chown root:root /etc/postfix/sasl_passwd
  chmod 600 /etc/postfix/sasl_passwd
  postmap /etc/postfix/sasl_passwd
  /etc/init.d/postfix restart
  echo "postfix has been installed" | mail -s "map-x provisioning" -a "From: $mailmapx" $mailadmin
  touch $dirReceipts/postfix
else
  printMsg "receipt postfix present, skipping"
fi



#
# N (nodejs version manager)
#

if [[ ! -e $dirReceipts/n ]]
then
  printMsg "no receipt for n (node version manager) install it"
  cd $dirDownload
  if [[ ! -e n ]]
  then
    git clone --depth=1 https://github.com/tj/n.git
    cd n
    make install
    n 0.10.40
    n 0.12.7
    n 5.10.1
  fi
  touch $dirReceipts/n
  cd $HOME
else
  printMsg "receipt for n found, skipping"
fi


#
# CONFIG POSTGRES
#

dbExists=$(su - postgres -c 'psql -lqt | cut -d \| -f1 | grep "mapx" | wc -l')
dbUsersExists=$(
if [[ $dbExists -eq 1 ]]
then
  echo $(su - postgres -c 'psql -d mapx -c "select tablename from pg_tables;" | grep "mx_users" | wc -l')
else
  echo 0
fi
)


if [[ ! -e $dirReceipts/postgres_init ]]
then
  printMsg "no receipt for postgres_init and Init db"
  # config postgres
  echo "host all all 0.0.0.0/0 md5" >> /etc/postgresql/9.5/main/pg_hba.conf
  echo "listen_addresses='*'" >> /etc/postgresql/9.5/main/postgresql.conf

  # CREATE MAPX DB
  if [[ $dbExists -eq 0  ]] 
  then
    echo "mapx db not found. create it"
    sudo -u postgres psql -c "CREATE DATABASE  mapx ENCODING 'UTF8';"
  else
    echo "mapx db already present : continue"
  fi

  # SET ROLES AND USERS GLOBAL ACROSS CLUSTER
  sudo -u postgres psql -d mapx -c "
  --
  -- Postgres
  --
  ALTER USER postgres WITH PASSWORD '$pwdpostgres';
  --
  -- readonly
  --
  CREATE ROLE  readonly;
  -- connect
  GRANT CONNECT ON DATABASE mapx TO readonly;
  -- usage
  GRANT USAGE ON SCHEMA public to readonly;
  -- privilege
  GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly;
  -- execute
  GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO readonly;
  --
  -- mapxr 
  --
  CREATE ROLE mapxr WITH LOGIN ENCRYPTED PASSWORD '$pwdmapxr' IN ROLE readonly;
  --
  -- readwrite
  --
  CREATE ROLE readwrite;
  -- connect
  GRANT CONNECT ON DATABASE mapx TO readwrite;
  -- usage
  GRANT USAGE ON SCHEMA public to readwrite;
  -- privileges
  GRANT SELECT,INSERT,UPDATE ON ALL TABLES IN SCHEMA public TO readwrite;
  -- execute
  GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO readwrite;
  --
  -- mapxw
  --
  CREATE ROLE mapxw WITH LOGIN ENCRYPTED PASSWORD '$pwdmapxw' IN ROLE readwrite;
  -- 
  -- Give select privilege to readonly for FUTURE table created by mapxw;
  --
  ALTER DEFAULT PRIVILEGES FOR ROLE mapxw GRANT SELECT ON TABLES TO readonly;"


  # INIT EXTENSIONS
  sudo -u postgres  psql -d mapx -c "
  -- postgis spatial data 
  CREATE EXTENSION IF NOT EXISTS postgis;
  -- case insensitive type; 
  CREATE EXTENSION IF NOT EXISTS citext;"
  # save crypto functions
  sudo -u postgres psql -d mapx -f $dirDbInit/mx_crypto.sql
  service postgresql restart 
  # save receipts
  touch $dirReceipts/postgres_init
else
  printMsg "receipt for mapx db init fount, skipping"
fi

#
# SET / UPDATE PASSWORD
#

if [[ ! -e $dirReceipts/postgres_update_password  ]] 
then
  sudo -u postgres psql -c "ALTER ROLE mapxw WITH PASSWORD '$pwdmapxw';"
  sudo -u postgres psql -c "ALTER ROLE mapxr WITH PASSWORD '$pwdmapxr';"
  sudo -u postgres psql -c "ALTER ROLE postgres WITH PASSWORD '$pwdpostgres';"
  service postgresql restart 
  touch $dirReceipts/postgres_update_password
else 
  printMsg "receipt update_password found, password already updated"
fi

#
# IMPORT / CREATE BASE TABLES
#
if [[ ! -e $dirReceipts/postgres_init_tables ]]
then
  printMsg "no receipt for postgres_init_users: create / import "
  sudo -u postgres psql -d mapx -f $dirDbInit/mx_tables.sql

  sudo -u postgres psql -d mapx -c "
  -- 
  -- Give select privilege on ALL existing table to mapxr
  --
  GRANT SELECT ON ALL TABLES IN SCHEMA public TO mapxr;
  " 
  # restart postgres
  service postgresql restart
  touch $dirReceipts/postgres_init_tables
else
  printMsg "receipt found for mapx tables, skipping"
fi


#
# IMPORT MAPX DUMP
#
if [[ -e $dirDumps/mapx.sql ]]
then
  if [[ ! -e $dirReceipts/postgres_import ]]
  then
    if [[ ! $dbExists ]]
    then
      printMsg "Importation of $dirDumps/mapx.sql requested, but db mapx does not exist. \
        Please init db and roles prior to importation (remove receipt postgres_init)"
    else
      printMsg "Mapx db exists, receipt postgres_import found and mapx.sql found : Import mapx dump."
      sudo -u postgres psql -d mapx -f $dirDumps/mapx.sql
      sudo -u postgres psql -d mapx -c "
      -- 
      -- Give select privilege on ALL existing table to mapxr
      --
      GRANT SELECT ON ALL TABLES IN SCHEMA public TO mapxr;
      " 
      touch $dirReceipts/postgres_import
    fi
  fi
fi


#
# R SHINY
#

if [[ ! -e $dirReceipts/r_shiny ]]
then 
  printMsg "No receipt r_shiny. Install shiny package"
  echo 'options("repos"="http://cran.rstudio.com")' >> /etc/R/Rprofile.site
  Rscript -e "install.packages(c('shiny'))"
  touch $dirReceipts/r_shiny
else
  printMsg "receipt r_shiny found, skipping"
fi

#
# SHINY SERVER
#

if [[ ! -e $dirReceipts/r_shiny_server ]]
then
  printMsg "No receipt r_shiny_server, add and install shiny server"
  cd $dirDownload
  # get the last version number
  SHINYVERSION=`curl https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/VERSION`
  # Get deb
  wget --no-verbose "https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/shiny-server-$SHINYVERSION-amd64.deb" -O shiny-server-latest.deb
  gdebi -n shiny-server-latest.deb
  rm -f shiny-server-latest.deb
  if [[ -e "$dirShinyApp/sample-apps" ]]
  then 
    rm -rf "$dirShinyApp/sample-apps"
  fi
  touch $dirReceipts/r_shiny_server
else
  printMsg "receipt r_shiny_server found, skipping"
fi


#
# Shiny server configuration
#

if [[ ! -e $dirReceipts/r_shiny_server_config ]]
then 
  printMsg "No receipt r_shiny_server config found, set up shiny server"
  cat $dirConfig/shiny/shiny-server.conf > /etc/shiny-server/shiny-server.conf
  service shiny-server restart
  touch $dirReceipts/r_shiny_server_config
else
  printMsg "receipt r_shiny_server_config found, skipping"
fi


#
# vt (tilesplash vector tile end point)
#

if [[ ! -e $dirReceipts/vt ]]
then 
  printMsg "no receipt for vt found : install or update it"
  # change node version
  n 5.10.1
  cd $dirTools
  if [[ ! -e vt ]]
  then
    # Install PGRestAPI
    git clone --depth=1 https://gitlab-ci-token:$pwdTokenGitLabVt@gitlab.com/fxi/vt.git
    cd vt
  else
    cd vt
    rm -rf node_modules
    git pull
  fi 
  # install modules
  npm install
  # copy and rename settings file 
  echo "var s = require('./settings-global.js');
  s.pg.con = {
  user : 'mapxr',
  database : 'mapx',
  password : '$pwdmapxr',
  port : 5432,
  host : 'localhost'};
  s.pg.key = '$pwdmapxcrypto';
  module.exports = s ;"  > $dirTools/vt/settings/settings-local.js

  mkdir -p tmp
  chmod -R 777 tmp
  touch tmp/restart.txt
  touch $dirReceipts/vt
else
  printMsg "receipt vt found, skipping"
fi


#
# Install shinyLoadBalancer ( worker 0 or w0)
#

if [[ ! -e $dirReceipts/shiny_load_balancer ]]
then
  printMsg "no receipt shiny_load_balancer found, install or update it"
  workerZero="w0"
  cd $dirShinyApp
  if [[ ! -e $workerZero ]]
  then 
    git clone --depth=1 "https://github.com/fxi/shinyLoadBalancer.git" "$workerZero"
  else
    cd $workerZero 
    git pull
  fi
  cd $dirShinyApp
  cp "$dirConfig/shinyLoadBalancer/shinyLoadBalancerConf.R" "$workerZero/config/config.R"
  touch restart.txt
  touch $dirReceipts/shiny_load_balancer
else
  printMsg "receipt shiny_load_balancer found, skipping"
fi

#
# Install mapx landing page:
#

if [[ ! -e $dirReceipts/mapx_landing ]]
then
  printMsg "no receipt for mapx_landing found: clone or update"
  if [[ ! -e $dirMapxLanding/index.html ]]
  then
    git clone --depth=1 "https://github.com/fxi/map-x-landing.git" $dirMapxLanding
  else
    cd $dirMapxLanding 
    git pull
  fi
  echo "Update ownership to shiny"
  chown -R shiny:shiny /srv/shiny-server
  touch $dirReceipts/mapx_landing 
else
  printMsg "receipt mapx_landing fount, skipping"
fi


#
# Install mapx:
#

if [[ ! -e $dirReceipts/mapx_shiny ]]
then
  printMsg "No receipt mapx_shiny, install or update"
  cd $dirShinyApp
  workerPrefix="w"
  workerMain="$workerPrefix""1"
  #   echo "<html><head><meta http-equiv=\"refresh\" content=\"0; url=w0\"></head></html>" > /srv/shiny-server/index.html
  if [[ ! -e "$workerMain" ]]
  then
    git clone --depth=1 "https://github.com/fxi/map-x-shiny.git" "$workerMain"
    cd $workerMain
    Rscript packrat/init.R --bootstrap-packrat
    touch restart.txt
  else
    cd $workerMain 
    git pull
    Rscript -e "packrat::restore()" 
    touch restart.txt
  fi

  # update passwords and key
  echo "mxConfig\$key <- '$pwdmapxcrypto';
  mxConfig\$remoteInfo <- list(
  host='127.0.0.1',
  user='vagrant',
  port=2222
  );
  mxConfig\$dbInfo <- list(
  host='127.0.0.1',
  dbname='mapx',
  port='5432',
  user='mapxw',
  password='$pwdmapxw'
  );"> settings/config-local.R


  cd $dirShinyApp
  if [[ $nMapxWorkers -gt 1 ]]
  then
    for i in $(seq 2 $nMapxWorkers)
    do
      echo "creating worker $i"
      if [[ -e $workerPrefix$i ]]
      then
        rm -rf $workerPrefix$i
      fi
      cp -r  $workerMain $workerPrefix$i
    done
  fi
  echo "Update ownership to shiny"
  chown -R shiny:shiny /srv/shiny-server
  touch $dirReceipts/mapx_shiny 
else
  printMsg "receipt for mapx_shiny found, skipping"
fi



#
# install gist
#

if [[ ! -e $dirReceipts/gist ]]
then
  printMsg "No receipt gist found. Install gist"
  gem install gist
  touch  $dirReceipts/gist
else
  printMsg "receipt gist found, skipping"
fi

#
# setup nginx
# 
if [[ ! -e $dirReceipts/nginx_config ]]
then
  printMsg "No receipt for nginx_config found, import it"
  cp $dirConfig/nginx/nginx.conf /etc/nginx/nginx.conf
  cp $dirConfig/nginx/mapx.conf /etc/nginx/sites-enabled/mapx.conf
  echo "restart nginx"
  service nginx restart
  touch $dirReceipts/nginx_config
else
  printMsg "receipt nginx_config found skipping"
fi

#
# GDAL
#

if [[ ! -e $dirReceipts/gdal_bin ]]
then
  printMsg "No receipt gdal. Add and install gdal "
  cd $dirDownload
  # get the last version number
  sudo wget http://download.osgeo.org/gdal/2.1.1/gdal-2.1.1.tar.gz gdal
  cd gdal
  ./configure
  make -j 10
  make install
  ldconfig
  touch $dirReceipts/gdal_bin
else
  printMsg "receipt gdal found, skipping"
fi



printMsg "Done."

