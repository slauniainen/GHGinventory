"""
.. module: litter
    :synopsis: functions for estimating litter inputs from stand attributes and peatland fertility type
.. moduleauthor:: Samuli Launiainen

References:
    Alm et al. 2023. Biogeosci.
    Ojanen et al. 2014. For. Ecol. Manag.
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

def tree_litter_flux(bm: pd.DataFrame):
    """
    Annual litter fall from living trees [g C m-2 a-1]. Uses turnover-rates from Alm et al. 2023 Table 5
    Args:
        region - 'north', 'south'
        species - 'pine', 'spruce', 'deciduous'
        bm - dataframe with annual biomasses per component [t ha-1 of dry mass]
    Returns:
        tree litter flux [g C m-2 a-1] in pd.DataFrame
    """
    cfact = 0.5 # conversion from dry mass to carbon
    
    afact = 1e6 / (100 * 100)

    #components = {1: 'stemwood', 2: 'bark', 3: 'live branch', 4: 'foliage', 5: 'dead branch', 6: 'stump', 7: coarse roots'}
    turnover = {'pine': {1: 0.0052, 2: 0.0052, 3: 0.02, 4: 0.33, 5: 0.02, 6: 0.0029, 7: 0.0184}, # pine
                'spruce': {1: 0.0027, 2: 0.0027, 3: 0.0125, 4: {'south': 0.1, 'north': 0.05}, 5: 0.0125, 6: 0.0015, 7: 0.0125}, # spruce: foliage turnover differs south/north
                'deciduous': {1: 0.0029, 2: 0.0029, 3: 0.0135, 4: 0.79, 5: 0.0135, 6: 0.0001, 7: 0.0135} # decid
               }

    comp = bm.columns.to_list()

    F = bm.copy()
    F.rename(columns={'bm': 'litter'}, inplace=True)
    F['litter'] = np.NaN

    for k in range(len(bm)):
        M = bm['bm'].iloc[k]
        region = bm['region'].iloc[k]
        species = bm['tree_type'].iloc[k]
        
        c = bm['component'].iloc[k]

        if species == 'spruce' and c == 4: # spruce
            ft = turnover[species][c][region]
        else:
            ft = turnover[species][c]

        F['litter'].iloc[k] = afact * cfact * M * ft
        del ft

    # return annual total litterfall per species
    regs = F['region'].unique()
    ftypes = F['peat_type'].unique()
    yrs = F['year'].unique()
    trees = F['tree_type'].unique()
    
    rows = len(regs)*len(ftypes)*len(yrs)*len(trees)
    cols = ['region', 'peat_type', 'tree_type', 'year', 'litter']

    Ftot = pd.DataFrame(columns=cols, data=np.zeros((rows, len(cols))))
    k = 0
    for r in regs:
        for f in ftypes:
            for tr in trees:
                for yr in yrs:
                    mask = (F['region'] == r) & (F['peat_type'] == f) & (F['tree_type'] == tr) & (F['year'] == yr)
                    Ftot['region'][k] = r
                    Ftot['peat_type'][k] = f
                    Ftot['tree_type'][k] = tr
                    Ftot['year'][k] = yr
                    Ftot['litter'][k] = F['litter'].loc[mask].sum()
                    k += 1

    for c in ['peat_type']:
        Ftot[c] = Ftot[c].astype(int)

    return F, Ftot

def estimate_root_gw_litter(data):

    N = len(data)
    lit = data.copy()
    lit['gw_litter'] = np.zeros(N)
    lit['root_litter'] = np.zeros(N)

    for k in range(N):
        lit['root_litter'][k] = fineroot_litter_flux(region=data['region'][k], ftype=data['peat_type'][k], 
                                                     BApine=data['BApine'][k], BAspruce=data['BAspruce'][k],
                                                     BAdecid=data['BAdeciduous'][k]
                                                     )
    
        lit['gw_litter'][k] =  ground_vegetation_litter_flux(data['peat_type'][k], data['BA'][k])
  
    return lit

def fineroot_litter_flux(region: str, ftype: int, BApine: float, BAspruce: float, BAdecid: float):
    """
    Annual fine root (tree + dwarf shrubs) litter production [g DM m-2 a-1]. Combines Table 3 & 6 in Alm et al. 2023.

    Args:
        region - 'north', 'south'
        ftype - site fertility type code
        BAspruce - m2 ha-1
        BAdecid - m2 ha-1
    Returns:
        fine root litter flux [g C m-2 a-1]
    """
    cfact = 0.5
    turnover = {1: 0.3, 2: 0.5, 4: 0.7, 6: 0.2, 7: 0.2} # fine root runover rate for each ftype [a-1]
    shrub_coverage = {1: 7.0, 2: 15.0, 4: 32.0, 6: 45.0, 7: 40.0} # shrub coverage for each ftype [%]

    a0 ={'south': 120.0, 'north': -53.2}
    
    rootmass = a0[region] + 8.80 * BApine + 6.61 * BAspruce + 17.3 * BAdecid + 4.81 * shrub_coverage[ftype]
    F = cfact * rootmass * turnover[ftype]

    return F

def ground_vegetation_litter_flux(ftype: int, BA:float):
    """
    Annual ground vegetation litter flux (excl. dwarf shrub fine root litter) [g C m-2 a-1]
    
    Args:
        ftype - site fertility type code
        BA - stand basal area [m2 ha-1]
    Returns:
        ground veget. litter flux [g C m-2 a-1]
    """
    cfact = 0.5
    a0 = {1: 227.0, 2: 227.0, 4: 256.0, 6: 298.0, 7: 187.0}

    F = cfact * (a0[ftype] - 4.52 * BA)

    return F
