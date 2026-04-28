# Pull Request

## Summary

Describe the change in clear technical terms.

- What changed:
- Why it changed:
- Main files/components affected:

## Change type

Select all that apply:

- [ ] Core C runtime
- [ ] Assembly / architecture primitives
- [ ] Android JNI/NDK bridge
- [ ] Android app/UI
- [ ] Build / CI
- [ ] Documentation
- [ ] Governance / safety
- [ ] Upstream compatibility
- [ ] Refactor only
- [ ] Test only

## Implementation status

Mark the actual status of this change:

- [ ] Implemented: code exists
- [ ] Integrated: connected to an execution path
- [ ] Tested: reproducibly validated
- [ ] Experimental: present but not production-validated
- [ ] Planned/follow-up: documented but not implemented in this PR

## Validation performed

List the checks actually run.

- [ ] I ran the Android build matrix: `./scripts/android_build_matrix.sh`
- [ ] I ran the Python reference benchmark: `python tools/cron_fidelity_grouping.py --iterations 1000 --seed 42`
- [ ] I ran native/core tests
- [ ] I inspected affected files manually
- [ ] Not run; reason:

## Native-code checklist

Required for changes under `core/`, `rafaelos.asm`, or native JNI files:

- [ ] No unnecessary heap allocation added to the low-level core path
- [ ] No unnecessary global mutable state added
- [ ] State ownership remains explicit
- [ ] ABI/API changes are documented
- [ ] Deterministic behavior is preserved where claimed
- [ ] Undefined behavior risk was considered
- [ ] No binary artifacts were committed

## Android checklist

Required for Android/JNI/NDK changes:

- [ ] `armeabi-v7a` remains buildable or the limitation is documented
- [ ] `arm64-v8a` remains buildable or the limitation is documented
- [ ] JNI names match Kotlin declarations
- [ ] CMake paths remain repository-relative
- [ ] Release build does not require signing secrets for unsigned artifacts

## Documentation checklist

- [ ] README updated if public behavior changed
- [ ] `docs/architecture.md` updated if architecture changed
- [ ] Governance docs updated if safety posture changed
- [ ] Known gaps documented
- [ ] Implemented/planned/tested/experimental status is clear
- [ ] No unsupported benchmark, performance, platform or safety claim was added

## Safety and governance checklist

- [ ] Change respects `SECURITY.md`
- [ ] Change respects `CODE_OF_CONDUCT.md`
- [ ] Change respects `CONTRIBUTING.md`
- [ ] Child protection constraints remain intact
- [ ] Human dignity and epistemic integrity constraints remain intact
- [ ] Unsafe operational detail was avoided in public documentation
- [ ] License/model-use obligations remain preserved

## Known gaps / follow-ups

List remaining work honestly.

- 

## Risk assessment

Describe possible regressions or safety risks.

- Technical risk:
- Build risk:
- Runtime risk:
- Documentation/governance risk:

## Reviewer notes

Anything the reviewer should inspect carefully:

- 
