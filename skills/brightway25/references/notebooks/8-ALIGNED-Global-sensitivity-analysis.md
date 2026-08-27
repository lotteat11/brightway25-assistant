# Notebook 8 — Global sensitivity analysis

Correlation analysis, then FAST via SALib. First-order vs total-order indices.

**Assumes:** Notebooks 5–7. Variance decomposition, conceptually.

This file carries the actual code from the notebook, so you can answer questions,
adapt the patterns, and debug without the notebook being open.

---

## What trips people up

**S1 vs ST**  
First-order is the parameter alone; total-order includes interactions. **ST > S1 means interaction effects** — that is the interpretive point of the whole notebook.

**Nobody is expected to derive FAST**  
They are expected to interpret it. Worth saying out loud; some assume they need the mathematics.

**GSA needs far more model runs than OAT**  
That is the cost of exploring the whole parameter space rather than one point.

**Does the GSA ranking agree with the OAT ranking?**  
If not, why not — that comparison is the payoff of doing both.

> In the course example `par3` (product required during the use stage) dominates, S1 = 0.934.

---

## The notebook, cell by cell

### Global Sensitivity Analysis

This is a more complex case. Involves varying multiple parameters together and understanding which parameter is the one with the largest influence on results. This translates into a large simulation testing the various possibilities. One could use brute force and test all possible combinations of all parameters, and then run a regression on the results where the dependent variable is the impact of the system and the independent variables are the parameters. However, calculating a result for every possible combination might end up taking too much computation time, especially if the number of tested variables is high.

#### Correlation Analysis

The content below shows how to perform a simple Global Sensitivity Analysis (GSA) for a example product system of a biobased product and using correlation analysis to quantify the defree of sensitivity.

```python
# Import brightway2.5 packages
import bw2calc as bc
import bw2data as bd
import numpy as np
import pandas as pd
from scipy import stats
from lci_to_bw2 import * # import all the functions of this module
```

```python
bd.projects.set_current('advlca25') # Still working in the same project
bd.databases
```

We start by importing data about a fictional ("dummy") product system for a biobased product.

```python
# Import the dummy product system

# import data from csv

#mydata = pd.read_csv('LCI1-bw-format.csv', header = 0, sep = ",") # using csv file avoids encoding problem
mydata = pd.read_csv('ALIGNED-LCI-biobased-product-dummy.csv', header = 0, sep = ",") # using csv file avoids encoding problem
mydata.head()

# keep only the columns not needed
mydb = mydata[['Activity database','Activity code','Activity name','Activity unit','Activity type',
               'Exchange database','Exchange input','Exchange amount','Exchange unit','Exchange type',
               'Exchange uncertainty type','Exchange loc','Exchange scale','Exchange negative', 'Exchange minimum', 'Exchange maximum', 
               'Simapro name',	'Simapro unit', 'Simapro type']].copy()

mydb['Exchange uncertainty type'] = mydb['Exchange uncertainty type'].fillna(0).astype(int) # uncertainty as integers
# Note: to avoid having both nan and values in the uncertainty column I use zero as default

#print(mydb.head())
```

```python
# Create dictionary in bw format and write database to disk. 
# Shut down all other notebooks using the same project before doing this
bw2_db = lci_to_bw2(mydb) # a function from the lci_to_bw2 module

# write database
bd.Database('ALIGNED-biob-prod-dummy').write(bw2_db)
```

The product system includes different activities such as the production, use, and end of life of the biobased product.

```python
# check what foreground activities are included
for act in bd.Database('ALIGNED-biob-prod-dummy'):
    print(act, act['code'])
```

```python
# More info 
myact = bd.Database('ALIGNED-biob-prod-dummy').get('f9eabf64-b899-40c0-9f9f-2009dbb0a0b2') # Biobased-product-use
myact._data
```

```python
# Uncertainty is also there
list(myact.exchanges())[1]._data
```

We calculate a nominal climate impact score for the fictional biobased product, to be used for reference later on.

```python
# calculation of nominal LCA score
mymethod = ('ecoinvent-3.11', 'IPCC 2021', 'climate change: fossil', 'global warming potential (GWP100)')
myact = bd.Database('ALIGNED-biob-prod-dummy').get('f9eabf64-b899-40c0-9f9f-2009dbb0a0b2') # Biobased-product-use
functional_unit = {myact: 1}
LCA = bc.LCA(functional_unit, mymethod)
LCA.lci()
LCA.lcia()
print(LCA.score)
```

