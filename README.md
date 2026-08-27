# Brightway 2.5 Assistant

**En AI-kodehjælper der rent faktisk kan Brightway 2.5.**

Til alle der arbejder med Brightway 2.5 og gerne vil have det til at gøre mindre ondt —
LCA-forskere, PhD-studerende, konsulenter. Og til studerende på Advanced LCA-kurset på
Aalborg Universitet, som det oprindeligt blev bygget til.

Du behøver ikke være god til Python. Det er netop pointen.

---

## Hvorfor findes det her

Brightway blev omskrevet fra version 2 til 2.5. API'et ændrede sig grundlæggende:
`brightway2` blev splittet i `bw2data`, `bw2calc` og `bw2io`, og `MonteCarloLCA`
forsvandt helt.

Men alle de tutorials, blogindlæg og Stack Overflow-svar, som AI-modeller er trænet på,
er skrevet til den **gamle** version. Så når du spørger Copilot eller ChatGPT om
Brightway, får du med stor sandsynlighed noget i denne stil:

```python
import brightway2 as bw                          # findes ikke i 2.5
mc = MonteCarloLCA({act: 1}, method)             # fjernet i 2.5
for _ in range(500):
    next(mc)
```

Det ser overbevisende ud. Det virker ikke. Og fordi fejlen er en `ImportError` og ikke
noget der peger på API-versionen, bruger du en time på at lede efter en fejl, du ikke
selv har lavet.

Denne assistent svarer i stedet:

```python
import bw2calc as bc
mc = bc.LCA({act: 1}, method, use_distributions=True)
mc.lci(); mc.lcia()
results = [mc.score for _ in zip(range(500), mc)]
```

som er den rigtige måde i 2.5.

---

## Hvordan virker det

Der er ingen server, intet der kører i baggrunden, og ingen model der er trænet om. Det
er **strukturerede tekstfiler**, som dit AI-værktøj læser, når du åbner mappen.

```
Du åbner mappen i VS Code
        ↓
Copilot læser AGENTS.md automatisk
        ↓
Du spørger: "hvorfor fejler den her celle?"
        ↓
AI'en svarer med Brightway 2.5-viden i konteksten
```

Instruktionerne indeholder tre slags viden:

**1. Hvad der er lavet om siden Brightway 2.** En oversættelsestabel, så AI'en ikke
falder tilbage på det, den har lært fra gamle kilder.

| Gammel (Brightway 2) | Brightway 2.5 |
|---|---|
| `import brightway2 as bw` | `import bw2data as bd`, `import bw2calc as bc` |
| `bw.LCA(...)` | `bc.LCA(...)` |
| `MonteCarloLCA(demand, method)` | `bc.LCA(demand, method, use_distributions=True)` |
| `bw2setup()` | `bi.import_ecoinvent_release()` henter biosphere med |

**2. De fejl der faktisk opstår.** Ikke generel Python-fejlfinding, men de konkrete
fejlbeskeder man møder i Brightway — hvad de betyder, og hvad der retter dem. Med særlig
vægt på ecoinvent, hvor de fleste går i stå.

**3. Kursets struktur.** Hvilken notebook dækker hvad, og hvor folk typisk går i stå.
Relevant hvis du følger kurset — ellers kan du se bort fra den del.

---

## Et par eksempler på forskellen

**Manglende pakke**

> `ModuleNotFoundError: No module named 'bw2data'`

*Generisk AI:* "Prøv `pip install bw2data`."
Det virker ikke, for pakken **er** installeret — notebooken kører bare på en anden
Python. Man installerer igen. Og igen.

*Denne assistent:* "Kør `import sys; print(sys.executable)`. Står der ikke `bw25` i
stien, er kernen forkert — Kernel → Change Kernel. Installer ikke igen, det installerer
bare det samme det forkerte sted."

**Usikkerhed der ser forkert ud**

> "Min Monte Carlo giver helt vanvittige tal."

*Generisk AI:* gætter på fordelingen, foreslår flere iterationer.

*Denne assistent:* ved at `loc` og `scale` i Brightway er **logaritmer** — `np.log(1.2)`,
ikke `1.2` — og at negative amounts skal negeres først, fordi `np.log()` af et negativt
tal ikke er defineret. To fejl der ikke giver nogen fejlbesked, bare forkerte tal.

**Kode der ser tom ud**

> "Min løkke over exchanges kører ikke anden gang."

*Generisk AI:* leder efter en logisk fejl i løkken.

*Denne assistent:* ved at `.exchanges()` returnerer en generator, som kun kan bruges én
gang. Fejlbesked: ingen. Løsningen: `list(act.exchanges())`.

---

## Ecoinvent — den største forhindring

