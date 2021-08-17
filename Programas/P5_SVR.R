#modelos support vector regresion SVR
require(openxlsx)
library(fpp)
library(forecast)
library(e1071)

# Rsquared <- function(y.est, y){
#   m.yest=mean(y.est)
#   m.y=mean(y)
#   y.est.sq=sum((y.est-m.y)^2)
#   y.sq=sum((y-m.y)^2)
#   
#   return(y.est.sq/y.sq)
#   
# }

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

#Modificar aca para cambiar el directorio de trabajo
setwd("C:/Users/Marcela/Documents/D/comahue/pp")
#setwd("~/Desktop/comahue/pp")

#parametros de referencia
miny <- 1981 # aca dijimos de hacer 1981 2015 y luego verificar
maxy <- 2020
#mes.referencia=11 #mes de referencia
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
  #   mes.referencia=12
  #   #Para comparar Obs de Enero y Reanalisis de Diciembre le saco el primer año a las observaciones
  #   #datos.obs=datos.obs[-1,]
  #   cluster.obs=cluster.obs[-1,]
  #   
  #   #Asi queda Renalisis(Dic 1979) vs Obs(Enero 1980) 
  #   
  # }      
  for(nclus in 1:length(cluster.name)){
    #Leo los predictores
    predictores=read.xlsx(paste0("Predictores.",mes.ref,"/Cluster",nclus,"/Predictores_",mes.ref,"_C",nclus,"_LASSO_Corregido.xlsx"))[1:cant.de.anios,]
    #predictor.name=colnames(predictores[1:ncol(predictores)])
    #y.dato = ts(as.numeric(as.vector(cluster.obs[,2+nclus])),start=1, end=cant.de.anios) 
    y.dato = cluster.obs[1:cant.de.anios,2+nclus] 
    
    predictor=cbind(y.dato,predictores)
    
    predictor.name=colnames(predictores[1:ncol(predictores)])
    
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
      #paste("y.dato ~ ",paste0("s(",predictor.name[i],",bs='tp',k=3)",collapse="+"))
      paste("y.dato ~ ",paste0(predictor.name[i],collapse="+"))
    )
    rm(fit.final)
    umbral=1000000
    resultado.modelo=NULL
    coef=list()
    i=1
    for(fml in 1:length(Formulas)){
      
      #Ajusto al modelo propuesto
      #fit = tslm(as.formula(Formulas[fml]))
      #fit = svm(as.formula(Formulas[fml]), data=predictores)
      print(paste0("Tunning: ",Formulas[fml]))
      tuneResult = tune(svm, as.formula(Formulas[fml]),  data=predictor,
                         ranges = list(epsilon = seq(0,1.,0.02),cost = 2^(2:5))
      ) 
     
      fit = tuneResult$best.model
      R2=round(Rsquared(fit$fitted,y.dato),3)
      Rbar2=round(RAdj(R2,length(y.dato),length(labels(terms(as.formula(Formulas[fml]))))),3)
      print(tuneResult)
      plot(tuneResult)

      errors = sqrt(mean(fit$residuals^2))
      resultado.modelo <- rbind(resultado.modelo,data.frame(R2,Rbar2,error=t(errors),epsilon=t(fit$epsilon),cost=t(fit$cost)))
      #coef[[i]]=fit$coefficients
      i=i+1
      #Chequeo el umbral
      if (errors < umbral){
        fit.final=fit
        #print(fit$coefficients)
        umbral=errors
        print(paste("fml:",fml,"error: ",errors,"umbral",umbral))
      }
      
    }
    
    resultado.modelo2=data.frame(Formulas,resultado.modelo)

    primera_c = array (NA,dim =c(1,nrow(resultado.modelo2)))
    resultado.modelo2=cbind(t(primera_c), resultado.modelo2)
    colnames(resultado.modelo2)[1] ="x"
    colnames(resultado.modelo2)[2] ="Formula"
    colnames(resultado.modelo2)[3] ="Rsquared"
    colnames(resultado.modelo2)[4] ="Radj"
    colnames(resultado.modelo2)[5] ="RMS"
    colnames(resultado.modelo2)[6] ="Epsilon"
    colnames(resultado.modelo2)[7] ="Cost"
    
    
    print(paste("Mejor modelo:" ))
    fit.final$coefficients      
    resultado.modelo2=resultado.modelo2[with(resultado.modelo2,order(Radj,decreasing = TRUE)),]
    resultado.modelo2$x[1]="1"
    
    write.xlsx(resultado.modelo2,file=paste0("Modelos.",mes.ref,"_",miny,"_",maxy,"/Cluster",nclus,"/Modelos_",mes.ref,"_C",nclus,"_LASSO_SVR.xlsx"))

  }  
}
#fin

