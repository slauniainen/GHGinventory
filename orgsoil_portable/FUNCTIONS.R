# Assisting functions go here.
# Prefix all functions with FUNC_

# This function takes data in the "wide" format and converts it to "longW"
# Input parameters: 
# wide_table - the table to be transformed. 
# value_name - name to be used for the value column in the new table

FUNC_longify <- function(wide_table, value_name) {
  converted_to_long <- 
    wide_table %>% 
    pivot_longer(
      cols = starts_with("X"),
      names_to = "year", values_to = value_name) %>%
    # Remove the X prefix from years and convert to number
    mutate(year = as.numeric(sub("X", "", year)))
  # Return 
  converted_to_long
}

# Reverse %in%, can be read "not in"
'%ni%' <- Negate('%in%')

# This function reads data in a uniform fashion. Expsep = exceptional separator

FUNC_read_file <- function(path) {

  read_data <- read.csv2(file = path, 
                         dec = ".", 
                         header = TRUE,
                         sep = ";", 
                         stringsAsFactors = FALSE)
  # return data
  read_data
}

# This function simply writes data to disk in a uniform fashion

FUNC_save_output <- function(data, path) {
  
  write.table(x = data,
              file = path, 
              row.names = FALSE, 
              quote = FALSE, 
              col.names = TRUE, 
              sep =";")
  print(paste("Saved output to: ", path), sep = "")
}


# This file contains an R-function of Yasso07. The version is
# based on matrix-version created by Jaakko Heikkinen with Matlab and
# Yasso07 description by Tuomi & Liski 17.3.2008  (Yasso07.pdf)
# Created by Taru Palosuo, Jaakko Heikkinen & Anu Akuj?rvi in December 2011
# Further modified for compatibility with dplyr/tidyverse by JP Myllykangas in March 2023

#  Instructions  IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII

# 1) first run the source code for the function with "source(R.Yasso_111205.r)"
# 2) then you can use the yasso07-function by just calling it yasso07(..)
# 3) Input needed for the function:
#        1. MeanTemperature - vector or a single value of mean annual temperatures [C], use single value for spin-up
#        2. TemperatureAmplitude - vector or a single value of temperature amplitudes [C], , use single value for spin-up
#        3. Precipitation - vecto ror a single value  of annual precipiations [mm], , use single value for spin-up
#        4. InitialCPool - vector of initial C pools of model compartments, can be either a single vector or a list of vectors. For spin-up, use single vector# 
#        5. LitterInput - litter input matrix, 5 columns x simulation years as rows, [whatever]. Typically a single {0,0,0,0,0} vector for spin-up
#        6. WoodySize - size of woody litter (for non-woody litter this is 0)
#        7. Yasso07Parameters - these in the format applied in the fortran version, length 44
#        8. SpinUP - boolean value for whether the function should run in spin-up mode or not. 
#        9. SpinUpYears - number of years for spin-up to run, only used if param 8 == TRUE

# NOTE that this function eats only one type of material at the time. So, non-woody and different woody litter
# materials needs to be calculated separately.

# The output of the function is a data frame of the C pool

# Basics  BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB

# additional R libraries (as needed)

# Function definition   FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

# The input for this function is provided as vectors, row = year

FUNC_yasso07 =  function(Climate, InitialCPool, LitterInput, WoodySize, Yasso07Parameters, SpinUp = FALSE, SpinUpYears = 0) {
  
  
  #    MeanTemperature,...                % Mean annual temperature, C
  #    TemperatureAmplitude,...           % (T_max-T_min)/2, C
  #    Precipitation,...                  % Annual rainfall, mm
  #    InitialCPool,...                   % AWENH, kg
  #    LitterInput,...                    % AWENH, kg/a
  
  MT = as.vector(Climate[,1])
  TA = as.vector(Climate[,2])
  PR = as.vector(Climate[,3])
  PR = PR/1000;               # conversion from mm to meters
  LI = matrix(unlist(LitterInput), ncol = 5, byrow = T) # Here we create a five column (AWENH) matrix from a list of vectors
  PA = Yasso07Parameters
  WS = WoodySize[1]     
  YR = length(MT)
  
  # Because the script can utilize both single vectors and lists of vectors
  if(typeof(InitialCPool) == "list") {
    InitialCPool = unlist(InitialCPool[1]) # Since these are all identical, we just extract the first row of vectors
  }
  
  alfa = c(-PA[1], -PA[2], -PA[3], -PA[4], -PA[35])   # Vector of decomposition rates
  
  # Creating the matrix A_p (here called p)
  
  row1 = c(-1, PA[5], PA[6], PA[7], 0)
  row2 = c(PA[8], -1, PA[9], PA[10], 0)
  row3 = c(PA[11], PA[12], -1, PA[13], 0)
  row4 = c(PA[14], PA[15], PA[16], -1, 0)
  row5 = c(PA[36], PA[36], PA[36], PA[36], -1)
  
  p = matrix(c(row1, row2, row3, row4, row5), 5, 5, byrow=T)  
  
  # temperature dependence parameters
  beta1 = PA[17]
  beta2 = PA[18]
  gamma = PA[26]
  
  # Woody litter size dependence parameters
  delta1 = PA[39]
  delta2 = PA[40]
  r = PA[41]
  
  LC = matrix(InitialCPool, nrow=YR + 1, ncol=5, byrow=TRUE)  # byrow added 30.10.2012! /TP
  
  for (h in 1:YR) {
    
    T1 = MT[h] + 4 * TA[h]/pi * (1/sqrt(2)-1)          # Eq. 2.4 in model description
    T2 = MT[h] - 4 * TA[h]/(sqrt(2) * pi)              # Eq. 2.5 in model description
    T3 = MT[h] + 4 *TA[h]/pi * (1-1/sqrt(2))          # Eq. 2.6 in model description
    T4 = MT[h] + 4 *TA[h]/(sqrt(2) * pi)              # Eq. 2.7 in model description 
    
    # k following Eq. 3 in Tuomi et al. 2009. Eco.Mod. 220: 3362-3371
    k=alfa*mean(exp(beta1*c(T1,T2,T3,T4)+beta2*(c(T1,T2,T3,T4)^2))*(1-exp(gamma*PR[h])))     
    
    # the effect of wl size as in Eq. 3.1 in model description
    k = c(k[1:4]*(1+delta1*WS+delta2*(WS^2))^(r),k[5])
    
    A=p%*%diag(k)                             # Matrix multiplication in R: %*%
    
    # analytical solution as in Eq. 1.3 in model description
    
    # if it's spin-up, we just insert the number of years into the equation, otherwise it's row-wise operations
    if(SpinUp) {
      LC[h+1,] = as.array(solve(A)%*% (expm(A*SpinUpYears)%*%(A%*%LC[h,]+LI[h,])-LI[h,]))
    } else {
      LC[h+1,] = as.array(solve(A)%*% (expm(A)%*%(A%*%LC[h,]+LI[h,])-LI[h,]))
    }
  }  # end of for h
  
  # Convert to data frame for tidyr/dplyr compatibility
  
  LC <- as.data.frame(LC)
  colnames(LC) <- c("A_", "W_", "E_", "N_", "H_")
  
  LC <- LC[-1,]# remove the first row since it only contains initialization data
  
  # return the end result
  LC
  
}  # end of yasso07 function


### 