Det er her, folk taber mest tid, og det er sjældent et Python-problem. Derfor er der en
tjekliste både i [GETTING-STARTED.md](GETTING-STARTED.md) og i assistentens opslagsfiler.

Det vigtigste, som næsten ingen ved:

> **Du skal logge ind på [ecoinvent.org](https://ecoinvent.org) i en browser og acceptere
> licensaftalen og databehandlingsaftalen, før API'et overhovedet virker.**
>
> En helt ny konto, der aldrig har været logget ind via hjemmesiden, bliver afvist fra
> Python — og fejlbeskeden nævner ikke aftaler med ét ord. Man kan lede meget længe efter
> en fejl i sin kode, som slet ikke er der.

Resten af tjeklisten dækker:

- **Institutionslogin er ikke det samme som en ecoinvent-konto.** Går du gennem AAU's
  portal, har du måske slet ikke et brugernavn og kodeord at bruge.
- **Importen tager 10–30 minutter uden fremdriftsindikator.** Cellen viser `[*]` og ser
  død ud. Afbryder du, kan du ende med en halvt importeret database, der fejler
  forvirrende bagefter.
- **`version='3.11'` er tekst**, ikke et tal.
- **Kodeord i notebooks** — hvordan du undgår det, og hvordan du gemmer det én gang for
  alle med `permanent_setting()`.
- **Advarslen om geocollections er harmløs.** Importen lykkedes.

Assistenten kender alle disse — og tjekker licensaftalen *først*, i stedet for at lede
efter fejl i din kode.

---

## Kom i gang

**→ [GETTING-STARTED.md](GETTING-STARTED.md)** har hele vejledningen på dansk: Python,
AI-værktøj, notebooks og ecoinvent. Regn med 30–60 minutter første gang.

Kort fortalt:

```bash
git clone https://github.com/lotteat11/brightway25-assistant.git
cd brightway25-assistant

conda env create -f environment.yml
conda activate bw25
python -m ipykernel install --user --name bw25 --display-name "Python (bw25)"
```

Åbn så **hele mappen** i VS Code (med Copilot) eller kør `claude` i den.

> **Vigtigt:** Åbn hele mappen — ikke bare en enkelt notebook. Det er sådan, værktøjet
> finder instruktionerne.

Notebooks hentes separat fra
[massimopizzol/advanced-lca-notebooks](https://github.com/massimopizzol/advanced-lca-notebooks).

### Virker det?

Spørg din AI: *"Hvordan laver jeg en Monte Carlo i Brightway 2.5?"*

- Svaret nævner `use_distributions=True` → **det virker**
- Svaret nævner `MonteCarloLCA` → instruktionerne læses ikke. Har du åbnet hele mappen?

---

## Sådan bruger du den

Spørg som du ville spørge en kollega, der kan Brightway:

- *"Hvorfor fejler den her celle?"* — indsæt hele fejlbeskeden, også det der ser
  irrelevant ud
- *"Skriv koden der tilføjer lognormal usikkerhed til den her exchange"*
- *"Hvordan finder jeg dansk elproduktion i ecoinvent?"*
- *"Lav et boxplot af mine Monte Carlo-resultater"*
- *"Hvad betyder ST > S1 i min følsomhedsanalyse?"*

Den skriver koden og forklarer kort, hvad der var galt. **Den holder ikke svar tilbage** —
udgangspunktet er, at du vil videre med dit arbejde.

**Vil du hellere forstå det end bare få svaret?** Sig det:

> *"Forklar det i stedet for at give mig svaret"*

Så skifter den til at stille spørgsmål, give hints og vise et **beslægtet** eksempel — med
andre tal end din egen opgave — før den til sidst giver svaret. Du kan altid afbryde med
*"bare vis mig det"*.

**Om referencer:** assistenten finder ikke på kilder. Spørger du, hvor en metode kommer
fra, siger den, at den ikke har referencen, frem for at gætte på forfatter og årstal.
Referencelisten sættes ind senere.

---

## Hvad ligger hvor

| | |
|---|---|
| [`GETTING-STARTED.md`](GETTING-STARTED.md) | Opsætningsvejledning til studerende (dansk) |
| [`environment.yml`](environment.yml) | Python-miljøet — alt der skal installeres |
| [`skills/brightway25/`](skills/brightway25/) | Selve assistenten |
| [`exercises/`](exercises/) | Øvelserne fra de ti notebooks, samlet ét sted |
| [`AGENTS.md`](AGENTS.md) | Instruktionerne i den form Copilot og andre værktøjer læser |
| [`ai-adapters/`](ai-adapters/) | Kilde til de værktøjsspecifikke filer |

### Assistentens opslagsfiler

`skills/brightway25/SKILL.md` styrer, hvordan den opfører sig. Resten slår den op i efter
behov:

| Fil | Indhold |
|---|---|
| [`errors.md`](skills/brightway25/references/errors.md) | 20 konkrete fejlbeskeder → hvad de betyder → hvordan de rettes. Database-, beregnings-, ecoinvent- og Python-fejl |
| [`setup.md`](skills/brightway25/references/setup.md) | Installation, kernel-problemer, projektmapper, synkroniserede mapper, **ecoinvent-tjekliste**, Windows/macOS-særheder |
| [`bw25-api.md`](skills/brightway25/references/bw25-api.md) | Den nuværende API gennemgået: projekter, databaser, activities, exchanges, LCIA-metoder, Monte Carlo, følsomhedsanalyse — plus oversættelsestabellen fra Brightway 2 |
| [`python-primer.md`](skills/brightway25/references/python-primer.md) | De Python-idiomer notebooks bruger: dicts, tuple-nøgler, comprehensions, generators, `zip(range(500), mc)`-mønsteret, pandas og numpy — kun det nødvendige |
| [`course-map.md`](skills/brightway25/references/course-map.md) | Alle ti kursus-notebooks: hvad de dækker, hvad der kræves først, og hvor det er svært |
| [`misconceptions.md`](skills/brightway25/references/misconceptions.md) | Otte typiske misforståelser — ikke kodefejl, men fejl i *forståelsen*, fx at OAT-resultater gælder globalt |
| `SKILL.md` | Hvordan assistenten opfører sig: hjælper som standard, underviser kun på opfordring |

---

## Understøttede værktøjer

| Værktøj | Sådan | Bemærkning |
|---|---|---|
| **GitHub Copilot** i VS Code | Åbn mappen | Gratis plan er nok. VS Code læser `AGENTS.md` selv |
| **Claude Code** | `claude` i mappen | Den grundigste version — henter opslagsfiler ind efter behov |
| **Cursor** | Åbn mappen | Læser `.cursor/rules/` |
| **Andet** | Indsæt `AGENTS.md` i chatten | Virker også i claude.ai og ChatGPT |

Claude Code-versionen er stærkest, fordi den kan hente de detaljerede opslagsfiler ind, når
de er relevante. De øvrige får én samlet instruktionsfil — mindre grundig på
tutor-delen, men kender stadig API-fælderne og fejlene.

---

## For undervisere

**Assistenten har to tilstande.** Standard er ren kodehjælp: den skriver koden, forklarer
kort, og går videre. Tutor-tilstanden — hvor den stiller spørgsmål i stedet for at svare —
aktiveres **kun**, når studenten beder om det ("forklar det", "hjælp mig med at forstå").

Det er et bevidst valg: en studerende der sidder fast i en `ModuleNotFoundError` kl. 22
lærer ikke LCA, men brænder den tid af, som skulle gå til LCA.

**Det håndhæver ingenting.** En studerende kan åbne en ny chat og spørge direkte. Det er et
undervisningsredskab, ikke en eksamensvagt — integritet hører hjemme i, hvordan der
bedømmes.

**Notebooks ligger ikke her.** De hentes fra Massimos repo, som forbliver den eneste kilde.
Ændres en notebook væsentligt, så opdater `course-map.md` tilsvarende — assistenten bruger
den til at vide, hvad der er svært hvor, og en forældet beskrivelse gør den selvsikkert
forkert.

**Instruktionerne redigeres ét sted:** `ai-adapters/AGENTS.md`. Kør derefter

```bash
bash ai-adapters/sync-adapters.sh
```

som kopierer dem ud til `AGENTS.md`, `.github/copilot-instructions.md` og
`.cursor/rules/`. Commit de genererede filer — studerende skal ikke køre noget.
`skills/brightway25/SKILL.md` vedligeholdes separat.

**`misconceptions.md` mangler input.** Den er udledt af, hvor notebooks selv advarer eller
gentager sig — ikke observeret i undervisningen. Hvert punkt er markeret med, hvor sikkert
det er. At rette den er den mest værdifulde forbedring, der kan laves. Filen har en dateret
sektion nederst til løbende noter: **de spørgsmål studerende faktisk stiller assistenten
er den rigtige liste.**

**Referencer er taget ud** og sættes ind senere. Indtil da siger assistenten, at den ikke
har kilden.

---

## Credits

Kursusmateriale af **Massimo Pizzol** —
[advanced-lca-notebooks](https://github.com/massimopizzol/advanced-lca-notebooks),
BSD 3-Clause.

Assistent af **Lotte Ansgaard Thomsen** og **Massimo Pizzol**, Aalborg Universitet.

Brightway er udviklet af
[Chris Mutel og Brightway-fællesskabet](https://github.com/brightway-lca).

BSD 3-Clause — se [LICENSE](LICENSE).
