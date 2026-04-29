# Repository Hygiene and Loose-File Policy

## 1. Purpose
This policy prevents root-level drift and documentation ambiguity that can break release confidence, onboarding, and CI traceability.

## 2. Root-Level File Rules
Allowed at root:
- canonical project metadata (`README.md`, licenses, contribution/security docs);
- source trees (`android/`, `core/`, `scripts/`, `docs/`, `tools/`, etc.);
- explicitly versioned assets with clear ownership.

Disallowed at root:
- temporary drafts with non-descriptive names;
- duplicated conceptual notes outside `docs/`;
- orphaned text artifacts not referenced by build, runtime, or governance documentation.

## 3. Classification Workflow
Before committing a new root-level file, classify it:
1. Is it executable build/runtime code?
2. Is it CI/release infrastructure?
3. Is it formal documentation under `docs/`?
4. Is it required compatibility data?

If none applies, do not commit at root.

## 4. Current Normalization Applied
The repository removed and consolidated loose conceptual drafts into formal documentation:
- removed `rrr.rrr` (duplicated exploratory note)
- removed `ra2.md` (duplicated exploratory note)

## 5. Maintenance Rule
All future conceptual or architectural narratives must be added under `docs/` with explicit title, scope, and operational relevance.
