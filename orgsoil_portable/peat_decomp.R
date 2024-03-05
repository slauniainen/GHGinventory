# This script deals with the decomposition of peat
# It requires weather and basal area data 

rm(list=ls())

source("PATHS.R")

# Here we input the tree basal area and weather data. Basal area unit m2/ha

basal_area_data <- 
  FUNC_read_file(PATH_input_basal_area) %>% 
  group_by(region, peat_type, year) %>% 
  summarize(basal_area = sum(basal_area))

weather_data_30rollavg <- FUNC_read_file(PATH_input_weather)

# Here is the actual for peat degradation. Linear equations 

peat_decomposition <-
  basal_area_data %>% 
  # First add in the weather data
  left_join(weather_data_30rollavg) %>% 
  # Then add the constants used in calculating the decomposition of peat
  left_join(CONST_peat_decomposition_by_peatland_type) %>% 
  # Finally calculate degradation using the constants provided separately. 
  # The equation used here is (a * [basal_area] + b * [t]) - c
  mutate(peat_deg = ((CONST_peat_decomposition_a * basal_area + CONST_peat_decomposition_b * roll_T)) - decomposition_constant) %>% 
  # Convert g CO2 / m2 to ton C / ha, note 10^4 * 10^-6 = 0.01. Decomposition is loss of carbon, hence negative values
  mutate(peat_deg = peat_deg / -CONST_C_to_CO2 * 0.01) %>% 
  # Select only the end result for saving
  select(region, year, peat_type, peat_deg)

# Save data

FUNC_save_output(peat_decomposition, PATH_peat_decomposition)