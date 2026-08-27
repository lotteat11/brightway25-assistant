# Notebook 5 — Uncertainty propagation

Lognormal distributions on exchanges; Monte Carlo with `use_distributions=True`.

**Assumes:** Notebooks 1–2. Distributions, mean vs median.

This file carries the actual code from the notebook, so you can answer questions,
adapt the patterns, and debug without the notebook being open.

---

## What trips people up

**`loc` and `scale` are logarithms**  
`loc = np.log(amount)`, `scale = np.log(GSD)`. Setting `scale=1.2` when you meant 20% gives a wildly wrong distribution — **with no error**.

**Negative amounts must be negated before the log**  
`np.log(-fuel_exc['amount'])`. Technosphere inputs are negative and `np.log()` of a negative is undefined. Copying the CO₂ line (positive) to a fuel input (negative) gives `nan` with no clear explanation.

**The MC mean does not equal the nominal score**  
Expected, not a bug. Nominal uses geometric means; the MC mean averages a right-skewed distribution and sits higher. Compare against the **median** — it sits much closer. Let the surprise land before explaining it.

**Identical values every iteration**  
Either `use_distributions=True` was omitted, or no exchange carries uncertainty. With no uncertainty data, Monte Carlo correctly returns the deterministic result.

**The iteration idiom is opaque**  
`[mc.score for _ in zip(range(500), mc)]` — `mc` is iterable, each step redraws; `zip` with `range(500)` caps it. A plain loop with `next(mc)` is equivalent and clearer.

---

## The notebook, cell by cell

> The method key below is this course project's. For any other project, look one up:
> `[m for m in bd.methods if 'IPCC' in str(m)][:5]`.

### Run Monte Carlo Simulation in Brightway

Now we are ready to start doing more intense simulations. In particular Brightway is great to perform fast error propagation with Monte Carlo simulation. 

This script shows how to add uncertainties to your home-made product system and run a Monte Carlo simulation. 

To better understand this script, I recommend reading read Limpert et al. (2001) that explains the log-normal distribution.

