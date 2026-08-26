# Brightway 2.5 Assistant

**En AI-hjælper der rent faktisk kan Brightway 2.5.**

Til Advanced LCA-kurset på Aalborg Universitet.

---

## Problemet

Du sidder med en notebook, får en fejlbesked, og spørger Copilot eller ChatGPT om hjælp.
Den svarer med noget der ser rigtigt ud:

```python
import brightway2 as bw
mc = MonteCarloLCA({act: 1}, method)
```

Det virker ikke. Det er **Brightway 2**, som blev afløst for flere år siden. Men AI'en
har lært fra gamle tutorials og gamle Stack Overflow-svar, så den foreslår det med stor
overbevisning — og du bruger en time på at finde ud af, at fejlen ikke var din.

## Løsningen

Denne mappe indeholder et sæt instruktioner, som din AI-hjælper læser automatisk. Bagefter
svarer den:

```python
import bw2calc as bc
mc = bc.LCA({act: 1}, method, use_distributions=True)
```

som er den rigtige måde i Brightway 2.5.

Den kender også de fejl, der er typiske på netop dette kursus — hvorfor `bw2data` ikke kan
findes, selvom du lige har installeret det, hvorfor din database er "locked", og hvorfor
ecoinvent-importen ser ud til at være gået i stå (det er den ikke, den tager bare 20
minutter).

---

## Kom i gang

**→ [GETTING-STARTED.md](GETTING-STARTED.md)** har hele vejledningen på dansk: Python,
AI-hjælper, notebooks og ecoinvent. Regn med 30–60 minutter første gang.

Kort fortalt:

```bash
git clone https://github.com/lotteat11/brightway25-assistant.git
cd brightway25-assistant
conda env create -f environment.yml
conda activate bw25
python -m ipykernel install --user --name bw25 --display-name "Python (bw25)"
```

Åbn så **hele mappen** i VS Code (med Copilot) eller kør `claude` i den.

> **Vigtigt:** Du skal åbne hele mappen — ikke bare en enkelt notebook. Det er sådan,
> værktøjet finder instruktionerne.

Notebooks hentes separat fra
[massimopizzol/advanced-lca-notebooks](https://github.com/massimopizzol/advanced-lca-notebooks).

### Virker det?

Spørg din AI: *"Hvordan laver jeg en Monte Carlo i Brightway 2.5?"*

- Nævner svaret `use_distributions=True` → **det virker**
- Nævner det `MonteCarloLCA` → den læser ikke instruktionerne. Har du åbnet hele mappen?

---

## Sådan bruger du den

Spørg som du ville spørge en kollega, der kan Brightway:

- *"Hvorfor fejler den her celle?"* — indsæt hele fejlbeskeden
- *"Skriv koden der tilføjer lognormal usikkerhed til den her exchange"*
- *"Hvordan finder jeg dansk elproduktion i ecoinvent?"*
- *"Lav et boxplot af mine Monte Carlo-resultater"*

Den skriver koden og forklarer kort, hvad der var galt. Den holder ikke svar tilbage.

**Vil du hellere forstå det end bare få svaret?** Sig det:

> *"Forklar det i stedet for at give mig svaret"*

Så stiller den spørgsmål og giver hints, indtil du selv er der. Du kan altid afbryde med
*"bare vis mig det"*.

**Om referencer:** assistenten finder ikke på kilder. Spørger du, hvor en metode kommer
fra, siger den, at den ikke har referencen — i stedet for at gætte på en forfatter og et
årstal, der kan ende forkert i din rapport.

---

## Hvad ligger hvor

| | |
|---|---|
| `GETTING-STARTED.md` | Opsætningsvejledning til studerende (dansk) |
| `environment.yml` | Python-miljøet — alt der skal installeres |
| `skills/brightway25/` | Selve assistenten |
| `exercises/` | Øvelserne fra notebooks, samlet ét sted |
| `AGENTS.md` | Instruktionerne, i den form Copilot og andre værktøjer læser |

Inde i `skills/brightway25/references/` ligger det, assistenten slår op i:

| | |
|---|---|
| `errors.md` | Fejlbesked → hvad det betyder → hvordan du retter det |
| `setup.md` | Installation, kernels, ecoinvent, projektmapper |
| `bw25-api.md` | Den nuværende API, og hvad der er lavet om siden Brightway 2 |
| `python-primer.md` | De Python-ting notebooks bruger, forklaret |
| `course-map.md` | Alle ti notebooks: hvad de dækker, og hvad der er svært |
| `misconceptions.md` | Hvad studerende typisk misforstår |

---

## Understøttede værktøjer

| Værktøj | |
|---|---|
| **GitHub Copilot** i VS Code | Gratis. Åbn mappen — VS Code læser `AGENTS.md` selv |
| **Claude Code** | Kræver abonnement. Den grundigste version |
| **Cursor** | Åbn mappen — læser `.cursor/rules/` |
| **Andet** | Indsæt `AGENTS.md` i chatten |

---

## For undervisere

**Notebooks ligger ikke her.** De hentes fra Massimos repo, som forbliver den eneste
kilde. Ændres en notebook væsentligt, så opdater
`skills/brightway25/references/course-map.md` — assistenten bruger den til at vide, hvad
der er svært i hver notebook.

**Instruktionerne redigeres ét sted:** `ai-adapters/AGENTS.md`. Kør derefter

```bash
bash ai-adapters/sync-adapters.sh
```

som kopierer dem ud til `AGENTS.md`, `.github/copilot-instructions.md` og
`.cursor/rules/`. Commit de genererede filer — studerende skal ikke køre noget.

`skills/brightway25/SKILL.md` vedligeholdes separat, da Claude Code kan hente
opslagsfiler ind efter behov, hvilket de andre formater ikke kan.

**`misconceptions.md` mangler input.** Den er gættet ud fra notebooks, ikke observeret i
undervisningen, og hvert punkt er markeret med hvor sikkert det er. At rette den er den
mest værdifulde forbedring. De spørgsmål studerende faktisk stiller assistenten *er*
listen.

**Referencer er taget ud** og sættes ind senere. Indtil da siger assistenten, at den ikke
har kilden, frem for at gætte.

---

## Credits

Kursusmateriale af **Massimo Pizzol** —
[advanced-lca-notebooks](https://github.com/massimopizzol/advanced-lca-notebooks),
BSD 3-Clause.

AI-hjælper af **Lotte Ansgaard Thomsen** og **Massimo Pizzol**, Aalborg Universitet.

Brightway er udviklet af [Chris Mutel og Brightway-fællesskabet](https://github.com/brightway-lca).

BSD 3-Clause — se [LICENSE](LICENSE).
