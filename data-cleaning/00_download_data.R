
library(here)
options(timeout = max(3600, getOption("timeout")))
path = here("data-cleaning", "raw_data")

##### Download WUSTL NO2 data #####
# 2019: https://zenodo.org/records/5484305#.YesGadHMJaQ
# 2013: https://zenodo.org/records/5424752#.YesGatHMJaQ

no2_2019_src = r"{https://zenodo.org/records/5484305/files/TROPOMI-inferred_surface_no2_northamerica_2019_annual_mean.nc?download=1}"
no2_2019_filename = "TROPOMI-inferred_surface_no2_northamerica_2019_annual_mean.nc" 
no2_2013_src = r"{https://zenodo.org/records/5424752/files/OMI_downscaled-inferred_surface_no2_northamerica_2013.nc?download=1}"
no2_2013_filename = "OMI_downscaled-inferred_surface_no2_northamerica_2013.nc" 

if(!(no2_2019_filename %in% list.files(path))){
  download.file(no2_2019_src, here(path, no2_2019_filename))
}

if(!(no2_2013_filename %in% list.files(path))){
  download.file(no2_2013_src, here(path, no2_2013_filename))
}

##### This section downloads data from the EPA #####
# https://www.epa.gov/smartgrowth/smart-location-mapping

### Download EPA Smart Location Database ###
smart_loc_src = r"{https://edg.epa.gov/EPADataCommons/public/OA/SLD/SmartLocationDatabaseV3.zip}"
smart_loc_filename = "SmartLocationDatabaseV3"

if(!(smart_loc_filename %in% list.files(path))){
  smart_loc_zip <- here(path, paste0(smart_loc_filename, ".zip"))
  download.file(smart_loc_src, smart_loc_zip)
  unzip(smart_loc_zip, exdir = here(path, smart_loc_filename))
  file.remove(smart_loc_zip)
}


##### ZEV Data California ####
# From https://www.energy.ca.gov/files/zev-and-infrastructure-stats-data

zev_filename = "Vehicle_Population.xlsx"
zev_src = r"{https://www.energy.ca.gov/filebrowser/download/6311?fid=6311#block-symsoft-page-title}"

if(!(zev_filename %in% list.files(path))){
  download.file(zev_src, here(path, zev_filename))
}