##### Now perform global sensitivity analysis

The procedure is in three steps.

1) A set of model input parameters is chosen. These are **values of specific exchanges**. A sample of values is produced for each model input, in this case, only 5 values.
2) A simulation is performed. Initial prameter values are substituted with those in the sample, iteratively, and new model outputs, that are LCA scores, are calculated.
3) A correlation is estimated between model input values and output values.

###### Step 1

A sample of values for each parameter.

```python
# Can be done in many ways, here very basic using lists.
par1_values = [-1.25, -1.10, -1, -0.9, -0.75] # In bomass growth, value of CO2 uptake
par2_values = [0.1, 0.3, 0.5, 0.7, 0.9] # In biomass processing, amount of energy used.
par3_values = [20,30,40,50,60]  # In use of product, amount of manufactured product needed
par4_values = [1.25, 1.10, 1, 0.9, 0.75] # In use of product, amount of manufactured product needed
```

Associate the values to specific exchanges using the coordinates (column and row) of the technosphere (A) and biosphere (B) matrices

```python
param_samples = [(('ALIGNED-biob-prod-dummy', 'a7d34649-9c10-4423-bac3-ecab9b43b20c'), 
  ('ecoinvent-3.11-biosphere','349b29d1-3e58-4c66-98b9-9d1a076efd2e'), par1_values), # In bomass growth, value of CO2 uptake
(('ALIGNED-biob-prod-dummy', '403a5c32-c769-46fc-8b9a-74b8eb3c79d1'),
 ('ecoinvent-3.11-consequential','a69490974731f9da34043d5c926cd167'), par2_values), # In biomass processing, amount of energy used.
 (('ALIGNED-biob-prod-dummy', 'f9eabf64-b899-40c0-9f9f-2009dbb0a0b2'),
  ('ALIGNED-biob-prod-dummy', 'a37d149a-6508-4563-8af6-e5a39b4176df'), par3_values), # In use of product, amount of manufactured product needed
  (('ALIGNED-biob-prod-dummy', 'c8301e73-d521-4a89-998b-30b7e7751011'),
   ('ecoinvent-3.11-biosphere','349b29d1-3e58-4c66-98b9-9d1a076efd2e'), par4_values)] # In end of life, amount of CO2 released
```

###### (technical note)

We can do the same in a more elegant way, taking the data directly from the BW database that we just created...

```python
# In biomass growth, value of CO2 uptake
par1 = list(bd.Database('ALIGNED-biob-prod-dummy').get('a7d34649-9c10-4423-bac3-ecab9b43b20c').exchanges())[3]
# In biomass processing, amount of energy used.
par2 = list(bd.Database('ALIGNED-biob-prod-dummy').get('403a5c32-c769-46fc-8b9a-74b8eb3c79d1').exchanges())[1]
# In use of product, amount of manufactured product needed
par3 = list(bd.Database('ALIGNED-biob-prod-dummy').get('f9eabf64-b899-40c0-9f9f-2009dbb0a0b2').exchanges())[1]
# In use of product, amount of manufactured product needed
par4 = list(bd.Database('ALIGNED-biob-prod-dummy').get('c8301e73-d521-4a89-998b-30b7e7751011').exchanges())[2]

n_iter = 5
param_samples = [(par1['output'],par1['input'], par1.random_sample(n = n_iter)),
                 (par2['output'],par2['input'], par2.random_sample(n = n_iter)),
                 (par3['output'],par3['input'], par3.random_sample(n = n_iter)),
                 (par4['output'],par4['input'], par4.random_sample(n = n_iter))]
```

Let's look at the samples obtained

```python
param_samples
```

###### Step 2

Iteration through all parameter samples. Input values are replaced and new impact scores are calculated at each iteration.

