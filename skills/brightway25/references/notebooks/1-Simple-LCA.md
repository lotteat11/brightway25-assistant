# Notebook 1 — First LCA in Brightway

The same textbook system, now as a Brightway database. Custom LCIA method.

**Assumes:** Notebook 0. Nested dicts and tuple keys.

This file carries the actual code from the notebook, so you can answer questions,
adapt the patterns, and debug without the notebook being open.

---

## What trips people up

**The nested dict structure is intimidating on first contact**  
Read it outside-in: outer dict keyed by `(database, code)` → activity fields → `'exchanges'` is a **list** of dicts. Three levels, all plain Python containers.

**Every activity needs exactly one production exchange**  
Missing or duplicated production exchanges are the usual cause of a singular matrix later.

**`'input'` is always a tuple**  
`['db','code']` raises `TypeError: unhashable type: 'list'` — the single most common Python error on this material.

**Substitution and sign conventions**  
Discussed at some length in the notebook, which suggests it causes trouble. Partitioning requires pre-calculated allocated values; Brightway does not do it for you.

> The notebook builds the same system twice — everything in one database, then technosphere and biosphere separated. Both give identical results. The second layout is closer to how ecoinvent is organised.

---

## The notebook, cell by cell

### 1. Simple LCA in Brightway2.5

