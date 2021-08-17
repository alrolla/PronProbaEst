
#Para correr este programa hay que tener los reanalisis del mes en curso calculados 
#en el directorio NNRmes

library(openxlsx)
library(ncdf4)
library(fields)
library(sp)
library(maptools)
library(openxlsx)
library(raster)


#Modificar aca para cambiar el directorio de trabajo
#setwd("C:/Users/Marcela/Documents/D/comahue/pp")
setwd("~/Dropbox/agroIDEAL/comahue/pp/")
mesn = c("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Set","Oct","Nov","Dec","A_year","DEF","MAM","JJA","SON")
meses = c("FebMar","MarApr","AprMay","MayJun","JunJul","JulAug","AugSet","SetOct","OctNov","NovDec","DecJan","JanFeb")
imeses = 1
variables = c("sst","tcw","hgt500","hgt1000","hgt200","u850","v850")
varnom = c("skt","pr_wtr","hgt","hgt","hgt","uwnd","vwnd")
umbrales=list(c(-0.35,0.35),c(-0.35,0.35),c(-0.35,0.35),c(-0.35,0.35),c(-0.35,0.35),c(-0.35,0.35),c(-0.35,0.35))

#CAMBIAR ACA LOS UMBRALES
umbrales=c(0.5,0.5,0.5,0.5)

#parametros de referencia que los dejo para control que no estamos agregando de mas o repitiendo años... en el LASSO Corregido
miny <- 1981
maxy <- 2020

cant.de.anios=maxy-miny+1

#meses a calcular los predictores con un mes de lag
#Esto controla que meses se usaran

#mes de pronostico
meses=c("07")

#Año que vamos a generar predictores
pred.anio=2021

miny.pred <- pred.anio
maxy.pred <- pred.anio

#dimension de los reanalisis
dimx=144
dimy=73

for( mes.ref in meses){
  
  #Leo las series medias de los clusters CREO QUE ESTO NO SIRVE PARA NADA, SOLO para saber cuantos CLUSTERS HAY
  # 
  cluster.obs=read.xlsx(paste0("clusters/series.medias.pre.",mes.ref,".xlsx"),sheet="Clusters")
  cluster.name=colnames(cluster.obs[3:ncol(cluster.obs)])
  
  mes.referencia=as.numeric(mes.ref)-1 #mes de referencia - 1
  if(mes.referencia == 0.) { 
     mes.referencia=0
  }      
  for(nclus in 1:length(cluster.name)){
  #for(nclus in 1:1){
    
    #Abro el workbook para grabar los datos
    wb <- createWorkbook()
    addWorksheet(wb, sheetName = "PronoProba")
    #Creo el directorio de trabajo para cada cluster
    dir.create(path = paste0("./Pronostico/",pred.anio,"_",mes.ref),recursive=TRUE,showWarnings = FALSE)
    
    #Leo los predictores
    predictores=read.xlsx( paste0("Predictores.",mes.ref,"/Cluster",nclus,"/Predictores_",mes.ref,"_C",nclus,"_LASSO_Corregido.xlsx"))
    predictor.name=colnames(predictores[1:ncol(predictores)])
    
    #Leo las regiones de los predictores
    #Calculo los predictores
    sw=0
    for(np in 1:length(predictor.name)){
      pre_nom=predictor.name[np]
      #leo la variable ptos.inn de la region del predictor en cuestion
      load(file=paste0("Predictores.Regiones.",mes.ref,"/Cluster",nclus,"/Predictor_",mes.ref,"-",pre_nom,".Rdata"))
      #leo la matriz del reanalisis para calcular el predictor
      #abro el netcdf y leo las coordenadas y la variable
      nom_var=as.character(strsplit(pre_nom,"_")[[1]][1])
      fh =  nc_open(paste0("../NNRMes/",nom_var,".nc"))
      lon = ncvar_get(fh,"lon")-180
      lat = rev(ncvar_get(fh,"lat"))
      time = ncvar_get(fh,"time")
      
      #recupero el nombre de la variable del netcdf
      var = ncvar_get(fh,varnom[which(variables == nom_var)])
      #reacomodo la matriz var 
      varp = var[c((round(dimx/2,0)/2+1):dimx, 1:(round(dimy/2,0))),ncol(var):1,]
      #image.plot(varp[,,1])  
      
      c.lon=c(1:dimx)
      c.lat= c(1:dimy) 
      
      print(paste("GENERANDO LOS PREDICTORES NUEVOS EN CADA REGION ",nclus," MES ",mes.ref," VARIABLE ",pre_nom))  
      
      puntos=expand.grid(x = c.lon, y = c.lat)    #generar los puntos para extraer las regiones interiores de los contornos  
      varp1=varp #copiar la matriz de reanalisis para redimensionarla
      dim(varp1)=c(dimx*dimy,length(time)) #redimensionar la matriz de 3d a 2d
      
      #tiempos=seq((miny.pred-1979)*12+mes.referencia,(maxy.pred-1979)*12+mes.referencia,12) #genera los tiempos a extraer
      tiempos=(12+mes.referencia)
      #tiempos= as.numeric(meses)#genera los tiempos a extraer
      
      long=as.numeric(lon[puntos[ptos.inn,]$x])#Longitudes de los puntos a promediar areal
      lati=as.numeric(lat[puntos[ptos.inn,]$y]) #Latitudes de los puntos a promediar areal
      predictor=c()
      for(t in 1:length(tiempos) ){
        predictor[t]=mean(varp1[ptos.inn,tiempos[t]],na.rm=TRUE)
      }  
      
      if(sw == 0){
        x.col=data.frame(predictor)
        colnames(x.col)=pre_nom
        predictor.nuevo=x.col
        sw=1
      }else{
        x.col=data.frame(predictor)
        colnames(x.col)=pre_nom
        predictor.nuevo=cbind(predictor.nuevo,x.col)
      }      
    } # fin calculo predictores nuevos
    #Agrego el predcitor nuevo
    predictor.agregado=rbind(predictores[1:cant.de.anios,],predictor.nuevo)
    write.xlsx( predictor.agregado,file=paste0("Predictores.",mes.ref,"/Cluster",nclus,"/Predictores_",mes.ref,"_C",nclus,"_LASSO_Corregidoxx.xlsx"))

  }  #Fin clusters
}  # Fin meses