```python
# testing the loop that will be used for the simulation, iterate through parameter values
    
for i in range(0,n_iter): # iterate 5 times...
    for s in param_samples: # and for each paramater...
        
        # Get the 'id' using the activity object
        col_id = bd.Database(s[0][0]).get(s[0][1]).id
        row_id = bd.Database(s[1][0]).get(s[1][1]).id
        
        # Use the id and the mapping dictionaries to find matrix row and columns
        if s[1][0] == 'ecoinvent-3.11-biosphere':
            col = LCA.dicts.activity[col_id] # find column index of A matrix for the activity
            row = LCA.dicts.biosphere[row_id] # find row index of B matrix for the exchange
            print(f"biosphere value: {LCA.biosphere_matrix[row,col]} | paramater value: {s[2][i]}")
        else:
            col = LCA.dicts.activity[col_id] # find column index of A matrix for the activity
            row = LCA.dicts.activity[row_id] # find row index of A matrix for the exchange
            print(f"technosphere value: {LCA.technosphere_matrix[row,col]} | paramater value: {-s[2][i]}") # CHANGE OF SIGN!
        
    print("* * *")
```

```python
# Implementing the loop
import copy # a library helps to save the original matrices

GSA_value_results = []

for i in range(0,n_iter): 
    LCA.lci()
    LCA.lcia()
    print("initial value", LCA.score)
    
    old_bio_matrix = copy.deepcopy(LCA.biosphere_matrix)
    old_tech_matrix = copy.deepcopy(LCA.technosphere_matrix)
    
    for s in param_samples:
        col_id = bd.Database(s[0][0]).get(s[0][1]).id
        row_id = bd.Database(s[1][0]).get(s[1][1]).id

        if s[1][0] == 'ecoinvent-3.11-biosphere':
            col = LCA.dicts.activity[col_id] # find column index of A matrix for the activity
            row = LCA.dicts.biosphere[row_id] # find row index of B matrix for the exchange
            new_bio = s[2][i]
            LCA.biosphere_matrix[row,col] = new_bio # substitute the value
        else:
            col = LCA.dicts.activity[col_id] # find column index of A matrix for the activity
            row = LCA.dicts.activity[row_id] # find row index of A matrix for the exchange
            new_tech = -s[2][i]
            LCA.technosphere_matrix[row,col] = new_tech # substitute the value
                
    LCA.redo_lci() # uses the new A matrix
    LCA.lcia()
    GSA_value_results.append(LCA.score)
    print('end value', LCA.score)
    print("---")

    # Restore the original matrices
    LCA.biosphere_matrix = old_bio_matrix
    LCA.technosphere_matrix = old_tech_matrix
```

###### Step 3

Now we have both the input and output values and we can look at their correlation.

To estimate the degree of correlation use a Pearson coefficient of linear relationship between two sets of values.

See here for info: 
https://en.wikipedia.org/wiki/Pearson_correlation_coefficient
https://docs.scipy.org/doc/scipy/reference/generated/scipy.stats.pearsonr.html

This approach has for example been used in:

_Kim, A., Mutel, C., Froemelt, A., 2021. Robust high-dimensional screening. Environmental Modelling & Software 105270._ https://doi.org/10.1016/j.envsoft.2021.105270

```python
# calcualte correlation

corr_data = pd.DataFrame([i[2] for i in param_samples], index = ['par1','par2', 'par3', 'par4']).T
corr_data['GWI'] = GSA_value_results
corr_data.corr()
```

In this specific case "par3"  is the parameter to which the results are most sensitive to.

```python
# what was "par3" again?
par3 # amount of manufactured product need din the use stage
```

#### FAST

The content below shows how to perform a simple Global Sensitivity Analysis (GSA) applying the FAST, a variance-based sensitivity analysis method, for an example product system of a biobased product.

Special thanks to _Pierre Jouannais_ for developing an early version of this tutorial.

```python
# importing packages
import bw2calc as bc
import bw2data as bd
import pandas as pd
import numpy as np
from scipy import stats
from lci_to_bw2 import * # import all the functions of this module
```

```python
# open a project with ecoinvent v.3.9.1 consequential system model
bd.projects.set_current('advlca25')
```

We start by importing data about a fictional ("dummy") product system for a biobased product.

