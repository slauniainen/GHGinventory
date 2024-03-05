# Denote all parameters with the prefix PARAM for easier reading

source("LIBRARIES.R")
source("FUNCTIONS.R")
source("CONSTANTS.R")


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# This path should point to the root folder of the whole project, where main.R is located.#
# Rest of the paths are generated automatically. Include / in the end of the path!                                         #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

PATH_main = "C:/path/to/script/"

###########################################################################################
########   There should be no need to touch anything beyond this point   ##################
###########################################################################################  

# Main folders
PATH_input =  paste(PATH_main, "Input/", sep = "")
PATH_midresults = paste(PATH_main, "Midresults/", sep = "")
PATH_results = paste(PATH_main, "Results/", sep = "")
PATH_lookup =  paste(PATH_main, "Lookup/", sep = "")

# Lookups. These are tables that are used in converting and aggregating things.
PATH_lookup_litter = paste(PATH_lookup, "litter_conversion.csv", sep = "") # for converting biomass fractions into litter fractions

# Script files

PATH_script_yasso = paste(PATH_main, "process_lognat_yasso.R", sep = "")
PATH_script_peat_decomposition = paste(PATH_main, "peat_decomp.R", sep = "") 
PATH_script_total_litter = paste(PATH_main, "total_litter.R", sep = "")
PATH_script_total_emission = paste(PATH_main, "total_emission.R", sep = "") 

# Input data

PATH_input_weather_logyasso <- paste(PATH_input, "logyasso_weather_data.csv", sep = "") # Weather data used in YASSO07
PATH_input_ghgi_litter <- paste(PATH_input, "ghgi_litter.csv", sep = "") # Full litter data for YASSO runs
PATH_input_basal_area <- paste(PATH_input, "basal_areas.csv", sep = "") # Basal area data
PATH_input_weather <- paste(PATH_input, "weather_data.csv", sep = "") # weather data
PATH_input_biomass <- paste(PATH_input, "biomass.csv", sep = "") # biomass data
PATH_input_dead_litter <- paste(PATH_input, "dead_litter.csv", sep = "") # total litter from logging and natural mortality
PATH_input_total_area = paste(PATH_input, "total_area.csv", sep = "") # Total peatland areas

# Midresults / intermediary results

PATH_living_tree_litter = paste(PATH_midresults, "living_tree_litter.csv", sep = "") # litter from living living trees from GHGI
PATH_living_litter = paste(PATH_midresults, "living_litter.csv", sep = "") # soil litter biomasses
PATH_lognat_decomp = paste(PATH_midresults, "lognat_decomp.csv", sep = "") # soil litter biomasses  

# Results

PATH_peat_decomposition = paste(PATH_results, "peat_decomposition.csv", sep = "" )
PATH_ef_emission_factor = paste(PATH_results, "emission_factor.csv", sep = "" )
PATH_total_soil_carbon = paste(PATH_results, "soil_carbon_balance_total.csv", sep = "")
