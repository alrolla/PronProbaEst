#pronostica un a?o con todos los modelos con r2 encima de un umbral y para un periodo de entrenamiento
#hace prono probabilistico
library(sp)
library(maptools)
library(dplyr)
library(yardstick)
library(openxlsx)
library(raster)
library(ncdf4)
library(fields)
library(fpp)
library(ggplot2)
library(reshape2)
library(ggrepel)
library(mgcv)
library(e1071)
#modelos redes el resto de los meses
#Sys.setenv(RETICULATE_PYTHON= "C:\\Users\\Marcela\\anaconda3\\python.exe")
Sys.setenv(RETICULATE_PYTHON= "/usr/local/opt/python@3.7/bin/python3")

library(keras)
library(tensorflow)

#Modificar aca para cambiar el directorio de trabajo
#setwd("C:/Users/Marcela/Documents/D/comahue/pp")
setwd("~/Dropbox/agroIDEAL/comahue/pp/")


mesn = c("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Set","Oct","Nov","Dec","A_year","DEF","MAM","JJA","SON")
meses = c("FebMar","MarApr","AprMay","MayJun","JunJul","JulAug","AugSet","SetOct","OctNov","NovDec","DecJan","JanFeb")
imeses = 1
variables = c("sst","tcw","hgt500","hgt1000","hgt200","u850","v850")
varnom = c("skt","pr_wtr","hgt","hgt","hgt","uwnd","vwnd")
umbrales=list(c(-0.35,0.35),c(-0.35,0.35),c(-0.35,0.35),c(-0.35,0.35),c(-0.35,0.35),c(-0.35,0.35),c(-0.35,0.35))

#CAMBIAR ACA LOS UMBRALES X CLUSTER
umbrales=c(0.5,0.5,0.5,0.5)

#parametros de referencia
miny <- 1981 # aca dijimos de hacer 1981 2015 y luego verificar
maxy <- 2020

cant.de.anios=maxy-miny+1

#meses a calcular los predictores con un mes de lag
#Esto controla que meses se usaran
meses=c("01","02","03","04","05","06","07","08","09","10","11","12")
meses=c("07")

#Año de Pronostico
pred.anio=2021

miny.pred <- pred.anio
maxy.pred <- pred.anio

#dimension de los reanalisis
dimx=144
dimy=73

