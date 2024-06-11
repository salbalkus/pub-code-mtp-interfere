library(tidyverse)
library(here)

### Download and read in data ###
source(here("data-cleaning", "03_download_network.R"))
setwd(here("data-cleaning"))

data_folder = "raw_network"
intermediate_folder = "intermediate_network"
derived_file = "derived_network.csv"
only_ca_file = "ca_network.csv"

# WARNING: The below takes a long time to run!
network <- read.csv(file.path(data_folder, mainfile))
xwalk <- read.csv(file.path(data_folder, xwalkfile)) %>% dplyr::select(tabblk2010, zcta)

# JT00 = All Jobs (what we want)
network_xwalk_w <- left_join(network, xwalk, by=c("w_geocode" = "tabblk2010")) %>% rename(w_zcta = zcta)
network_xwalk <- left_join(network_xwalk_w, xwalk, by=c("h_geocode" = "tabblk2010")) %>% rename(h_zcta = zcta)

### Summarize the number of commuters within each ZCTA ###
network_zcta <- network_xwalk %>% group_by(w_zcta, h_zcta) %>% summarize(jobs = sum(S000))

# Store current processing step
write_csv(network_zcta, file.path(intermediate_folder, derived_file))

### Filter to only include commuters within California ###
network_zcta <- read_csv(file.path(intermediate_folder, derived_file))

valid_zcta <- unique(result$ZCTA)
valid_network <- network_zcta %>% filter(w_zcta %in% valid_zcta) %>% filter(h_zcta %in% valid_zcta)
write_csv(valid_network, file.path(intermediate_folder, only_ca_file))


### Extra Summary Statistics ###
# By filtering out commuters outside of California, we only throw out 0.03% of the units
# so it should be fine
print(paste0("Proportion of commuters dropped: ", 1 - sum(valid_network$jobs) / sum(network_zcta$jobs)))

# Compute the density of the graph
print(paste0("Graph density: ", nrow(network_zcta) / (length(unique(network_zcta$w_zcta))**2)))

# Compute K_max
works <- table(network_zcta$w_zcta)
print(paste0("Max degree of work: ", max(works)))
homes <- table(network_zcta$h_zcta)
print(paste0("Max degree of home: ", max(homes)))

