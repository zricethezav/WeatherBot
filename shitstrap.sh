#!/bin/bash
#
# install wgrib2 for grb->csv
# http://www.cpc.ncep.noaa.gov/products/wesley/wgrib2/csv.html
echo *** Installing wgrib2 ***
if ! [ -x /usr/bin/wgrib2 ]; then 
    sudo apt-get install -y gfortran
    wget --quiet ftp://ftp.cpc.ncep.noaa.gov/wd51we/wgrib2/wgrib2.tgz
    tar -xzvf wgrib2.tgz 
    cd grib2
    export CC=gcc
    export FC=gfortran
    make
    cd ../
    echo $PWD
    sudo cp grib2/wgrib2/wgrib2 /usr/bin
    rm wgrib2.tgz
    rm -rf grib2
else
    echo "wgrib2 already installed"
fi

# Install PostGIS
echo *** Installing PostGIS ***
	sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt trusty-pgdg main" >> /etc/apt/sources.list'
	wget --quiet -O - http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | apt-key add -
	sudo apt-add-repository -y ppa:georepublic/pgrouting
    sudo apt-get update
	sudo apt-get install -y postgresql-9.4-postgis-2.1 pgadmin3 postgresql-contrib libssl-dev

echo ' '
echo --- PostGIS Installed - note there will be post-configuration steps needed ---
