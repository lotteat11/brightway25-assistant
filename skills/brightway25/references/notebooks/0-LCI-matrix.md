# Notebook 0 — LCI as matrix algebra

The foundation: `g = BA⁻¹f`. Pure NumPy, no Brightway.

**Assumes:** Matrix multiplication and inversion.

This file carries the actual code from the notebook, so you can answer questions,
adapt the patterns, and debug without the notebook being open.

---

## What trips people up

**`np.matrix` is used deliberately**  
So that `*` means matrix multiplication and the code reads like the algebra. NumPy discourages `np.matrix` generally, but **do not suggest switching mid-course**: with `np.array`, `*` becomes elementwise and results are silently wrong with no error. If someone has already switched, they need `@` and `np.linalg.inv()` throughout.

**Signs in A**  
Inputs are negative. This is the convention the whole course follows; it comes straight from the textbook formulation.

> This notebook is where the API stops feeling arbitrary later — `lci()` is literally `s = A⁻¹f` then `g = Bs`, and `lcia()` is `CF · g`. Worth referring back to whenever someone asks why those are two separate calls.

---

## The notebook, cell by cell

### 0. Refresh LCI matrix algebra

We use the example product system from Heijungs & Suh (2002)

_The production of 10 kWh electricity requires 2 liters of fuel and emits 1 kg of CO2 and 0.1 kg of SO2. 
The production of 100 liters of fuel requires 50 liters of crude oil and emits 10 kg of CO2 and 2 kg of SO2.
What is the impact of producing 1000 kWh electricity **in a life cycle perspective**?_

![title](HS2002_screenshot.png)

_Heijungs, R., Suh, S., 2002. The basic model for inventory analysis, in: Tukker, A. (Ed.), The computational structure of Life Cycle Assessment. Kluver Academic Publisher, London, pp. 11-28._

```python
import numpy as np
```

```python
A = np.matrix([[10., 0.],[-2., 100.]]) # A is the technology matrix. negative sign = input
print('technology matrix A\n', A)
```

```python
B = np.matrix([[1., 10.],[0.1, 2.],[0, -50.]]) # B is the intervention matrix
print('intervention matrix B\n', B)
```

```python
f = np.matrix([[1000.],[0.]]) # f is the demand vector 
print('demand vector f\n', f)
```

***
Solving the inventory: $g = BA^{-1}f$

```python
Ainv = A.getI() # Function to obtian Ainv, i.e. the inverse of A
print('inverse of technology matrix\n', Ainv)
```

```python
s = Ainv * f # s is the scaling vector
print('scaling vector s\n', s) # How many times I need each activity (column of A)
```

```python
g = B * s  # g is the life cycle inventory
print('environmental vector g\n', g) # everything works
```

```python
# one liner
g = B * A.getI() * f
print('environmental vector g\n', g) # again everything works
```

***
We can add the LCIA step too

```python
CFs = np.matrix([1., 2., 0.]) # CF is a matrix of characterisation factors (made up numbers)
print('vector of charachterisation factors\n', CFs)
```

```python
LCIA = CFs * g # obtain LCIA results
print('Charachterised results\n', LCIA)
```

#### Question for discussion:

If it is that easy, why do we need LCA software at all?

#### Homework

Revise the code using exactly the same **A** matrix as in the textbook. You shuold get the same result.