```python
# Import the dummy product system

# import data from csv
mydata = pd.read_csv('ALIGNED-LCI-biobased-product-dummy.csv', header = 0, sep = ",") # using csv file avoids encoding problem
mydata.head()

# keep only the columns not needed
mydb = mydata[['Activity database','Activity code','Activity name','Activity unit','Activity type',
               'Exchange database','Exchange input','Exchange amount','Exchange unit','Exchange type',
               'Exchange uncertainty type','Exchange loc','Exchange scale','Exchange negative', 'Exchange minimum', 'Exchange maximum', 
               'Simapro name',	'Simapro unit', 'Simapro type']].copy()

mydb['Exchange uncertainty type'] = mydb['Exchange uncertainty type'].fillna(0).astype(int) # uncertainty as integers
# Note: to avoid having both nan and values in the uncertainty column I use zero as default

#print(mydb.head())
```

```python
# Create dictionary in bw format and write database to disk. 
# Shut down all other notebooks using the same project before doing this
bw2_db = lci_to_bw2(mydb) # a function from the lci_to_bw2 module

# write database
bd.Database('ALIGNED-biob-prod-dummy').write(bw2_db)
```

The product system includes different activities such as the production, use, and end of life of the biobased product.

```python
# check what foreground activities are included
for act in bd.Database('ALIGNED-biob-prod-dummy'):
    print(act, act['code'])
```

```python
# More info 
myact = bd.Database('ALIGNED-biob-prod-dummy').get('f9eabf64-b899-40c0-9f9f-2009dbb0a0b2') # Biobased-product-use
myact._data
```

```python
# Uncertainty is also there
list(myact.exchanges())[1]._data
```

We calculate a static climate impact score for the fictional biobased product, to be used for reference later on.

```python
# calculation of static LCA score
mymethod = ('ecoinvent-3.11', 'IPCC 2021', 'climate change: fossil', 'global warming potential (GWP100)')
myact = bd.Database('ALIGNED-biob-prod-dummy').get('f9eabf64-b899-40c0-9f9f-2009dbb0a0b2') # Biobased-product-use
functional_unit = {myact: 1}
LCA = bc.LCA(functional_unit, mymethod)
LCA.lci()
LCA.lcia()
print(LCA.score)
```

##### Now perform sensitivity analysis

The procedure is in three steps.

1) A set of model input parameters is chosen. These are **values of specific exchanges**. A sample of values is produced for each model input **using a specific and efficient sampling design** (the **"problem"** below)
2) A simulation is performed. Initial prameter values are substituted with those in the sample, iteratively, and new model outputs, that are LCA scores, are calculated.
3) **A sensitivity index is calculated** using model input values (the "problem") and output values.

###### Step 1

Obtain a sample of values for each parameter.

This is a  pseudo-random sample obtained using a sampling method from the SALib package on the problem previously defined.

it is defined as a __FAST__ sample ("Fourier Amplitude Sensitivity Analysis"), another alternative to Sobol method.

Sobol and FAST sampling methods use different pseudo-random patterns to cover the space of parameters, and different calculations for the sensitivity indices.

Besides these differences, the (extended) FAST method is, just like the Sobol one, a variance-based method for sensitivity analysis. It provides the same information as the Sobol method but with higher computational efficiency.

For further information and comparison see: 

_Saltelli, A.; Tarantola, S.; Chan, K. P. S. A Quantitative Model-Independent Method for Global Sensitivity Analysis of Model Output. Technometrics 1999, 41 (1), 39–56._ https://doi.org/10.1080/00401706.1999.10485594.

Before you run the next cell __you need to install the SALib library!__

Please do `conda install SALib` in the brightway environment´

```python
# need to import the SALib library and relaive methods for sensitvity analysis
# do 'conda install SALib' in the brightway environment

from SALib.sample import saltelli
from SALib.sample import fast_sampler
from SALib.analyze import sobol
from SALib.analyze import fast
```

Define the "problem" for the GSA analysis as indicated in the SALib library.
Uniform distributions for the uncertainty of for each input parameter are here assumed.

```python
problem = { 'num_vars': 4, # number of variables
            'names': ['par1', 'par2', 'par3', 'par4'], # names of variables, same as parameters
            'bounds': [[-1.25, -0.75], # careful here to what is the lower bound with negative values...
                       [0.1, 0.9],  
                       [20, 60],
                       [0.75, 1.25]] ,
           'dists':["unif","unif","unif","unif"] } # all uniform distributions
```

```python
# FAST sampler creates N*P parameters sets with N=sample size, P = number of parameters
param_values_FAST = fast_sampler.sample(problem, 200)
print(param_values_FAST.shape)

param_values_FAST
```

