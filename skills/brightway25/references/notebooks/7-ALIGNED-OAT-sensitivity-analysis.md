# Notebook 7 — Local (one-at-a-time) sensitivity analysis

Perturb each foreground parameter by 10%, recompute, rank by sensitivity ratio.

**Assumes:** Notebooks 1–5.

This file carries the actual code from the notebook, so you can answer questions,
adapt the patterns, and debug without the notebook being open.

---

## What trips people up

**OAT results are local, not global**  
The notebook says so outright — the effect of changing one parameter can be entirely different when the others sit at different values. A clean ranked table looks definitive and invites over-generalisation. **This warning is the pedagogical point** and the bridge to notebook 8.

**Modifying the matrix then recalculating**  
`lca.technosphere_matrix[row, col] = value` then `redo_lci()` and `lcia()`. Order matters.

**Only foreground parameters are perturbed**  
Background uncertainty does not show up. Worth flagging if someone is surprised.

> The question to ask afterwards: what happens to this ranking if two parameters are both at the high end of their range? OAT never visits that corner — which makes GSA in notebook 8 arrive as the answer to a question they already have.

---

## The notebook, cell by cell

### One At the Time (OAT) Sensitivity analysis

This is the simplest case. Also called a _local_ Sensitivity analysis. One parameter is changed by keeping all the other constant and the difference in results is compared to the change. This allows to investigate how much results are affected by the specific change in the parameter. This is good for some types of analysis, but has some problems. Main issue is that the effect of a change in the parameter might be different when other parameters assume different values...so OAT can be misleading!  This problem can only be solved with a global sensitivity analysis (next notebook)

This notebook show how to perform a simple One A Time (OAT) sensitivity analysis for a example product system of a biobased product, and calculated sensitivity ratios for each parameter.

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

The product system includes different activities such as the production, use, and end of life of the biobased product.

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

# Create dictionary in bw format and write database to disk. 
# Shut down all other notebooks using the same project before doing this
bw2_db = lci_to_bw2(mydb) # a function from the lci_to_bw2 module

# write database
bd.Database('ALIGNED-biob-prod-dummy').write(bw2_db)

# check what foreground activities are included
for act in bd.Database('ALIGNED-biob-prod-dummy'):
    print(act, act['code'])
```

```python
# More info 
myact = bd.Database('ALIGNED-biob-prod-dummy').get('f9eabf64-b899-40c0-9f9f-2009dbb0a0b2') # Biobased-product-use
myact._data
```

We calculate a static climate impact score for the fictional biobased product, to be used for reference later on.

```python
# calculation of nominal LCA score
mymethod = ('ecoinvent-3.11', 'IPCC 2021', 'climate change: fossil', 'global warming potential (GWP100)')
myact = bd.Database('ALIGNED-biob-prod-dummy').get('f9eabf64-b899-40c0-9f9f-2009dbb0a0b2') # Biobased-product-use
functional_unit = {myact: 1}
LCA = bc.LCA(functional_unit, mymethod)
LCA.lci()
LCA.lcia()
print("The nominal Global Warming impact score is", LCA.score, bd.methods[mymethod]['unit'])
```

##### Now perform sensitivity analysis

The procedure is in **two steps**: 

1) A simulation is performed where the initial parameter (value of each exchange) is increased by 10%. New results are calculated. 

2) Sensitivity rations are calculated for each parameter and then ranked.

###### Step 1

Iteration through all parameters, change the technology matrix and recaltulate results.

```python
mymethod = ('ecoinvent-3.11', 'IPCC 2021', 'climate change: fossil', 'global warming potential (GWP100)')
myact = bd.Database('ALIGNED-biob-prod-dummy').get('f9eabf64-b899-40c0-9f9f-2009dbb0a0b2') # Biobased-product-use
functional_unit = {myact: 1}
LCA = bc.LCA(functional_unit, mymethod)

act = list(bd.Database('ALIGNED-biob-prod-dummy'))[0]
exc = list(act.exchanges())[0]

LCA.lci()
LCA.lcia()
```

```python
# Iterate through all exchanges in the foreground system and change the value up by 10%
par_name = []
par_values = []
par_upper_values = []
score_values = []
OAT_values  = []

