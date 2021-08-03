# Pronostico Probabilistico Estadistico (Machine Learning?) [paper](https://www.dropbox.com/s/akhc6kb6493c1rd/TAAC-D-21-00248.pdf?dl=0)
## Resumen
<p align="justify" >
The “Gran Chaco Argentino” is an area with great diversity of vegetation and climate and its productivity is highly dependent on the interannual variability of rainfall. That is why the implementation of precipitation forecasts on monthly scales are important for decision makers in different areas such as agriculture, industry and power generation. Within the medium-scale forecasting methodologies are the statistical techniques that provide the possibility of learning from past situations to forecast future ones. Data mining techniques are currently a powerful tool to address these problems. In this work, neural networks, support vector regression and generalized additive models are considered besides the most commonly used multiple linear regression methodology, to obtain precipitation forecasting models. The results indicate that data mining techniques improve forecasts derived from other methodologies, although the efficiency of the different methodologies is highly dependent on the month and the region. In addition, the possibility of generating ensemble means of several models and deriving probabilistic forecasts is a highly advisable alternative for prediction in this region of Argentina.
</p>

## PASOS (Lenguaje R)
   - ## Preparacion de las Observaciones
      * Deben estar dentro del directorio <style>p{color:red;}clusters </style>
      * Deben estar contenidas en un archivo excel 
      * Tiene que haber un archivo excel por cada mes
      * Los archivos excel deben llamarse "series.medias.pre.{mes} donde {mes} es 01,02,...12  
      * Como se observa en la figura habra un columna para el año y una columna por cada cluster 
      * Ejemplo de excel con las observaciones de cada cluster
      * Cada columna se debe llamar "cluster1, cluster2, ... clusterN"

      <p align="center">
        <img src="./img/Observaciones.png" width="500"/>
      </p>
      
      :+1: Listo esto
    
     
      
   - ## Generacion de predictores
      - ### Diagrama de funcionamiento
<p align="center">
  <img src="./img/P3.png" width="800"/>
</p>
      - **P3_Predictores.R** .  
     
         - [RESULTADOS](https://github.com/alrolla/Especializacion_2018/tree/master/Analisis_Exploratorio)
