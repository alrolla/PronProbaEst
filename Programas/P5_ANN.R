#modelos redes neuronales ANN
Sys.setenv(RETICULATE_PYTHON= "C:\\Users\\Marcela\\anaconda3\\python.exe")

require(openxlsx)
library(fpp)
library(forecast)

library(keras)
library(tensorflow)

Rsquared <- function(y.est, y){
  m.yest=mean(y.est)
  m.y=mean(y)
  y.est.sq=sum((y.est-y)^2)
  #y.sq=sum((y-m.y)^2)
  y.sq=sum((y-m.y)^2)  
  return(1-y.est.sq/y.sq)
  
}

RAdj <- function(R2,n,k){
  #n: numero de observaciones
  #k: numero de predictores
  return ( 1-(1-R2)*(n-1)/(n-k-1) )
}

#sessionInfo()
#reticulate::py_config()

setwd("C:/Users/Marcela/Documents/D/comahue/pp")
#setwd("~/Desktop/comahue/pp")

#parametros de referencia
miny <- 1981 # aca dijimos de hacer 1981 2015 y luego verificar
maxy <- 2020

cant.de.anios=maxy-miny+1

#meses a calcular los predictores con un mes de lag
#Esto controla que meses se usaran
meses=c("01","02","03","04","05","06","07","08","09","10","11","12")
#meses=c("01")

#parametros generales de la red
par.epochs=1000
par.batch=5
par.verbose=FALSE

#parametros particulares de la arquitectura de las redes
capa.tipo=c()
capa.neuronas=c()
capa.activacion=c()

#arquitectura de la red 1
capa.tipo[[1]]=c("dense","drop","dense","dense")
capa.neuronas[[1]]=c(16,.2,32,1)
capa.activacion[[1]]=c("relu","","relu","relu")

#arquitectura de la red 2
capa.tipo[[2]]=c("dense","drop","dense","dense")
capa.neuronas[[2]]=c(32,.2,32,1)
capa.activacion[[2]]=c("relu","","relu","relu")

#arquitectura de la red 3
capa.tipo[[3]]=c("dense","drop","dense","dense")
capa.neuronas[[3]]=c(16,.1,32,1)
capa.activacion[[3]]=c("relu","","relu","relu")

#arquitectura de la red 4
capa.tipo[[4]]=c("dense","drop","dense","dense")
capa.neuronas[[4]]=c(32,.1,32,1)
capa.activacion[[4]]=c("relu","","relu","relu")

# Y asi seguimos para las distintas redes

