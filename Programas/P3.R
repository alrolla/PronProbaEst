library(ncdf4)
library(fields)
library(sp)
library(maptools)
library(openxlsx)
library(raster)

#Modificar aca para cambiar el directorio de trabajo
#setwd("C:/Users/Marcela/Documents/D/comahue/pp") #cambiar aca!!!
setwd("~/Dropbox/agroIDEAL/comahue/pp")

source("./FunContour.R")

mesn = c("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Set","Oct","Nov","Dec","A_year","DEF","MAM","JJA","SON")
meses = c("FebMar","MarApr","AprMay","MayJun","JunJul","JulAug","AugSet","SetOct","OctNov","NovDec","DecJan","JanFeb")
imeses = 1
variables = c("sst","tcw","hgt500","hgt1000","hgt200","u850","v850")
varnom = c("skt","pr_wtr","hgt","hgt","hgt","uwnd","vwnd")
umbrales=list(c(-0.35,0.35),c(-0.35,0.35),c(-0.35,0.35),c(-0.35,0.35),c(-0.35,0.35),c(-0.35,0.35),c(-0.35,0.35))

#meses a calcular los predictores con un mes de lag
meses=c("01","02","03","04","05","06","07","08","09","10","11","12")
#
meses=c("01","02") #ALFREDO 2021

