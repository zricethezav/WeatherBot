#!/bin/bash

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
#
# mkdir for tmp, precip csv grib files
mkdir -p "$PWD/tmp"
mkdir -p "$PWD/pwat"
mkdir -p "$PWD/merged"
mkdir -p "$PWD/filter"
# base url for download
BASE_URL='http://www.ftp.ncep.noaa.gov/data/nccf/com/gfs/prod/gfs.%s%s/gfs.t%sz.pgrb2.0p50.f%s'
# dates and hour 
YMD=$(date -u +"%Y%m%d")
H=$(date -u +"%H")
# hours array
HOURS=($(seq -f '%03g' -s ' ' 0 3 380))

# arg1 - url for an individual hour
# extracts products from grib files and marshals them into 
marshalwx() {
    wget -P "$PWD/gribs" $1
    FILENAME="$(cut -d'/' -f10 <<<"$1")"
    PWAT_FILENAME="$PWD/pwat/pwat_$FILENAME"
    TMP_FILENAME="$PWD/tmp/tmp_$FILENAME"
    MERGED_CSV="$PWD/merged/merged_$FILENAME"
    FILTER_CSV="$PWD/filter/filter_$FILENAME"

	# TEMPERATURE
    wgrib2 -match "TMP:surface:" "gribs/$FILENAME" -csv $TMP_FILENAME
    # PRECIP
    wgrib2 -match "PWAT" "gribs/$FILENAME" -csv $PWAT_FILENAME
    # merge two csvs
    awk 'NR==FNR{a[NR]=$0;next}{print a[FNR],$0}' OFS=","  $TMP_FILENAME $PWAT_FILENAME > $MERGED_CSV 
    # filter csv
	awk -F, '{print $1,$2,$5,$6,$7,$14}' OFS="," $MERGED_CSV > $FILTER_CSV

    # update csv
    sudo -u postgres -H -- psql -d weather -c "copy data (
        analysis_utc,
		start_forecast_utc,
		longitude,
		latitude,
		tmp,
        pwat
		) from '$FILTER_CSV' with (format csv);"
    # remove old forecast
    rm $PWAT_FILENAME $TMP_FILENAME $MERGED_CSV $FILTER_CSV 
}

# define function for xarg call
export -f marshalwx

# determine utc hour
if [ $H -le 2 ]; then H=18; YMD=$(date -u +"%Y%m%d" -d "1 days ago"); 
elif [ $H -ge 4 -a $H -le 8 ]; then H=00
elif [ $H -gt 8 -a $H -le 14 ]; then H=06
elif [ $H -gt 14 -a $H -le 22 ]; then H=12
elif [ $H -gt 22 ]; then H=18
fi

# generate url list
URL_LIST=$(for x in ${HOURS[@]}; do printf "$BASE_URL\n" $YMD $H $H $x; done)

# download the grib files and marshal into postgres
echo $URL_LIST | xargs -n1 -P8 bash -c 'marshalwx "$@"' _ 

# remove all da shit dirs
rm -rf filter gribs merged pwat tmp

sudo -u postgres -H -- psql -d weather -c "update data
    set long_lat = ST_GeographyFromText('SRID=4326;POINT(' || longitude || ' ' || latitude || ')');"

