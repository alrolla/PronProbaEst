# Pronostico Probabilistico Estadistico (Machine Learning?) 
## Resumen
<p align="justify" >
Se describe la implementacion de un sistema para realizar un pronostico climático (trimestral - bimensual - mensual) en cualquier region de la que se tengan Observaciones provenientes de reanalisis. La implementación de pronósticos de precipitación a escalas mensuales es importante para los tomadores de decisiones en diferentes áreas como la agricultura, la industria y la generación de energía. Dentro de las metodologías de pronóstico de mediana escala se encuentran las técnicas estadísticas que brindan la posibilidad de aprender de situaciones pasadas para pronosticar futuras. Las técnicas de minería de datos son actualmente una herramienta poderosa para abordar estos problemas. En este caso se consideran las redes neuronales, la regresión vectorial de soporte y los modelos aditivos generalizados, además de la metodología de regresión lineal múltiple más utilizada en el pasado, para obtener modelos de predicción de precipitaciones. Los resultados indican que las técnicas de minería de datos mejoran los pronósticos derivados de otras metodologías, aunque la eficiencia de las diferentes metodologías depende en gran medida del mes y la región. Además, la posibilidad de generar ensambles de varios modelos y derivar pronósticos probabilísticos es una alternativa muy recomendable para realizar el pronóstico.        
</p>

## Diagrama General 
La figura siguiente muestra la interaccion entre los distintos modulos del sistema de pronostico.<br>
* Todos los modulos fueron escritos en lenguaje R.<br>
* Los resultados/salidas en general se escribieron en formato excel.<br>
      
<p align="center">
        <img src="./img/DiagramaGeneral.png" width="800"/>
</p>

## MODULOS 
   - ## Preparación de las Observaciones
      * Deben estar dentro del directorio "clusters" en el directorio de trabajo
      * Deben estar contenidas en un archivo excel 
      * Tiene que haber un archivo excel por cada mes
      * Los archivos excel deben llamarse "series.medias.pre.{mes} donde {mes} es 01,02,...12  
      * Como se observa en la figura habra un columna para el año y una columna por cada cluster 
      * Ejemplo de excel con las observaciones de cada cluster
      * Cada columna se debe llamar "cluster1, cluster2, ... clusterN"

      <p align="center">
        <img src="./img/Observaciones.png" width="400"/>
      </p>
      
      :+1: Listo con este Paso !!!
  - ## Preparación de los Reanálisis
      * Los reanalisis deben estar en el directorio **nnr** (ncep-ncar-reanalisis)
      * Son reanalisis de NCEP-NCAR globales 
      * Cuya resolucion es de 144 puntos de longitud por 73 puntos de latitud
      * Esto implica que cubren reticulos de 250x250 Km2
      * La resolucion temporal es mensual
      * Es importante que inicien en el Enero del año 1979 **(aunque el periodo inical en el proceso debe ser 1980!)**
      * las variables de los reanalisis considerados son: 
         *  **hgt200**: geopotencial en 200 hPa
         *  **hgt500**: geopotencial en 200 hPa
         *  **hgt1000**: geopotencial en 1000 hPa,sst
         *  **sst**: temperatura superficie del mar
         *  **tcw**: agua total en la columna
      *  hay una variable que no cambia:
         * **lsm**: mascara de tierra y agua
      * (Explicar el script de descarga y preparacion de estos archivos)

     :+1: Listo con este Paso !!! 
      
   - ## P3-Generación de predictores
      - ### Diagrama de funcionamiento
<p align="center">
  <img src="./img/P3.png" width="800"/>
</p>

El objetivo de este programa es de obtener regiones cuya correlacion desfasada entre reanalisis y observaciones 
tenga un nivel de correlacion significativa y de ese modo obtener las series de predictores para que sirvan
de entrada al programa de generación de modelos, previa seleccion de aquellos predictores con sentido fisico, que aporten informacion a los modelos generados <br>

Como se observa en el diagrama de funcionamiento las observaciones estan en el directorio **CLUSTERS** que es un lugar fijo dentro del programa P3 y los renanalisis estan en el directorio **NNR** que tambien es un lugar fijo. y generará mapas de correlacion y por otro lado excels con predictores para el mes considerado.

Importante: 
si queremos pronosticar febrero , correlacionamos los reanalisis de enero con las observaciones de febrero y guardamos los predictores en las planillas excel de febrero con estos predictores se generaran los modelos para febrero.

Ejemplo de archivo excel de predictores:
<p align="center">
  <img src="./img/Predictores_ejemplo.png" width="600"/>
</p>
Ejemplo de mapa de correlación:
<p align="center">
  <img src="./img/MapaCorrelacion.png" width="600"/>
