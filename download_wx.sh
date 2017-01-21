#!/bin/zsh

BASE_URL='http://www.ftp.ncep.noaa.gov/data/nccf/com/gfs/prod/gfs.%s%s/gfs.t%sz.pgrb2.0p50.f%s'

# dates and hour 
YMD=$(date -u +"%Y%m%d")
H=$(date -u +"%H")

# determine utc hour
if [ $H -ge 0 -a $H -le 8 ]; then H=0
elif [ $H -gt 8 -a $H -le 14 ]; then H=6
elif [ $H -gt 14 -a $H -le 20 ]; then H=12
elif [ $H -gt 20 ]; then H=18
fi

# hour list
HOURS=($(seq -f '%03g' -s ' ' 0 3 6))

# generate url list
URL_LIST=$(for x in $HOURS; do printf "$BASE_URL\n" $YMD $H $H $x; done)

# download the grib files
echo $URL_LIST | xargs -n1 -P8 wget -P weather/

# References:
#
# http://www.nco.ncep.noaa.gov/pmb/docs/on388/table2.html
#   - column names
#
# items we care about to -match when generating csvs with wgrib2:
# Surface Temp: 
#   - TMP:surface:anl
# Surface Pressure:
#   - PRES:surface:anl
# Wind Speed:
#   - WIND
# wgrib2 -match TMP:surface:anl: weather/gfs.t12z.pgrb2.0p50.f000 -csv tmp


