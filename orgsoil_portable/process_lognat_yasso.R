# Organic soil YASSO

rm(list=ls())

source("PATHS.R")

# YASSO, Scandinavian parameters


# Read climate data

weather <-
  FUNC_read_file(PATH_input_weather_logyasso)

#Read litter data, add humus fraction as zero

litter <-
  FUNC_read_file(PATH_input_ghgi_litter) %>% 
  mutate(H = 0)

# Define the size of different litter categories in cm here

lookup_woodysize <- 
  data.frame(litter_type = 
               c("non-woody_litter", "fine_woody_litter", "coarse_woody_litter"), 
                               wood_size = c(0, 2, 15))
                       
# We need simple averages for 1960-1990 weather data for spin-up. Temperature and temperature amplitude in celcius
# precipitation in mm

spinup_weather <-
  weather %>% 
  filter(year < 1991) %>% 
  group_by(region) %>% 
  summarize(mean_T = mean(mean_T),
            ampli_T = mean(ampli_T),
            precip = mean(sum_P)) %>% 
  ungroup()

# We also need 30 year rolling means for all weather params to smooth out interannual variation

weather_roll <-
  weather %>% 
  group_by(region) %>% 
  mutate(roll_T = rollmean(mean_T, 30, align = "right", fill = NA),
         roll_amp = rollmean(ampli_T, 30, align = "right", fill = NA),
         roll_P = rollmean(sum_P, 30, align = "right", fill = NA)) %>% 
  select(year, region, roll_T, roll_amp, roll_P) %>% 
  fill(roll_T, roll_amp, roll_P, .direction  = "downup")

# For the spin-up litter input, we the mean values from 1970-1976 and 1982-1984 for South and North Finland, respectively

spinup_litter <-
  litter %>% 
  filter((soil == "org" & region == "south" & year %in% c(1970:1976)) |
    (soil == "org" & region == "north" & year %in% c(1982:1984))) %>% 
  group_by(region, ground, litter_source, litter_type) %>% 
  # summarize by litter type
  summarise_at(c("A", "W", "E", "N", "H"), mean, na.rm = TRUE) %>% 
  ungroup() %>% 
  group_by(region, litter_type) %>% 
  summarise_at(c("A", "W", "E", "N", "H"), sum, na.rm = TRUE) %>% 
  # To make things a bit more tidy, we condense the separate AWENH columns into a list of vectors
  mutate(AWENH_initial = mapply(c, A, W, E, N, H, SIMPLIFY = F))  %>% 
  select(region, litter_type, AWENH_initial)

# Here we calculate the spin-up. Mean weather and litter data act as input, spin-up
# period is 50 years. Be sure to use SpinUp = TRUE for the function to work

yasso_spinup <-
  spinup_litter %>% 
  left_join(spinup_weather) %>% 
  left_join(lookup_woodysize) %>% 
  group_by(region, litter_type) %>% 
  mutate(FUNC_yasso07(Yasso07Parameters = CONST_yasso07_ska,
                     Climate = data.frame(mean_T, ampli_T, precip),
                     InitialCPool = c(0,0,0,0,0),
                     LitterInput = AWENH_initial,
                     WoodySize = wood_size,
                     SpinUp = TRUE,
                     SpinUpYears = 50)) %>% 
  mutate(AWENH_spinup = mapply(c, A_, W_, E_, N_, H_, SIMPLIFY = F)) %>%
  select(region, litter_type, wood_size, AWENH_spinup)

# Here we process the litter input data required for the actual Yasso calculations
# In order to avoid double counting, we want to leave out roots and branches from natural logging

yasso_litter <-
  litter %>% 
  # This might seem confusing but essentially we want: all litter types from logging, only cwl from natural mortality
  filter(soil == "org", !(litter_source == "natmort" & !litter_type == "coarse_woody_litter"), year > 1971) %>% 
  group_by(region, litter_type, year) %>% 
  summarise_at(c("A", "W", "E", "N", "H"), sum, na.rm = TRUE) %>% 
  mutate(C_input = A + W + E + N + H) %>% 
  mutate(AWENH_litterinput = mapply(c, A, W, E, N, H, SIMPLIFY = F))  %>% 
  select(region, year, litter_type, AWENH_litterinput, C_input) 

# Here are the actual yasso runs
yasso_runs <-
  yasso_litter %>% 
  # Add in weather and litter data
  left_join(weather_roll) %>% 
  left_join(yasso_spinup) %>% 
  group_by(region, litter_type) %>% 
  # Run the model
  mutate(FUNC_yasso07(Climate = data.frame(roll_T, roll_amp, roll_P),
                     Yasso07Parameters = CONST_yasso07_ska, 
                     InitialCPool = AWENH_spinup,
                     LitterInput = AWENH_litterinput,
                     WoodySize = wood_size)) %>% 
  mutate(C_final = A_ + W_ + E_ + N_ + H_) %>% 
  ungroup()

# Calculate the decomposition of logging and natural mortality by subtracting
# annual net change in C stock from the initial C input
lognat_annual_balance <-
  yasso_runs %>% 
  group_by(region, year) %>% 
  summarize(C_input = sum(C_input), 
            C_final = sum(C_final)) %>% 
  # Calculate the change in annual C stock
  mutate(annual_C_change = C_final - lag(C_final),
         lognat_decomp = C_input - annual_C_change) %>% 
  select(region, year, lognat_decomp) %>% 
  filter(year > 1989)

FUNC_save_output(lognat_annual_balance, PATH_lognat_decomp)