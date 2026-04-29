# Security Policy

## Purpose

RafCoder treats security, child protection, human dignity and epistemic integrity as project-level engineering requirements.

This document defines how security-sensitive issues should be reported, triaged and handled for this repository.

## Supported scope

Security review applies to:

- native C/ASM code;
- Android JNI/NDK integration;
- build scripts and CI workflows;
- model-facing examples and prompts;
- governance and responsible-use documentation;
- license and redistribution constraints;
- child protection and human-safety controls.

## Reportable issues

Please report security-sensitive issues if they involve any of the following:

- memory-safety risk in native code;
- unsafe JNI boundary behavior;
- build or CI supply-chain weakness;
- accidental exposure of secrets or credentials;
- unsafe model-use guidance;
- bypass of child-protection controls;
- instructions enabling harm, exploitation or abuse;
- misleading technical claims that could cause unsafe deployment;
- license or model-use conflict affecting redistribution.

## Non-security issues

The following should usually be handled as normal GitHub issues or pull requests:

- documentation typos;
- ordinary build failures;
- feature requests;
- benchmark improvements;
- refactoring proposals without safety impact.

## Reporting process

Preferred process:

1. Open a private security advisory if available.
2. If private advisories are not available, contact the maintainer directly before public disclosure.
3. Provide enough detail to reproduce or evaluate the issue.
4. Avoid publishing exploit instructions before a fix or mitigation exists.

A useful report should include:

- affected file or component;
- expected behavior;
- observed behavior;
- reproduction steps;
- potential impact;
- suggested mitigation, if known.

## Child protection priority

Any issue involving child exploitation, grooming, sexualization of minors or evasion of child-safety controls is treated as highest priority.

Do not include graphic abusive material in reports. Provide minimal technical detail necessary for triage.

## Human dignity and high-risk domains

Reports involving physical harm, psychological manipulation, coercive control, surveillance abuse or unsafe automation affecting people should be handled cautiously and with minimum harmful detail.

The project may choose refusal, redirection, removal or useful silence when publication would increase risk.

## Coordinated disclosure

The maintainer should aim to:

- acknowledge security reports promptly;
- assess severity and affected scope;
- prepare a patch or mitigation;
- document the fix without creating an abuse guide;
- preserve traceability in commits and release notes.

## Security posture for native code

Native changes should prefer:

- deterministic behavior;
- explicit state ownership;
- no unnecessary global mutable state;
- no avoidable undefined behavior;
- no committed binaries;
- reproducible build paths;
- tests for security-relevant behavior.

## Security posture for documentation

Documentation must distinguish:

- implemented behavior;
- integrated behavior;
- tested behavior;
- planned behavior;
- experimental behavior.

Unsupported benchmark, safety or performance claims should be treated as documentation defects.

## Related documents

- `docs/governance/license_and_safety_matrix.md`
- `docs/governance/research_only_and_noncommercial_policy.md`
- `docs/governance/child_protection_and_global_inclusion_standard.md`
- `docs/governance/human_dignity_and_epistemic_integrity.md`
- `docs/architecture.md`
