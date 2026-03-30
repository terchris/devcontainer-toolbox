# Investigate: Restructure ai-development folder

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Completed

**Completed**: 2026-03-30

**Goal**: Determine how to restructure `website/docs/ai-development/` — move `ai-developer/` up to `website/docs/ai-developer/` and decide what to do with remaining files.

**Last Updated**: 2026-03-30

---

## Questions to Answer

1. What is the content and purpose of each file in `ai-development/` (outside `ai-developer/`)?
2. Is there overlap or duplication between `ai-development/` files and `ai-developer/` files?
3. What references/links point to these paths (CLAUDE.md, other docs, plan files)?
4. What should happen to `ai-docs/` — merge into `ai-developer/`, keep separate, or remove?
5. Can `ai-development/` be fully eliminated after the move?
6. What is the impact on Docusaurus sidebar navigation?

---

## Current State

```
website/docs/ai-development/               ← parent category "AI Development" (sidebar pos 5)
├── _category_.json                         ← label: "AI Development", position: 5
├── index.md                                ← "Developing with AI" user-facing intro page
├── creating-plans.md                       ← user-facing plan guide (simplified version)
├── workflow.md                             ← user-facing workflow guide (simplified version)
├── ai-developer/                           ← "AI Developer (Internal)" (sidebar pos 4, collapsed)
│   ├── _category_.json                     ← label: "AI Developer (Internal)"
│   ├── README.md
│   ├── PLANS.md                            ← full plan reference (used by Claude via CLAUDE.md)
│   ├── WORKFLOW.md                         ← full workflow reference (used by Claude via CLAUDE.md)
│   ├── CREATING-SCRIPTS.md                 ← script conventions (used by Claude via CLAUDE.md)
│   ├── CREATING-TOOL-PAGES.md
│   └── plans/
│       ├── backlog/    (9 files)
│       ├── active/     (1 file)
│       └── completed/  (42 files)
└── ai-docs/                                ← "AI Demos & Recordings" (sidebar pos 5, collapsed)
    ├── _category_.json                     ← label: "AI Demos & Recordings"
    ├── developing-using-ai.md              ← longer version of index.md with full GIF
    └── CREATING-RECORDINGS.md              ← how to create asciinema recordings
```

---

## Investigation

### File-by-file analysis of ai-development/ (top level)

| File | Purpose | Duplicated in ai-developer/? |
|------|---------|------------------------------|
| `index.md` | User-facing intro: "Developing with AI" — cage/plan/tests concept, getting started with Claude Code | No — unique user-facing content |
| `creating-plans.md` | User-facing plan guide — simplified version of PLANS.md | **YES — simplified duplicate of `ai-developer/PLANS.md`**. Same content but shorter, less technical, uses Docusaurus admonitions |
| `workflow.md` | User-facing workflow guide — simplified version of WORKFLOW.md | **YES — simplified duplicate of `ai-developer/WORKFLOW.md`**. Same flow but shorter, no feature branch explanation, no version management |
| `_category_.json` | Docusaurus sidebar: "AI Development" at position 5 | N/A |

### File-by-file analysis of ai-docs/

| File | Purpose | Duplicated? |
|------|---------|-------------|
| `developing-using-ai.md` | **Near-duplicate of `index.md`** — same cage/plan/tests structure, but with full GIF instead of teaser, links to ai-developer/ docs | **YES — very similar to `ai-development/index.md`** |
| `CREATING-RECORDINGS.md` | How to create asciinema recordings + convert to GIF | No — unique contributor guide |
| `_category_.json` | Sidebar: "AI Demos & Recordings" at position 5 | N/A |

### References to current paths

**CLAUDE.md** (6 references — most critical):
- `website/docs/ai-developer/PLANS.md`
- `website/docs/ai-developer/WORKFLOW.md`
- `website/docs/ai-developer/CREATING-SCRIPTS.md`
- `website/docs/ai-developer/plans/` (backlog, active)
- `website/docs/ai-developer/` (2 more general references)

**Internal docs** (cross-references in 19 files):
- `workflow.md` → references `ai-developer/plans/backlog/`
- `creating-plans.md` → references `ai-developer/plans/`
- `developing-using-ai.md` → multiple references to `../ai-developer/`
- `contributors/website.md` → directory tree shows `ai-development/`
- `ai-developer/WORKFLOW.md` → 3 full path references
- `ai-developer/PLANS.md` → 2 full path references
- `ai-developer/_category_.json` → `id: "ai-developer/README"`
- 9 completed plan files reference the path:
  - `PLAN-update-dev-template-repo-name.md`
  - `PLAN-docusaurus-website.md`
  - `PLAN-developer-extension-documentation.md`
  - `PLAN-auto-generate-commands-md.md`
  - `PLAN-ai-developer-folder.md`
  - `PLAN-011-prebuilt-container-image.md`
  - `PLAN-004-tool-display-components.md`
  - `PLAN-003-extended-metadata.md`
  - `INVESTIGATE-lightweight-powershell.md`
  - `INVESTIGATE-docusaurus-enhancements.md`
- 2 backlog files reference the path:
  - `INVESTIGATE-ai-workflow-installer.md`
  - `PLAN-010-config-refactor.md`

### Docusaurus config and component references