</p>

- ## P4-Reduccion de predictores
<p align="center">
  <img src="./img/P4.png" width="800"/>
</p>

- ## P4.5 y P4.8 - Calculo de predictores siguiente año
<p align="center">
  <img src="./img/P4.5.png" width="800"/>
</p>

- ## P5-RLM - Modelos de regresion lineal multiple 
<p align="center">
  <img src="./img/P5-RLM.png" width="800"/>
</p>
A continuacion se muestra un ejemplo del excel de salida de regresion lineal multiple, se observa la columna de R^2 para este tipo de modelo.<br>

<p align="center">
  <img src="./img/SalidaRLM.png" width="500"/>
</p>

- ## P5-SVR - Support Vector Regression 
<p align="center">
  <img src="./img/P5-SVR.png" width="800"/>
</p>
A continuacion se muestra un ejemplo del excel de salida de SVR, se observa la columna de R^2 para este tipo de modelo.<br>
<p align="center">
  <img src="./img/SalidaSVR.png" width="500"/>
</p>

- ## P5-GAM - Modelos de Generalize Additive Models
<p align="center">
  <img src="./img/P5-GAM.png" width="800"/>
</p>
A continuacion se muestra un ejemplo del excel de salida de GAM, se observa la columna de R^2 para este tipo de modelo.<br>
<p align="center">
  <img src="./img/SalidaGAM.png" width="500"/>
</p>

- ## P5-ANN - Modelos de Artificial Neural Networks
<p align="center">
  <img src="./img/P5-ANN.png" width="800"/>
</p>

Este es esquema de las 4 arquitecturas de redes usadas. <br>
<p align="center">
  <img src="./img/Redes.png" width="500"/>
</p>
A continuacion se muestra un ejemplo del excel de salida de ANN, se observa la columna de R^2 para este tipo de modelo.<br>
<p align="center">
  <img src="./img/SalidaANN.png" width="800"/>
</p>

- ## P7 - Pronóstico Probabilistico
<p align="center">
  <img src="./img/P7.png" width="800"/>
</p>

Ejemplo de las distintas partes del Excel resultante del modulo P7 <br><br>
Parte 1: <br>
<p align="center">
  <img src="./img/P7Excel1.png" width="800"/>
</p> 
<br>

* Se observa que 8 modelos superaron el umbral de 0.5 de R^2 ajustado
* Se ven los predictores que quedaron en las formulas de pronóstico
* solo entraron 3 de los cuatro tipos de modelos GAM, SVR, ANN el tipo RLM no genero modelos que superen el umbral de 0.5
* Se ve el pronostico y la observacion para verificar 
<br>

Parte 2: <br>
<p align="center">
  <img src="./img/P7Excel2.png" width="400"/>
</p>
<br>

* La primer columna son los quintiles de las observaciones 
* La segunda columna La probabilidad "mayor que ..."
* La tercer columna el limite inferior
* La cuarta columna la probabilidad asosciada a cada umbral
<br>

Parte 3: <br>
<p align="center">
  <img src="./img/P7Excel3.png" width="500"/>
</p>

* La primer columna son los quintiles de las observaciones 
* La segunda columna La probabilidad "entre quitiles ..."
* La tercer columna la probabilidad asociada
* La cuarta columna la OBSERVACION
* La quinta columna  el intervalo en que cae la observación
* la sexta columna  el intervalo en que cae el pronostico
* la septima columna IDX: el intervalo diferencia o error

Parte 4: <br>
<p align="center">
  <img src="./img/P7Excel4.png" width="400"/>
</p>

* La primer columna es el tipo de modelo donde TOTAL es el ensamble medio
* La segunda columna es la cantidad de modelos usados
* La tercer columna es la media por tipo de modelo
* La cuarta columna es el desvio
* La ultima fila es el ensamble medio de los modelos

<br>

- ## P8 - Pronóstico Probabilistico proximo mes

Este modulo es similar al Modulo P7 con la diferencia que como estamos pronosticando sin disponer de la observacion TODO lo relacionado a verificacion es omitido en el excel resultante <br>
<p align="center">
  <img src="./img/P8.png" width="800"/>
</p>

- ## P9 - Resumen de pronosticos probabilisticos

Este modulo lee todos los pronosticos y arma un excel con 4 tabs cada una conteniendo resumenes de los errores de todos los pronosticos.

<p align="center">
  <img src="./img/P9.png" width="800"/>
</p>

- ## ANEXO - Instalacion de virtualbox y linux en Windows

- [Como instalar virtualbox y ubuntu?](https://osl.ugr.es/2020/09/29/como-instalar-ubuntu-en-virtual-box/)
