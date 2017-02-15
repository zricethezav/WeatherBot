#!/bin/bash

# defs
PG_VERSION=9.4
PG_CONF="/etc/postgresql/$PG_VERSION/main/postgresql.conf"
PG_HBA="/etc/postgresql/$PG_VERSION/main/pg_hba.conf"
PG_DIR="/var/lib/postgresql/$PG_VERSION/main"

# --------------------------------------------------------
# Install PostGIS
postgis() {
    if ! [ -x /usr/bin/psql ]; then
        echo *** Installing PostGres/PostGIS ***
        sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt trusty-pgdg main" >> /etc/apt/sources.list'
        wget --quiet -O - http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | apt-key add -
        sudo apt-add-repository -y ppa:georepublic/pgrouting
        sudo apt-get update
        sudo apt-get install -y  "postgresql-$PG_VERSION-postgis-2.1" pgadmin3 postgresql-contrib libssl-dev
    else
        echo "postgres already installed"
    fi

    # listen on '*'
    sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "$PG_CONF"
    # password auth
    sudo echo "host    all             all             all                     md5" >> "$PG_HBA"
    # Explicitly set default client_encoding
    sudo echo "client_encoding = utf8" >> "$PG_CONF"
    # Restart so that all new config is loaded:
    service postgresql restart

    # create weather database
    sudo -u postgres createdb weather
    sudo -u postgres psql -c "CREATE EXTENSION postgis;" weather
	sudo -u postgres -H -- psql -d weather -c "create table tmp(
	  id serial not null,
	  analysis_utc timestamp,
	  start_forecast_utc timestamp,
	  field varchar(4),
	  field_level varchar(64),
	  longitude real,
	  latitude real,
	  grid_value real,
	  long_lat geography(point,4326)
	);"

}


# --------------------------------------------------------
# install wgrib2 for grb->csv
# http://www.cpc.ncep.noaa.gov/products/wesley/wgrib2/csv.html
wgrib2() {
    echo *** Installing wgrib2 ***
    if ! [ -x /usr/bin/wgrib2 ]; then 
        sudo apt-get install -y gfortran
        wget --quiet ftp://ftp.cpc.ncep.noaa.gov/wd51we/wgrib2/wgrib2.tgz.v2.0.4
        tar -xzvf wgrib2.tgz.v2.0.4
        cd grib2
        export CC=gcc
        export FC=gfortran
        sudo make
        cd ../
        echo $PWD
        sudo cp grib2/wgrib2/wgrib2 /usr/bin
        # rm wgrib2.tgz
        # rm -rf grib2
    else
        echo "wgrib2 already installed"
    fi
}


# TODO setup crontab to schedule psql inserts

# --------------
# install da shit
wgrib2
postgis
