# Notebook 3 — Importing and searching ecoinvent

Real background data at scale.

**Assumes:** Notebooks 1–2, a working install, and an ecoinvent licence.

This file carries the actual code from the notebook, so you can answer questions,
adapt the patterns, and debug without the notebook being open.

---

## What trips people up

**The biosphere database name varies by release**  
This notebook says "biosphere3" in places. Recent `import_ecoinvent_release()` calls name it
after the version instead — `ecoinvent-3.11-biosphere`. Never hardcode either; read it from
`list(bd.databases)`.

**Licence agreement must be accepted on the website first**  
Before anything else. The API rejects accounts that have never logged in through a browser and accepted the licence and personal-data agreement — and the error says nothing about agreements. See `../setup.md`.

**The import takes 10–30 minutes with no progress bar**  
A cell stuck at `[*]` is normal. Interrupting leaves a half-imported project that fails confusingly afterwards.

**Arguments are strings**  
`version='3.11'`, not `3.11`.

**Search returns many near-identical hits**  
Differing by location, system model, market vs production. **Choosing between them is a modelling decision**, not a search-syntax problem. Do not just hand over a `filter` argument — ask what the study is actually modelling.

**"Not able to determine geocollections"**  
Harmless warning about regionalization. The import succeeded.

---

## The notebook, cell by cell

### 3. Import biosphere3 and ecoinvent

Now that you know how to work with the foreground system, it's time to learn how to work with the background system. In particular it is useful to import and work with two databases: _biosphere_ that contains all the exchanges and impact assessment methods, and _ecoinvent_.

###### Read this before starting