Associate the values to specific exchanges using the coordinates (column and row) of the technosphere (A) and biosphere (B) matrices, taking the data directly from the BW database that we just created.

```python
# In biomass growth, value of CO2 uptake
par1 = list(bd.Database('ALIGNED-biob-prod-dummy').get('a7d34649-9c10-4423-bac3-ecab9b43b20c').exchanges())[3]
# In biomass processing, amount of energy used.
par2 = list(bd.Database('ALIGNED-biob-prod-dummy').get('403a5c32-c769-46fc-8b9a-74b8eb3c79d1').exchanges())[1]
# In use of product, amount of manufactured product needed
par3 = list(bd.Database('ALIGNED-biob-prod-dummy').get('f9eabf64-b899-40c0-9f9f-2009dbb0a0b2').exchanges())[1]
# In use of product, amount of manufactured product needed
par4 = list(bd.Database('ALIGNED-biob-prod-dummy').get('c8301e73-d521-4a89-998b-30b7e7751011').exchanges())[2]

n_iter = len(param_values_FAST)
param_samples = [(par1['output'],par1['input'], [i[0] for i in param_values_FAST]),
                 (par2['output'],par2['input'], [i[1] for i in param_values_FAST]),
                 (par3['output'],par3['input'], [i[2] for i in param_values_FAST]),
                 (par4['output'],par4['input'], [i[3] for i in param_values_FAST])]
```

###### Step 2

Iteration through all parameter samples. New LCA scores are calculated for each combination of values.

With 800 iterations, **this will take some time**

```python
# Implementing the loop (This cell will take some time to run)
import copy # a library helps to save the original matrices

GSA_value_results = []

for i in range(0,len(param_values_FAST)): 
    LCA.lci()
    LCA.lcia()
    print("initial value", LCA.score)
    
    old_bio_matrix = copy.deepcopy(LCA.biosphere_matrix)
    old_tech_matrix = copy.deepcopy(LCA.technosphere_matrix)
    
    for s in param_samples:
        # Get the 'id' using the activity object
        col_id = bd.Database(s[0][0]).get(s[0][1]).id
        row_id = bd.Database(s[1][0]).get(s[1][1]).id
        
        # Use the id and the mapping dictionaries to find matrix row and columns
        if s[1][0] == 'ecoinvent-3.11-biosphere':
            col = LCA.dicts.activity[col_id] # find column index of A matrix for the activity
            row = LCA.dicts.biosphere[row_id] # find row index of B matrix for the exchange
            LCA.biosphere_matrix[row,col] = s[2][i] # substitute the value
        else:
            col = LCA.dicts.activity[col_id] # find column index of A matrix for the activity
            row = LCA.dicts.activity[row_id] # find row index of A matrix for the exchange
            LCA.technosphere_matrix[row,col] = -s[2][i] # substitute the value
        
    LCA.redo_lci() # uses the new A matrix
    LCA.lcia()
    GSA_value_results.append(LCA.score)
    print('end value', LCA.score)
    print("---")

    # Restore original matrices
    LCA.biosphere_matrix = old_bio_matrix
    LCA.technosphere_matrix = old_tech_matrix
```

###### Step 3

Now we have both the input and output values and we can feed the problem and the results to the Sobol function to obtain the FAST indices.

First we look at the parameters and the result

```python
# Organize data first to give a look at what we have done: a sample of input values and a corresponding output value
fast_data = pd.DataFrame([i[2] for i in param_samples], index = ['par0','par1', 'par2', 'par3']).T
fast_data['GWI'] = GSA_value_results
fast_data.head(10) # show only the first ten samples
```

Now we calculate the SI index

```python
si = fast.analyze(problem, np.array(GSA_value_results), print_to_console=True) # must use np.array
```

In this specific case "par3"  is the parameter to which the results are most sensitive to, this because it has the highest value for "S1" which is the first order effect.

This is determined with relativelygood confidence as the error (value of "S1_conf") is small compared to the coefficient.

Note also that "par3" is also the parameter withi highest sensitivity in the total model, i.e. when in combinatino with other parameters, as observed by the highest value of "ST".

```python
# In this specific case "par3" is the parameter to which the results ar emost sensitive to, and values have high confidente (small error)
# what was "par3" again?
par3 # amount of manufactured product need din the use stage
```
