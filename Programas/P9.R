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

#Modificar aca para cambiar el directorio de trabajo
setwd("C:/Users/Marcela/Documents/D/comahue/pp")
#setwd("~/Desktop/comahue/pp")
#parametros de referencia
miny <- 2016
maxy <- 2020
cant.de.anios=maxy-miny+1

#parametro cantidad de clusters
clusters=3
#meses a calcular los predictores con un mes de lag
#Esto controla que meses se usaran
meses=c("01","02","03","04","05","06","07","08","09","10","11","12")

wb <- createWorkbook()
addWorksheet(wb, sheetName = "RMSExCluster")
addWorksheet(wb, sheetName = "Media_DesvioxCluster")
addWorksheet(wb, sheetName = "IDXxCluster")
addWorksheet(wb, sheetName = "ErrorxCluster")
rcluster=1
for(nclus in 1:clusters){
    RMSE_cluster=data.frame()
    MDESV_cluster=data.frame()
    
    for( mes.ref in meses){
      ECM=data.frame()
      for (yy in miny:maxy){
        prono=read.xlsx(xlsxFile = paste0("Pronostico/Pronostico_",mes.ref,"_",yy,"_C",nclus,".xlsx"))
        prono=prono[c("Tipo","Prono","obs")]
        if (length(which(prono$Prono < 0))){
          prono[which(prono$Prono <0),2]=0
        } 
        prono=na.omit(prono)
        ECM=rbind(ECM,prono)
       
      }  # Fin años pronostico
      # Calculamos el error cuadratico medio
      mECM_T=sqrt(1/nrow(ECM)*sum((ECM$Prono-ECM$obs)^2))
      ECM_RLM=filter(ECM,Tipo=="RLM")
      mECM_RLM=sqrt(1/nrow(ECM_RLM)*sum((ECM_RLM$Prono-ECM_RLM$obs)^2))
      ECM_GAM=filter(ECM,Tipo=="GAM")
      mECM_GAM=sqrt(1/nrow(ECM_GAM)*sum((ECM_GAM$Prono-ECM_GAM$obs)^2))
      ECM_SVR=filter(ECM,Tipo=="SVR")
      mECM_SVR=sqrt(1/nrow(ECM_SVR)*sum((ECM_SVR$Prono-ECM_SVR$obs)^2))
      ECM_ANN=filter(ECM,Tipo=="ANN")
      mECM_ANN=sqrt(1/nrow(ECM_ANN)*sum((ECM_ANN$Prono-ECM_ANN$obs)^2))  
      
      RMSE_cluster=rbind(RMSE_cluster,data.frame(mes=mes.ref,
                                               RMSE_RLM=round(mECM_RLM,1),
                                               RMSE_GAM=round(mECM_GAM,1),
                                               RMSE_SVR=round(mECM_SVR,1),
                                               RMSE_ANN=round(mECM_ANN,1),
                                               RMSE_ENS=round(mECM_T,1)))
      # Calculamos media y desvio
      mMEAN_T=mean(ECM$Prono,na.rm = TRUE)      
      mDESV_T=sd(ECM$Prono,na.rm = TRUE)   
      
      ECM_RLM=filter(ECM,Tipo=="RLM")
      mMEAN_RLM=mean(ECM_RLM$Prono,na.rm = TRUE)
      mDESV_RLM=sd(ECM_RLM$Prono,na.rm = TRUE)      
      
      ECM_GAM=filter(ECM,Tipo=="GAM")
      mMEAN_GAM=mean(ECM_GAM$Prono,na.rm = TRUE)
      mDESV_GAM=sd(ECM_GAM$Prono,na.rm = TRUE)      
      
      ECM_SVR=filter(ECM,Tipo=="SVR")
      mMEAN_SVR=mean(ECM_SVR$Prono,na.rm = TRUE)
      mDESV_SVR=sd(ECM_SVR$Prono,na.rm = TRUE)    
      
      ECM_ANN=filter(ECM,Tipo=="ANN")
      mMEAN_ANN=mean(ECM_ANN$Prono,na.rm = TRUE)
      mDESV_ANN=sd(ECM_ANN$Prono,na.rm = TRUE)         

      MDESV_cluster=rbind(MDESV_cluster,data.frame(mes=mes.ref,
                                               MEAN_RLM=round(mMEAN_RLM,1),
                                               DESV_RLM=round(mDESV_RLM,1),
                                               MEAN_GAM=round(mMEAN_GAM,1),
                                               DESV_GAM=round(mDESV_GAM,1),
                                               MEAN_SVR=round(mMEAN_SVR,1),
                                               DESV_SVR=round(mDESV_SVR,1),
                                               MEAN_ANN=round(mMEAN_ANN,1),
                                               DESV_ANN=round(mDESV_ANN,1),
                                               MEAN_ENS=round(mMEAN_T,1),
                                               DESV_ENS=round(mDESV_T,1)))     

      }  #Fin meses
    #Escribir el resumen del CLUSTER

    RMSE_cluster[is.na(RMSE_cluster)] = NA
    writeData(wb, sheet = "RMSExCluster", x = paste0("CLUSTER: ",nclus), startCol = 1, startRow = rcluster,rowNames = F)
    writeData(wb, sheet = "RMSExCluster", x = RMSE_cluster, startCol = 1, startRow = rcluster+1,rowNames = F)

    MDESV_cluster[is.na(MDESV_cluster)] = NA
    writeData(wb, sheet = "Media_DesvioxCluster", x = paste0("CLUSTER: ",nclus), startCol = 1, startRow = rcluster,rowNames = F)
    writeData(wb, sheet = "Media_DesvioxCluster", x = MDESV_cluster, startCol = 1, startRow = rcluster+1,rowNames = F)
    rcluster=rcluster+15
    
    
    
}  # Fin clusters

