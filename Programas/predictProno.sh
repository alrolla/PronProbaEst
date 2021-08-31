#!/bin/bash
#==============================
# IMPORTANTE
# El directorio donde corra este script debe estar limpio ( ningun archivo excepto el script!)
#===============================

if [ "$#" -ne 1 ]; then
    echo ""
    echo "*** NUMERO INCORRECTO DE PARAMETROS ....***"
    echo ""
    echo "Parametros para input_modelos.sh: "
    echo " Año Referencia: DDDD ( cuatro digitos) ;ej. 2015"
    exit
fi
if [ "${#1}" -ne 4 ]; then
      echo "error en AÑO (debe ser de 4 digitos)..."
      exit
fi

aa=$1
aa0=$(($1-1))


rm -fr NNRMes

mkdir -p NNRMes

# Procesando altura geopotencial año anterior
wget ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis.dailyavgs/pressure/hgt.${aa0}.nc -O hgt.${aa0}.nc
cdo monmean hgt.${aa0}.nc hgt.${aa0}.mon.1.nc

# Procesando altura geopotencial 
wget ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis.dailyavgs/pressure/hgt.${aa}.nc -O hgt.${aa}.nc
cdo monmean hgt.${aa}.nc hgt.${aa}.mon.2.nc

ncrcat  hgt.${aa0}.mon.1.nc hgt.${aa}.mon.2.nc hgt.nc

cdo sellevel,1000 hgt.nc NNRMes/hgt1000.nc
cdo sellevel,500 hgt.nc  NNRMes/hgt500.nc
cdo sellevel,200 hgt.nc  NNRMes/hgt200.nc


rm hgt.${aa0}.mon.1.nc
rm hgt.${aa0}.nc
rm hgt.${aa}.mon.2.nc
rm hgt.${aa}.nc

rm hgt.nc


# Procesando Agua Precipitable
wget  wget ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis.dailyavgs/surface/pr_wtr.eatm.${aa0}.nc -O pr_wtr.eatm.${aa0}.nc
cdo monmean pr_wtr.eatm.${aa0}.nc pr_wtr.eatm.${aa0}.mon.1.nc

# Procesando Agua Precipitable
wget  wget ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis.dailyavgs/surface/pr_wtr.eatm.${aa}.nc -O pr_wtr.eatm.${aa}.nc
cdo monmean pr_wtr.eatm.${aa}.nc pr_wtr.eatm.${aa}.mon.2.nc

ncrcat  pr_wtr.eatm.${aa0}.mon.1.nc  pr_wtr.eatm.${aa}.mon.2.nc NNRMes/tcw.nc

rm pr_wtr.eatm.${aa}.nc
rm pr_wtr.eatm.${aa0}.nc
rm pr_wtr.eatm.${aa0}.mon.1.nc
rm pr_wtr.eatm.${aa}.mon.2.nc

# 
# Procesando U-WND
# 
wget ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis.dailyavgs/pressure/uwnd.${aa0}.nc -O uwnd.${aa0}.nc
cdo monmean uwnd.${aa0}.nc uwnd.${aa0}.mon.1.nc

wget ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis.dailyavgs/pressure/uwnd.${aa}.nc -O uwnd.${aa}.nc
cdo monmean uwnd.${aa}.nc uwnd.${aa}.mon.2.nc

ncrcat  uwnd.${aa0}.mon.1.nc  uwnd.${aa}.mon.2.nc uwnd.nc

cdo sellevel,850 uwnd.nc NNRMes/u850.nc

rm uwnd.${aa0}.mon.1.nc
rm uwnd.${aa}.mon.2.nc
rm uwnd.${aa0}.nc
rm uwnd.${aa}.nc

rm uwnd.nc

# 
# Procesando V-WND
# 
wget ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis.dailyavgs/pressure/vwnd.${aa0}.nc  -O vwnd.${aa0}.nc
cdo monmean vwnd.${aa0}.nc vwnd.${aa0}.mon.1.nc

wget ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis.dailyavgs/pressure/vwnd.${aa}.nc  -O vwnd.${aa}.nc
cdo monmean vwnd.${aa}.nc vwnd.${aa}.mon.2.nc

ncrcat  vwnd.${aa0}.mon.1.nc  vwnd.${aa}.mon.2.nc vwnd.nc

cdo sellevel,850 vwnd.nc NNRMes/v850.nc

rm vwnd.${aa}.mon.2.nc
rm vwnd.${aa}.nc
rm vwnd.${aa0}.mon.1.nc
rm vwnd.${aa0}.nc
rm vwnd.nc

# 
# Procesando SST
# 
wget  ftp://ftp2.psl.noaa.gov/Datasets/ncep.reanalysis.dailyavgs/surface_gauss/skt.sfc.gauss.${aa0}.nc -O skt.sfc.gauss.${aa0}.nc
  
cdo remapbil,AUX1/GridDes skt.sfc.gauss.${aa0}.nc  sst${aa0}_r.nc
  
if [ $aa -gt 2014 ]
	then
	    #cdo remapbil,AUX1/GridDes skt.sfc.gauss.${a}.nc  sst${a}_r.nc
		ncwa -a nbnds sst${aa0}_r.nc sst${aa0}_r1.nc
		ncks -x -v time_bnds sst${aa0}_r1.nc sst${aa0}_r2.nc
		cdo div sst${aa0}_r2.nc AUX1/land2.nc sst${aa0}_m.nc
		cdo -addc,-273.15 sst${aa0}_m.nc sst${aa0}_c.nc
	else
	    cdo div sst${aa0}_r.nc AUX1/land2.nc sst${aa0}_m.nc
	    cdo -addc,-273.15 sst${aa0}_m.nc sst${aa0}_c.nc
fi
  
cdo monmean sst${aa0}_c.nc sst1.nc

rm sst${aa0}_m.nc
rm sst${aa0}_c.nc
rm sst${aa0}_r1.nc
rm sst${aa0}_r2.nc
rm sst${aa0}_r.nc
rm skt.sfc.gauss.${aa0}.nc


wget  ftp://ftp2.psl.noaa.gov/Datasets/ncep.reanalysis.dailyavgs/surface_gauss/skt.sfc.gauss.${aa}.nc -O skt.sfc.gauss.${aa}.nc
  
cdo remapbil,AUX1/GridDes skt.sfc.gauss.${aa}.nc  sst${aa}_r.nc
  
if [ $aa -gt 2014 ]
	then
	    #cdo remapbil,AUX1/GridDes skt.sfc.gauss.${a}.nc  sst${a}_r.nc
		ncwa -a nbnds sst${aa}_r.nc sst${aa}_r1.nc
		ncks -x -v time_bnds sst${aa}_r1.nc sst${aa}_r2.nc
		cdo div sst${aa}_r2.nc AUX1/land2.nc sst${aa}_m.nc
		cdo -addc,-273.15 sst${aa}_m.nc sst${aa}_c.nc
	else
	    cdo div sst${aa}_r.nc AUX1/land2.nc sst${aa}_m.nc
	    cdo -addc,-273.15 sst${aa}_m.nc sst${aa}_c.nc
fi
  
cdo monmean sst${aa}_c.nc sst2.nc


rm sst${aa}_m.nc
rm sst${aa}_c.nc
rm sst${aa}_r1.nc
rm sst${aa}_r2.nc
rm sst${aa}_r.nc
rm skt.sfc.gauss.${aa}.nc


ncrcat  sst1.nc  sst2.nc NNRMes/sst.nc

rm sst1.nc
rm sst2.nc



