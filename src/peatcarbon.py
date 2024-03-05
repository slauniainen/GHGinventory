"""
.. module: peatcarbon
    :synopsis: functions for estimating soil GHG emissions from peatlands
.. moduleauthor:: Samuli Launiainen

References:
    Ojanen et al. 2014. For. Ecol. Manag.
    Alm et al. 2023. Biogeosci.
"""
import numpy as np


def soil_respiration_flux(ftype: int, BA: float, T:float):
    """
    Annual heterotropthic respiration from peatland soil (old peat + implicit plant litter)
    Based on Ojanen et al. 2014. For. Ecol. Manag.; exact form as Alm et al. 2023 Biogeosci. Table 2

    Args:
        ftype - site fertility type code: 1  Herb-rich type; 2  Vaccinium myrtillus type; 4  Vaccinium vitis-idaea type;
                6  Dwarf shrub type; 7  Cladina type
        BA - mean stand basal area [m2 ha-1]
        T - mean (30-year running average) May-Oct air temperature
    Returns:
        Rhet - heterorophic respiration, CO2 emission from soil [g CO2 m-2 a-1]
    """

    a0 = {1: -1383.0, 2: -1440.0, 4: -1662.0, 6: -1771.0, 7: -1814.0} # intercept for each ftype [g CO2 m-2 a-1]
    a1 = 14.74 # g CO2 m-2 a-1 ha m-2
    a2 = 242.8 # g CO2 m-2 a-1 degC-1

    Rhet = a0[ftype] + a1*BA + a2*T

    # Q10
    R1 = a0[ftype] + a1*BA + a2 * (T-1)
    R2 = a0[ftype] + a1 * BA + a2 * (T + 1)
    Q10 = (R2/R1)**(10.0/2.0)

    return Rhet, Q10

def soil_nee_linear(region: str, ftype: int, BA: float, T: float):
    """
    Annual peatland soil NEE (old peat + implicit plant litter)

    Args:
        ftype - site fertility type code: 1  Herb-rich type; 2  Vaccinium myrtillus type; 4  Vaccinium vitis-idaea type;
                6  Dwarf shrub type; 7  Cladina type
        BA - mean stand basal area [m2 ha-1]
        T - mean (30-year running average) May-Oct air temperature
    Returns:
        NEEs - soil NEE [g CO2 m-2 a-1]
    """

    a0 = {1: -1383.0, 2: -1440.0, 4: -1662.0, 6: -1771.0, 7: -1814.0} # intercept for each ftype [g CO2 m-2 a-1]
    a1 = 14.74 # g CO2 m-2 a-1 ha m-2
    a2 = 242.8 # g CO2 m-2 a-1 degC-1

    # median litter production / BA ratios for 5 last years
    b = {'south': {1: 43.19, 2: 50.67, 4: 72.37, 6: 63.68, 7: 72.59},
         'north': {1: 44.60, 2: 45.45, 4: 65.08 , 6: 71.58, 7: 76.96}}
    
    NEEs = a0[ftype] + (a1 - b[region][ftype]) * BA + a2 * T

    dBA = a0[ftype] + (a1 - b[region][ftype]) *(BA + 1) + a2 * T - NEEs
    dT = a0[ftype] + (a1 - b[region][ftype]) * BA + a2 * (T + 1) - NEEs


    return NEEs, dBA, dT, dBA/NEEs, dT/NEEs
