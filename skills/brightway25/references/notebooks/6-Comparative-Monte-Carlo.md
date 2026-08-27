# Notebook 6 — Comparative Monte Carlo with dependent sampling

The methodological centrepiece: one shared A matrix per iteration, so paired tests are valid.

**Assumes:** Notebook 5. Paired vs unpaired tests.

This file carries the actual code from the notebook, so you can answer questions,
adapt the patterns, and debug without the notebook being open.

---

## What trips people up

**Dependent sampling looks like cheating**  
It is the opposite. Both alternatives face the same sampled background, so what varies between them is only what actually *differs* between them. Lower variance, fewer iterations, and **paired tests become valid**. Independent sampling inflates the apparent uncertainty of the difference — which is the quantity the comparison is about.

**What `redo_lcia()` actually reuses**  
The same sampled matrices. That reuse is the entire mechanism — not an optimisation.

**Comparing two independently sampled distributions by eye is a weaker claim**  
Worth stating explicitly; it is the reason the whole approach exists.

> A useful analogy for the paired argument: testing two treatments on the same subjects versus two different groups. The paired design is stronger precisely because it removes between-subject variation.

---

## The notebook, cell by cell

### Comparative Monte Carlo

This script shows how to perform a more advanced comparative Monte Carlo simulation.

We also run Monte Carlo simulation using the background system and not only the foreground one as in the previous notebook.

A comparative Monte Carlo is the type of simulation to be used in comparative LCAs, i.e. in analyses where different alternatives to provide the same Functional Unit are compared. In this comparative case it is important to randomly sample a common technology matrix **A** for all alternatives at each iteration, instead of having a different technology matrix per each alternative at each iteration. This allows for a smaller variance and shorter computational times. Moreover, this allows to optimally perform the  statistical testing of the results with paired tests, to see if the two alternatives are significantly different from each other or not. 

This script was inspired by the paper by Henriksson et al. (2015), a very good  example of an LCA with comparative Monte Carlo simulation followed by statistical testing for significant differences between alternatives. It ewas then applied in larger scale in Pizzol (2019).

