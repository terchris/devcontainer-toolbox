# Investigate: `quickstart` block in template-info.yaml

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Backlog

**Goal**: Make `dev-template <id>`'s "Next steps" output show concrete, runnable commands so the user can see the project working without reading the README first. Each template provides its own quickstart commands via a new `quickstart` block in `template-info.yaml`.

**Priority**: Medium — small UX improvement that compounds over time. Every new user runs `dev-template <id>` once and decides "is this thing easy?" based on what they see next. The current "4. Start building your project" tells them nothing.

**Last Updated**: 2026-04-10

**Related**:
- [INVESTIGATE-host-identity-and-template-defaults.md](INVESTIGATE-host-identity-and-template-defaults.md) — also touches `template-info.yaml` schema and `dev-template.sh`. Sequencing: that work should land first since it's higher priority.

---

## Problem

When a user runs `dev-template python-basic-webserver-database`, the script ends with:

```
📝 Next steps:

   1. Update your terminal (tools were installed):
      source ~/.bashrc

   2. Read the template instructions:
      cat README-python-basic-webserver-database.md

   3. Configure services (database, auth, etc.):
      Edit template-info.yaml params, then run:
      dev-template configure

   4. Start building your project
```

Step 4 is content-free. The user has to either:
- Open the README (~250 lines for the python template) and find the "Run the app" section
- Guess what to run

For the python-basic-webserver-database template specifically, the user needs to know:

```bash
uv venv
uv pip install -r requirements.txt
uv run python app/app.py
```

…and then look at port 3000 in the VS Code Ports tab. None of that is on the user's screen after `dev-template`. They have to go hunting.

**Each template has different start commands** (Python uses `uv`, Node uses `npm`, Go uses `go run`, etc.) so DCT can't hardcode anything. The fix has to come from the template itself.

---

## Proposed solution

Add a `quickstart` block to `template-info.yaml` that each template populates. `dev-template.sh` reads it and prints it as step 4 of "Next steps".

### Schema

```yaml
# In templates/<id>/template-info.yaml
quickstart:
  title: "Run the Flask app"
  commands:
    - uv venv
    - uv pip install -r requirements.txt
    - uv run python app/app.py
  note: |
    Flask debug server starts on port 3000.
    VS Code auto-forwards the port — click the globe icon in the
    Ports tab to open it in your browser.
```

| Field | Type | Required | Purpose |
|---|---|---|---|
| `title` | string | yes | One-line label shown in the heading |
| `commands` | list of strings | yes | Shell commands to run, in order, printed verbatim |
| `note` | multi-line string | no | Free-form text shown after the commands (port info, what to expect, common pitfalls) |

### What `dev-template` would print

When `quickstart` is present:

```
   4. Run your app — Run the Flask app

         uv venv
         uv pip install -r requirements.txt
         uv run python app/app.py

      Flask debug server starts on port 3000.
      VS Code auto-forwards the port — click the globe icon in the
      Ports tab to open it in your browser.
```

When `quickstart` is **absent**, fall back to the current generic message:

```
   4. Start building your project
```

No breakage for templates that haven't migrated.

---

## Design decisions

### Q1 — Structured (`title`/`commands`/`note`) vs freeform string?

| Structured (proposed) | Freeform (`quickstart: \|`) |
|---|---|
| dev-template formats consistently across all templates | Each template can look different |
| Easy to extract just the commands programmatically (e.g., for a future `--exec-quickstart` flag) | Have to parse |
| Clean YAML | Whitespace-sensitive |
| Slightly more constrained — no tables/images/headings | Maximum flexibility |

**Decision: structured**. The constraint is a feature: every template's quickstart looks the same, which is itself a UX win.

### Q2 — Should DCT actually run the commands, or just print them?

Three levels of helpfulness:

1. **Print only** (proposed) — show the commands, user copy-pastes them
2. **Print + offer to run** — `Run them now? [y/N]`. If yes, dev-template execs them sequentially
3. **Auto-run** — runs them immediately after install with no prompt

**Decision: (1) for now**. (1) is safest and easy. (2) adds error-handling complexity (what if `uv venv` fails halfway?). (3) is too magical and might surprise users with side effects (creates a `.venv/`, downloads packages). Add (2) later if users ask.

### Q3 — Should there be a `prerequisite` field?

Some templates won't actually run without first running `dev-template configure` (e.g., the python-basic-webserver-database needs `DATABASE_URL` in `.env`). The user should know that before copy-pasting.

```yaml
quickstart:
  title: "Run the Flask app"
  prerequisite: "Run 'dev-template configure' first to create the database"
  commands: [...]
```

