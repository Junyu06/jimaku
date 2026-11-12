# Agent rules

This file is the only shared entry point for coding agents. It holds behavior rules and the reading order. **It holds no project facts**; facts live in `docs/`.

## Reading order

1. This file.
2. `AGENTS.local.md` in the repository root, if it exists (machine-local notes, gitignored).
3. `docs/README.md`, then only the `docs/` files whose names match the task. Run `ls` on a directory before opening anything in it.
4. `docs/pitfalls/`, if it exists, before touching code or configuration.
5. The `docs/workflows/` file for the procedure you are about to run, if it exists.

## The one documentation rule

**One file states one proposition, the file name is the proposition, and the directory is the kind of proposition.** Each directory's README says what question its files answer; content that cannot be phrased as an answer to that question does not belong there.

- Before adding, changing, or moving any document, reread `docs/README.md` and the target directory's `README.md`, then `ls` that directory. Follow the current rules, not the memory of an earlier session or the habits of another repository. `docs/README.md` decides where root-level instruction files belong.
- If an existing file already carries the same proposition, edit it in place. Otherwise create a new file named after the proposition in the matching directory. If no directory matches, raise a specific question about where it belongs; do not invent a directory or rename content to make it fit. Never append a second topic to an existing file.
- Every maintained document has one current location. Change it in place; Git keeps the history. Record the reason for a change under `docs/decisions/` using its supersede rule.
- Repository documents carry only confirmed facts, accepted decisions, and plans being executed. Keep accepted future work clearly apart from behavior that is implemented and verified. Proposals awaiting a decision and raw handoff material stay outside the repository. The repository must state every accepted requirement needed to do the work, so a reader never has to dig through chat history to start. Checking accepted content for accuracy is normal review; review alone does not approve a new design.
- A file name states the proposition itself, so reading the name tells you what the file asserts. Split plans, reports, and session output into one file per proposition before committing them.
- Do not create new top-level directories. A code directory is created only when a file in `docs/architecture/` names that component, and it takes the same name.
- A file longer than about 300 lines almost always holds two propositions; split it. Requirement documents are the exception: one feature per file, no length limit.
- Create a `docs/` subdirectory only when its first file is needed, and add a README saying what question it answers.

## Boundary

### What you may write

- **Write directly:** code and tests named by the task; one new file each under `docs/decisions/`, `docs/cases/`, `docs/pitfalls/`, `docs/runbook/failures/`; the requirement or document that corresponds to the task's change.
- **Write only when the task explicitly authorizes it:** paths listed in `docs/conventions/frozen-paths.md` once that file exists; refactors across modules; this file and the root README; pushes to `main`.
- **Never write:** secrets (write a pointer to where they live); generated files, caches, build output; someone else's unfinished work; material moved into an official location as if it were approved.
- Read-only by default. Do not touch directories the task did not name.

### What counts as a test case

One case = one fixture + one expected observable result + one sentence stating the property it proves. Missing any of the three, it is not a case. The result must be observable from outside (a verdict, a call count, a receipt, a file); "it ran without errors" is not a result. Simulated cases are marked `status: simulated` under `docs/cases/`, and a passing simulation never stands in for the real path. Failure cases rank equal to normal cases. A case that was not run is recorded as `not-run`, never as passed.

For this project, behavior that depends on screen broadcast, Picture in Picture, or background execution is verified only on a physical device. A simulator run is a simulation.

### Definition of done

- Changed product code comes with passing tests and the matching documentation change; otherwise do not push.
- Passing locally is not shipping. Claim that something works on a device only with evidence from that device.
- Without runtime evidence, do not describe anything as working, stable, or released.
- At every completion point (opening a pull request, merging, finishing a plan step, ending a session), update the documents touched or learned from in this task, and nothing beyond it.
- Language follows the repository: English, including comments and commit messages.

### Irreversible actions need separate authorization every time

Spending money; publishing (registering, posting, releasing a package or build, making a repository public); pushing to `main`; deleting or rewriting someone else's work; security and signing configuration. One authorization covers one action.

## Local overrides

`AGENTS.local.md` is gitignored. It holds only machine-local notes and pointers, never repository facts and never secrets. Anything a collaborator would need is promoted into `docs/`.