for( mes.ref in meses){
  
    #Lectura de series medias de los CLUSTERS
    datos.obs=read.xlsx(paste0("clusters/series.medias.pre.",mes.ref,".xlsx"),sheet="Clusters")
    cluster.name=colnames(datos.obs[3:ncol(datos.obs)])
    
    #parametros de referencia
    miny <- 1981 # aca dijimos de hacer 1981 2015 y luego verificar
    #creo que minx tendria que ser 1979 ! porque los reanalisis arrancan de 1979!!!!
    # Estariamos correlacionando desfasado!!!
    #Para hacer, poner 1981 , habria que sumar al indice del reanalisis el miny!!! para justar y correlacionar correctamente.

    maxy <- 2015
    
    mes.referencia=as.numeric(mes.ref)-1 #mes de referencia - 1
    if(mes.referencia == 0.) { 
      mes.referencia=0 # Cambio Enero ALF 2021-06-01
      #Para comparar Obs de Enero y Reanalisis de Diciembre le saco el primer año a las observaciones
      datos.obs=datos.obs[,-1]
      #Asi queda Renalisis(Dic 1979) vs Obs(Enero 1980) 
      
    }
    
    cant.de.anios=maxy-miny+1
    
    # Esto permite variar el miny!! Si los reanalisis arrancan de 1979!!#ALFREDO 2021
    delta=(miny-1979)*12 #ALFREDO 2021
    deltaa=(miny-1979)
    #dimension de los reanalisis
    dimx=144
    dimy=73
    
    for(nclus in 1:length(cluster.name)){
    #for(nclus in 1:1){
              dir.create(path = paste0("./Predictores.",mes.ref,"/Cluster",nclus), recursive = TRUE,showWarnings = FALSE)
              dir.create(path = paste0("./Predictores.Regiones.",mes.ref,"/Cluster",nclus),recursive = TRUE, showWarnings = FALSE)
              sw=0
              for( ivariable in 1:length(variables)){
                
                print("VARIABLE")
                print(variables[ivariable])
                #Esto asume que las observaciones arrancan en miny!!!
                datos=datos.obs[cluster.name[nclus]][1:cant.de.anios,]
                
                #abro el netcdf y leo las coordenadas y la variable
                fh = nc_open(paste0("../nnr/",variables[ivariable],".nc"))
                lon = ncvar_get(fh,"lon")-180
                lat = rev(ncvar_get(fh,"lat"))
                
                time = ncvar_get(fh,"time")
                var = ncvar_get(fh,varnom[ivariable])
                
               
                fh2 <- nc_open("../nnr/lsm.nc")
                lsm <- ncvar_get(fh2,"msk")
                lsmp <- lsm[c((round(dimx/2,0)/2+1):dimx, 1:(round(dimy/2,0))),ncol(lsm):1]
                #Le pongo a Panama a la mascara , porque NO LO TIENE (el pacifico y el atlantico estan conectados, ahi!!)
                lsmp[76,41]=1
                lsmp[77,40]=1
                image.plot(lsmp)
                 
                  #redimensiono la variable a 3d , por si quiero usar  subareas
                  #Esta puesto al Area completa ( o sea de mas!)
                  dim(var) = c(dimx,dimy,length(time))
    
                  print("PROCESO MES")
                  print(mesn[mes.referencia])
                  #calculo la correlacion entre el acumObs y varp
                  # el resultado quedara en corvar               
                  corvar = array(0,dim=c(dimx,dimy))
                  #reacomodo la matriz var con las inversiones de latitudes y el desplazamiento de longitudes en varp               
                  varp = var[c((round(dimx/2,0)/2+1):dimx, 1:(round(dimy/2,0))),ncol(var):1,]
                  #image.plot(varp[,,1])  
                    # varmed = array(0,dim=c(length(seq(mes.referencia,length(datos.obs$CLUSTER1)*12,12))))
                    varmed = array(0,dim=c(length(seq(mes.referencia+delta,(length(datos)+deltaa)*12-1,12)))) #ALFREDO 2021
                    
                  print("INICIO --- CALCULO de MATRIZ de CORRELACION")  
                  for(i in 1:dimx){
                     for(j in 1:dimy){
                       varmed = varp[i,j,seq(mes.referencia+delta,(length(datos)+deltaa)*12-1,12)] #ALFREDO 2021
                       corvar[i,j] = cor(varmed,as.numeric(datos))
                       
                     }
                  }
                  
                  corvar.2=corvar
                  print("FIN --- CALCULO de MATRIZ de CORRELACION")  
                  ## Buscar puntos dentro de convexos de isolineas de correlacion
                 
                  print("INICIO --- CALCULO DE LINEAS DE CONTORNO")  
                  #definir umbral de correlacion c(-0.30,.30) por ejemplo
                  uc=umbrales[[ivariable]]  #c(-0.42,0.42)
                  c.lon=c(1:dimx)
                  c.lat= c(1:dimy) 
                  l.contours <- contourLines(c.lon,c.lat,corvar, level=c(uc))
                  if (length(l.contours) == 0) {
                    stop("NO HAY CONTORNOS!!")
              
                  }
                  print("FIN --- CALCULO DE LINEAS DE CONTORNO")  
              
                  #funcion para generar colores transparentes para la mascara de tierra-agua
                  add.alpha <- function(COLORS, ALPHA){
                    if(missing(ALPHA)) stop("provide a value for alpha between 0 and 1")
                    RGB <- col2rgb(COLORS, alpha=TRUE)
                    RGB[4,] <- round(RGB[4,]*ALPHA)
                    NEW.COLORS <- rgb(RGB[1,], RGB[2,], RGB[3,], RGB[4,], maxColorValue = 255)
                    return(NEW.COLORS)
                  }    
                  
                  
                  pdf(file=paste0("Predictores.",mes.ref,"/Cluster",nclus,"/Predictor_",mes.ref,"-",variables[ivariable],"_C",nclus,".pdf"),width = 12,height=6)
                  print("PLOTEO MAPA DE CORRELACIONES")  
                  #Ploteo el mapa de correlaciones
                  colpal<-colorRampPalette(c("darkblue","blue","cyan","lightgreen","yellow","orange","red","darkred"))
                  par(mar=c(5,4.5,4,7))
                  image(c.lon,c.lat,corvar, col=(colpal(128)),zlim=c(-0.8,0.8),ylab="Latitud",xlab="Longitud",axes=F)
                  axis(1, at=seq(0, dimx,4), labels=c(seq(90,180,10),seq(-170,0,10),seq(10,90,10)), cex.axis=0.7,las=2)
                  axis(2, at=seq(1, dimy, 4), labels=seq(-90, 90, 10), cex.axis=0.7,las=1)
                  image.plot(c.lon,c.lat,corvar,col=(colpal(128)),zlim=c(-0.8,0.8), ylab="Latitud",xlab="Longitud",legend.only=T)
                  title(paste0("Predictor: ",variables[ivariable]," Mes Ref:",mes.ref," Cluster: ",nclus))
                  #image.plot(c.lon,c.lat,corvar, ylab="Latitud",xlab="Longitud")
                  #Ploteo la mascara de tierra y agua con un nivel de transparencia de 0.2 ( 1=sin transparencia)
                  COLORS <- add.alpha(c("#000000FF","#ffffff00"), 0.4)
                  image(c.lon,c.lat,lsmp, col=COLORS, add=TRUE)
                  
                  print("PLOTEO LOS CONTORNOS SELECCIONADOS")  
                  #Ploteo los contornos (positivos y negativos de acuerdo a los contornos seleccionados en "uc")
                  icontour=0
                  for(narea in 1:length(l.contours)){
                    if(length(l.contours[[narea]]$x) > 20) {
                      
                      if(l.contours[[narea]]$level > 0 ){
                        lines(l.contours[[narea]],lwd=1,col="black")
                      } else {
                        lines(l.contours[[narea]],lwd=1,col="black")
                      } 
                      icontour=icontour+1
                      print(paste0("contorno",icontour,"  i:",narea))
                    text(mean(l.contours[[narea]]$x),mean(l.contours[[narea]]$y),as.character(narea),col="yellow",cex=0.8,lwd=2)
                    } 
                  }
                  dev.off()
                  print("GENERANDO LOS EXCEL CON LAS SERIES MEDIAS EN CADA REGION")  
                  #generar los puntos para extraer las regiones interiores de los contornos
                  puntos=expand.grid(x = c.lon, y = c.lat)
                  
                  #Crear el workbook de predictores para el archivo excel
                  #wb <- createWorkbook()
                  
                  #definir parametros de tiempo para el predictor
                  tiempos=seq(mes.referencia+delta,(length(datos)+deltaa)*12-1,12) #genera los tiempos a extraer #ALFREDO 2021
                  varp1=varp #copiar la matriz de reanalisis para redimensionarla
                  dim(varp1)=c(dimx*dimy,length(time)) #redimensionar la matriz de 3d a 2d
                  icontour2=0
                  for(narea in 1:length(l.contours)){
                    if(length(l.contours[[narea]]$x) > 20) {
                     #Marca con 1 los puntos de la matriz que pertenecen a la region 
                     mat.puntos=point.in.polygon(puntos$x,puntos$y, l.contours[[narea]]$x, l.contours[[narea]]$y)
                     #dim(mat.puntos)=c(720,361) #redimensionar el vector devuelto en una matriz
                     #Selecciona/recorta solo los puntos interiores del contorno ( son lo marcados con 1)
                     ptos.inn=which(mat.puntos == 1)
                     long=as.numeric(lon[puntos[ptos.inn,]$x])#Longitudes de los puntos a promediar areal
                     lati=as.numeric(lat[puntos[ptos.inn,]$y]) #Latitudes de los puntos a promediar areal
                     predictor=c()
                     for(t in 1:length(tiempos) ){
                       predictor[t]=mean(varp1[ptos.inn,tiempos[t]],na.rm=TRUE)
                     }
                     #points(puntos[ptos.inn,]$x,puntos[ptos.inn,]$y,cex=0.01,col="red")
                     #predictor=data.frame(long=as.numeric(lon[puntos[ptos.inn,]$x]),lati=as.numeric(lat[puntos[ptos.inn,]$y]),val=rep(l.contours[[narea]]$level,length(ptos.inn)))
                     icontour2=icontour2+1
                     print(paste0("contorno",icontour2,"  i:",narea))
                     if(sw == 0){
                       x.col=data.frame(predictor)
                       colnames(x.col)=paste0(variables[ivariable],"_C",nclus,"_",narea)
                       predictor.xls=x.col
                       sw=1
                     }else{
                       x.col=data.frame(predictor)
                       colnames(x.col)=paste0(variables[ivariable],"_C",nclus,"_",narea)
                       predictor.xls=cbind(predictor.xls,x.col)
                     }
                     # addWorksheet(wb, paste0(variables[ivariable],"_",narea))
                     # writeData(wb, sheet = paste0(variables[ivariable],"_",narea),x = predictor )
                     
                     #Guardo la region del predictor =========================================================================
                     save(ptos.inn,file=paste0("Predictores.Regiones.",mes.ref,"/Cluster",nclus,"/Predictor_",mes.ref,"-",variables[ivariable],"_C",nclus,"_",narea,".Rdata"))
                     print(paste0("Predictores.Regiones.",mes.ref,"/Cluster",nclus,"/Predictor_",mes.ref,"-",variables[ivariable],"_C",nclus,"_",narea,".Rdata"))
                     print(ptos.inn)
                     #Plotea los puntos interiores de la region en proceso
                     #points(puntos[ptos.inn,]$x,puntos[ptos.inn,]$y, pch = 19,cex=0.01,col="white")
                     
                    }
                  } 
                  
                  #Escribir el workbook
                  #saveWorkbook(wb, paste0("Predictores/Cluster",nclus,"/Predictor_",variables[ivariable],"_C",nclus,".xlsx"), overwrite = TRUE)
    
              } #fin todas las variables
              write.xlsx(predictor.xls,file=paste0(paste0("Predictores.",mes.ref,"/Cluster",nclus,"/Predictores_",mes.ref,"_C",nclus,".xlsx")))
    }
} # fin meses

