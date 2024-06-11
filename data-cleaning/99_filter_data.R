library(here)
library(tidyverse)

setwd(here("data-cleaning"))
data_folder = "intermediate_data"
csvfile = "ca_zev_no2_confounders_nomissing.csv"

df = read_csv(file.path(data_folder, csvfile))


