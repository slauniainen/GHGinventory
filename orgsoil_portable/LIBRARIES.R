# This script activates all the necessary packages needed for the calculation and installs any missing packages.
# In brief, it checks all the packages currently installed in the system for the current user, and installs any
# packages missing from the listing

# Install packages to default location
dir.create(path = Sys.getenv("R_LIBS_USER"), showWarnings = FALSE, recursive = TRUE)

# List ALL the needed packages here
list.of.packages <- c(
  "dplyr",
  "tidyr",
  "zoo",
  "ggplot2",
  "ggthemes",
  "roll",
  "openxlsx", 
  "modelr",
  "Matrix"
)

# List all packages that are *not* installed
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]

# Proceeds to install missing packages
if(length(new.packages) > 0){
  install.packages(new.packages, dep=TRUE, lib = Sys.getenv("R_LIBS_USER"), repos = "https://cran.rstudio.com/")
}

# Finally we load all the listed packages
for(package.i in list.of.packages){
  suppressPackageStartupMessages(
    library(
      package.i, 
      character.only = TRUE
    )
  )
}

