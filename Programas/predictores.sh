#!/bin/bash
# Este script descarga los reanalisis , funciona en LINUX
# =====================================================================
# Es necesario tener instalado CDO y NCO para los recortes y calculos
# =====================================================================

rm -fr NNR

mkdir NNR

#descargo el geopotencial en multiniveles

wget ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis.derived/pressure/hgt.mon.mean.nc -O hgt.mon.mean.nc

#Recorto los niveles que interesan

cdo sellevel,1000 hgt.mon.mean.nc hgt1000_r.nc
ncks -d time,372, hgt1000_r.nc hgt1000.nc
mv hgt1000.nc NNR

rm hgt1000_r.nc

cdo sellevel,500 hgt.mon.mean.nc hgt500_r.nc
ncks -d time,372, hgt500_r.nc hgt500.nc
mv hgt500.nc NNR

rm hgt500_r.nc

cdo sellevel,200 hgt.mon.mean.nc hgt200_r.nc
ncks -d time,372, hgt200_r.nc hgt200.nc
mv hgt200.nc NNR

rm hgt200_r.nc
rm hgt.mon.mean.nc
#descargo el uwnd en multiniveles

wget ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis.derived/pressure/uwnd.mon.mean.nc -O uwnd.mon.mean.nc

cdo sellevel,850 uwnd.mon.mean.nc u850_r.nc
ncks -d time,372, u850_r.nc u850.nc
mv u850.nc NNR
rm u850_r.nc
rm uwnd.mon.mean.nc

#descargo el vwnd en multiniveles

wget ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis.derived/pressure/vwnd.mon.mean.nc -O vwnd.mon.mean.nc

cdo sellevel,850 vwnd.mon.mean.nc v850_r.nc
ncks -d time,372, v850_r.nc v850.nc
mv v850.nc NNR
rm v850_r.nc
rm vwnd.mon.mean.nc

#descargo el agua precipitable

wget ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis.derived/surface/pr_wtr.mon.mean.nc -O pr_wtr.mon.mean.nc
ncks -d time,372, pr_wtr.mon.mean.nc tcw.nc
mv tcw.nc NNR
rm pr_wtr.mon.mean.nc

# Proceso SST
cd SST

for (( a=1979; a < 2022 ; a++)); do

	wget  ftp://ftp2.psl.noaa.gov/Datasets/ncep.reanalysis.dailyavgs/surface_gauss/skt.sfc.gauss.${a}.nc -O skt.sfc.gauss.${a}.nc
	
	cdo remapbil,AUX1/GridDes skt.sfc.gauss.${a}.nc  sst${a}_r.nc
	
	ncwa -a nbnds sst${a}_r.nc sst${a}_r1.nc
	ncks -x -v time_bnds sst${a}_r1.nc sst${a}_r2.nc
	cdo div sst${a}_r2.nc AUX1/land2.nc sst${a}_m.nc
	cdo -addc,-273.15 sst${a}_m.nc sst${a}_c.nc  
	cdo monmean sst${a}_c.nc sst${a}_c_m.nc
	#Borro temporales	
	rm sst${a}_m.nc
	rm sst${a}_r*.nc
	rm sst${a}_r*.nc
	rm sst${a}_c.nc
	rm skt.sfc.gauss.${a}.nc


done

#concateno todos los años
ncrcat  sst????_c_m.nc  sst.nc

mv sst.nc ../NNR/

#borro los temporales y nos quedamos con el sst.nc
rm sst????_c_m.nc



