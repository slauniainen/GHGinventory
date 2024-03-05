
# This script calculates the total above and below ground litter production, as a function of fine root biomass, 
# and different categories of litter. The final production amount is weighted by the proportional area of different
# peatland types.

# The biomass of fine roots based on the basal area of different tree types, based on linear equations from Ojanen et al. 2014
# Read the input data. Tree basal areas and average dwarf shrub coverages for different peatland types.

# Above ground litter is calculated based on linear equations by Ojanen and tree basal area data.
# Below ground litter 
rm(list=ls())

source("PATHS.R")

## Here we calculate living tree litter based on biomass fractions

biomass <- FUNC_read_file(PATH_input_biomass)
LOOKUP_litter_conversion <- read.table(PATH_lookup_litter, header = TRUE)

#### TABLE OF BIOMASS #####

bm_conv <- LOOKUP_litter_conversion[1:7, 3:4]

bm_conv <- data.frame(component = 1:7,
                      bmtype = c("Stemwood",
                                 "Bark",
                                 "Live branches",
                                 "Foliage",
                                 "Dead brances",
                                 "Stumps",
                                 "Roots"))

# Calculate litter production from biomass fractions

litter_types <-
  biomass %>%
  # Leave out total biomasses (categories 8 & 9)
  filter(component < 8) %>% 
  left_join(LOOKUP_litter_conversion) %>%
  # Calculate litter production from biomass, convert to C
  mutate(litter = bm * bm_turnover_constant * CONST_biomass_to_C) %>%
  select(-bm, -bm_turnover_constant, -bmtype) %>%
  mutate(region = ifelse(region == 1, "south", "north"))

# Calculate litter production of living trees

living_tree_litter <-
  litter_types %>%
  # Leaving out dead branches in order to avoid double counting
  filter(component != 5) %>%
  # # Leave out spruce bark
  filter(!(component == 2 & species == 2)) %>%
  # divide into above and below ground litter
  mutate(ground = ifelse(component == 7, "below", "above")) %>%
  group_by(region, year, tkg, litter_type, ground) %>%
  summarize(living_tree_litter = sum(litter)) %>%
  # designate these as living
  mutate(litter_source = "living") %>% 
  rename(peat_type = tkg)

FUNC_save_output(living_tree_litter, PATH_living_tree_litter)

########

# Read in the basal area data. in m2/ha
basal_area_data <-
  FUNC_read_file(PATH_input_basal_area) %>% 
  group_by(region, peat_type, year) %>% 
  summarize(basal_area = sum(basal_area))
# Read basal area data by treetype
basal_area_by_treetype <- FUNC_read_file(PATH_input_basal_area)
# Read in the living tree woody litter data from GHG inventory. Already in tons C
living_tree_litter <- FUNC_read_file(PATH_living_tree_litter) %>% 
  group_by(region, year, peat_type) %>% 
  summarize(living_tree_litter = sum(living_tree_litter))
  
# Calculate ground vegetation biomass. It's based on basal areas

ground_vegetation_litter <-
  basal_area_data %>% 
  # Add in the regression constants and calculate the biomass
  left_join(CONST_total_ground_vegetation_biomass_by_peatland_type) %>% 
  mutate(biomass = (CONST_total_ground_vegetation_biomass_A * basal_area) + regression_constant) %>% 
  # Transform g/m2 dry mass to ton C/ha/y
  mutate(ground_vegetation_litter = biomass * CONST_biomass_to_C * 0.01) %>% 
  # leave out unnecessary columns
  select(region, peat_type, year, ground_vegetation_litter)

# The actual calculation that yields us fine root biomass in tons of biomass / ha
fine_root_litter <-
  basal_area_by_treetype %>% 
  # Add in the regression constants for calculating the biomass
  left_join(CONST_fine_root_biomass_by_treetype) %>% 
  # Then calculate the biomass for each tree type using the regression constants provided
  mutate(tree_fine_root_biomass = basal_area * regression_constant) %>% 
  # Group and sump up all tree types together 
  group_by(region, peat_type, year) %>% 
  summarize(tree_fine_root_biomass = sum(tree_fine_root_biomass)) %>% 
  # Add in dwarf shrub coverage by peatland type, along with regional constants needed in the calculation
  left_join(CONST_dwarfshrub_coverage) %>% 
  left_join(CONST_fine_root_biomass_region) %>% 
  # Calculate the final biomass, by adding the contribution from dwarf shrubs and adjust with the regional modifiers. Convert to tons BM / ha (0.01)
  mutate(fine_root_biomass = (tree_fine_root_biomass + (dshrub_cover * CONST_dwarfshrub_root_biomass) + regional_modifier) * 0.01) %>% 
  # Drop out unnecessary variables
  select(region, peat_type, year, fine_root_biomass) %>% 
  # Final step is calculating fine root litter production based on fine root turnover rate, adjusted for deep roots missing from the original data
  # and assuming 50% of dry BM is carbon
  # Add in the turnover rates for different peatland types
  left_join(CONST_fine_root_turnover) %>% 
  # Calculate fine root litter production in tons of C/ha/y
  mutate(fine_root_litter_production = fine_root_biomass * CONST_fine_root_deep_fraction * fine_root_turnover * CONST_biomass_to_C) %>% 
  # drop out all the unnecessary variables
  select(region, peat_type, year, fine_root_litter_production)

# Combining the the fine root litter production to other litter types.

# Combine above and below ground litter

total_living_litter <-
  living_tree_litter %>% 
  left_join(ground_vegetation_litter) %>% 
  left_join(fine_root_litter) %>% 
  mutate(total_living_litter = living_tree_litter + fine_root_litter_production + ground_vegetation_litter) %>% 
  select(region, year, peat_type, total_living_litter)

FUNC_save_output(total_living_litter, PATH_living_litter)