# Contact Garden

TuJuJu Studios | First Godot prototype | Version 0.1.1

Set the conditions under which English and the fictional language Taluma meet. Run an abstract social simulation, inspect speakers, and observe changing language use, vocabulary, and grammar.

## Open and play

1. Extract the whole ZIP into a folder.
2. Open Godot 4.3 or a newer Godot 4 editor, using the standard version. Godot 3 is not compatible.
3. In Godot's project manager, choose **Import**, select `project.godot` inside `Contact_Garden`, and open it.
4. Press **F5** or the triangular **Run Project** button at the top right.
5. Enter the laboratory. Pick a preset, then click **Start new experiment** and **Run**.

You do not need web hosting to play inside Godot. This ZIP contains editable project source, not an exported Windows executable.

## First experiments

- **English to Taluma**: try the new language-shift challenge. Most founding households speak English; success requires sustained Taluma use at home, in public, and within those households and their descendants.
- **Two domains**: try the diglossia challenge. Watch home/public use on the timeline.
- **Institutional shift**: observe Taluma readiness across incoming cohorts.
- **Protected homes**: compare with institutional shift, then reduce bilingual education alone.
- **New shared variety**: inspect the language examples and try the contact-variety or creole-formation laboratory challenge.
- **Patterns without loans**: keep word borrowing at zero while allowing grammatical transfer.

The presets describe starting situations. They do not select a predetermined ending.

Run 150 to 250 rounds initially. One round is an abstract model unit, not a year. A new cohort enters every 25 rounds, replacing the selected share of speakers.

## Controls

- Starting-condition changes apply when you click **Start new experiment**. They do not secretly alter the current town.
- **Run**, **Pause**, and **Step** control the visible experiment. **Stop at** is an absolute stopping round.
- A seed repeats the same random choices in the same engine version and project version.
- Click a speaker to inspect their two repertoires.
- **Pin this run as a comparison** saves an in-memory baseline. The next run shows a faint baseline bilingualism line and endpoint differences.
- **Experiments** runs six seeds from round zero using the currently shown starting conditions. The visible town is unchanged.
- Exports include a plain-text report, a timeline CSV, and a JSON checkpoint. Desktop checkpoints preserve the simulation state and random generator state so you can resume.

The dark square inside a dot marks a new learner. Dot color shows relative readiness; a light ring marks readiness in both languages. Readiness is a model quantity, not a CEFR or fluency assessment.

## What the labels mean

Diglossia-like outcomes track functional public/home separation. Bilingual readiness and actual language use are separate measures. A contact variety is a combination of measurable changes in this finite model.

The **Shift English to Taluma** challenge measures a change in everyday use plus transmission. English can remain available as a second language. It is different from simply increasing bilingual readiness. An English-majority population with less than half initially Taluma-ready must be the starting point. Taluma must account for at least 75% of home and public encounters across the latest 25 rounds; English-origin networks must use it for at least 65% of their encounters in each domain. At least 75% of those networks and new speakers must be Taluma-ready, with at least half the population replaced, at least 75 rounds elapsed, and cumulative births at least equal to the population.

The **Creole formation laboratory** challenge asks for contact-variety formation plus home use and transmission through new cohorts. It does not claim that these numerical conditions diagnose a real creole. Linguistic history, community identity, and social relations also matter.

## Web export later

The project uses Godot's Compatibility renderer and has no external assets or network services.

To share it on the web, install export templates matching your editor version, add a Web export preset, and export the complete bundle. For a simple static host, use the single-threaded web option if your Godot version offers it. Godot web exports contain several files, including WebAssembly; this project does not become a standalone HTML file. Upload the complete export bundle to a suitable host, or test with Godot's local web runner.

The exported browser build supports report/CSV/checkpoint downloads. Loading checkpoints is implemented for desktop builds only in this first version.

Official documentation: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html

## Project files

- `simulation.gd`: speaker model, learning, cohort replacement, metrics, and goals.
- `language.gd`: invented lexicon, grammar contrasts, and bounded example generator.
- `visual.gd`: town and timeline drawing.
- `main.gd`: controls, tabs, experiments, and export interface.
- `MODEL_GUIDE.md`: explicit assumptions, equations, and research sources.
- `tests/test_simulation.gd`: native Godot behavioral checks.
- `VALIDATION.md`: checks performed and their limits.

## Useful next extensions

Persistent households and peer networks; multiple social classes; demographic growth and migration; dialects within languages; more meanings and actual sentence interpretation; pronunciation; semantic calques; innovation of new grammatical variants; event-based challenges; and a campaign that compares several plausible language futures.

These extensions should be added separately so their effects remain understandable.
