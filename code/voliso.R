# Definir carpeta con archivos NetCDF
envirDir <- "raw/"

# Definir valor de isoterma a buscar
isoVal <- 15

# Definir parámetros de polígono
polygonPars <- list(
  p1     = c(-78.33, -10),  
  p2     = c(-80.56, -3.1),
  d      = 120, 
  method = 2, 
  ylim   = c(0, 6, 0.2, 0.4)
)

# Calcular campos de isotermas diarias 

# Cargar paquetes necesarios
require(terra)
source("code/auxiliarFUN.R")

# Listar archivos NetCDF 
allFiles <- list.files(path = envirDir, pattern = "\\.nc$", full.names = TRUE)




# Obtener volumen (archivo único) -----------------------------------------

# Archivo 1, polígono cuadrado
getVoliso(x = allFiles[1], iso_val = isoVal, polygon_pars = polygonPars)

# Archivo 2, polígono EEZ Perú
getVoliso(
  x = allFiles[1], 
  iso_val = isoVal, 
  polygon = sf::st_read(dsn = "data/PER_eez.gpkg", layer = "eez")
)


# Obtener volumen (Todos los archivos) ------------------------------------

require(dplyr)
require(ggplot2)

# Definir valores de isoterma
isos <- c(iso15 = 15, iso20 = 20)

# Calcular volúmenes 
lapply(
  X = isos,
  FUN = \(x){
    setNames(object = allFiles, nm = basename(allFiles)) |> 
      
      lapply(
        FUN = getVoliso,
        iso_val = x, 
        polygon_pars = polygonPars
      ) |> 
      
      bind_rows(.id = "file")
  }
)

  