# Notebook 2 — Exploring a database

Getting at activities and exchanges; `code` vs `id`.

**Assumes:** Notebook 1. Dict iteration, comprehensions, generators.

This file carries the actual code from the notebook, so you can answer questions,
adapt the patterns, and debug without the notebook being open.

---

## What trips people up

**`.exchanges()` returns a generator**  
It looks empty when printed and can only be consumed once. A second loop over it silently does nothing — **no error at all**. Fix once at the top: `excs = list(act.exchanges())`.

**`code` vs `id`**  
`code` is a stable string you share and link with. `id` is an integer matrix coordinate specific to this installation. Conflating them produces code that works locally and breaks when shared.

**Exchanges have no name of their own**  
The name belongs to the input activity — which is why 'retrieve an exchange by name' is harder than it looks, and a good exercise.

---

## The notebook, cell by cell

### 2. How to navigate activities and exchanges in Brightway2.5

When you do an LCA you need to access the various activities and look at them to understand what are their inputs and outputs and how they are linked to other activities. This script includes code to do this in different ways. Try it out and try it on your own product system as well. 

(For an extensive list of useful commands, see the online [cheatsheet](https://docs.brightway.dev/en/latest/content/cheatsheet/index.html) guide)

```python
# Import brightway2.5 package
import bw2data as bd
```

```python
bd.projects.set_current('advlca25')  # created in the previous notebook
```

```python
bd.databases  # should have the two databases: "testdb" and "testbiosphere"
```

```python
t_db = bd.Database('testdb') # We create an instance of this database class
```

First we look into the information associated with a **specific activity**.
This is how we select the activity (which is a python dictionary):

```python
el = t_db.get('Electricity production')  # reads: "get the activity 'Electricity production' from the database instance 't_db'... 
                                         # ...and associate it to a python object 'el'"
print(el)
```

```python
for k in el:  # k for "key". These the possible keys of an activity dictionary
    print(k)
# Note that there is a key called "id" that we didn't define in the previous notebook. More on this later.
```

```python
el.as_dict()  # or just this (type '.' and then press 'tab')
```

```python
print(el['name'])  # print the value of one key

print(el['name'], "***", el['code'], "***", el['unit'], "***", el['database'], "***", el['id'])  # print more than one...

print(el.get('unit'))  # another way...
```

**What is the "id" specifically?** 
It is a unique identifier of each element in the techosphere/biosphere matrix, also called a "node". 
See documentation [here](https://docs.brightway.dev/en/latest/content/overview/inventory.html). 
In the case of technosphere matrix where we have pairs of activities wach with a respective product, with some simplification (it is not entirely correct) we can think of the "id" value as the unique identifier of each activity (product), in the sense that each activity (product) has a different id value. So it is an identifier of each column (row) of the matrix. Note that in this specific example the "id" has been assigned automatically to each activity of our product system. 
The same applies for the intervention matrix (biosphere exchanges).

```python
print("the 'id' value for this activity is", el['id'])
```

```python
# Compare also
print(bd.Database('testdb').get('Electricity production').id)
print(bd.Database('testdb').get('Fuel production').id)
# with
print(bd.Database('testbiosphere').get('Carbon dioxide').id) # Also biosphere nodes have ids...these are the rows of the intervention matrix.
print(bd.Database('testbiosphere').get('Sulphur dioxide').id)
```

Now instead we look at the **exchanges** of a specific activity

```python
#el['exchanges']  # this doesn't work.
#el.exchanges()  # neither this
list(el.exchanges())  # yeps, this one
```

```python
for exc in el.exchanges():  # or this, visualize all exchanges of an activity and specific attributes
    print(exc)
    print(exc['type'])
    print(exc['input'])
    print(exc['input'][0])
    print(exc['input'][1])
    print(exc.input)
    print("-------")
```

Now we look at the information associated with a specific **exchange** of a specific activity

```python
el_exc = list(el.exchanges())[0]  # "the first exchange of the el activity" (this is also a DICT)
print(el_exc)
```

```python
print(type(el))  # compare the three
print(type(el.exchanges()))
print(type(el_exc))
```

```python
for i in el_exc:  # the possible keys of an exchange (DICT iteration)
    print(i, ':', el_exc[i])
```

```python
el_exc.as_dict()  # or just this, as above
```

```python
el_exc.items() # another nice one
```

```python
el_exc.unit == el_exc['unit']  # equivalent ways, different from activities
```

```python
# Note that exchanges do not have "id" 
el_exc['id']
```

On the meaning of input and output, as this can be confusing:

```python
print(el_exc['amount'], el_exc['unit'], el_exc['input'], 
      '\nto\n',
      el_exc['output'], 
      '\nwithin\n', 
      el_exc['type'])
```

The terms "input" and "output" are used to identify two coordinates in the technology matrix
"input" corresponds to the row (product input) and "output" corresponds to the column (activity output).

In the case below "the production of electricity requires fuel".

Or, in other words, "to obtain an __output__ of electricity one requires an __input__ from fuel production"

Or "there is an exchange of product __from__ fuel production __to__ electricity production"

```python
print(el_exc.input)  # One can intended the word 'input' as "from'
print(el_exc.output)  # ...and 'output' as 'to'
```

What if I want to get a specific exchange of a specific activity **without using numeric indexing**, but by using its name? Let's see if we can find the amount of Carbon Dioxide emitted from electricity production

```python
for exc in list(el.exchanges()):
    if exc['input'] == ('testbiosphere', 'Carbon dioxide'):
        print(exc)
    else:
        print(exc['input'][1],'...Not this one')
```

Good. Now we store the value **in a variable** for future use

```python
for exc in list(el.exchanges()):
    if exc['input'] == ('testbiosphere', 'Carbon dioxide'):
        elCO2_amount = exc['amount'] # creates the variable elCO2amount

print(elCO2_amount)
```

```python
elCO2_amount * 1234.56  # it's a number and you can make operations with that
```
