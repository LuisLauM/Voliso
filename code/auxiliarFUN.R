
# Funciones para dibujar polígono -----------------------------------------

getCorners <- function(coords){
  switch(
    coords$method,
    "1" = corners_1(coords = coords),
    "2" = corners_2(coords = coords),
    stop("Wrong value for 'method'.")
  )
}

corners_1 <- function(coords){
  list(
    lon = sort(c(coords[[1]][1], coords[[2]][1]))[c(1, 2, 2, 1)],
    lat = sort(c(coords[[1]][2], coords[[2]][2]))[c(1, 1, 2, 2)]
  )
}

corners_2 <- function(coords){
  
  alpha <- with(coords, atan(abs(p1[1] - p2[1])/abs(p1[2] - p2[2])))
  
  x1 <- coords$p1[1]
  x2 <- x1 - coords$d*cos(alpha)/60
  x3 <- coords$p2[1]
  x4 <- x3 - coords$d*cos(alpha)/60
  
  y1 <- coords$p1[2]
  y2 <- y1 - coords$d*sin(alpha)/60
  y3 <- coords$p2[2]
  y4 <- y3 - coords$d*sin(alpha)/60
  
  list(
    lon = c(x1, x2, x4, x3),
    lat = c(y1, y2, y4, y3)
  )
}

corners2polygon <- function(coords, outClass = c("terra", "sf", "sp")){
  
  # Obtener vértices
  coords <- getCorners(coords = coords)
  
  coords <- cbind(x = coords$lon, y = coords$lat)
  coords <- rbind(coords, coords[1,])
  
  outClasses <- list(
    terra = c("SpatVector", "terra"),
    sf    = c("sfc_POLYGON", "sf"),
    sp    = c("SpatialPolygons", "sp")
  )
  
  if(outClass[1] %in% outClasses$terra){
    
    terra::vect(coords, type = "polygons", crs = "EPSG:4326")
    
  }else if(outClass[1] %in% outClasses$sf){
    
    sf::st_polygon(x = list(coords)) |> sf::st_sfc(crs = 4326)
    
  }else if(outClass[1] %in% outClasses$sp){
    
    sp::SpatialPolygons(list(sp::Polygons(list(sp::Polygon(coords)), 1)))
    
  }else{
    sapply(FUN = "[", 1) |> 
      
      sprintf(fmt = "Valid values for `outClass`: %s") |> 
      
      stop()
  } 
}


# Función de cálculo de profundidad de isoterma ---------------------------

getIsoTemp <- function(x, depths, iso_val){
  if(sum(x > iso_val, na.rm = TRUE) > 0 & sum(x < iso_val, na.rm = TRUE) > 0){
    approx(x = x, y = depths, xout = iso_val, ties = min)$y
  }else{
    index <- !is.na(x)
    
    if(sum(index) > 0){
      max(depths[index])
    }else{
      NA
    }
  }
}


# Función principal de cálculo de volumen de isoterma ---------------------

getVoliso <- function(x, iso_val = 15, polygon = NULL, polygon_pars = NULL){
  
  sprintf(fmt = "Isoterma de %.1f°C | Archivo %s", iso_val, basename(x)) |> 
    
    cli::cli_h2()
  
  # Obtener volúmenes de isoterma a partir de un archivo NetCDF
  envir <- rast(x = x, subds = "thetao")
  
  # Obtener vectores de tiempo y profundidad
  depthsNtime <- list(time = terra::time(x = envir), 
                      depth = terra::depth(x = envir)/1e3) |> 
    
    lapply(FUN = \(x) unique(x) |> sort())
  
  # Dividir en grupos por fecha (día)
  isothermals <- split(
    x = envir,
    f = time(x = envir)
  ) |> 
    
    # setNames(nm = depthsNtime$time) |> 
    
    # Aplicar la función getIsoTemp a cada grupo y, dentro de cada grupo, 
    # a cada grilla
    lapply(
      FUN = app,
      fun = getIsoTemp,
      depths = depthsNtime$depth, 
      iso_val = iso_val
    ) |> 
    
    # Concatenar lista de SpatRasters en un único SpatRaster
    rast() 
  
  # Definir valores de fecha
  time(isothermals) <- names(isothermals) <- depthsNtime$time
  
  
  # Construir polígono
  if(is.null(polygon)){
    if(is.null(polygon_pars)){
      stop("Debe definir el argumento para `polygon` o `polygon_pars`.")
    }else{
      polygonVect <- corners2polygon(coords = polygon_pars, outClass = "terra")
    }
  }else{
    polyClass <- c("SpatVector", "sf", "SpatialPolygons")
    index <- sapply(X = polyClass, FUN = inherits, x = polygon) |> any()
    
    if(!index){
      
      sprintf(fmt = "`%s`", polyClass) |> 
        
        paste(collapse = ", ") |> 
        
        sprintf(fmt = "`polygon` debe ser un objeto de clase %s.")|> 
        
        stop()
    }
    
    polygonVect <- vect(x = polygon)
  }
    
  
  cli::cli_progress_step(msg = "Calcular volumen de isoterma\n")
  
  # Multiplicar cada valor de profundidad de isoterma por el tamaño de cada 
  # grilla (en km^2)
  xapp(
    x = isothermals, 
    y = cellSize(x = isothermals[[1]], unit = "km"), 
    fun = "*"
  ) |> 
    
    # Aplicar polígono como máscara y sumar valores de volumen
    zonal(z = polygonVect, fun = sum, na.rm = TRUE) |> 
    
    # Convertir valores a un tabla (data.frame)
    as.numeric() |> dplyr::as_tibble() |> 
    
    # Editar nombres de columnas 
    dplyr::mutate(
      time = time(isothermals) |> as.Date(),
      voliso_km3 = value,
      .keep = "none"
    )
}
