require(reticulate)

# Instalar python (ejecutar SOLO SI es que NO está previamente instalado)
# install_python()

# Definir un nombre para nuestro entorno virtual python
entorno <- "DescargaCopernicus"

virtualenv_create(envname = entorno)

virtualenv_install(envname = entorno, packages = "copernicusmarine")

use_virtualenv(virtualenv = entorno, required = TRUE)

# El entorno virtual debería haberse creado en 
# C:/Usuarios/nombreususario/Documentos/.virtualenvs/

# Atributos del módulo 'copernicusmarine'
atributos_cms <- import(module = "copernicusmarine")

# Definir en atributos los nombres de usuario y contraseña
# atributos_cms$login("usuario", "contraseña")


# Descargar meses puntuales -----------------------------------------------
# Marzo 2023
atributos_cms$subset(
  dataset_id        = "cmems_mod_glo_phy-thetao_anfc_0.083deg_P1D-m",
  variables         = list("thetao"),
  minimum_longitude = -83,
  maximum_longitude = -78,
  minimum_latitude  = -11,
  maximum_latitude  = -3,
  start_datetime    = "2023-03-01T00:00:00",
  end_datetime      = "2023-03-31T00:00:00",
  minimum_depth     = 0,
  maximum_depth     = 1e4,
  output_filename   = "raw/thetao_2023-03.nc"
)

# Septiembre 2023
atributos_cms$subset(
  dataset_id        = "cmems_mod_glo_phy-thetao_anfc_0.083deg_P1D-m",
  variables         = list("thetao"),
  minimum_longitude = -83,
  maximum_longitude = -78,
  minimum_latitude  = -11,
  maximum_latitude  = -3,
  start_datetime    = "2023-09-01T00:00:00",
  end_datetime      = "2023-09-30T00:00:00",
  minimum_depth     = 0,
  maximum_depth     = 1e4,
  output_filename   = "raw/thetao_2023-09.nc"
)


# Descargar período entre 2022-2026 ---------------------------------------

allDates <- seq(
  from = as.Date("2022-7-1"),
  to = as.Date("2026-1-1"),
  by = "month"
)
for(i in 2:length(allDates)){
  atributos_cms$subset(
    dataset_id        = "cmems_mod_glo_phy-thetao_anfc_0.083deg_P1D-m",
    variables         = list("thetao"),
    minimum_longitude = -83,
    maximum_longitude = -78,
    minimum_latitude  = -11,
    maximum_latitude  = -3,
    start_datetime    = format(x = allDates[i - 1], format = "%FT00:00:00"),
    end_datetime      = format(x = allDates[i] - 1, format = "%FT00:00:00"),
    minimum_depth     = 0,
    maximum_depth     = 1e4,
    output_filename   = sprintf(fmt = "raw/thetao_%s.nc", format(x = allDates[i - 1], format = "%Y-%m"))
  )
  
  cli::cli_alert_success(text = as.character(allDates[i - 1]))
}