for( mes.ref in meses){
  
    #Leo las series medias de los clusters  
    cluster.obs=read.xlsx(paste0("clusters/series.medias.pre.",mes.ref,".xlsx"),sheet="Clusters")
    cluster.name=colnames(cluster.obs[3:ncol(cluster.obs)])

    set.seed(123)
    tensorflow::tf$random$set_seed(123)
  
    for(nclus in 1:length(cluster.name)){
  
      #Leo los predictores
      predictores=read.xlsx(paste0("Predictores.",mes.ref,"/Cluster",nclus,"/Predictores_",mes.ref,"_C",nclus,"_LASSO_Corregido.xlsx"))[1:cant.de.anios,]
      predictor.name=colnames(predictores[1:ncol(predictores)])
      y.dato = as.numeric(as.vector(cluster.obs[,2+nclus]))[1:cant.de.anios]
  
      #Acomodamos los predictores y el predictando entre 0 y 1
      predictores.max=sapply(predictores, max, na.rm = TRUE)
      predictores.min=sapply(predictores, min, na.rm = TRUE)
      predictores.max_min=predictores.max - predictores.min
      for(p in 1:length(predictor.name)){
        predictores[,p]=(predictores[,p]-predictores.min[p])/predictores.max_min[p]
      }  
      y.dato.min=min(y.dato)
      y.dato.max=max(y.dato)
      y.dato.max_min=y.dato.max-y.dato.min
      y.dato=(y.dato-y.dato.min)/y.dato.max_min
      
      dir.create(path = paste0("./Modelos.",mes.ref,"_",miny,"_",maxy,"/Cluster",nclus), recursive = TRUE,showWarnings = FALSE)
      pred.train=as.matrix(predictores,ncol=ncol(predictores),nrow=cant.de.anios)
      pred.clase=as.matrix(y.dato,nrow=cant.de.anios)
  
      wb <- createWorkbook()
      addWorksheet(wb, sheetName = "MLP")
      colum=2
      fila=2      
      #Entreno todos los modelos y los guardo para despues
      for(nr in 1:length(capa.tipo)){
        
          layerx=c()  
          modelo = keras_model_sequential(name=paste0("ANN_",nr))
          
          for(nl in 1:((length(capa.tipo[[nr]])-1))){
               if(capa.tipo[[nr]][nl] == "dense") {
                   if(nl == 1){
                     layerx[[nl]]=layer_dense(modelo,units = capa.neuronas[[nr]][nl], activation = capa.activacion[[nr]][nl], input_shape = ncol( pred.train)) 
                   }else{
                     layerx[[nl]]=layer_dense(modelo,units = capa.neuronas[[nr]][nl], activation = capa.activacion[[nr]][nl]) 
                   }
               }
               if(capa.tipo[[nr]][nl] == "drop") {
                layerx[[nl]]=layer_dropout(modelo,capa.neuronas[[nr]][nl]) 
               }
           } 
          layerx[[nl+1]]= layer_dense(modelo,units = capa.neuronas[[nr]][nl+1], activation = capa.activacion[[nr]][nl])
          
          compile(modelo, loss = "mse", optimizer = optimizer_adam(lr=0.001))

          history = fit(modelo,x = pred.train,y=pred.clase, epochs = par.epochs, batch_size = par.batch, verbose = par.verbose)
      
          save_model_hdf5(modelo,filepath=paste0("Modelos.",mes.ref,"_",miny,"_",maxy,"/Cluster",nclus,"/Modelos_",mes.ref,"_C",nclus,"_LASSO_ANN_",nr,".hdf5"),overwrite = TRUE)
      
          #modelo2 <- load_model_hdf5(filepath=paste0("Modelos.",mes.ref,"/Cluster",nclus,"/Modelos_",mes.ref,"_C",nclus,"_LASSO_ANN_",nr,".hdf5"))
          fit.y=predict(modelo,x=pred.train)
          R2=round(Rsquared(fit.y,y.dato),3)
          Rbar2=round(RAdj(R2,length(y.dato),ncol( pred.train)),3)

          print(paste0("nclus: ",nclus))
          print(history)

          
          #recupero informacion para guardar el excel 

          conf=modelo$get_config()
          conf.capas=length(capa.tipo[[1]])
          conf.entradas=conf$layers[[1]]$config$batch_input_shape[[2]]
          conf.salidas=conf$layers[[length(conf$layers)]]$config$units
          conf.epochs=history$params$epochs
          conf.metric.error=history$metrics$loss[length(history$metrics$loss)] 

                    

          writeData(wb,"MLP","#Modelo",startCol=colum,startRow=fila)
          writeData(wb,"MLP","Capas",startCol=colum+1,startRow=fila)
          writeData(wb,"MLP","Entradas",startCol=colum+2,startRow=fila)
          writeData(wb,"MLP","Salidas",startCol=colum+3,startRow=fila)
          writeData(wb,"MLP","Error",startCol=colum+4,startRow=fila)
          writeData(wb,"MLP","Epochs",startCol=colum+5,startRow=fila)
          writeData(wb,"MLP","Capa",startCol=colum+6,startRow=fila)
          writeData(wb,"MLP","Tipo",startCol=colum+7,startRow=fila)
          writeData(wb,"MLP","Neuronas",startCol=colum+8,startRow=fila)
          writeData(wb,"MLP","Activacion",startCol=colum+9,startRow=fila)
          writeData(wb,"MLP","Rate",startCol=colum+10,startRow=fila)
          writeData(wb,"MLP","Rsquared",startCol=colum+11,startRow=fila)
          writeData(wb,"MLP","Radj",startCol=colum+12,startRow=fila)
          
          fila=fila+1
          writeData(wb,"MLP",conf.capas,startCol=colum+1,startRow=fila)
          writeData(wb,"MLP",conf.capas,startCol=colum+1,startRow=fila)
          writeData(wb,"MLP",conf.entradas,startCol=colum+2,startRow=fila)
          writeData(wb,"MLP",conf.salidas,startCol=colum+3,startRow=fila)
          writeData(wb,"MLP",conf.metric.error,startCol=colum+4,startRow=fila)
          writeData(wb,"MLP",conf.epochs,startCol=colum+5,startRow=fila)
          writeData(wb,"MLP",R2,startCol=colum+11,startRow=fila)
          writeData(wb,"MLP",Rbar2,startCol=colum+12,startRow=fila)
          
          for (nc in 1:length(capa.tipo[[1]])){
              conf.tipo=capa.tipo[[nr]][nc] # tipo "dense"
              conf.neuronas=capa.neuronas[[nr]][nc] # numero de neuronas
              conf.activacion=capa.activacion[[nr]][nc] # activacion
              if (substr(conf.tipo,1,4) == "drop"){
                conf.activacion.rate=capa.neuronas[[nr]][nc] # rate
              }
        
              fila=fila+1
              writeData(wb,"MLP",(nc-1),startCol=colum+6,startRow=fila)
              writeData(wb,"MLP",conf.tipo,startCol=colum+7,startRow=fila)
              if (substr(conf.tipo,1,4) == "Drop"){
                writeData(wb,"MLP",conf.activacion.rate,startCol=colum+10,startRow=fila)
              }else{
                writeData(wb,"MLP",conf.neuronas,startCol=colum+8,startRow=fila)
                writeData(wb,"MLP",conf.activacion,startCol=colum+9,startRow=fila)
                
              }
          }       
      
          fila=fila+2
      } # fin entrenamiento de modelos
      
      saveWorkbook(wb,paste0("Modelos.",mes.ref,"_",miny,"_",maxy,"/Cluster",nclus,"/Modelos_",mes.ref,"_C",nclus,"_LASSO_ANN.xlsx"),overwrite = TRUE)
      
      #stop(paste0("FIN CLUSTER:",nclus))
      
   }  # fin cluster
      
} #fin meses
  
print("fin")
#fin




