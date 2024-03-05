"""
.. module: utils
    :synopsis: input-output functions and general utilities
.. moduleauthor:: Samuli Launiainen

"""
import os
import numpy as np
import pandas as pd
from .litter import tree_litter_flux

def get_datasets(dir_path):
    """
    Reads Alm et al. 2023 Zenodo-datasets and returns dataframes.
    
    Args:
        dir_path
    """

    weather_file = r'weather_data.csv'
    ba_file = r'basal_areas.csv'
    treebm_file = r'biomass.csv'
    area_file = r'total_area.csv'
    residue_file = r'dead_litter.csv' 

    # read data. All have format 'region', 'peat_type', 'year', 'variables
    weather = pd.read_csv(os.path.join(dir_path, weather_file), sep=';')
    basal_areas = pd.read_csv(os.path.join(dir_path, ba_file), sep=';')
    biomass = pd.read_csv(os.path.join(dir_path, treebm_file), sep=';')
    ftype_areas = pd.read_csv(os.path.join(dir_path, area_file), sep=';')
    residue_litter = pd.read_csv(os.path.join(dir_path, residue_file), sep=';')


    biomass.rename(columns={'tkg': 'peat_type', 'species': 'tree_type'}, inplace=True)

    biomass['region'].replace({1: 'south', 2: 'north'}, inplace=True)
    biomass['tree_type'].replace({1: 'pine', 2: 'spruce', 3: 'deciduous'}, inplace=True)

    litter, tot_litter = tree_litter_flux(biomass)

    return litter, tot_litter#, biomass, basal_areas, ftype_areas, residue_litter, weather

