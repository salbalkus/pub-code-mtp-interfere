library(here)
library(ncdf4)
library(raster)
library(terra)
library(tigris)
library(tidycensus)
library(sf)
library(tidyverse)
library(areal)
library(readxl)
options(tigris_use_cache = TRUE)

# Download necessary data
# Also loads the source file names for each data source
source(here("data-cleaning", "00_download_data.R"))

# Load desired geographies from Census Bureau
zcta_vars <- tigris::zctas(year=2010, state="CA")
zcta_vars_terra <- vect(zcta_vars$geometry)

##### Aggregate NO2 grid to ZCTA #####

# Function to process the grid of air pollution data
# and compute zonal statistics for ZCTAs
get_pollutant <- function(filename, zcta_vars_terra){
  path <- file.path(getwd(), filename)
  x <- nc_open(path)
  
  lon <- ncvar_get(x, "LON_CENTER")
  lat <- ncvar_get(x, "LAT_CENTER", verbose = F)
  
  x.array <- ncvar_get(x, "surface_no2_ppb") # store the data in a 3-dimensional array
  r.x <- raster(t(x.array), xmn=min(lon), xmx=max(lon), ymn=min(lat), ymx=max(lat), crs=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs+ towgs84=0,0,0"))
  r.x <- flip(r.x, direction='y')
  r.x.terra <- rast(r.x)
  
  # Compute zonal statistics
  # Exclude NA to avoid counting ocean, etc. where air pollution is not measured
  zonal_mean <- zonal(r.x.terra, zcta_vars_terra,
                      fun = "mean", touches = TRUE, na.rm = TRUE, 
                      as.polygons = TRUE
  )
  return(zonal_mean$layer)
}

zcta_vars["no2_2019"] = get_pollutant(no2_2019_filename, zcta_vars_terra)
zcta_vars["no2_2013"] = get_pollutant(no2_2013_filename, zcta_vars_terra)

##### Call Census Data API #####

### Population ###
# Function to obtain population from full census
# https://api.census.gov/data/2010/dec/sf1/variables.html
zcta_pop <- get_decennial(geography = "zcta",
                          variables = c(
                            "P001001" # Total Population
                            #"P003002", # White
                            #"P003003", # Black
                            #"P003004", # Indian/Alaskan
                            #"P003005", # Asian
                            #"P003006", # Islander
                            #"P003007", # Other
                            #"P003008", # Two or More Races
                            #"P013001", # Median Age
                          ),
                          state = "CA",
                          year = 2010,
                          geometry = F) %>%
  pivot_wider(id_cols = GEOID,
              names_from = variable,
              values_from = value
  ) %>% mutate(pop = P001001, .keep = "unused")

zcta_pop$GEOID <- str_sub(zcta_pop$GEOID, start = 3)

### American Community Survey (ACS) ###
# From https://api.census.gov/data/2021/acs/acs5/variables.html
# Function to obtain ACS demographic characteristics for the given year
get_socio_year <- function(year){
  return(get_acs(geography = "zcta",
                 variables = c(
                   # General Population
                   #"DP05_0001E", # Total Population
                   "DP05_0018E", # Median Age
                   # Education (collapse)
                   "DP02_0067PE", # High school graduate or higher
                   "DP02_0068PE", # Bachelor's degree or higher
                   # Marital Status
                   "DP02_0025E", # Males 15 and older
                   "DP02_0027E", # Married Males 15 and older
                   "DP02_0031E", # Females 15 and older
                   "DP02_0033E", # Married Females 15 and older
                   # Race (keep all)
                   "DP05_0037PE", # White
                   "DP05_0038PE", # Black
                   "DP05_0039PE", # Indian/Alaskan
                   "DP05_0044PE", # Asian
                   "DP05_0052PE", # Hawaiian/Islander
                   "DP05_0057PE", # Other
                   "DP05_0058PE", # Two or more races
                   # Hispanic/Latino,
                   "DP05_0071PE", # Hispanic or Latino
                   # Households with Children
                   "DP02_0001E", # Total Households
                   "DP02_0003E", # Married with children
                   "DP02_0005E", # Cohabiting with Children
                   "DP02_0007E", # Single Father
                   "DP02_0011E" # Single Mother
                 ),
                 state = "CA",
                 year = year, geometry=F) %>%
           pivot_wider(
             id_cols = GEOID,
             names_from = variable,
             values_from = estimate
           ) %>%
           mutate(
             median_age = DP05_0018,
             pct_highschool = DP02_0067P,
             pct_college =  DP02_0068P,
             pct_married = ifelse(DP02_0025 + DP02_0031 == 0, 0, (DP02_0027 + DP02_0033) / (DP02_0025 + DP02_0031)),
             pct_white = DP05_0037P,
             pct_black = DP05_0038P,
             pct_asian = DP05_0044P,
             pct_hispanic = DP05_0071P,
             pct_other =  DP05_0039P + DP05_0052P + DP05_0057P + DP05_0058P,
             pct_children = ifelse(DP02_0001 == 0, 0, (DP02_0003 + DP02_0005 + DP02_0007 + DP02_0011) / DP02_0001), # compute number of children; if no valid households, replace with 0
             .keep = "unused"
           ))
}

# Get the sociodemographic variables for 2019
zcta_socio <- get_socio_year(2019)

# From https://api.census.gov/data/2019/acs/acs5/profile/variables.html
# Function to compute economic characteristics for a given year
get_econ_year <- function(year){
  return(get_acs(geography = "zcta",
                 variables = c(### ECONOMIC CHARACTERISTICS
                   "DP03_0062E", # Median household income in past 12 months (2021 inflation-adjusted)
                   "DP03_0119PE", # Poverty Rate
                   "DP03_0005PE", # Civilian labor force unemployed %
                   "DP04_0046PE", # Owner-occupied Housing Units
                   "DP04_0089E", # Median value of owner-occupied housing
                   "DP04_0134E", # Median rent of occupied units
                   "DP03_0019PE", # Car, Truck, or Van - drove alone (should we include carpooled as well? This is to estimate network)
                   "DP03_0021PE", # Public Transportation
                   "DP03_0024PE" # Work from home
                 ),
                 state = "CA",
                 year = year)  %>%
           pivot_wider(
             id_cols = GEOID,
             names_from = variable,
             values_from = estimate
           ) %>%
           mutate(
             median_income = DP03_0062,
             pct_poverty =  DP03_0119P,
             unemployment = DP03_0005P,
             pct_owner_occupied = DP04_0046P,
             median_home_value = DP04_0089,
             median_rent = DP04_0134,
             pct_auto = DP03_0019P,
             pct_public_transport =  DP03_0021P,
             pct_wfh = DP03_0024P,
             .keep = "unused"
           ))
}

# Get the economic data for 2019
zcta_econ <- get_econ_year(2019)

# join the population, sociodemographic, and economic variables into a table of covariates
zcta_covariates <- zcta_pop %>% 
  inner_join(zcta_socio, by = "GEOID") %>% inner_join(zcta_econ, by = "GEOID")

# join the covariates to the outcome
zcta <- inner_join(zcta_vars, zcta_covariates, by = c("ZCTA5CE10"="GEOID"), )

# Clean up the dataframes that we've joined to avoid using too much memory
rm(zcta_socio)
rm(zcta_econ)
rm(zcta_pop)
rm(zcta_covariates)


##### EPA Smart Location Database #####

### Smart Location ###
# Load the data
epa_SL <- st_read(file.path(smart_loc_filename, "SmartLocationDatabase.gdb"))

# Select potentially relevant covariates from the Smart Location Mapping
epa_SL <- epa_SL %>% dplyr::select(
  GEOID10,
  Pct_AO0, # % of zero-car households in CGB, 2018
  D3A, # Total road network density
  D1C5_RET, # Gross retail (5-tier) employment density (jobs/acre) on unprotected land
  D1C5_OFF, # Gross office (5-tier) employment density (jobs/acre) on unprotected land
  D1C5_IND, # Gross industrial (5-tier) employment density (jobs/acre) on unprotected land
  D1C5_SVC, # Gross service (5-tier) employment density (jobs/acre) on unprotected land
  D1C5_ENT, # Gross entertainment (5-tier) employment density (jobs/acre) on unprotected land
  D4C, # Aggregate frequency of transit service within 0.25 miles of CBG boundary per hour during evening peak period
  NatWalkInd # National Walkability Index
)

# Filter to California
epa_SL_CA <- epa_SL[epa_SL$GEOID10 %>% str_sub(1, 2) == "06",] 

# Some values of D4c are -99999. From the documentation: 
#"CBGs in areas that do not have transit service were assigned the value “-99999""
# This means that this area does not have access to public transportation (or at least, any public transportation
# tracked via the internet) and its value should actually be assumed 0 for our use case
epa_SL_CA[epa_SL_CA$D4C < 0,]$D4C = 0

# Set data to recommended CRS from the `areal` package
epa_SL_CA <- st_transform(epa_SL_CA, crs = 26915)
zcta <- st_transform(zcta, crs = 26915)

# Interpolate to the ZCTA geography using *areal weighted interpolation*
# WARNING: the line below takes 15+ minutes!
zcta_interp <- aw_interpolate(zcta, tid = ZCTA5CE10, source = epa_SL_CA, sid = GEOID10, intensive = names(epa_SL_CA)[2:10])

# Merge based on UDS ZIP to the ZEV data
zcta_vars <- tigris::zctas(year=2010, state="CA")
zip_zcta_xref <- read_excel("ZIPCodetoZCTACrosswalk2019UDS.xlsx")

# Note that we exclude two ZIP_CODE : 89061 Nevada and 97635 Oregon included in the CA ZEV data since they presumably only count part of the vehicles (the ones who live in CA) in those ZIP codes, which would be misleading. Hence we limit to only ZCTAs fully enclosed in CA state.


##### ZEV California data #####

# Read in the electric vehicle data
# This may need to be updated if CA Energy Commission changed the number of columns,
# as they did during this project
zrz <- read_excel("Vehicle_Population.xlsx", sheet = "ZIP",
                  col_types = c("numeric", "text", "text", "text", "numeric")) %>% filter(`Data Year` %in% c(2013, 2019))


# Merge electric vehicle data to ZCTAs
zcta_zev <- zip_zcta_xref %>% left_join(zrz, by = c("ZIP_CODE" = "ZIP")) %>% 
  drop_na() %>% filter(STATE == "CA") %>%
  group_by(ZCTA, `Data Year`, `Fuel Type`, STATE) %>%
  summarise(
    `Number of Vehicles` = sum(`Number of Vehicles`)
  )

# Add label for whether the vehicle is ZEV or not ZEV
# This may need to be updated if CA Energy Commission changes the text labels denoting the type of vehicle,
# as they did during this project
zcta_zev$ZEV = ifelse(zcta_zev$`Fuel Type` %in% c("Battery Electric (BEV)", "Gasoline Hybrid", "Plug-in Hybrid (PHEV)", "Fuel Cell (FCEV)"), "ZEV", "NonZEV")

# Compute number of vehicles in each ZIP code for each year
zcta_zev <- zcta_zev %>%
  group_by(ZCTA, `Data Year`, ZEV, STATE) %>%
  summarise(
    `Number of Vehicles` = sum(`Number of Vehicles`)
  ) %>%
  pivot_wider(names_from = c(`ZEV`, `Data Year`), values_from = c(`Number of Vehicles`))

# Merge ZEV data with covariate data computed previously
result <- full_join(zcta_zev, zcta_interp, by=c("ZCTA"="ZCTA5CE10"))
# Compute population density. ALAND10 represents m^2, so convert to km^2
result$pop_density <- result$pop / result$ALAND10 * 1000 * 1000

# Save results as intermediate datasets in both shapefile and CSV formats
setwd("..")
shp_filepath = file.path("intermediate_data", "ca_zev_no2_confounders.shp")
csv_filepath = file.path("intermediate_data", "ca_zev_no2_confounders.csv")
st_write(result, shp_filepath)
write_csv(st_drop_geometry(result), csv_filepath)

