# docs/ directory guide

**One file states one proposition, the file name is the proposition, and the directory is the kind of proposition.** People and coding agents read the same files, all placed in the directories listed below. History lives in Git; files that describe current state are edited in place.

## What may be committed

Repository documents carry only confirmed facts, accepted decisions, and plans being executed. Accepted future work must be kept apart from behavior that is implemented and verified, and gaps in evidence are stated plainly. Proposals awaiting a decision and raw handoff material stay outside the repository; checking accepted content for accuracy is normal review.

Every maintained document has one current location and is updated in place; Git keeps the history. The reason for a change is kept under `decisions/`, following its supersede rule. A document may link to an outside discussion as its source, but the repository itself must contain the accepted requirements that later work depends on.

## Which directory answers which question

Directories are created when their first file is needed. Each gets a README stating the question below.

| Directory | Each file here answers | File name | Lifecycle |
|---|---|---|---|
| `domain/` | What exists in this product's world, and which rule must never break? | The proposition | Edited in place |
| `glossary.md` | What does this word mean here? | One table | Edited in place |
| `architecture/` | What is component X and what may it depend on? Or: which statement about the system's structure holds? | Component name or structural proposition | Edited in place; code directories take their names from here |
| `prd/` | How must feature X behave, and what counts as accepted? | Feature name | One feature per file, no length limit |
| `cases/` | Input I must produce observable result O, proving property P. | `<area>-<nnn>-<proposition>` | Frontmatter `status` |
| `decisions/` | Why A instead of B, or why C was rejected? | `YYYY-MM-DD-<proposition>` | Append only; overturn with a new file and mark the old one superseded |
| `conventions/` | What is the one allowed way to write code here? | The rule itself | Edited in place |
| `workflows/` | How exactly is X done, every time? | `<verb>-<object>` | Edited in place |
| `runbook/` | Where does this run, and what do you do when it breaks? | Environment or procedure name | Edited in place |
| `runbook/failures/` | When symptom X appears, what is the cause and the fix? | The symptom | One symptom per file |
| `pitfalls/` | What must not happen again, and why? | The lesson | One lesson per file |
| `plans/` | What are the steps of the work in progress? | `YYYY-MM-DD-<goal>` | **Deleted once executed**; conclusions move to `decisions/` or `prd/` first |

Discussion drafts are not stored in the repository. Splitting or renaming a pending proposal does not turn it into an accepted document.

## Before writing

1. Before adding, changing, or moving any document, reread this file and the target directory's `README.md`, then `ls` that directory. This file decides where root-level instruction files belong. Do not rely on the memory of an earlier session or on another repository's habits.
2. Confirm the content is a confirmed fact, an accepted decision, or an accepted plan. If an existing file already carries the same proposition, edit it in place.
3. Otherwise name a new file after the proposition. If no directory matches, raise a specific question about where it belongs; do not invent a location.
4. Split accepted compound content into single-proposition files; raw material stays outside the repository.

## Frontmatter

Only `cases/` and `runbook/failures/` carry frontmatter, because they are filtered by `status` and `area`. Files under `decisions/` carry a three-line header (date, status, supersedes). No other file carries one.

## Language

English throughout, including comments and commit messages.
