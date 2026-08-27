# Kom i gang

Denne guide tager dig fra ingenting til en fungerende opsætning, hvor din AI-assistent
kender Brightway 2.5. Regn med **30–60 minutter** første gang, plus ventetid på
ecoinvent-download.

Du skal igennem fire ting:

1. [Installer Python-miljøet](#1-python-miljøet) — 10 min
2. [Sæt AI-assistenten op](#2-ai-assistenten) — 10 min
3. [Hent kursusmaterialet](#3-kursusmaterialet) — 2 min
4. [Hent ecoinvent](#4-ecoinvent) — 5 min opsætning + 10–30 min download

Gå i rækkefølge. Punkt 4 kan vente til notebook 3.

> **Hvis noget går galt:** spring til [Når det driller](#når-det-driller) nederst. De tre
> hyppigste problemer står der, og du kan også bare spørge AI-assistenten — den er sat op
> til at kende netop disse fejl.

---

## 1. Python-miljøet

Du skal bruge **conda**. Har du det ikke, installer
[Miniforge](https://github.com/conda-forge/miniforge#download) (anbefalet, gratis, virker
på Mac/Windows/Linux).

Åbn en terminal (Mac: Terminal · Windows: **Anaconda Prompt**, ikke PowerShell):

```bash
git clone https://github.com/lotteat11/brightway25-assistant.git
cd brightway25-assistant

conda env create -f environment.yml
conda activate bw25
python -m ipykernel install --user --name bw25 --display-name "Python (bw25)"
```

Den sidste linje registrerer miljøet, så Jupyter kan se det. **Spring den ikke over** —
det er den hyppigste kilde til problemer senere.

Tjek at det virker:

```bash
python -c "import bw2data, bw2calc; print('OK')"
```

---

## 2. AI-assistenten

Vælg ét af de to. **Copilot er gratis** og det oplagte valg, hvis du ikke allerede har
noget.

### Mulighed A: GitHub Copilot i VS Code (gratis)

1. Installer [VS Code](https://code.visualstudio.com/)
2. Opret en [GitHub-konto](https://github.com/signup) hvis du ikke har en
3. Åbn VS Code → klik **Copilot-ikonet** i statuslinjen nederst → **Use AI Features**
4. Log ind med din GitHub-konto

Du bliver automatisk sat på **Copilot Free**, som har en månedlig kvote. Det rækker fint
til kurset.

> **Er du studerende?** Ansøg om [GitHub Student Developer Pack](https://education.github.com/pack)
> og få Copilot Pro gratis — ingen kvote. Verificering tager typisk et par dage, så start
> med Free imens.

**Vigtigt — åbn den rigtige mappe.** Assistenten virker kun, når `brightway25-assistant`-mappen
er åben i VS Code:

```
File → Open Folder… → vælg brightway25-assistant
```

VS Code læser så automatisk `AGENTS.md` og `.github/copilot-instructions.md`. Du skal ikke
gøre noget aktivt. Åbner du en notebook alene uden mappen, får du en almindelig Copilot
uden Brightway-viden.

Du får også brug for **Jupyter**-udvidelsen til at køre notebooks (VS Code foreslår den
selv, når du åbner en `.ipynb`-fil).

### Mulighed B: Claude Code

Kræver et Claude-abonnement eller en API-nøgle.

```bash
npm install -g @anthropic-ai/claude-code
cd brightway25-assistant
claude
```

Claude Code læser `skills/brightway25/` automatisk. Denne version er den grundigste —
den henter detaljerede opslagsfiler ind efter behov.

### Virker det?

Spørg din assistent:

> *Hvordan laver jeg en Monte Carlo-simulering i Brightway 2.5?*

**Rigtigt svar** nævner `bc.LCA(..., use_distributions=True)`.
**Forkert svar** nævner `MonteCarloLCA` — så læser den ikke instruktionerne. Tjek at du
har åbnet hele mappen, ikke bare en enkelt fil.

---

## 3. Kursusmaterialet

Notebooks ligger i Massimos repo og hentes separat:

```bash
git clone https://github.com/massimopizzol/advanced-lca-notebooks.git
```

Du skal bruge mappen `Course-material-bw25`. Læg den gerne ved siden af
`brightway25-assistant`, eller flyt den ind i mappen — begge dele virker.

Åbn en notebook og **vælg den rigtige kernel**:

```
Kernel → Change Kernel → Python (bw25)
```

Dette trin bliver glemt hele tiden. Uden det får du `ModuleNotFoundError`, uanset hvor
mange gange du installerer.

---

## 4. Ecoinvent

**Det er her, de fleste går i stå.** Tag trinene i rækkefølge — hvert trin udelukker en
hel type problem. Bruges fra notebook 3.

### Trin 0: Log ind på hjemmesiden og accepter aftalen

> **Det vigtigste trin, og det der oftest springes over.**

Gå til [ecoinvent.org](https://ecoinvent.org), log ind, og **accepter licensaftalen og
databehandlingsaftalen**.

Har du aldrig logget ind i en browser, **virker din konto ikke fra Python** — uanset at
brugernavn og kodeord er rigtige. Og fejlbeskeden siger ikke noget om aftaler, så du kan
lede længe.

Virker login på hjemmesiden ikke, hjælper det ikke at prøve i Python.

### Trin 1: Tjek at du har en rigtig ecoinvent-konto

Bruger du normalt ecoinvent gennem AAU's portal, har du måske **ikke** et direkte
brugernavn og kodeord. Det er ikke det samme som dit AAU-login.

Kan du logge ind direkte på ecoinvent.org med brugernavn og kodeord? Så er du klar.
Ellers skal du have oprettet adgang først — spørg din vejleder eller biblioteket.

### Trin 2: Installer pakken

```bash
conda activate bw25
conda install -c conda-forge ecoinvent_interface
```

### Trin 3: Kør importen

```python
import bw2io as bi

bi.import_ecoinvent_release(
    version='3.11',
    system_model='consequential',
    username='DIT-BRUGERNAVN',
    password='DIT-KODEORD')
```

Bemærk at `version` og `system_model` er **tekst** — `'3.11'` med anførselstegn, ikke
`3.11`. Systemmodeller: `'cutoff'`, `'consequential'`, `'apos'`.

### Trin 4: Vent — og afbryd ikke

**Importen tager 10–30 minutter uden nogen fremdriftsindikator.** Cellen viser `[*]` og
ser fuldstændig død ud.

> **Den er ikke gået i stå.** Lad den køre.

Afbryder du, kan du ende med en halvt importeret database, der fejler på forvirrende måder
bagefter. Er det allerede sket, er det hurtigste at slette projektet og starte forfra:

```python
import bw2data as bd
bd.projects.delete_project('projektnavn', delete_dir=True)
```

Vær opmærksom på **pladsen**: hvert ecoinvent-projekt fylder flere GB.

---

### Undgå at dit kodeord ender i notebooken

Deler du din notebook, følger kodeordet med. Vælg én af disse:

**Spørg hver gang** — intet gemmes:
```python
import getpass
username = input('ecoinvent brugernavn: ')
password = getpass.getpass('ecoinvent kodeord: ')
```

**Gem det én gang** — så skal du aldrig skrive det igen:
```python
from ecoinvent_interface import permanent_setting
permanent_setting("username", "dit-brugernavn")
permanent_setting("password", "dit-kodeord")
```
Derefter kan du kalde `import_ecoinvent_release()` uden `username` og `password`.

---

### Når det stadig ikke virker

| Symptom | Sandsynlig årsag |
|---|---|
| Login afvises, men kodeordet er rigtigt | Aftalen er ikke accepteret på hjemmesiden — **trin 0** |
| Du har aldrig logget ind i browseren | Samme — gå til ecoinvent.org først |
| Virker hos en kollega, ikke hos dig | Jeres licenser dækker forskellige versioner |
| `version` eller `system_model` afvises | Skrevet som tal i stedet for tekst, eller ikke dækket af din licens |
| Cellen kører i det uendelige | Normalt. 10–30 min. Afbryd ikke |
| Importen fejlede, og nu opfører den sig sært | Halvt importeret projekt — slet det og start forfra |
| *"Not able to determine geocollections"* | **Harmløs advarsel.** Importen lykkedes |

Er du stadig blokeret, så spørg assistenten og indsæt hele fejlbeskeden — den kender netop
disse problemer.

---

## Når det driller

### `ModuleNotFoundError: No module named 'bw2data'`

Det hyppigste problem. Pakken er der — notebooken kører bare på en anden Python.

Kør dette i notebooken:

```python
import sys; print(sys.executable)
```

Står der ikke `bw25` i stien, er kernen forkert:
**Kernel → Change Kernel → Python (bw25)**

**Installer ikke igen.** Det installerer bare det samme det forkerte sted.

### `Database ... is locked`

To notebooks er åbne på samme projekt. Luk de andre (i Jupyter: fanen **Running** →
Shutdown), eller genstart kernen.

Tommelfingerregel: **én notebook ad gangen per projekt.**

### AI'en foreslår kode der ikke virker

Foreslår den `import brightway2 as bw` eller `MonteCarloLCA`, bruger den den gamle
Brightway 2. Sig til den:

> *Det er Brightway 2. Vi bruger Brightway 2.5 — brug bw2data og bw2calc.*

Sker det tit, læser den ikke instruktionerne. Tjek at hele `brightway25-assistant`-mappen er
åben.

### Noget helt tredje

Spørg assistenten og indsæt hele fejlbeskeden. Den kender de fejl, der er typiske på dette
kursus. Kopier hele beskeden med — også det der ser irrelevant ud.

---

## Sådan bruger du den

Den er en **kodeassistent**. Spørg løs, som du ville spørge en kollega:

- *"Hvorfor giver den her celle en fejl?"* — indsæt fejlbeskeden
- *"Skriv koden der tilføjer lognormal usikkerhed til den her exchange"*
- *"Hvordan finder jeg elproduktion i Danmark i ecoinvent?"*
- *"Lav et boxplot af mine Monte Carlo-resultater"*

Den skriver koden og forklarer kort. Den holder ikke svar tilbage.

**Vil du hellere lære det end få svaret?** Så sig det:

- *"Forklar det i stedet for at give mig svaret"*
- *"Hjælp mig med at forstå hvorfor det virker"*

Så stiller den spørgsmål og giver hints i stedet. Du kan altid afbryde med *"bare vis mig
det"*.

**Assistenten finder ikke på referencer.** Spørger du, hvor en metode kommer fra, siger
den, at den ikke har kilden — i stedet for at gætte på en forfatter og et årstal. Kig i
notebooken eller slides.
