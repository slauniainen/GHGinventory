# Total emission / Soil CO2 balance
#
# This script calculates the final emission factors and soil CO2 balance.
rm(list=ls())

source("PATHS.R")

# Here we load in the various data sources used in calculating the total EF
peat_decomposition <- FUNC_read_file(PATH_peat_decomposition) # peat degradation
total_living_litter <- FUNC_read_file(PATH_living_litter) # Total litter
lognat_litter <- FUNC_read_file(PATH_input_dead_litter) # litter from logging and natural mortality
lognat_decomp <- FUNC_read_file(PATH_lognat_decomp) # decomposition of logging and natural litter, from Yasso07 modelling
total_area <- FUNC_read_file(PATH_input_total_area) # area data

# Calculate the emission factor per peatland type by summing up total litter production and
# subtracting peat degradation from the total. Unit ton C / ha

emission_factor <-
  total_living_litter %>% 
  left_join(peat_decomposition) %>% 
  left_join(lognat_litter) %>% 
  left_join(lognat_decomp) %>% 
  mutate(EF_drained_peatland = (total_living_litter + lognat_litter) + (peat_deg - lognat_decomp)) %>% 
  select(region, peat_type, year, EF_drained_peatland) 

# Save EF output
FUNC_save_output(emission_factor, PATH_ef_emission_factor)

# Calculate final emission
total_emission <-
  emission_factor %>% 
  left_join(total_area) %>% 
  # Calculate total emission, convert to kilotons
  mutate(total_ktC = (drained_peatland_area * EF_drained_peatland) / 1000) %>% 
  group_by(year) %>% 
  summarize(total_ktC = sum(total_ktC))

FUNC_save_output(total_emission, PATH_total_soil_carbon)