| File | Line | Reference | Notes |
|------|------|-----------|-------|
| `website/src/components/AiDemo/index.tsx` | 24 | `to="/docs/ai-development"` | Homepage AI demo link |
| `website/src/components/HomepageFeatures/index.tsx` | 44 | `link: '/docs/ai-development/'` | Homepage features card link |
| `website/docs/ai-development/_category_.json` | 6 | `id: "ai-development/index"` | Sidebar category doc link |
| `website/docs/ai-developer/_category_.json` | 7 | `id: "ai-developer/README"` | Sidebar category doc link |

These React components on the homepage link directly to `/docs/ai-development` and will break after the move. They must be updated to `/docs/ai-developer`.

### Overlap analysis

There are **two layers of duplication**:

1. **`creating-plans.md` vs `ai-developer/PLANS.md`** — Both describe plan structure. The ai-developer version is the authoritative one (used by Claude via CLAUDE.md). The top-level one is a simplified user-facing version.

2. **`index.md` vs `ai-docs/developing-using-ai.md`** — Nearly identical content (cage/plan/tests). `index.md` has teaser GIF, `developing-using-ai.md` has full GIF. Both serve the same purpose.

---

## Options

### Option A: Move ai-developer/ up, merge remaining content

```
website/docs/ai-developer/            ← moved up from ai-developer/
├── PLANS.md, WORKFLOW.md, etc.       ← unchanged
├── plans/                            ← unchanged
├── recordings.md                     ← merged from ai-docs/CREATING-RECORDINGS.md
└── index.md                          ← merged from ai-development/index.md

DELETE: website/docs/ai-development/  ← entire folder removed
```

**Pros:**
- Cleanest result — one folder, no duplication
- Simpler sidebar: "AI Developer" at top level
- All AI content in one place

**Cons:**
- User-facing intro content mixed with internal developer docs
- Recordings guide doesn't fit naturally in "AI Developer"

### Option B: Move ai-developer/ up, keep ai-development/ as user-facing section

```
website/docs/ai-development/          ← user-facing docs only
├── index.md                          ← keep (intro page)
├── creating-plans.md                 ← DELETE (duplicate of ai-developer/PLANS.md)
├── workflow.md                       ← DELETE (duplicate of ai-developer/WORKFLOW.md)
└── recordings.md                     ← moved from ai-docs/

website/docs/ai-developer/            ← moved up (internal/Claude docs)
├── PLANS.md, WORKFLOW.md, etc.
└── plans/
```

**Pros:**
- Separation of user-facing vs internal docs
- Removes duplicates

**Cons:**
- Two similar-named folders: `ai-development/` and `ai-developer/`
- Confusing navigation

### Option C: Move ai-developer/ up, flatten everything into it

```
website/docs/ai-developer/            ← single home for all AI content
├── index.md                          ← from ai-development/index.md (user intro)
├── PLANS.md                          ← keep (authoritative)
├── WORKFLOW.md                       ← keep (authoritative)
├── CREATING-SCRIPTS.md               ← keep
├── CREATING-TOOL-PAGES.md            ← keep
├── CREATING-RECORDINGS.md            ← from ai-docs/
├── README.md                         ← keep or merge into index.md
├── plans/                            ← keep unchanged
└── _category_.json                   ← update label, remove "Internal"

DELETE: website/docs/ai-development/  ← entire folder removed
DELETE: ai-docs/developing-using-ai.md ← duplicate of index.md
```

**Pros:**
- One folder for everything AI-related
- No duplication
- Clear, flat structure
- `ai-development/creating-plans.md` and `workflow.md` deleted (duplicates)
- `ai-docs/developing-using-ai.md` deleted (duplicate of index.md)

**Cons:**
- User intro page mixed with technical docs (manageable via sidebar ordering)

---

## Recommendation

**Option C** — Move `ai-developer/` up to `website/docs/ai-developer/`, merge `index.md` as the intro page, bring `CREATING-RECORDINGS.md` along, delete all duplicates and the `ai-development/` folder entirely.

**Why:**
- Eliminates the confusing nested structure
- Removes all 3 duplicated files
- One clear location for all AI development content
- CLAUDE.md paths become shorter and clearer
- The sidebar can use ordering to separate user-facing (index, intro) from internal (PLANS, WORKFLOW, plans/)

**Files to delete** (duplicates):
- `ai-development/creating-plans.md` (duplicate of `ai-developer/PLANS.md`)
- `ai-development/workflow.md` (duplicate of `ai-developer/WORKFLOW.md`)
- `ai-docs/developing-using-ai.md` (duplicate of `ai-development/index.md`)

**Files to move:**
- `ai-development/index.md` → `ai-developer/index.md`
- `ai-docs/CREATING-RECORDINGS.md` → `ai-developer/CREATING-RECORDINGS.md`
- `ai-developer/` → move entire folder up one level

**References to update (full list):**
- `CLAUDE.md` (6 path references)
- `website/src/components/AiDemo/index.tsx` (homepage link)
- `website/src/components/HomepageFeatures/index.tsx` (homepage link)
- `website/docs/contributors/website.md` (directory tree)
- `ai-developer/_category_.json` (update label, doc ID)
- `ai-developer/WORKFLOW.md` (3 full path references)
- `ai-developer/PLANS.md` (2 full path references)
- 9 completed plan files with path references
- 2 backlog plan files with path references
- `index.md` internal links (if any relative links break after move)

---

## Next Steps

- [ ] Create PLAN-ai-development-folder-restructure.md with chosen approach
