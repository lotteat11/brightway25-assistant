# Notebook 4 — Importing your own inventory from a spreadsheet

CSV → pandas → `lci_to_bw2()` → Brightway database.

**Assumes:** Notebooks 1–3, basic pandas. Requires `lci_to_bw2.py` in the same directory.

This file carries the actual code from the notebook, so you can answer questions,
adapt the patterns, and debug without the notebook being open.

---

## What trips people up

**The CSV format is unforgiving**  
Column names and order both matter. First five columns are `Activity …`, the rest `Exchange …`. Most failures here are data-shape failures, not code failures — **inspect `df.columns` before debugging any code**.

**Three databases, three code formats in one column**  
`Exchange database` + `Exchange input` form the link tuple. Foreground uses your own names; ecoinvent uses 32 hex chars without dashes; biosphere uses 36 chars with dashes. See `../linking.md`.

**Export as CSV, not xlsx**  
Avoids encoding problems — the notebook says so explicitly.

**Database locked**  
Two notebooks open on one project. One notebook per project at a time.

**`.write()` replaces, it does not merge**  
Re-running a cell can silently discard earlier work.

> The group exercise — exchange data with another group and reproduce their results — reliably surfaces `code` vs `id` problems, absolute paths, and undocumented assumptions. That is the lesson, not a failure.

---

## The notebook, cell by cell

### 4. Import data from MS Excel

Brightway2.5 has a series of options for data import and export that you are invited to read about and try, they are on the [official website and notebooks](https://docs.brightway.dev/en/latest/content/examples/import.html). 

However, you can also developed your own importer, that fits with your workflow. For example, the file `lci_to_bw2.py` includes a code to convert a properly formatted csv file into a Brightway2.5 database dict. You need the Python Data Analysis Library [pandas](https://pandas.pydata.org/) to make it work (if you need to install it: within your virtual environment, run `conda install pandas` or `pip install pandas`). 

How does this importer work? 

1. Prepare your inventory in MS Excel using the template. See the example file _test\_db\_excel\_w\_ecoinvent.xlsx_
2. Save the relevant MS Excel sheet as .csv file, see the example file _test\_db\_excel\_w\_ecoinvent.csv_
3. Import the module in your script with the command `from lci_to_bw2 import *` 
4. Import the .csv file as a dataframe with the pandas function `.read_csv()`. Clean it up for unnecessary columns.
5. Convert the dataframe into a dictionary using the function `lci_to_bw2()`
6. Save the python dictionary as a Brightway2.5 database in the usual way i.e. using Brightway's `Database()`and `.write()` functions.

**NOTE:** this importer contains no automated tests so you need to make sure manually that the excel and csv files are in good order.

More information abuot this LCI data template (including a schema) and importer can be found in a dedicated [open Zenodo repository](https://zenodo.org/records/10843472) of the [ALIGNED project](https://alignedproject.eu/). 
In particular the document _Explainer to understanding the ALIGNED LCI data template_ provides information that is useful also to undersand brightway strutures and the combined use of database and code ids as composite unique identifier in brightway. 

See an example below.

```python
# Import brightway2.5 packages
import bw2calc as bc
import bw2data as bd
import pandas as pd
import numpy as np
from lci_to_bw2 import * # import all the functions of this module
```

```python
bd.projects.set_current('advlca25')
```

```python
bd.databases
```

```python
mydb = pd.read_csv('test_db_excel_w_ecoinvent.csv', header = 0, sep = ",") # using csv file avoids encoding problem
mydb.head()
```

```python
# clean up a bit
mydb = mydb.drop('Notes', axis=1)  # remove the columns not needed
mydb['Exchange uncertainty type'] = mydb['Exchange uncertainty type'].fillna(0).astype(int) # uncertainty as integers
# Note: to avoid having both nan and values in the uncertainty column I use zero as default
mydb.head()
```

```python
# Create a dict that can be written as database
bw2_db = lci_to_bw2(mydb) # a function from the lci_to_bw2 module
bw2_db
```

Time to write the data on a database. 

Important: 

- The **database names should be the same** as in the excel file...

- make sure you **shut down** all other notebooks using **the same bw project** before you run this. Only one user at the time can write on a database. Otherwise you'll get a "Database locked" error.

- give a look at the .csv file using a text editor before importing (often there are mistakes...)

```python
t_db = bd.Database('exldb') # it works because the database name in the excel file is the same
t_db.write(bw2_db)
# Error: "Not able to determine geocollections for all datasets. This database is not ready for regionalization." 
# This is because the "activity" data don't have 'location' key-value pair, but it is fine, you can add it or not.
```

```python
bd.databases # It worked, exldb is there
```

Give a look at your imported database

```python
[print(act, act.id) for act in t_db]  # check more stuff 
print('---------')
[[print(act, exc) for exc in list(act.exchanges())]for act in t_db]  # check more stuff 
print('---------')
[[print(exc.uncertainty) for exc in list(act.exchanges())]for act in t_db]  # check more stuff
```

```python
myact = bd.Database("exldb").get('Fuel production')
exchanges = list(myact.exchanges())
for exc in exchanges:
    print(exc)
```

Let's check if calculations work

```python
mymethod = ('ecoinvent-3.11', 'IPCC 2021', 'climate change: fossil', 'global warming potential (GWP100)')
el = t_db.get("Electricity production")
functional_unit = {el: 1000}
lca = bc.LCA(functional_unit, mymethod)
lca.lci()
lca.lcia()
print(lca.score)
```

### Question

Do you think this results includes all emissions you have imported from the excel file?

### Group exercise

Prepare your own product system in excel, linked to biosphere and ecoinvent, and import it. Run calculations to see if it works as expected. Send all the code and data to another group and see if they can reproduce your results, in that case, the exercise will be a success. Get feedback from other group on your code and what difficulties they had in reading and running it.
