#!/bin/zsh

BASE_URL='http://www.ftp.ncep.noaa.gov/data/nccf/com/gfs/prod/gfs.%s%s/gfs.t%sz.pgrb2.0p50.f%s'

# dates and hour 
YMD=$(date -u +"%Y%m%d")
H=$(date -u +"%H")

# determine utc hour
if [ $H -ge 0 -a $H -le 6 ]; then H=0
elif [ $H -gt 6 -a $H -le 12 ]; then H=6
elif [ $H -gt 12 -a $H -le 18 ]; then H=12
elif [ $H -gt 18 ]; then H=18
fi

# hour list
HOURS=($(seq -f '%03g' -s ' ' 0 3 6))

# generate url list
URL_LIST=$(for x in $HOURS; do printf "$BASE_URL\n" $YMD $H $H $x; done)

# download the grib files
echo $URL_LIST | xargs -n1 -P8 wget -P /weather




