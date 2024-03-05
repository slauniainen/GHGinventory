# Please read the README.txt

rm(list=ls())

source("PATHS.R")

# YASSO decomposition of natural and logging mortality
source(PATH_script_yasso)
# Calculate peat decomposition
source(PATH_script_peat_decomposition)
# Calculate above and below ground litter from living trees, fine roots and shrub
source(PATH_script_total_litter)
# Calculate the final emissions based on emission factors and area data
source(PATH_script_total_emission)