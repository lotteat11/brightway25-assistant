# Exercises

The upstream repository notes that the notebooks are "de-contextualized from the teaching
activities" — they lack the exercises, Q&A and explanation that happen in the room. This
folder is where that context goes back in.

## Status

`exercises-from-notebooks.md` collects the exercises **already embedded in the notebooks**,
pulled out so they can be seen in one place, assigned, and adapted. That extraction is
done and accurate to the source.

Everything beyond that — new exercises, worked solutions, assessment criteria — is for
Lotte and Massimo to write. Nothing here is invented teaching content.

## Suggested structure, if you extend this

```
exercises/
├── README.md
├── exercises-from-notebooks.md    ← extracted from the notebooks (done)
├── solutions/                     ← keep out of the student-facing branch
└── data/                          ← alternative datasets for exercise variants
```

## A note on the assistant

The assistant reads `skills/brightway25/references/course-map.md`, which lists these
exercises. If you add new ones, add a line there too so it knows they exist — otherwise it
will tutor the notebook exercises and be unaware of yours.

If you write solutions, keep them out of any branch students can reach. The assistant will
happily read a solutions file it can see.
