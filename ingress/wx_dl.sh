#!/bin/bash
# 
# fast grib get_inv.pl INV_URL | grep FIELDS | get_grib.pl GRIB_URL OUTPUT
# 
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
mkdir -p "$PWD/apcp"
mkdir -p "$PWD/merged"
mkdir -p "$PWD/filter"
mkdir -p "$PWD/gribs"
# base url for download
BASE_URL='http://www.ftp.ncep.noaa.gov/data/nccf/com/gfs/prod/gfs.%s%s/gfs.t%sz.pgrb2.0p25.f%s'
# dates and hour 
YMD=$(date -u +"%Y%m%d")
H=$(date -u +"%H")
# hours array
HOURS=($(seq -f '%03g' -s ' ' 0 3 240)$(seq -f '%03g' -s ' ' 252 12 384))

# arg1 - url for an individual hour
# extracts products from grib files and marshals them into 
marshalwx() {
    FILENAME="$(cut -d'/' -f10 <<<"$1")"
    $PWD/get_inv.pl $1.idx | egrep "(TMP:surface:|:APCP:surface)" | $PWD/get_grib.pl $1 "gribs/$FILENAME"

    APCP_FILENAME="$PWD/apcp/apcp_$FILENAME"
    TMP_FILENAME="$PWD/tmp/tmp_$FILENAME"
    MERGED_CSV="$PWD/merged/merged_$FILENAME"
    FILTER_CSV="$PWD/filter/filter_$FILENAME"

	# TEMPERATURE
    wgrib2 -match "TMP:surface:" "gribs/$FILENAME" -csv $TMP_FILENAME
    # PRECIP
    wgrib2 -match "APCP" "gribs/$FILENAME" -csv $APCP_FILENAME
    # merge two csvs
    awk 'NR==FNR{a[NR]=$0;next}{print a[FNR],$0}' OFS=","  $TMP_FILENAME $APCP_FILENAME > $MERGED_CSV 
    # filter csv
    awk -F, '{print $1,$2,$5,$6,$7,$14}' OFS="," $MERGED_CSV > $FILTER_CSV
}

# define function for xarg call
export -f marshalwx

# determine utc hour
if [ $H -le 4 ]; then H=18; YMD=$(date -u +"%Y%m%d" -d "1 days ago"); 
elif [ $H -ge 4 -a $H -le 8 ]; then H=00
elif [ $H -gt 8 -a $H -le 16 ]; then H=06
elif [ $H -gt 16 -a $H -le 22 ]; then H=12
elif [ $H -gt 22 ]; then H=18
fi

#====[generate url list & download]======
URL_LIST=$(for x in ${HOURS[@]}; do printf "$BASE_URL\n" $YMD $H $H $x; done)
echo $URL_LIST | xargs -n1 -P8 bash -c 'marshalwx "$@"' _ 

#====[ make csv. each row is a cell ]==== 
ROLLING_CSV=$PWD/rolling.csv
awk -F "\"*,\"*" '{print $5, $6}' OFS="," merged/merged_gfs.t12z.pgrb2.0p25.f003 > $ROLLING_CSV
vals=$PWD/vals


#=============[ pivot ]==================
for file in $PWD/filter/*
do
	awk -F "\"*,\"*" '{printf "{tmp:%s,apcp:%s}\n", $5, $6 }' $file > $vals 	
	paste -d " " $ROLLING_CSV <(awk '{print $NF}' $vals) > $ROLLING_CSV'.tmp'
	mv $ROLLING_CSV'.tmp' $ROLLING_CSV
done

