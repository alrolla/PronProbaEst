#modelos de regresion lineal multiple
require(openxlsx)
library(fpp)
library(forecast)

#Modificar aca para cambiar el directorio de trabajo
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

for( mes.ref in meses){

  #Leo las series medias de los clusters  
  cluster.obs=read.xlsx(paste0("clusters/series.medias.pre.",mes.ref,".xlsx"),sheet="Clusters")
  cluster.name=colnames(cluster.obs[3:ncol(cluster.obs)])
  # mes.referencia=as.numeric(mes.ref)-1 #mes de referencia - 1
  # if(mes.referencia == 0.) { 
    #cluster.obs=cluster.obs[,-1]
  # }      
  for(nclus in 1:length(cluster.name)){
    #Leo los predictores
    predictores=read.xlsx(paste0("Predictores.",mes.ref,"/Cluster",nclus,"/Predictores_",mes.ref,"_C",nclus,"_LASSO_Corregido.xlsx"))[1:cant.de.anios,]
    predictor.name=colnames(predictores[1:ncol(predictores)])
    y.dato = ts(as.numeric(as.vector(cluster.obs[,2+nclus])),start=1, end=cant.de.anios) 
    #convierto los predictores en clase ts
    for(p in 1:length(predictor.name)){
      predictores[,p] = ts(predictores[,p],start =1, end=cant.de.anios)
    }
    dir.create(path = paste0("./Modelos.",mes.ref,"_",miny,"_",maxy,"/Cluster",nclus), recursive = TRUE,showWarnings = FALSE)
    n <- length(predictor.name)
    #Genero las combinaciones de predictores
    id <- unlist(
      lapply(1:n,
             function(i)combn(1:n,i,simplify=F)
      )
      ,recursive=F)
    #Genero las formulas
    Formulas <- sapply(id,function(i)
      #paste("y.dato ~ ",paste0("predictores$",predictor.name[i],collapse="+"))
      paste("y.dato ~ ",paste0(predictor.name[i],collapse="+"))
    )
    rm(fit.final)
    umbral=0.1
    resultado.modelo=NULL
    coef=list()
    i=1
    for(fml in 1:length(Formulas)){
      
      #Ajusto al modelo propuesto
      fit = tslm(as.formula(Formulas[fml]),data=predictores)
      errors = CV(fit)
      resultado.modelo <- rbind(resultado.modelo,t(errors))
      coef[[i]]=fit$coefficients
      i=i+1
      #Chequeo el umbral
      if (errors[["AdjR2"]] > umbral){
        fit.final=fit
        print(fit$coefficients)
        umbral=errors[["AdjR2"]]
        print(paste("fml:",fml,"error: ",errors[["AdjR2"]],"umbral",umbral))
      }
      
    }
    resultado.modelo2=data.frame(Formulas,resultado.modelo,as.character(coef))
    colnames(resultado.modelo2)[1] ="Formula"
    colnames(resultado.modelo2)[7] ="Coeficientes"
    
    
    print(paste("Mejor modelo:" ))
    fit.final$coefficients      
    
    write.xlsx(resultado.modelo2,file=paste0("Modelos.",mes.ref,"_",miny,"_",maxy,"/Cluster",nclus,"/Modelos_",mes.ref,"_C",nclus,"_LASSO_RLM.xlsx"))
  }  
}
#fin