#===========================================================
#Voy por el IDX
#===========================================================
rcluster=1
for(nclus in 1:clusters){
  IDX_cluster=data.frame()
  for( mes.ref in meses){
    IDX_mes=data.frame()
    IDX_yy=c()
    i=1
    for (yy in miny:maxy){
      IDX=read.xlsx(xlsxFile = paste0("Pronostico/Pronostico_",mes.ref,"_",yy,"_C",nclus,".xlsx"))
      IDX=IDX[c("IDX")]
      
      IDX=na.omit(IDX)
      IDX_mes=rbind(IDX_mes,IDX)
      IDX_yy[i]=as.numeric(IDX)
      i=i+1
    }
    YY=as.data.frame(t(IDX_yy))
    colnames(YY)=c(miny:maxy)
    mIDX_MEAN_T=mean(IDX_mes$IDX,na.rm = TRUE)      
    mIDX_DESV_T=sd(IDX_mes$IDX,na.rm = TRUE)   
    IDX_cluster=rbind(IDX_cluster,data.frame(mes=mes.ref,
                                               IDX_MEAN=round(mIDX_MEAN_T,1),
                                               IDX_DESV=round(mIDX_DESV_T,1),YY))

  }
  
  writeData(wb, sheet = "IDXxCluster", x = paste0("CLUSTER: ",nclus), startCol = 1, startRow = rcluster,rowNames = F)
  writeData(wb, sheet = "IDXxCluster", x = IDX_cluster, startCol = 1, startRow = rcluster+1,rowNames = F)
  rcluster=rcluster+15
}


#===========================================================
#Voy por el ERROR x Año
#===========================================================
rcluster=1
for(nclus in 1:clusters){
  Error_cluster=data.frame()
  for( mes.ref in meses){
    Error_mes=data.frame()
    Error_yy=c()
    i=1
    sw=0
    for (yy in miny:maxy){
      Pronox=readWorkbook(xlsxFile = paste0("Pronostico/Pronostico_",mes.ref,"_",yy,"_C",nclus,".xlsx"),rows=10:15,cols=c(10,12))
      Obs=readWorkbook(xlsxFile = paste0("Pronostico/Pronostico_",mes.ref,"_",yy,"_C",nclus,".xlsx"),rows=1:2,cols=c(8))
      Pronox$MEDIA=round(Pronox$MEDIA-Obs$obs,1)
      Pronox$Tipo[Pronox$Tipo == "TOTAL"]= "ENS"
        Pronox2=data.frame()
        i=1
        if (Pronox$Tipo[i] == "ANN"){ Pronox2=rbind(Pronox2,data.frame(TIPO="ANN",MEDIA=Pronox[i,2]))
                                        i=i+1   }else{Pronox2=rbind(Pronox2,data.frame(TIPO="ANN",MEDIA=NA)) }
        if (Pronox$Tipo[i] == "GAM"){ Pronox2=rbind(Pronox2,data.frame(TIPO="GAM",MEDIA=Pronox[i,2]))
                                        i=i+1   }else{Pronox2=rbind(Pronox2,data.frame(TIPO="GAM",MEDIA=NA)) }
        if (Pronox$Tipo[i] == "RLM"){ Pronox2=rbind(Pronox2,data.frame(TIPO="RLM",MEDIA=Pronox[i,2]))
                                        i=i+1   }else{Pronox2=rbind(Pronox2,data.frame(TIPO="RLM",MEDIA=NA)) }
        if (Pronox$Tipo[i] == "SVR"){ Pronox2=rbind(Pronox2,data.frame(TIPO="SVR",MEDIA=Pronox[i,2]))
                                        i=i+1   }else{Pronox2=rbind(Pronox2,data.frame(TIPO="SVR",MEDIA=NA)) }
        if (Pronox$Tipo[i] == "ENS"){ Pronox2=rbind(Pronox2,data.frame(TIPO="ENS",MEDIA=Pronox[i,2]))         }else{Pronox2=rbind(Pronox2,data.frame(TIPO="ENS",MEDIA=NA)) }
        Pronox=Pronox2

      if (sw == 0){
        PronoRes=Pronox
        PronoRes=cbind(MES=rep(mes.ref,nrow(Pronox)),PronoRes)
        colnames(PronoRes)=c("Mes","Metodo",miny)
        sw=1
      }else{
        colnames(Pronox)=c("Metodo",yy)
        PronoA=Pronox[,2]
        PronoRes=cbind(PronoRes,PronoA)
      }

    }

    colnames(PronoRes)=c("Mes","Metodo",c(miny:maxy))
    writeData(wb, sheet = "ErrorxCluster", x = paste0("CLUSTER: ",nclus, " MES: ",mes.ref), startCol = 1, startRow = rcluster,rowNames = F)
    writeData(wb, sheet = "ErrorxCluster", x = PronoRes, startCol = 1, startRow = rcluster+1,rowNames = F)
    rcluster=rcluster+8
    
    
  }
  rcluster=rcluster+2

}

saveWorkbook(wb, file = paste0("./Pronostico/Resumen.xlsx"),overwrite = T)






