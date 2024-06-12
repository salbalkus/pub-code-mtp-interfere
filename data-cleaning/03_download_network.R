
library(here)
library(R.utils)
options(timeout = max(3600, getOption("timeout")))

##### Longitudinal Employer-Household Dynamics #####
# Source: https://lehd.ces.census.gov/data/
# Downloaded from California Origin-Destination LODES 8

path = here("data-cleaning", "raw_network")
mainfile = "ca_od_main_JT00_2019.csv"
xwalkfile = "ca_xwalk.csv"

main_src = "https://lehd.ces.census.gov/data/lodes/LODES7/ca/od/ca_od_main_JT00_2019.csv.gz"
xwalk_src = "https://lehd.ces.census.gov/data/lodes/LODES7/ca/ca_xwalk.csv.gz"

if(!(mainfile %in% list.files(path))){
  main_zip = here(path, paste0(mainfile, ".gz"))
  download.file(main_src, main_zip)
  gunzip(main_zip)
}

if(!(xwalkfile %in% list.files(path))){
  xwalk_zip = here(path, paste0(xwalkfile, ".gz"))
  download.file(xwalk_src, xwalk_zip)
  gunzip(xwalk_zip)
}