for( mes.ref in meses){
  #Leo las series medias de los clusters
  
  cluster.obs=read.xlsx(paste0("clusters/series.medias.pre.",mes.ref,".xlsx"),sheet="Clusters")
  cluster.name=colnames(cluster.obs[3:ncol(cluster.obs)])
  
  mes.referencia=as.numeric(mes.ref)-1 #mes de referencia - 1
  
  for(nclus in 1:length(cluster.name)){

    #Abro el workbook para grabar los datos
    wb <- createWorkbook()
    addWorksheet(wb, sheetName = "PronoProba")
    #Creo el directorio de trabajo para cada cluster
    dir.create(path = paste0("./Pronostico/"),recursive=TRUE,showWarnings = FALSE)

    #Leo los predictores
    predictores=read.xlsx( paste0("Predictores.",mes.ref,"/Cluster",nclus,"/Predictores_",mes.ref,"_C",nclus,"_LASSO_Corregido.xlsx"))[1:cant.de.anios,]
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
            
            #MIRAR ESTO
            #tiempos=seq((miny.pred-1979)*12+as.numeric(mes.ref),(maxy.pred-1979)*12+as.numeric(mes.ref),12) #genera los tiempos a extraer
            tiempos=(12+mes.referencia)
            
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
      
    predictor.nuevo=cbind(year=c(miny.pred:maxy.pred),predictor.nuevo)

    
    
          y.pred=c()
          y.tipo.modelo=c()
          y.modelo=c()
          y.umbral.modelo=c()
          y.i=1
          umbral=umbrales[nclus]
          
          # PROCESO los modelos de RLM
          
              modelos=read.xlsx(xlsxFile = paste0("Modelos.",mes.ref,"_",miny,"_",maxy,"/Cluster",nclus,"/Modelos_",mes.ref,"_C",nclus,"_LASSO_RLM.xlsx"))
              #Selecciono el mejor modelo, que puse en la primera fila del archivo de modelos
              #bFormula=modelos[1,1]
              bFormulas=modelos[which(modelos$AdjR2 > umbral),1]
              RLM.umbral=modelos[which(modelos$AdjR2 > umbral),6]

          if (length(bFormulas) !=0){
              
              for(iFor in 1:length(bFormulas)){ 
                    bFormula=bFormulas[iFor]
                    # Leo los datos del cluster corespondiente en el rango de 1 hasta los datos para armar el modelo
                    y.dato = ts(as.numeric(as.vector(cluster.obs[,nclus+2])),start=1, end=cant.de.anios) 
    
                    #Ajusto la formula para obtener los coeficientes de nuevo.
                    fit = lm(as.formula(bFormula),data = predictores)
                    
                    tmp.pred=predict.lm(fit, newdata=predictor.nuevo) #calculo de la prediccion por el modelo
                    if (tmp.pred >= 0){
                      y.pred[y.i]=tmp.pred
                      y.tipo.modelo[y.i]="RLM"
                      y.umbral.modelo[y.i]=RLM.umbral[iFor]
                      y.modelo[y.i]=bFormulas[iFor]
                      y.i=y.i+1
                    }
              } # Fin formulas
          }
          # Fin RLM
 
          # PROCESO los modelos de GAM
          
          modelos=read.xlsx(xlsxFile = paste0("Modelos.",mes.ref,"_",miny,"_",maxy,"/Cluster",nclus,"/Modelos_",mes.ref,"_C",nclus,"_LASSO_GAM.xlsx"))
          #Selecciono el mejor modelo, que puse en la primera fila del archivo de modelos

          bFormulas=modelos[which(modelos$Radj > umbral),2]
          GAM.umbral=modelos[which(modelos$Radj > umbral),4]
          if (length(bFormulas) !=0){
          for(iFor in 1:length(bFormulas)){ 
            bFormula=bFormulas[iFor]
            # Leo los datos del cluster corespondiente en el rango de 1 hasta los datos para armar el modelo
            
            y.dato = ts(as.numeric(as.vector(cluster.obs[,nclus+2])),start=1, end=cant.de.anios) 
            
            #Ajusto la formula para obtener los coeficientes de nuevo.
            fit = gam(as.formula(bFormula), method = "REML",data=predictores)
            
            #Evaluo el modelo en los puntos de entrenamiento
            tmp.pred=predict.gam(fit, predictor.nuevo)
            if (tmp.pred >= 0){
              y.pred[y.i]=tmp.pred            
              y.tipo.modelo[y.i]="GAM"
              y.umbral.modelo[y.i]=GAM.umbral[iFor]
              y.modelo[y.i]=bFormulas[iFor]
              y.i=y.i+1
            }  
          } # Fin formulas
          }
          # Fin GAM                      
          
          # PROCESO los modelos de SVR
          
          modelos=read.xlsx(xlsxFile = paste0("Modelos.",mes.ref,"_",miny,"_",maxy,"/Cluster",nclus,"/Modelos_",mes.ref,"_C",nclus,"_LASSO_SVR.xlsx"))
          
          bFormulas=modelos[which(modelos$Radj > umbral),2]
          bEpsilons=modelos[which(modelos$Radj > umbral),4]
          bCostos=modelos[which(modelos$Radj > umbral),5]
          SVR.umbral=modelos[which(modelos$Radj > umbral),4]
          if (length(bFormulas) !=0){
          for(iFor in 1:length(bFormulas)){ 
            bFormula=bFormulas[iFor] # selecciono una de los modelos a aplicar 
            #ALROLLA
            y.dato = ts(as.numeric(as.vector(cluster.obs[,nclus+2])),start=1, end=cant.de.anios) 
            epsilon=bEpsilons[iFor]
            costo=bCostos[iFor]
            print(paste0("Formula: ",bFormula))
            
            fit = svm(as.formula(bFormula), data=predictores,epsilon=epsilon,cost=costo)
            
            #Evaluo el modelo 
            tmp.pred =  predict(fit, predictor.nuevo)
            if (tmp.pred >= 0){
              y.pred[y.i] =tmp.pred
              y.tipo.modelo[y.i]="SVR"
              y.umbral.modelo[y.i]=SVR.umbral[iFor]
              y.modelo[y.i]=bFormulas[iFor]
              y.i=y.i+1
            }
          } # Fin formulas
          }
          # Fin SVR      
          
          # PROCESO los modelos de ANN
          modelos=read.xlsx(xlsxFile = paste0("Modelos.",mes.ref,"_",miny,"_",maxy,"/Cluster",nclus,"/Modelos_",mes.ref,"_C",nclus,"_LASSO_ANN.xlsx"))
          modelos=na.omit(modelos$Radj)
          modelos=as.numeric(modelos[modelos!="Radj"])
          predictor.nuevo2=predictor.nuevo[2:ncol(predictor.nuevo)]
          
          
          #!!!!! **** Hay que escalar los predictores y la salida que esta entre 0 y 1 reescalarla a precipitacion en mm
          #=====================================================
          #Acomodamos los predictores y el predictando entre 0 y 1
          predictores.max=sapply(predictores, max, na.rm = TRUE)
          predictores.min=sapply(predictores, min, na.rm = TRUE)
          predictores.max_min=predictores.max - predictores.min
          
          for(p in 1:length(predictor.name)){
            predictores[,p]=(predictores[,p]-predictores.min[p])/predictores.max_min[p]
            predictor.nuevo2[,p]=(predictor.nuevo2[,p]-predictores.min[p])/predictores.max_min[p]
          }  
          
          predictor.nuevo2=as.matrix(predictor.nuevo2,ncol=ncol(predictor.nuevo2),nrow=1)
          #ALROLLA
          y.dato = ts(as.numeric(as.vector(cluster.obs[,nclus+2])),start=1, end=cant.de.anios) 
          y.dato.min=min(y.dato)
          y.dato.max=max(y.dato)
          y.dato.max_min=y.dato.max-y.dato.min
          #y.dato=(y.dato-y.dato.min)/y.dato.max_min
          
          ANN.umbral=c()
          i.ANN=1
          for (nr in 1:length(modelos)){
            if(modelos[nr]> umbral){
              ANN.umbral[i.ANN]=modelos[nr]
              modelo <- load_model_hdf5(filepath=paste0("Modelos.",mes.ref,"_",miny,"_",maxy,"/Cluster",nclus,"/Modelos_",mes.ref,"_C",nclus,"_LASSO_ANN_",nr,".hdf5"),compile = TRUE)

              tmp.pred = predict(modelo,x=predictor.nuevo2)
              #Aca convertimos el rango 0 1 a precip en mm
              if (tmp.pred >= 0){             
                y.pred[y.i]=tmp.pred*y.dato.max_min+y.dato.min
                y.tipo.modelo[y.i]="ANN"
                y.umbral.modelo[y.i]=modelos[nr]
                y.modelo[y.i]=paste0("ANN_",nr)
                y.i=y.i+1
                i.ANN=i.ANN+1
              }
            }
            
          }
          # Fin ANN 
          
          if(length(y.pred) != 0){
            #calculo los quintiles
            
            quintil=quantile(y.dato, probs = (0:5)/5)
            Prono=round(y.pred,2)
            tcount=length(Prono)
            proba=c()
            proba2=c()
            rango=c()
            rango2=c()
            proba.mayor=c()
            proba.entre=c()
            lim.inf=c()
            for( p in 1:(length(quintil)-1)){
              proba[p]=round(length(Prono[which(Prono > quintil[p])])/tcount,2)
              proba2[p]=round(length(Prono[which(Prono > quintil[p] & Prono < quintil[p+1])])/tcount,2)
              rango[p]=paste0(sprintf("%6.2f",quintil[p])," - ",sprintf("%6.2f",quintil[p+1],2))
              
              proba.mayor[p]=paste0("P[pre > ",sprintf("%6.2f",quintil[p]),"]")
              proba.entre[p]=paste0("P[pre > ",sprintf("%6.2f",quintil[p])," Y pre < ",sprintf("%6.2f",quintil[p+1]),"]")
              lim.inf[p]=quintil[p]
            }
            
            #obs.ver=cluster.obs[cant.de.anios+1,nclus+2]
            #obs.intervalo=which(quintil > obs.ver)[1]-1
            #if(is.na(obs.intervalo)) obs.intervalo=5 # si el observado  esta por encima del quintil...
            prono.intervalo=which (proba2 == max(proba2))[1]
            
            #adjR.modelo=round(c(RLM.umbral,GAM.umbral,SVR.umbral,ANN.umbral),3)
            res.proba=data.frame(Quintiles=rango,P.mayor.que=proba.mayor,lim.inf=lim.inf,Proba=proba)
            res.proba.entre=data.frame(Quintiles=rango,P.entre=proba.entre,Proba=proba2)
            
            resultado=data.frame(N.Modelo=1:(y.i-1),adjR=y.umbral.modelo,Umbral=rep(umbral,(y.i-1)),Pred.Anio=rep(pred.anio,(y.i-1)),Formula=y.modelo,Tipo=y.tipo.modelo,Prono=round(y.pred,2))
            
            
            Parciales= group_by(resultado,Tipo) %>% summarise(N=n(),MEDIA=mean(Prono),DESVIO=sd(Prono))
            Totales= summarize(resultado,Tipo="TOTAL",N=n(),MEDIA=mean(Prono),DESVIO=sd(Prono))
            Cuadro.total=rbind(Parciales,Totales)
            writeData(wb, sheet = "PronoProba", x = res.proba, startCol = 10, startRow = 1,rowNames = F)
            writeData(wb, sheet = "PronoProba", x = res.proba.entre, startCol = 15, startRow = 1,rowNames = F)
            #writeData(wb, sheet = "PronoProba", x = "obs", startCol = 18, startRow = 1,rowNames = F)
            #writeData(wb, sheet = "PronoProba", x = obs.ver, startCol = 18, startRow = 2,rowNames = F)            
            #writeData(wb, sheet = "PronoProba", x = "i.obs", startCol = 19, startRow = 1,rowNames = F)
            #writeData(wb, sheet = "PronoProba", x = obs.intervalo, startCol = 19, startRow = 2,rowNames = F)
            writeData(wb, sheet = "PronoProba", x = "i.prono", startCol = 18, startRow = 1,rowNames = F)
            writeData(wb, sheet = "PronoProba", x = prono.intervalo, startCol = 18, startRow = 2,rowNames = F)
            #writeData(wb, sheet = "PronoProba", x = "IDX", startCol = 21, startRow = 1,rowNames = F)
            #writeData(wb, sheet = "PronoProba", x = obs.intervalo-prono.intervalo, startCol = 21, startRow = 2,rowNames = F)            
            
            writeData(wb, sheet = "PronoProba", x = Cuadro.total, startCol = 10, startRow = 10,rowNames = F)   
            writeData(wb, sheet = "PronoProba", x = resultado, startCol = 1, startRow = 1,rowNames = F)
            
            saveWorkbook(wb, file = paste0("./Pronostico/Pronostico_",mes.ref,"_",pred.anio,"_C",nclus,"_ProxMes.xlsx"),overwrite = T)
        }
  
  }  #Fin clusters
}  # Fin meses