_Limpert, E., Stahel, W. A., & Abbt, M. (2001). Log-normal distributions across the sciences: Keys and clues. Bioscience, 51(5), 341-352. [https://doi.org/10.1641/0006-3568(2001)051[0341:LNDATS]2.0.CO;2](https://academic.oup.com/bioscience/article/51/5/341/243981)_

A very useful resource is the book: _Heijungs, R. (2024). Probability, Statistics and Life Cycle Assessment: Guidance for Dealing with Uncertainty and Sensitivity. Springer International Publishing. [https://doi.org/10.1007/978-3-031-49317-1](https://link.springer.com/book/10.1007/978-3-031-49317-1)_

```python
# Import brightway2.5 packages
import bw2calc as bc
import bw2data as bd
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
```

```python
bd.projects.set_current('advlca25')
```

```python
bd.databases
```

A short recap, let's create a foreground database and run LCA calculations

```python
t_db = bd.Database('testdb')

t_db.write({  # A simplified version, only CO2 as emission
    ('testdb', 'Electricity production'): {
        'name': 'Electricity production',
        'unit': 'kWh',
        'location': 'GLO',
        'exchanges': [{
                'input': ('testdb', 'Fuel production'),
                'amount': -2,
                'unit': 'kg',
                'type': 'technosphere'
            }, {
                'input': ('testdb', 'Carbon dioxide'),
                'amount': 1,
                'unit': 'kg',
                'type': 'biosphere'
            }, {
                'input': ('testdb', 'Electricity production'),
                'amount': 10,
                'unit': 'kWh',
                'type': 'production'
            }]
        },
    ('testdb', 'Fuel production'): {
        'name': 'Fuel production',
        'unit': 'kg',
        'location': 'GLO',
        'exchanges': [{
                'input': ('testdb', 'Carbon dioxide'),
                'amount': 10,
                'unit': 'kg',
                'type': 'biosphere'
            }, {
                'input': ('testdb', 'Fuel production'),
                'amount': 100,
                'unit': 'kg',
                'type': 'production'
            }]
    },
    ('testdb', 'Carbon dioxide'): {'name': 'Carbon dioxide', 'unit': 'kg', 'type': 'biosphere'}
    })

myLCIAdata = [[('testdb', 'Carbon dioxide'), 1.0]]
method_key = ('simplemethod', 'imaginaryendpoint', 'imaginarymidpoint')
my_method = bd.Method(method_key)
my_method.validate(myLCIAdata)
my_method.register()
my_method.write(myLCIAdata)
my_method.load()

functional_unit = {t_db.get('Electricity production'): 1000}
lca = bc.LCA(functional_unit, method_key)  # LCA calculations with method
lca.lci()
lca.lcia()
```

```python
print(lca.score)
```

What is important here is that 80.0 is the **nominal** value (other places called *static* or *deterministic* , see Heijungs R. (2024), chapter 10.1.11 for more info). In pragmatic terms, this is the result of the LCA without considering uncertainties, what 99.9% of LCA studies usually report. We need to remember that for later.

### Now add uncertainty

See a tutorial [here](http://nbviewer.jupyter.org/urls/bitbucket.org/cmutel/brightway2/raw/default/notebooks/Activities%20and%20exchanges.ipynb)

**Note**: uncertainties are always added to **exchanges** (not to activities...)

So I'll get one  exchange from one activity

```python
el = t_db.get('Electricity production')  
co2_exc = list(el.exchanges())[1]   # the first exchange
co2_exc
```

```python
# Lognormal distribution first
from stats_arrays import LognormalUncertainty
import numpy as np
co2_exc['uncertainty type'] = LognormalUncertainty.id # this is an integer (not a float)
co2_exc['loc'], co2_exc['scale'] = np.log(co2_exc['amount']), np.log(1.01) 
'''The lognorm dist is defined here two parameters: location and scale 
i.e. by the log of the geometric mean and by the geometric standard dev'''
co2_exc.save() # important
```

```python
el = t_db.get('Electricity production')  
fuel_exc = list(el.exchanges())[0]   # the first exchange
fuel_exc
```

```python
# Lognormal distribution first
from stats_arrays import LognormalUncertainty
import numpy as np
fuel_exc['uncertainty type'] = LognormalUncertainty.id # this is an integer (not a float)
fuel_exc['loc'], fuel_exc['scale'] = np.log(-fuel_exc['amount']), np.log(1.01)
fuel_exc['negative'] = True
'''The lognorm dist is defined here two parameters: location and scale 
i.e. by the log of the geometric mean and by the geometric standard dev'''
fuel_exc.save() # important
```

```python
fuel_exc.uncertainty  #
```

```python
co2_exc.uncertainty  # check that info is stored
```

```python
co2_exc.as_dict()  # Now uncertainty is included
```

```python
co2_exc.random_sample(n=10)  # nice
```

```python
# if you want to see this
%matplotlib inline
plt.hist(co2_exc.random_sample(n=1000))
```

```python
# this in case you want to try with normal dist
#from stats_arrays import NormalUncertainty

#co2_exc['uncertainty type'] = NormalUncertainty.id
#co2_exc['loc'], co2_exc['scale'] = 1, 0.01
#co2_exc.save()
#co2_exc.uncertainty  # check that
#co2_exc.as_dict()  # OK
```

### Now MC simulation

```python
# Check again that uncertainty info is stored
list(el.exchanges())[0].uncertainty
```

```python
bd.methods
```

###### Note: the way MC simulation is run in bw2.5 is slightly divverent than in bw2

```python
# This is the montecarlo simulation
mc = bc.LCA(demand={el: 1000}, method=method_key, use_distributions=True)
mc.lci()
mc.lcia()
mc_results = [mc.score for _ in zip(range(500), mc)] # this is a different way of calling the mc than in bw2

# two things here:
# 1. zip() returns a zip object, which is an iterator of tuples, for instance:
    # a = (1, 2, 3)
    # b = ('a', 'b', 'c')
    # for i in zip(a, b):
    #     print(i) 
    # # output will be: 
    #     # (1, 'a')
    #     # (2, 'b')
    #     # (3, 'c')

# 2. using a fuction within [ ] usig a for loop is called a "list comprehension". The result is a list
```

```python
mc_results[1:10] # printing the first 10 elements on the list...remember, the nominal value was 80
```

```python
# Look at the MC results, what you see is the sample distribution
plt.hist(mc_results, density=True)  # From matplotlib package. Use bins = int(500/15) to increase number of bars
plt.ylabel("Probability")
plt.xlabel('lca.score')
```

```python
print(np.mean(mc_results)) # from numpy package
print(np.median(mc_results)) # from numpy package
print(lca.score) # the nominal value, we are very close to the mean and median
```

```python
pd.DataFrame(mc_results).describe()  # useful descriptive stats from pandas package
```

```python
# Do this again and compare results
mc2 = bc.LCA(demand={el: 1000}, method=method_key, use_distributions=True)
mc.lci()
mc.lcia()
mc2_results = [mc.score for _ in zip(range(500), mc)]

plt.hist(mc2_results, density=True)
plt.ylabel("Probability")
plt.xlabel('lca.score')
```

```python
print(np.mean(mc2_results))
print(np.median(mc2_results))
print(lca.score)
```

```python
plt.scatter(mc_results, mc2_results) # Correct. Do you understand why? 

#(there is no relation because the two distributions are independent. We see an indistinct "cloud" and no pattern)
```

```python
# Another way to do it
iterations = 1000
scores = np.zeros(iterations)  # 1-dimensional array filled with zeros
for iteration in range(iterations):
    next(mc)
    scores[iteration] = mc.score
for i in range(1, 10):
    print(scores[i])  # need the zero because one-dimensional array
```

```python
# Another way, get a list instead of an array
iterations = 1000
scores = []
for iteration in range(iterations):
    next(mc)
    scores.append(mc.score)
for i in range(1, 10):
    print(scores[i])
type(scores) == type(mc_results)  # same type of results as in the first case
```