The most important data structures of brightway are represented [here](https://docs.brightway.dev/en/latest/_images/org-scheme.png) and the inventory structure is described [here](https://docs.brightway.dev/en/latest/content/overview/inventory.html). Look at the figure  and try to make the parallel with what you know already (e.g. Simapro). I recommend that later you read carefully this documentation page. This is also the terminology to use when working with Brightway2.5.

We again use the example product system from Heijungs & Suh (2002)

The point with this script is to understand the dict structure of a brightway database.

```python
# Import brightway2.5 packages (to use functions from the brightway2.5 module)
import bw2calc as bc
import bw2data as bd
```

```python
# Choose a project (in this case create one) 
bd.projects.set_current('advlca25') # bd.projects.output_dir to find out where projects are stored in the hd
```

```python
# bd.databases.clear() # line to use in case you had already databases in the project space
bd.databases # lists all databases. We start from an empty project
```

```python
# This cell is to clean up
# del bd.databases['testdb'] 
# del bd.databases['testbiosphere']
```

```python
t_db = bd.Database("testdb") # creates an instance of the database class # Try doing t_db.name for example.
```

```python
# This is the most important cell in this notebook, read it carefully
t_db.write({
    ("testdb", "Electricity production"):{ # Note that a tuple is used to identify an activity univocally
        'name':'Electricity production',
        'unit': 'kWh', 
        'location': 'GLO',
        'exchanges': [{
                'input': ('testdb', 'Fuel production'),
                'amount': 2,
                'unit': 'liters',
                'type': 'technosphere'
            },{
                'input': ('testdb', 'Carbon dioxide'),
                'amount': 1,
                'unit': 'kg',
                'type': 'biosphere'
            },{
                'input': ('testdb', 'Sulphur dioxide'),
                'amount': 0.1,
                'unit': 'kg',
                'type': 'biosphere'
            },{
                'input': ('testdb', 'Electricity production'), #important to write the same process name in output
                'amount': 10,
                'unit': 'kWh',
                'type': 'production'
            }]
        },
    ('testdb', 'Fuel production'):{ # here starts another activity
        'name': 'Fuel production',
        'unit': 'liters',
        'location': 'GLO',
        'exchanges':[{
                'input': ('testdb', 'Carbon dioxide'),
                'amount': 10,
                'unit': 'kg',
                'type': 'biosphere'
            },{
                'input': ('testdb', 'Sulphur dioxide'),
                'amount': 2,
                'unit': 'kg',
                'type': 'biosphere'
            },{
                'input': ('testdb', 'Crude oil'),
                'amount': -50,
                'unit': 'liters',
                'type': 'biosphere'
            },{
                'input': ('testdb', 'Fuel production'),
                'amount': 100,
                'unit': 'liters',
                'type': 'production'
            }]
    },
    ('testdb', 'Carbon dioxide'):{'name': 'Carbon dioxide', 'unit':'kg', 'type': 'biosphere'}, # env exchanges
    ('testdb', 'Sulphur dioxide'):{'name': 'Sulphur dioxide', 'unit':'kg', 'type': 'biosphere'},
    ('testdb', 'Crude oil'):{'name': 'Crude oil', 'unit':'liters', 'type': 'biosphere'}

    })
```

```python
bd.databases # Now I see the database
```

```python
# Access one activity using the `.get` python method
t_db.get("Electricity production")
```

```python
# Now solve the inventory
functional_unit = {t_db.get("Electricity production") : 1000} # the selected activity
lca = bc.LCA(functional_unit)
lca.lci()
print(lca.inventory) # Is this what you expected?
```

```python
# We can't do the LCIA because we have no characterisation factors yet. So we create a LCIA method.
myLCIAdata = [[('testdb', 'Carbon dioxide'), 1.0], 
              [('testdb', 'Sulphur dioxide'), 2.0],
              [('testdb', 'Crude oil'), 0.0]]

method_key = ('simplemethod', 'imaginaryendpoint', 'imaginarymidpoint')
my_method = bd.Method(method_key)
my_method.validate(myLCIAdata)
my_method.register() 
my_method.write(myLCIAdata)
my_method.load()
```

```python
# Calculate LCIA results
lca = bc.LCA(functional_unit, method_key) # run LCA calculations again with method
lca.lci()
lca.lcia() # the LCIA step
lca.score

print("characterized_inventory\n", lca.characterized_inventory)
print("Score\n", lca.score) # same as in the previous script
```

```python
# Why 'score'? The point with 'score' is that what in Brightway2 is called a "method" is in fact an "impact category"...
# So all characterised results of the method are correctly summed up.

import numpy as np
np.sum(lca.characterized_inventory) == lca.score
```

### Same but different

Here a different way to link the technosphere and biosphere flows. 
This time we create two databases, "testdb"  for product flows and 'testbiosphere' for environmental flows (This is closer to how brightway works with commercial dabases such as ecoinvent). 

Note how the two are linked. Before you had this input line in "testdb":

```python
'input': ('testdb', 'Carbon dioxide')
```
now you have this one instead:

```python
'input': ('testbiosphere', 'Carbon dioxide')
```

Run the script and check that you get the same results as before.

```python
if 'testdb' in bd.databases: del bd.databases['testdb'] # just another way to clean up
if 'testbiosphere' in bd.databases: del bd.databases['testbiosphere'] # just another way to clean up
bd.databases
```

```python
bs_db = bd.Database("testbiosphere")

bs_db.write({
    ('testbiosphere', 'Carbon dioxide'):{'name': 'Carbon dioxide', 'unit':'kg', 'type': 'biosphere'},
    ('testbiosphere', 'Sulphur dioxide'):{'name': 'Sulphur dioxide', 'unit':'kg', 'type': 'biosphere'},
    ('testbiosphere', 'Crude oil'):{'name': 'Crude oil', 'unit':'liters', 'type': 'biosphere'}
    })
```

```python
t_db = bd.Database("testdb")

t_db.write({
    ("testdb", "Electricity production"):{
        'name':'Electricity production',
        'unit': 'kWh', 
        'location': 'GLO',
        'exchanges': [{
                'input': ('testdb', 'Fuel production'),
                'amount': 2,
                'unit': 'liters',
                'type': 'technosphere'
            },{
                'input': ('testbiosphere', 'Carbon dioxide'), # the KEY line, this exchange is from the "testbsiosphere" database.
                'amount': 1,
                'unit': 'kg',
                'type': 'biosphere'
            },{
                'input': ('testbiosphere', 'Sulphur dioxide'),
                'amount': 0.1,
                'unit': 'kg',
                'type': 'biosphere'
            },{
                'input': ('testdb', 'Electricity production'), 
                'amount': 10,
                'unit': 'kWh',
                'type': 'production'
            }]
        },
    ('testdb', 'Fuel production'):{
        'name': 'Fuel production',
        'unit': 'liters',
        'location': 'GLO',
        'exchanges':[{
                'input': ('testbiosphere', 'Carbon dioxide'),
                'amount': 10,
                'unit': 'kg',
                'type': 'biosphere'
            },{
                'input': ('testbiosphere', 'Sulphur dioxide'),
                'amount': 2,
                'unit': 'kg',
                'type': 'biosphere'
            },{
                'input': ('testbiosphere', 'Crude oil'),
                'amount': -50,
                'unit': 'kg',
                'type': 'biosphere'
            },{
                'input': ('testdb', 'Fuel production'),
                'amount': 100,
                'unit': 'liters',
                'type': 'production'
            }]
    }}) # Differnetly from before, I don't have the environmental exchanges here
```

```python
bd.databases # Now I see also the testbiosphere one
```

```python
# I need a new LCIA meethod too!
myLCIAdata = [[('testbiosphere', 'Carbon dioxide'), 1.0], # testbiosphere instead of testdb
              [('testbiosphere', 'Sulphur dioxide'), 2.0],
              [('testbiosphere', 'Crude oil'), 0.0]]

method_key = ('simplemethod', 'imaginaryendpoint', 'imaginarymidpoint')
my_method = bd.Method(method_key)
my_method.validate(myLCIAdata)
my_method.register() 
my_method.write(myLCIAdata)
my_method.load()
```

```python
functional_unit = {t_db.get("Electricity production") : 1000}
lca = bc.LCA(functional_unit, method_key) #run LCA calculations again with method
lca.lci()
lca.lcia()
print(lca.score)
```

### Exercise in group (course Module 2, Session 1)

Model the product system in the "Heat production exercise" slides using first excel then brighway2 and make sure you get the same result.
(Practical hint: when you do the brightway2 version make a copy of this notebook and edit that direclty)

### Exercise (optional, at home)

Take your own product system, select two or three activities that are linked together, and that have also some environmental exchanges associated with, and make by hand a database using the Brightway2 standard dict structure. Run the calculations on that. If you don't have data, use the data [here](http://moutreach.science/2017/12/01/LCI-reporting.html#fnref:2).

### A note on co-products

There are at least two ways to model co-products with the substitution method. Besides the exchange types `‘technosphere’`, `‘biosphere’`, and `‘production’` there is a fourth type called `‘substitution’`. You can use that (use __plus__ sign!). Alternatively, you can create an exchange of the `‘technosphere’` type but using the __minus__ sign. I.e. a negative input of some product. This is similar to e.g. SimaPro where there are two options: either use the predefined line for co-products or insert a negative input from technosphere.

Note that this sign convention is consistent with the Hejiungs and Suh (2002) book chapter. Diagonal values in the A matrix are positive, off-diagonal inputs are negative. Intervention matrix signs depend on the convention (you decide the sign or you have to follow the convention used of the database, e.g. the biosphere database may assume that +10 kg CO2 means the emission of CO2 and +10 kg crude oil means the extraction of oil). 

To use the __partitioning method__ one needs to calculate the allocated values (by mass/energy/revenue etc) for each exchange before importing the data into Brightway2 (or write a code that does that automatically), just like in e.g. SimaPro.
