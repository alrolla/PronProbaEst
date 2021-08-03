# Pronostico Probabilistico Estadistico (Machine Learning?) [descargar paper](https://www.dropbox.com/s/akhc6kb6493c1rd/TAAC-D-21-00248.pdf?dl=0)
## Resumen
<p align="justify" >
The “Gran Chaco Argentino” is an area with great diversity of vegetation and climate and its productivity is highly dependent on the interannual variability of rainfall. That is why the implementation of precipitation forecasts on monthly scales are important for decision makers in different areas such as agriculture, industry and power generation. Within the medium-scale forecasting methodologies are the statistical techniques that provide the possibility of learning from past situations to forecast future ones. Data mining techniques are currently a powerful tool to address these problems. In this work, neural networks, support vector regression and generalized additive models are considered besides the most commonly used multiple linear regression methodology, to obtain precipitation forecasting models. The results indicate that data mining techniques improve forecasts derived from other methodologies, although the efficiency of the different methodologies is highly dependent on the month and the region. In addition, the possibility of generating ensemble means of several models and deriving probabilistic forecasts is a highly advisable alternative for prediction in this region of Argentina.
</p>

## PROGRAMAS (Lenguaje R)
   - ### Análisis exploratorio de los datos.
      - **P0_a.DistrEstaciones.R** . DISTRIBUCION DE ESTACIONES METEOROLOGICAS.  
      - **P0_b.Boxplots.R**        . BOXPLOTS POR ESTACION Y POR AGRUPAMIENTO.    
         - [RESULTADOS](https://github.com/alrolla/Especializacion_2018/tree/master/Analisis_Exploratorio)
   - ### Clustering (agrupamientos).       
      - **P1_Clusters_DEF_PRE.R**  . AGRUPAMIENTO DE ESTACIONES (JERARQUICO y  NO- JERARQUICO).  
      - **P1_Tests_Clusters.R**   . ANOVA DE AGRUPAMIENTOS.     
         - [RESULTADOS](https://github.com/alrolla/Especializacion_2018/tree/master/Agrupamientos)
   - ### Generacion de series de datos.
      - **P2_SeriesEstacion.R**  . GENERA SERIES POR ESTACION METEO.  
      - **P2_SeriesMedias.R**    . GENERA SERIES MEDIAS POR AGRUPAMIENTO.     
         - [RESULTADOS](https://github.com/alrolla/Especializacion_2018/tree/master/Series_Medias_Agrup_Estaciones)
   - ### Análisis de forzantes globales.         
      - **P3_Predictores.R**    . GENERA PREDICTORES ( MAPAS DE CORRELACION y SERIES DE PREDICTORES).     
         - [RESULTADOS](https://github.com/alrolla/Especializacion_2018/tree/master/Predictores)
   - ### LASSO (pre-selección de predictores).     
      - **P4_Lasso.R**    . SELECCION DE PREDICTORES SIGNIFICATIVOS.     
         - [RESULTADOS](https://github.com/alrolla/Especializacion_2018/tree/master/Lasso)
   - ### Construcción de los modelos.              
      - **P5_Modelos.R**    . STEP_FORWAD GENERACION DE MODELOS CON LOS PREDICTORES SELECCIONADOS.     
         - [RESULTADOS](https://github.com/alrolla/Especializacion_2018/tree/master/Modelos)
   - ### Verificación de los modelos.             
      - **P6_Regresion_Clasificacion.R**    . VERIFICACION Y LA CLASIFICACION EN SUB,SOBRE y NORMAL.     
         - [RESULTADOS](https://github.com/alrolla/Especializacion_2018/tree/master/Regresion_Clasificacion)
   - ### Pronóstico estacional de verano.      
      - **P7_PronosticoXEstacion.R**    . PRONOSTICO PARA LA REGION CON LOS MEJORES MODELOS.     
         - [RESULTADOS](https://github.com/alrolla/Especializacion_2018/tree/master/Pronostico)
   - ### Verificación del pronóstico para el año 2016     
      - **P8_MapaVerificacion.R**    . MAPA RESULTANTE DEL PRONOSTICO.     
         - [RESULTADOS](https://github.com/alrolla/Especializacion_2018/tree/master/Pronostico)