_Henriksson, P. J. G., Rico, A., Zhang, W., Ahmad-Al-Nahid, S., Newton, R., Phan, L. T., … Guinée, J. B. (2015). Comparison of Asian Aquaculture Products by Use of Statistically Supported Life Cycle Assessment. Environmental Science and Technology, 49(24), 14176-14183. [https://doi.org/10.1021/acs.est.5b04634](https://doi.org/10.1021/acs.est.5b04634)_

_Pizzol, M. (2019). Deterministic and stochastic carbon footprint of intermodal ferry and truck freight transport across Scandinavian routes. Journal of Cleaner Production, 224, 626–636. [https://doi.org/10.1016/j.jclepro.2019.03.270](https://doi.org/10.1016/j.jclepro.2019.03.270)_

```python
# Import brightway2.5 packages
import bw2calc as bc
import bw2data as bd
import pandas as pd
import numpy as np
from matplotlib import pyplot as plt
from scipy import stats
```

```python
bd.projects.set_current('advlca25')
bd.databases
```

```python
db = bd.Database("ecoinvent-3.11-consequential")
ipcc = ('ecoinvent-3.11', 'IPCC 2021', 'climate change: fossil', 'global warming potential (GWP100)')
```

```python
# Simple montecarlo on ecoinvent process as we know it. We are using the background system.
mydemand = {db.random(): 1}  # select a random process
lca = bc.LCA(mydemand, ipcc)
lca.lci()
lca.lcia()
lca.score # nominal value
```

```python
# run montecarlo simulation uwing the bw2.5 command
mc = bc.LCA(demand=mydemand, method=ipcc, use_distributions=True) # "use_distributions" is the difference btw bw2 and bw2.5
mc.lci()
mc.lcia()
mc_results = [mc.score for _ in zip(range(100), mc)] # will take a minute, we are randomly sampling ecoinvent 100 times
```

```python
# plot MC results
plt.hist(mc_results, density=True)
plt.ylabel("Probability")
plt.xlabel(bd.methods[ipcc]["unit"])
pd.DataFrame(mc_results).describe() 
lca.score
```

```python
# Now comparative analysis, select two different transport activities
activity_name = 'transport, freight, lorry, >32 metric ton, diesel, EURO 5'    
for activity in bd.Database("ecoinvent-3.11-consequential"):
    if activity['name'] == activity_name:
        truckE5 = bd.Database("ecoinvent-3.11-consequential").get(activity['code'])

activity_name = 'transport, freight, lorry, >32 metric ton, diesel, EURO 6'    
for activity in bd.Database("ecoinvent-3.11-consequential"):
    if activity['name'] == activity_name:
        truckE6 = bd.Database("ecoinvent-3.11-consequential").get(activity['code'])
```

```python
print(truckE5,'\n', truckE6) # just a check that we have selected the right activities
```

```python
# make a list with the alternatives
demands = [{truckE5.id: 1}, {truckE6.id: 1}]  # At home, check by using the same process (e.g. truckE5) two times.

# We are calculating the impact of transport with the EURO5 truck
mc = bc.LCA(demand=demands[0], method=ipcc, use_distributions=True)
mc.lci()
mc.lcia()
mc_results = [mc.score for _ in zip(range(1), mc)]
print(mc_results[0])
```

```python
# look at this first
demands = [{truckE5.id: 1}, {truckE6.id: 1}]
mc.redo_lcia(demands[0]) # EURO5 truck
print(mc.score, 'euro5')
mc.redo_lcia(demands[1]) # EURO6 truck. I am using the same technology matrix "A" as before to calcualte results
print(mc.score, 'euro6')
mc.redo_lcia(demands[0]) # EURO5 truck again. Same result. Note how "redo.lcia" allows doing dependent sampling
print(mc.score, 'euro5 again')
```

```python
# Now for several iterations
iterations = 1000
simulations = [] # empty list that will contain the restuls of all iterations, for all alternatives

for _ in range(iterations):
    
    next(mc)
    mcresults = []    # empty list that will contain results for one iteration, for two alteratives
    
    for i in demands:
        mc.redo_lcia(i)
        mcresults.append(mc.score)
    
    simulations.append(mcresults) # appends one list to another
    
    
df = pd.DataFrame(simulations, columns = ['truckE5','truckE6']) # df is for "dataframe"
#df.to_csv('ComparativeMCsimulation.csv') # to save it
```

```python
df
```

```python
df.plot(kind = 'box')
#df.T.melt()
```

```python
# plot one against the other to see if there is any trend
plt.plot(df.truckE5, df.truckE6, 'o')
plt.xlabel('truckE5 - kg CO2-eq')
plt.ylabel('truckE6 - kg CO2-eq')
```

```python
# You can see how many times the difference is positive. This is what Simapro does (but differently)
df['diffe'] = df.truckE5 - df.truckE6
plt.hist(df.diffe.values)
print(len(df.diffe[df.diffe < 0]))
print(len(df.diffe[df.diffe > 0]))
print(len(df.diffe[df.diffe == 0]))
```

```python
# Statistical testing (using the stats package)
# I can use a paired t-test

t_value, p_value = stats.ttest_rel(df.truckE5,df.truckE6)
t_value, p_value

# Low p-values in the t-test indicate a small probability that the two samples have the same average 
# (that means the two samples are very likely different...).
```

```python
# But wait! did we check for normality? We can do a Shapiro-Wilk test
plt.hist(df.truckE5.values)
plt.xlabel('truckE5 - kg CO2-eq')

SW_value, SW_p_value = stats.shapiro(df.truckE5)
print(SW_p_value) # Not normally distributed...

plt.hist(df.truckE6.values)
SW_value, SW_p_value = stats.shapiro(df.truckE6)
print(SW_p_value) # Not normally distributed...

# Low p-values in the SW test indicate a small probability that the sample is from a normal distribution
```

```python
# Alright need a non-parametric test. Wilcox sign rank test
s_value, p_value = stats.wilcoxon(df.truckE5, df.truckE6)
s_value, p_value # Not bad, significant difference at p < 0.01.
```

```python
# What if we had done the MC on the processes independently.
# truckE5
mc1 = bc.LCA(demand={truckE5: 1}, method=ipcc, use_distributions=True)
mc1.lci()
mc1.lcia()
mc1_results = [mc1.score for _ in zip(range(100), mc1)]

# it's still truckE5 !!! I am comparing two times the same activity
mc2 = bc.LCA(demand={truckE5: 1}, method=ipcc, use_distributions=True)
mc2.lci()
mc2.lcia()
mc2_results = [mc2.score for _ in zip(range(100), mc2)]

df_ind = pd.DataFrame({'mc1': mc1_results, 'mc2' : mc2_results})
```

```python
df_ind.head()
```

```python
# compare to this
demands = [{truckE5: 1}, {truckE5: 1}]  # Two times truckE5! I want to see if the MC results are paired

mc = bc.LCA(demand=demands[0], method=ipcc, use_distributions=True)
mc.lci()
mc.lcia()

simulations = []

demands = [{truckE5.id: 1}, {truckE5.id: 1}]  

for _ in  zip(range(100), mc):
    mc.score
    mcresults = []    
    for i in demands:
        mc.redo_lcia(i)
        mcresults.append(mc.score)
    simulations.append(mcresults)
    
    
simulations
df_dep = pd.DataFrame(simulations, columns = ['mc1','mc2'])
```

```python
df_dep.head()
```

```python
# visual inspection
df_ind.plot(kind = 'box', title = "independent sampling")
df_dep.plot(kind = 'box', title = "dependent sampling")
```

```python
# Plot them together and one against the other
plt.plot(df_ind.mc1, df_ind.mc2, 'o')
plt.plot(df_dep.mc1, df_dep.mc2, 'o') # see?
```

```python
# and of course:
t_value, p_value = stats.ttest_rel(df_dep.mc1, df_dep.mc2)
print(t_value, p_value)  # no difference AT ALL (as expected)

# t_value, p_value = stats.ttest_rel(df_ind.mc1, df_ind.mc2)
# print(t_value, p_value)  # no difference (as expected! But still some variance even if it's the same perocess!)

# s_value, p_value = stats.wilcoxon(df_ind.mc1, df_ind.mc2)
# print(s_value, p_value)
```

### Additional resources to understand LCA statistics

When applying a statistical approach to LCA, there are some key concepts that is important to understand in detail: distribution types, error propagation, statistical testing. If you are new to statistics, a first step is reading the wikipedia pages explaining [Monte Carlo method](https://en.wikipedia.org/wiki/Monte_Carlo_method), general [statistical hypothesis testing](https://en.wikipedia.org/wiki/Statistical_hypothesis_testing), [parametric](https://en.wikipedia.org/wiki/Parametric_statistics) and [nonparametric](https://en.wikipedia.org/wiki/Nonparametric_statistics) statistics, [normality tests](https://en.wikipedia.org/wiki/Normality_test), [t-test](https://en.wikipedia.org/wiki/Student%27s_t-test#Alternatives_to_the_t-test_for_location_problems), [Wilcoxon signed-rank test](https://en.wikipedia.org/wiki/Wilcoxon_signed-rank_test). When implementing this in Brightway2, it is then useful to read the corresponding python documentation for [statistical functions](https://docs.scipy.org/doc/scipy/reference/stats.html) of the stats package. For example the following functions were used in this script: [Shapiro-Wilk test](https://docs.scipy.org/doc/scipy/reference/generated/scipy.stats.shapiro.html#scipy.stats.shapiro), [paired t-test](https://docs.scipy.org/doc/scipy/reference/generated/scipy.stats.ttest_rel.html#scipy.stats.ttest_rel), and [Wilcoxon signed-rank test](https://docs.scipy.org/doc/scipy/reference/generated/scipy.stats.wilcoxon.html#scipy.stats.wilcoxon). 

If you want to learn more, buy a good introductory statistics book. Ideally one which has a good balance between mathematical expressions and pedagogic explanations. There are also many open source or free ones, I can recommend e.g. [Statistics](https://en.wikibooks.org/wiki/Statistics) which explains testing in general and it's written in a way which is easy to understand, [The Elements of Data Analytic Style](https://leanpub.com/datastyle) which introduces to data analysis in general, and [Statistical inference for data science](http://leanpub.com/LittleInferenceBook) which is is very practical and especially useful if you also know R. In general I would encourage to learn R too if you plan to work with stats - I honestly prefer it to python for doing statistical analysis and also for plots.

### Check also these

#### On Wikipedia

Monte Carlo method 
https://en.wikipedia.org/wiki/Monte_Carlo_method

Normal distribution
https://en.wikipedia.org/wiki/File:Standard_deviation_diagram.svg#/media/File:Standard_deviation_diagram.svg

Parameters of a logrormal distribution
https://en.wikipedia.org/wiki/Log-normal_distribution#/media/File:LogNormal17.jpg

#### On the Brightway website docs

Storing uncertain values
https://2.docs.brightway.dev/intro.html#storing-uncertain-values

#### Papers on this topic (recent ones)

A critique (not very clear tbh but still, a perspective) 
https://pub.epsilon.slu.se/19792/1/von_bromssen_c_et_al_201229.pdf

How many montecarlo runs? 
https://link.springer.com/article/10.1007/s11367-019-01698-4

Ways of doing comparative testing
https://link.springer.com/article/10.1007/s11367-020-01851-4
