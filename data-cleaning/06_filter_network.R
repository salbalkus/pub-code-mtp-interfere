library(here)
library(tidyverse)
library(igraph)

# This script performs two tasks:
# 1. Compute the network weights as the proportion of commuters using electric vehicles
# 2. Save the network in an edgelist format
# Load the data and the network

df =  read_csv(here("data-cleaning", "intermediate_data", "ca_zev_no2_confounders_nomissing.csv")) %>% dplyr::select(ZCTA, pct_aut)
net = read_csv(here("data-cleaning", "intermediate_network", "ca_network_2019.csv")) %>%
      right_join(df, by = join_by(h_zcta == ZCTA)) %>%
      mutate(weight = jobs * pct_aut / 100) %>%
      select(w_zcta, h_zcta, weight)

normalize = net %>% group_by(w_zcta) %>% summarize(total = sum(weight))

netnormalized = net %>% left_join(normalize) %>% mutate(weight = weight / total) %>% select(w_zcta, h_zcta, weight)
netnormalized

g = graph_from_data_frame(netnormalized, directed = TRUE)

# Save the data in GraphML format
write_graph(
  g,
  here("data", "ZEV_commuters.xml"),
  format = "graphml"
)

# Save the data as a .csv edgelist
write_csv(netnormalized, here("data", "ZEV_commuters.csv"))
