#!/bin/zsh
INSTALL_DIR=/usr/bin/
GRIB_TAR="grib_api-1.19.0-Source.tar.gz?api=v2"
GRIB_SOURCE="grib_api-1.19.0-Source"
LIB_JASPER_URL="http://ftp.us.debian.org/debian/pool/main/j/jasper/libjasper-dev_1.900.1-debian1-2.4+deb8u1_amd64.deb"
LIB_JASPER1_URL="http://ftp.us.debian.org/debian/pool/main/j/jasper/libjasper1_1.900.1-debian1-2.4+deb8u1_amd64.deb"

# grib api dep -- need jpeg lib
if ! [ -x /usr/include/jasper ]; then 
    wget $LIB_JASPER1_URL
    dpkg -i libjasper1_1.900.1-debian1-2.4+deb8u1_amd64.deb
    apt-get install -f
    wget $LIB_JASPER_URL
    dpkg -i libjasper-dev_1.900.1-debian1-2.4+deb8u1_amd64.deb 
    apt-get install -f
    rm libjasper*
else
    echo "libjasper-dev already installed"
fi

# pull and build grib api
if ! [ -x /usr/local/include/grib_api ]; then
    if ! [ -d grib_build ]; then mkdir grib_build; fi 
    cd grib_build
    if ! [ -f $GRIB_TAR ]; then
        wget "https://software.ecmwf.int/wiki/download/attachments/3473437/grib_api-1.19.0-Source.tar.gz?api=v2" 
    fi
    tar -xzf $GRIB_TAR
    cd $GRIB_SOURCE
    if ! [ -f /usr/bin/include/grib_api.h ]; then
        ./configure --prefix=$INSTALL_DIR
        make
        # Uncomment if you want to download and run tests
        # make check
        make install
    fi

    # cleanup
    cd ../../
    rm -rf grib_build
else
    echo "Grib API already installed"
fi


# install pygrib
if ! [ -f /usr/local/lib/python2.7/dist-packages/pygrib.so ]; then
    if ! [ -d pygrib ]; then git clone https://github.com/jswhit/pygrib.git; fi
    mv setup.cfg pygrib/setup.cfg
    cd pygrib && python setup.py build && python setup.py install && python test.py test && cd ../

    # cleanup
    rm -rf pygrib
else
    echo "PyGrib already installed"
fi


