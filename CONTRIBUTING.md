# Contributing to RafCoder

## Purpose

RafCoder is a research-oriented native runtime repository focused on the RAFAELOS low-level execution core, Android JNI/NDK integration, architecture primitives, deterministic behavior and safety governance.

Contributions should improve technical clarity, reproducibility, portability, safety or maintainability.

## Contribution principles

All contributions should follow these principles:

1. **Be explicit about status**
   - Implemented means code exists.
   - Integrated means connected to an execution path.
   - Tested means reproducibly validated.
   - Planned means not yet implemented.
   - Experimental means present but not production-validated.

2. **Do not overclaim**
   - Do not claim performance wins without benchmark evidence.
   - Do not claim ARM32/NEON support unless the route exists and is validated.
   - Do not claim safety guarantees without documented controls.

3. **Keep native code disciplined**
   - Prefer explicit state ownership.
   - Avoid unnecessary global mutable state.
   - Avoid unnecessary heap allocation in low-level core paths.
   - Avoid unnecessary dependencies.
   - Preserve deterministic behavior where claimed.

4. **Respect human safety constraints**
   - Child protection has highest priority.
   - Human dignity is a project-level constraint.
   - Useful silence, abstention or refusal is valid where unsafe or false continuation would cause harm.

5. **Preserve upstream obligations**
   - Keep license notices intact.
   - Respect `LICENSE-CODE` and `LICENSE-MODEL`.
   - Separate upstream DeepSeek compatibility from RafCoder/RAFAELOS additions.

## Development workflow

Recommended workflow:

```bash
git checkout -b feature/<short-name>
# make a focused change
# run relevant local checks
git commit -m "area: concise change summary"
```

Preferred commit style:

```text
area: concise imperative summary
```

Examples:

```text
android: expose sector output through JNI
core: make sector workspace reentrant
docs: clarify architecture status
ci: add deterministic sector snapshot test
```

## Native core changes

When changing `core/` or `rafaelos.asm`, include:

- reason for the change;
- expected effect on determinism;
- whether state layout changed;
- whether ABI/API changed;
- test or validation path;
- known limitations.

Avoid changing multiple layers in one patch unless required.

## Android changes

When changing Android/JNI/NDK files, verify:

- `armeabi-v7a` remains buildable;
- `arm64-v8a` remains buildable;
- JNI names match Kotlin declarations;
- CMake paths remain relative and repository-safe;
- no binaries are committed;
- release builds do not require signing secrets.

## Documentation changes

Documentation must remain professional, precise and auditable.

Every major document should distinguish:

- implemented;
- integrated;
- tested;
- planned;
- experimental.

Avoid unsupported claims, decorative certainty or vague safety statements.

## Governance changes

Changes to governance documents should preserve:

- child protection priority;
- human dignity constraints;
- epistemic integrity;
- responsible-use boundaries;
- license clarity;
- minimal harmful detail in safety-sensitive areas.

## Pull request expectations

A pull request should include:

- summary of changes;
- files/components affected;
- validation performed;
- known gaps;
- safety/governance impact, if any;
- whether documentation was updated.

## Tests and validation

Until full CI coverage exists, contributors should provide the strongest available validation path.

Examples:

```bash
./scripts/android_build_matrix.sh
python tools/cron_fidelity_grouping.py --iterations 1000 --seed 42
```

Planned validation paths:

- deterministic `run_sector(42)` snapshot test;
- native core CI;
- Android instrumentation smoke test;
- Python vs C reference comparison.

## F de resolvido

This document defines contribution expectations for technical correctness, native-code discipline, documentation professionalism and safety governance.

## F de gap

Automated PR enforcement is still pending.

## F de next

1. Add pull request template.
2. Add deterministic core test.
3. Add documentation lint/check workflow.
