# Validation status

## Completed here

- Parsed all five GDScript files, including the native test script, using gdtoolkit 4.5.0.
- Passed GDScript lint checks. Only the style limits on line length and number of returns were disabled in `gdlintrc`; long explanatory strings and explicit goal branches are intentional.
- Executed a reference harness translated from the core GDScript logic, with Python stand-ins for Godot arrays/dictionaries and a Python random generator.
- Checked reproducible state with a fixed reference seed, serialized checkpoint continuation, probability bounds, constant population, one history observation per round, a zero lexical gate with continued pattern transfer, and canonical example messages.
- Compared scenario trajectories, including domain separation and institutional shift versus home-language protection.

The reference harness tests model logic; it is not a native Godot run. Its random generator differs from Godot's, so its numerical trajectories do not establish the exact outcomes of particular Godot seeds.

## Still requires native Godot

Godot was not available in the build environment, and an engine download was unavailable. The project has therefore not been launched or visually inspected in the Godot engine here. Runtime type checking, rendering, mouse interaction, file dialogs, and web export still require an engine playtest. This is editable prototype source, not a verified executable release.

With Godot on your path, run:

```
godot --headless --path Contact_Garden --script res://tests/test_simulation.gd
```

Run this from the folder containing `Contact_Garden`, or replace that path with the project's actual folder. If the binary has another name, use that name.

The native script checks determinism, JSON checkpoint continuation, bounded probabilities, population conservation, lexical resistance with independent grammatical transfer, and the five English display templates. It prints a PASS message after successful assertions.

Then import `project.godot` and press F5 to check the splash screen, layout, Run/Pause/Step, speaker selection, tabs, ensemble experiments, exports, and checkpoint restoration. Test a web export separately before publishing one.

## Version 0.1.1 shift extension

All GDScript files parsed and lint passed using the project's existing style configuration. The reference behavior checks passed again. Six English-to-Taluma histories with 48 speakers and 175 rounds were evaluated, including initial failure, eventual use and founding-network evidence, and incoming-cohort readiness. Results are in `validation/shift_results.json`. These use the reference Python random generator, not Godot's generator. Existing scenario trajectories were unchanged because no learning coefficients or existing presets were modified.

The native test script additionally checks that initial conditions cannot award a shift, founding-network measures remain bounded, and readiness without recent Taluma use cannot award the challenge. Native engine testing remains outstanding.