mymethod = ('ecoinvent-3.11', 'IPCC 2021', 'climate change: fossil', 'global warming potential (GWP100)')
myact = bd.Database('ALIGNED-biob-prod-dummy').get('f9eabf64-b899-40c0-9f9f-2009dbb0a0b2') # Biobased-product-use
functional_unit = {myact: 1}
LCA = bc.LCA(functional_unit, mymethod)

for act in bd.Database('ALIGNED-biob-prod-dummy'): # for all activities...
    for exc in act.exchanges(): # for all exchanges...
        LCA.lci()
        LCA.lcia()
        print("initial value", LCA.score)
        
        par_name.append((act['code'], exc['input'][1]))
        par_values.append(exc['amount'])
        par_upper_values.append(exc['amount'] * 1.1)
        score_values.append(LCA.score)

        # Get the 'id' using the activity object
        col_id = bd.Database(exc['output'][0]).get(exc['output'][1]).id
        row_id = bd.Database(exc['input'][0]).get(exc['input'][1]).id

        # Use the id and the mapping dictionaries to find matrix row and columns
        if exc['type'] == "biosphere":
            col = LCA.dicts.activity[col_id] # find column index of A matrix for the activity
            row = LCA.dicts.biosphere[row_id] # find row index of B matrix for the exchange
            
            old_bio = LCA.biosphere_matrix[row,col]
            new_bio = LCA.biosphere_matrix[row,col] * 1.1
            LCA.biosphere_matrix[row,col] = new_bio 
        else:
            col = LCA.dicts.activity[col_id] # find column index of A matrix for the activity
            row = LCA.dicts.activity[row_id] # find row index of A matrix for the exchange
            
            old_tech = LCA.technosphere_matrix[row,col]
            new_tech = LCA.technosphere_matrix[row,col] * 1.1
            LCA.technosphere_matrix[row,col] = new_tech
            
        LCA.redo_lci() # uses the new A matrix
        LCA.lcia()
        OAT_values.append(LCA.score)
        print('end value', LCA.score)
        print("---")

        # Restore original matrices, so that we can have the same inital value each iteration.
        if exc['type'] == "biosphere":
            LCA.biosphere_matrix[row,col] = old_bio
        else:
            LCA.technosphere_matrix[row,col] = old_tech
```

Let's look at the results. 

Initial and increased ('upper') parameter values and initial and end values of the Global Warming Impact (GWI) scores.

```python
sr = pd.DataFrame([par_name, par_values, par_upper_values, score_values, OAT_values], 
                  index = ['par_name','par_initial', 'par_upper', 'GWI_initial', 'GWI_end']).T
sr.head()
```

###### Step 2

**Sensitivity ratios** (SR) are calculated using the formula for discrete distributions, see equation (2) in Bisinella et al. (2016) 

_Bisinella, V., Conradsen, K., Christensen, T.H., Astrup, T.F., 2016. A global approach for sparse representation of uncertainty in Life Cycle Assessments of waste management systems. International Journal of Life Cycle Assessment._ https://doi.org/10.1007/s11367-015-1014-4

```python
# calcualte sensitivity ratios
sr['SR'] = ((sr['GWI_end']-sr['GWI_initial'])/sr['GWI_initial']) / ((sr['par_upper']-sr['par_initial'])/sr['par_initial']) 

sr['SR_abs'] = abs(sr['SR'])
```

```python
sr.head()
```

We can rank the parameters to see the most sensitive ones. I use the absolute value of SR in this case.

```python
sr_sorted = sr.sort_values('SR_abs', ascending = False, ignore_index = True).copy() # important to re-index...
sr_sorted
```

What are the most sensitive parameters in plain English?

```python
#scroll through the table, identify the specific exchanges.
testing = []

for i in range(0, sr_sorted.shape[0]):
    
    par = sr_sorted.iloc[i,0] 
    
    for i in bd.Database('ALIGNED-biob-prod-dummy').get(par[0]).exchanges():
        if i['input'][1] == par[1]:
            print(i)
            testing.append(str(i))
```

```python
sr_sorted['par_long-name'] = testing
sr_sorted
```