**Decision: omit for now**. The "Next steps" block already orders things: step 3 is "Configure services", step 4 is "Run your app". The ordering implies the dependency. Add a prerequisite field later if it turns out templates need more nuance.

### Q4 — Should `quickstart` support multiple stages?

Some templates have several "things you might want to run":

```yaml
quickstart:
  - title: "Run locally"
    commands: [...]
  - title: "Run tests"
    commands: [...]
  - title: "Build for production"
    commands: [...]
```

**Decision: omit for now**. One quickstart per template keeps the output focused. If a template has many runnable things, document them in the README. Revisit if multiple templates feel constrained.

### Q5 — How should multi-command quickstarts handle failures if Q2 ever moves to "offer to run"?

Defer. Out of scope until Q2 is reopened.

### Q6 — Where does the schema get documented?

Two places:
- `helpers-no/dev-templates/README.md` (template-author guide)
- `helpers-no/devcontainer-toolbox/website/docs/contributors/...` (contributor docs about templates)

Both should reference the field shape and at least one full example.

---

## Code reference

### Files involved

| File | What changes |
|---|---|
| `helpers-no/devcontainer-toolbox/.devcontainer/manage/dev-template.sh` | New parser block that reads `quickstart:` from `template-info.yaml`. New formatter that prints it as step 4. Fall back to current message if absent. |
| `helpers-no/dev-templates/templates/python-basic-webserver-database/template-info.yaml` | First template to migrate. Becomes the canonical example. |
| `helpers-no/dev-templates/templates/<each-other-template>/template-info.yaml` | Migrate over time. Each template author owns their own quickstart. |
| `helpers-no/dev-templates/README.md` | Document the new schema field |
| `helpers-no/devcontainer-toolbox/website/docs/contributors/...` | Document the new schema field on the contributor site |

### Where the change goes in `dev-template.sh`

Currently the "Next steps" block is at the end of `dev-template.sh` (around the same area where it prints "Configure services" and "Start building your project"). We'd add:

1. A small YAML parser for the `quickstart:` block (similar to the existing `params:` parser in `dev-template-configure.sh:81`)
2. After step 3, check if `quickstart` was parsed; if yes, print the new step 4 with title/commands/note; if no, print the old generic step 4.

The parser doesn't need to be sophisticated — `quickstart` is a simple block with three known keys. Same approach as the existing param parser.

---

## Cross-repo coordination

| Repo | Change | Sequencing |
|---|---|---|
| **DCT** | Add parser + new output format to `dev-template.sh`. No behavior change for existing templates (they fall back gracefully). | First |
| **TMP** | Add `quickstart` block to `python-basic-webserver-database/template-info.yaml`. Document schema. Migrate other templates over time. | After DCT lands |

DCT's change is fully backwards-compatible — existing templates without `quickstart` get the old output. So DCT can ship before any template migrates. Templates can migrate at their own pace.

---

## Acceptance criteria

When complete, a user running:

```bash
git clone https://github.com/MyOrg/my-cool-app.git
cd my-cool-app
curl -fsSL .../install.sh | bash
code .
# Reopen in Container
dev-template python-basic-webserver-database
```

Should see "Next steps" output where step 4 contains:

- [ ] A meaningful title (e.g., "Run the Flask app")
- [ ] The literal commands the user can copy-paste, properly indented
- [ ] A note explaining what to expect (port number, where to look in VS Code)
- [ ] No need to read the README to figure out what to run next

And:

- [ ] Templates without a `quickstart` block still print the old generic step 4 (no breakage)
- [ ] The `quickstart` schema is documented in both TMP's template-author guide and DCT's contributor docs
- [ ] At least one template (`python-basic-webserver-database`) has migrated as the canonical example

---

## Out of scope for this investigation

- The "auto-run" feature (Q2 option 3) — defer until users ask
- The "offer to run" feature (Q2 option 2) — defer until users ask
- Multi-stage quickstarts (Q4) — defer until templates feel constrained
- Prerequisite field (Q3) — defer until the simple ordering proves insufficient
- Migrating templates other than `python-basic-webserver-database` — each template's author owns their own migration

---

## Open questions before this becomes a plan

1. **Q1 (structured vs freeform):** Confirm structured
2. **Q2 (run vs print):** Confirm print-only for v1
3. **Q3 (prerequisite field):** Confirm omit for v1
4. **Q4 (multi-stage):** Confirm omit for v1
5. **Naming:** Is `quickstart` the right name? Alternatives: `run`, `start`, `getting_started`, `try_it`. `quickstart` reads naturally and matches the user's mental model.
6. **Sequencing:** Should this wait for `INVESTIGATE-host-identity-and-template-defaults.md` to land first, since both touch `template-info.yaml`? Or can they ship independently?