This tutorial shows current recommended way of importing ecoinvent. 
**You need to have the ecoinvent credentials** (username and password) to do this. 
Check also the [official docs](https://docs.brightway.dev/en/latest/content/cheatsheet/importing.html).

Before you run this tutorial, please **install** `ecoinvent_interface`. 
- Open your terminal / powershell where the notebook is running
- Close this notebook (Ctrl + C)
- Run `conda install ecoinvent_interface` 
- Reopen the notebook

If everything worked fine you should have installed the ecoinvent interface in the same virtual environment where brightweay is installed.

Some more info on the package [here](https://github.com/brightway-lca/ecoinvent_interface).

```python
# Import brightway2.5 packages
import bw2calc as bc
import bw2data as bd
import bw2io as bi
import ecoinvent_interface # this will only work if you installed the ecoinvent_interface package
```

```python
# first select the right project (do bd.projects to check what projects you have)
bd.projects.set_current('advlca25')
# bd.projects.delete_project('advlca25', delete_dir=True) # if you want a fresh start
```

```python
# Which databases are present?
bd.databases
```

We are going to use version 3.11 of ecoinvent, consequential model, for this course (it's the latest at the time of writing).

```python
bi.import_ecoinvent_release(
    version='3.11',
    system_model='consequential',
    username ='XXX', # use your own
    password='XXX' # use your own
)
```

```python
bd.databases # you should now see both biosphere and ecoinvent
```

### Navigate biosphere and ecoinvent

A key difference compared to previous exercises is that in ecoinvent each activity and exchange is defined by a **code** which are unique identifiers. So it is important to learn how to find both activity code and name and how to match them _(Actually we used the codes also in the previous lectures but they were identical to the activity names for simplicity)_.

One key and I would say __fundamental__ aspect to remember is that __codes works across bw installations__. This means that the code (actually it's a unique identifier or [UUID](https://en.wikipedia.org/wiki/Universally_unique_identifier), I think) is the same on your computer and on another person's computer. This is extremely important to be able to __share data__.

```python
# Search stuff in biosphere
bd.Database("ecoinvent-3.11-biosphere").search("carbon dioxide") # there is more than one activity with this name. Only code is univocal.
```

```python
CO2 = bd.Database("ecoinvent-3.11-biosphere").get("349b29d1-3e58-4c66-98b9-9d1a076efd2e") 
# This code works across bw2.5 installations, 
# i.e. is univocal for biosphere3 everywhere
print(CO2['name']) # there is more than one activity with this name. Only code is univocal.
print(CO2['code'])
```

```python
# Search stuff in ecoinvent

# Search by keyword
mydb = bd.Database('ecoinvent-3.11-consequential')
mydb.search("transport freight euro5")

#bd.Database('ecoinvent-3.11-consequential').search("transport freight euro5") # gives the same result obviously
```

```python
# explore activities
activity_name = 'electricity denmark wind'

# Same but different:
for activity in bd.Database("ecoinvent-3.11-consequential").search(activity_name, limit = 5):  
    print(activity)
    print(activity['code'])
    print(activity['id'])
```

###### Again on difference between 'code' and 'id' (introduced in bw25)

In bw2.5 there is a new field, the "id" field. This is also an unique identifier of each exchange, but it's an integer not a string. Specifically, the "id" could be intended as a coordinate, it is the row/(column number of this exchange in the technology matrix (or in the biosphere matrix if a biosphere excahange).

Careful that (but I am not sure) differently from the 'code' the 'id' might not be univocal across bw installations!

```python
act = bd.Database("ecoinvent-3.11-consequential").search('electricity denmark wind')[0] # take the firt activity of the list
print(act['name'])
print(type(act['code'])) # the code is a string
print(type(act['id'])) # the id is an integer
```

```python
# Try this        
for activity in bd.Database("biosphere").search('heat production'):  
    print(activity)
    print(activity['code']) # Can you explain this result?
```

```python
# you can be much more specific in your search:
for activity in bd.Database("ecoinvent-3.11-consequential").search(activity_name, filter={"location" : 'DK'}, limit = 5):
    print(activity)
    print(activity['code'])
    print(activity['id'])
```

Now you know how to find activities. What about **selecting** activities?

```python
# If you know the code (e.g. found with method above) it's simple.        
mycode = '4b61f97a9b942ba05720a1cea09eacc9'
myact = bd.Database("ecoinvent-3.11-consequential").get(mycode)
#myact = Database("biosphere").get(mycode)  # Not working of course...

print(myact['name'])
```

```python
myact.id # access the id directly
```

```python
myact.code # this won't work though. It's only for exchanges (see further below)
```

```python
myact._data # a lot of detail
```

```python
# Check the exchanges in one activity
for i in list(myact.exchanges()):  # Epxlore the activity as usual
    print(i['type'])
    print(i)
    print(i['input'])
    print('-------')
```

```python
# If you know the name of the activity and want to select it:
activity_name = 'market for electricity, low voltage'
    
for activity in bd.Database("ecoinvent-3.11-consequential"):  # can you find an easier way? I couldn't
    if activity['name'] == activity_name:
        myact = bd.Database("ecoinvent-3.11-consequential").get(activity['code'])

myact  # Careful! Might not return the danish market. Not what I wanted!
```

```python
# A more specific search
for activity in bd.Database("ecoinvent-3.11-consequential"):  
    if activity['name'] == activity_name and activity['location'] == "DK":  # need to be specific...
        myact = bd.Database("ecoinvent-3.11-consequential").get(activity['code'])
myact  # alright
```

```python
# selecting multiple acitivites with same criteria (very useful!)
# we use list comprehension
acts = [act for act in bd.Database("ecoinvent-3.11-consequential") if act['name'] == 'market for electricity, low voltage']
acts[0:10]
```

```python
# Explore exchanges
myexc = list(myact.exchanges())[1]
```

```python
# All the metadata of an exchange 
for i in myexc:
    print(i)
```

```python
# access exchange metadata
print(myexc['type'], myexc['output'], myexc['input'])
```

```python
# again exchange metadata
print(myexc['pedigree'])
```

### Calculate with biosphere and ecoinvent

Now we can run an LCA with a dataset from ecoinvent.

```python
list(bd.methods)[0:5] # remove [0:5] to see the very long list of all methods.
```

See also the cheatsheet [here](https://docs.brightway.dev/en/latest/content/cheatsheet/ia.html#how-do-i-search-for-an-impact-category-using-list-comprehensions) to use methods.

```python
# More convenient, search the IPCC method, cf cheatsheet linked above
[method for method in bd.methods if 'IPCC 2021' in method[1] and 'fossil' in method[2]]
```

```python
# First select a method
mymethod = ('ecoinvent-3.11', 'IPCC 2021', 'climate change: fossil', 'global warming potential (GWP100)')
bd.methods[mymethod]
```

```python
mycode = '4b61f97a9b942ba05720a1cea09eacc9'
myact = bd.Database("ecoinvent-3.11-consequential").get(mycode)
```

```python
functional_unit = {myact : 1}
lca = bc.LCA(demand=functional_unit, method=mymethod) #run LCA calculations again with method
lca.lci()
lca.lcia()
print(lca.score) # What is the unit? Find out! (alright it's bd.methods[mymethod])
```

### Exercise (at home)

Link the emissions of your previously defined foreground system to the biosphere database, and link some of the ecoinvent database activities to your foreground system. Run the calculations and get a carbon footprint with the ILCD climate change method.
