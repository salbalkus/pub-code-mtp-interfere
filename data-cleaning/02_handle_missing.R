library(here)
library(sf)
library(tidyverse)
library(areal)
library(readxl)

# Define files we need
data_folder = here("data-cleaning", "intermediate_data")
shpfile = "ca_zev_no2_confounders.shp"
csvfile = "ca_zev_no2_confounders.csv"

cur_files = list.files(data_folder)

# Read in intermediate files
if(!(shpfile %in% cur_files) || !(csvfile %in% cur_files)){
  source("01_combine_data.R")
}

result <- read_csv(file.path(data_folder, csvfile))
result <- st_read(file.path(data_folder, shpfile))


##### Handle Missing Data #####

# Interpolate ZCTAs with missing values
index <- st_touches(result, result)

neighbor_mean <- function(df, var, weight){
  return(ifelse(is.na(var), apply(index, 1, function(i){weighted.mean(var[i], weight[i], na.rm=T)}), var))
} 

# Interpolate mean of neighboring ZCTAs
interp <- result
prev <- nrow(interp) + 1
i <- 1
while(nrow(interp[rowSums(is.na(interp)) > 0,]) < prev){
  cat("\nSpatial Interpolation Round", i)
  prev <- nrow(interp[rowSums(is.na(interp)) > 0,])
  interp <- interp %>%
    mutate(mdn_rnt = neighbor_mean(interp, mdn_rnt, ALAND10),
           mdn_hm_ = neighbor_mean(interp, mdn_hm_, ALAND10),
           mdn_ncm = neighbor_mean(interp, mdn_ncm, ALAND10),
           pct_aut = neighbor_mean(interp, pct_aut, ALAND10),
           p__2013 = neighbor_mean(interp, p__2013, ALAND10),
           pct_pb_ = neighbor_mean(interp, pct_pb_, ALAND10),
           pct_wfh = neighbor_mean(interp, pct_wfh, ALAND10),
           pct_pvr = neighbor_mean(interp, pct_pvr, ALAND10),
           medin_g = neighbor_mean(interp, medin_g, ALAND10),
           pct_wn_ = neighbor_mean(interp, pct_wn_, ALAND10),
           pct_hgh = neighbor_mean(interp, pct_hgh, ALAND10),
           pct_cll = neighbor_mean(interp, pct_cll, ALAND10),
           pct_mrr = neighbor_mean(interp, pct_mrr, ALAND10),
           pct_chl = neighbor_mean(interp, pct_chl, ALAND10),
    )
  i <- i + 1
}

# There are 15 ZCTAs that cannot be interpolated since they do not neighbor any ZCTAs
sum(sapply(index, length) == 0)

# DROPPING ZCTAS: We drop ZCTAs that...
# 1.) Are missing all 17 demographic variables (the next highest is 8 missing demographic variables)
# 2.) Of the remaining, drop any missing variables that could not be imputed because the ZIPs were isolated from any other ZIP
# All of these have population < 800, besides...
# - ZIP 94130: Treasure Island (the one missing the PM2.5 measurement) with population 2880
# - ZIP 92310: Fort Irwin (isolated military base) with population 8845
interp_drop <- interp %>% filter(rowSums(is.na(interp)) == 0)

# Store the files with interpolated missing values
shp_filepath_nomissing = here("data-cleaning", "intermediate_data", "ca_zev_no2_confounders_nomissing.shp")
csv_filepath_nomissing = here("data-cleaning", "intermediate_data", "ca_zev_no2_confounders_nomissing.csv")

st_write(interp_drop, shp_filepath_nomissing)
write_csv(st_drop_geometry(interp_drop), csv_filepath_nomissing)
