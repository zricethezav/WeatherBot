#!/bin/zsh
INSTALL_DIR=/usr/bin
GRIB_TAR="grib_api-1.19.0-Source.tar.gz?api=v2"
GRIB_SOURCE="grib_api-1.19.0-Source"
LIB_JASPER_URL="http://ftp.us.debian.org/debian/pool/main/j/jasper/libjasper-dev_1.900.1-debian1-2.4+deb8u1_amd64.deb"
LIB_JASPER1_URL="http://ftp.us.debian.org/debian/pool/main/j/jasper/libjasper1_1.900.1-debian1-2.4+deb8u1_amd64.deb"
if ! [ -x /usr/bin/jasper ]; then 
    wget $LIB_JASPER1_URL
    dpkg -i libjasper1_1.900.1-debian1-2.4+deb8u1_amd64.deb
    apt-get install -f
    wget $LIB_JASPER_URL
    dpkg -i libjasper-dev_1.900.1-debian1-2.4+deb8u1_amd64.deb 
    apt-get install -f
fi
if ! [ -d grib_build ]; then mkdir grib_build; fi 
cd grib_build
if ! [ -f $GRIB_TAR ]; then
    wget "https://software.ecmwf.int/wiki/download/attachments/3473437/grib_api-1.19.0-Source.tar.gz?api=v2" 
fi
tar -xzf $GRIB_TAR
cd $GRIB_SOURCE
./configure --prefix=$INSTALL_DIR
make
# Uncomment if you want to download and run tests
# make check
make install
cd ../../
rm -rf grib_build
rm libjasper*


