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


# Obtener volúmenes de isoterma

# Archivo 1
getVoliso(x = allFiles[1], iso_val = isoVal, polygon_pars = polygonPars)

# Archivo 2
getVoliso(x = allFiles[2], iso_val = isoVal, polygon_pars = polygonPars)

# Todos los archivos
require(dplyr)
require(ggplot2)

setNames(object = allFiles, nm = basename(allFiles)) |> 
  
  lapply(
    FUN = getVoliso,
    iso_val = isoVal, 
    polygon_pars = polygonPars
  ) |> 
  
  bind_rows(.id = "file") |> 
  
  ggplot() +
  
  geom_path(
    mapping = aes(
      x = time,
      y = voliso_km3
    )
  ) +
  
  facet_wrap(~file, scales = "free_x") +
  
  theme_bw()

  
  