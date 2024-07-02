library(here)
library(tidyverse)
library(sf)

data_folder = here("data-cleaning", "intermediate_data")
csvfile = "ca_zev_no2_confounders_nomissing.csv"
shpfile = "ca_zev_no2_confounders_nomissing.shp"
df = st_read(here(data_folder, shpfile))
# Compute the desired treatment and outcome variables
# putting them on the "change from 2013 to 2019" scale
df = st_read(here(data_folder, shpfile)) %>%
  mutate(Total_2013 = ZEV_2013 + NZEV_2013,
         Total_2019 = ZEV_2019 + NZEV_2019,
         ZEV_2013_pct = (ZEV_2013 / Total_2013) * 100,
         ZEV_2019_pct = (ZEV_2019 / Total_2019) * 100,
         no2 = n2_2019 - n2_2013
    ) %>%
  filter(pp_2019 > 0) %>%
  mutate(pop = pp_2019)

# Define the parsimonious subset to use as controls.

ctrl = c(
  "ZCTA",     # ZIP Code Tabulation Area (serves as an ID to link to network)
  "pop",       # Population
  "medin_g",   # Median Age
  "pct_cll",   # % College Educated (proxy for Education)
  "pct_hgh",   # % High School Educated (proxy for Education)
  "pct_wht",   # % White (proxy for Race)
  "mdn_ncm",   # Median Income
  "pct_pvr",   # % in Poverty
  "pct_wn_",   # % of Homes Owner-Occupied
  "mdn_hm_",   # Median Home Value
  "pct_aut",   # % Take Automobile to Work
  "pct_pb_",   # % Take Public Transportation to Work
  "pct_wfh",   # % Work from Home
  "D1C5_IN",   # % Gross Industrial Employment Density
  "D3A",       # Total Road Network Density
  "D4C",       # Aggregate Transit Frequency During Peak Period
  "NtWlkIn"    # Walkability Index
)

treat_and_resp = c("no2", "n2_2019", "ZEV_2019_pct", "ZEV_2013_pct")
df16 = df[,c(treat_and_resp, ctrl)]

st_write(df16, here("data", "NO2_ZEV_ZCTAs.shp"))
write_csv(as.data.frame(df16) %>% select(-geometry), here("data", "NO2_ZEV_ZCTAs.csv"))

