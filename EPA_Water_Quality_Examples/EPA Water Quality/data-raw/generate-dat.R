library(tidyverse)

# identify water quality csv
water_url <- "https://www.epa.gov/sites/production/files/2014-10/nla2007_chemical_conditionestimates_20091123.csv"

# site info csv (w lat lon data)
site_url <- "https://www.epa.gov/sites/production/files/2014-01/nla2007_sampledlakeinformation_20091113.csv"

# read sites
sites <- read_csv(site_url) %>% 
  janitor::clean_names()

# read water
water_q <- read_csv(water_url) %>% 
  janitor::clean_names()

# join together
# join together
clean <- select(sites, lon_dd, lat_dd, lakename, site_id, state_name, st) %>% 
  inner_join(water_q, by = "site_id") %>% 
  # join a table that has region info
  left_join(
    tibble(st = state.abb,
           region = state.region), by = c("st.y" = "st")
  ) %>% 
  # select only data of interest
  select(contains("_cond"), ptl, ntl, chla, st = st.x, region,
         lon_dd = lon_dd.x, lat_dd = lat_dd.x, lakename)


write_csv(clean, "data/water_quality.csv") 
