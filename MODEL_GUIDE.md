# Contact Garden: model guide

This is an educational, stochastic, agent-based toy model. Its numerical coefficients and challenge thresholds are design assumptions. It is not a fitted reconstruction of any historical contact situation.

## Why this is a complex system

The model contains heterogeneous speakers, local encounters, frequency-dependent learning, separate contexts of use, cohort replacement, and feedback between readiness and language choice. Those interactions can produce nonlinear community trajectories. Stochastic encounters can also produce different histories under the same starting conditions.

Complexity here refers to interacting agents and feedback. It does not establish that this particular model reproduces every mechanism of language change or predicts a real community's future.

Published precedents include models of language competition, bilingual learning/attrition, contact-language emergence, and conventionalization versus code-switching. This project combines simplified mechanisms for play; it does not reproduce any one paper's validated implementation.

## State of a speaker

Each of 144 agents stores:

| State | Representation |
|---|---|
| Founding network | Taluma-origin or English-origin |
| Readiness | One continuous score from 0 to 1 for each repertoire |
| Vocabulary | Twenty English-form probabilities per repertoire |
| Grammar | Six English-variant probabilities per repertoire |
| Recent use | Counts of home and public encounters in each repertoire |
| Learning stage | Fewer than 9 rounds since entry means a new learner |
| Cohort history | Whether this speaker entered after setup |

The founding network is fixed for each population slot. It is a simplified inherited social-network identity, not a realistic model of ethnicity or identity choice. Each speaker has two separate repertoires, which allows maintenance, functional separation, and structural convergence to be measured separately.

## Taluma

Taluma is invented for this project, not presented as a documented language.

| Meaning/function | Taluma baseline | English template baseline |
|---|---|---|
| I | mi | I |
| bird | panu | bird |
| book | peli | book |
| see | mira | see |
| Clause order | subject, object, verb | subject, verb, object |
| Plural | -ri | -s, with fish/children exceptions in the lexicon |
| Past | pa before an unchanged verb | a past verb form |
| Negative past | ne before the verb | did not + base verb |
| Past question | final ka | Did + subject + base verb? |
| Evidence | obligatory vi/su in display templates | optional reporting construction |

Examples:

- `mi panu-ri pa mira vi.`: I saw birds, witnessed.
- `mi peli-ri pa ne sari vi.`: I did not carry books, witnessed.
- `mi lomi-ri pa vemi vi ka?`: Did I want flowers?

Hybrid forms are generated from the current most likely vocabulary and grammatical variants. An invented verb can acquire an English-pattern past suffix; an English noun can acquire Taluma plural marking. These are visible schematic combinations, not claims about the only way languages adapt borrowed items.

The display generator uses five fixed messages, mostly first-person past clauses. It is not an unrestricted English grammar. The simulation samples individual noun forms and grammatical choices; displayed full sentences summarize modal preferences and are not transcripts of simulated parsed conversations. Verb/pronoun source in displayed examples follows the repertoire's average noun-form preference.

## Encounter process

Each round contains three times the population size in directed encounters, with a 50/50 home/public context draw. Each encounter selects a speaker, a network partner, a repertoire, one of twenty noun meanings, and six grammatical variants.

Partner selection first draws whether to seek the other founding network. Home cross-network contact is reduced by network mobility and domain separation. Low mobility favors candidates within 18 population slots; this is a spatial-network proxy, not an explicit dynamic graph.

Language choice uses readiness and social incentives. For speaker a and listener b:

```
English weight = (0.07 + sqrt(qEnglish(a) * qEnglish(b))) * exp(pressure)
Taluma weight  = 0.07 + sqrt(qTaluma(a) * qTaluma(b))
P(English)    = English weight / (English weight + Taluma weight)
```

Pressure depends on English opportunity advantage, context separation, and commitment to the founding home language. Higher public/home separation strengthens English public incentives and Taluma-origin home incentives. The model also gives English a small background exposure advantage when its opportunity setting is high. Bilingual education gives small repeated readiness gains in both repertoires.

These rules explicitly encode hypotheses about social incentives. The player observes their interacting consequences; the model is not free of assumptions.

## Production and learning

Speakers sample English-form probabilities independently for a noun and the six grammatical contrasts. A speaker with low readiness in the selected nonfounding repertoire can transfer patterns from their founding repertoire. This approximates imposition without attempting a full second-language acquisition model.

Listeners update readiness and preference probabilities through weighted interpolation:

```
new preference = old preference + learning rate * (heard variant - old preference)
```

Young learners have higher update rates. Grammar generally updates more slowly than vocabulary, and plural/past morphology updates more slowly than the other tracked contrasts. Home-language commitment reduces foreign-feature uptake. Word acceptance can block lexical transfer independently of grammatical permeability.

Bilingual speakers exposed across founding networks also have a smaller transfer path between repertoires. That path can alter grammar without importing words. It is an explicit approximation of pattern replication.

Unused repertoires lose a small amount of readiness. Education and recurring use can compensate. Readiness is not simply the proportion of known vocabulary and does not correspond to a clinical or educational proficiency scale.

Expected comprehension is a weighted sum of listener readiness, noun-form familiarity, and grammatical-variant familiarity. It is recorded as an expected score, not resolved as successful sentence interpretation or a binary communication event. Comprehension adjusts readiness learning, but this version does not assign prestige bonuses to successful variants.

## Cohorts

Every 25 rounds, the selected fraction of population slots is replaced. New agents draw two caregiver models from the existing network and enter with compressed prior acquisition. Starting readiness combines caregiver readiness, home use, and the configured school/opportunity input. Their starting lexical and grammar preferences average caregiver input.

The input-pooling setting can additionally combine caregiver home repertoires when contexts are not strongly separated. Lexical pooling is multiplied by word acceptance, so a zero word-acceptance setting blocks this path as well as ordinary foreign-word adoption. Education affects both continuing exposure and the compressed pre-entry acquisition of incoming cohorts.

New learners slightly sharpen a preference using:

```
p' = p^r / (p^r + (1-p)^r)
r = 1 + 0.65 * input-pooling setting
```

This regularizes whichever variant is favored; it does not universally choose English or simpler grammar. No entirely new variant is created. A cohort interval is abstract simulation time, not a fixed historical generation.

## Measurements

- Ready in a repertoire: readiness at least 0.60.
- Bilingual: both readiness scores at least 0.60.
- Public/home use: share of observed encounters choosing English in that context.
- Average profile: readiness-weighted average of speaker preferences.
- Taluma loans: mean English-form probability in the Taluma profile.
- Grammar change: average probability movement from each baseline across both profiles.
- Repertoire distance: mean absolute difference between the profiles' six grammar probabilities.
- Modal confidence: mean probability of each profile's more likely grammatical variant. This is preference concentration, not inter-speaker agreement.
- New-speaker transmission: modeled participation/readiness of agents that entered after setup, with additional cohort and duration conditions.

At round zero, use is estimated from self-pair language-choice probabilities because no encounters have occurred. It is labeled as an expectation. Comprehension at round zero is zero because no exchanges have occurred.

## Challenge thresholds

These thresholds are intentionally inspectable game criteria, not linguistic diagnostic standards. Multiple goals can be satisfied at once.

| Goal | Conditions |
|---|---|
| Maintain bilingualism | Bilingual share >= 55%; each language readiness share >= 70%; total change in public/home English use over 25 rounds < 20 percentage points |
| Sustain diglossia | Public English use exceeds home English use by >= 35 points; each readiness share >= 55%; same recent stability criterion |
| Grow a contact variety | Within one active repertoire: mixed vocabulary score >= 0.25; grammar change >= 0.16; repertoire distance <= 0.35; modal confidence >= 0.60; use share >= 15%; readiness share >= 35%; > 25 observations |
| Creole formation laboratory | Contact-variety conditions; confidence >= 0.65; >= 50% new speakers; >= one population of births; >= 75 rounds; English-selected home use between 20% and 95% |
| Preserve Taluma | >= 75% ready in Taluma; >= 65% of new speakers ready in Taluma; the cohort/duration conditions above |
| Patterns without loans | Taluma English-pattern grammar preference >= 10%; Taluma English-form vocabulary preference <= 4%; >= 50 rounds |

Mixed vocabulary score is twice the minority-source proportion in a repertoire lexicon. The contact-variety goal requires the vocabulary and grammar criteria to hold within the same active repertoire, so an unused repertoire cannot trigger an achievement. That score detects source mixing, not a full sociolinguistic mixed-language classification.

The creole laboratory is especially provisional: its criteria neither capture all historical creoles nor imply that all contact varieties develop this way. A real classification requires social and transmission history. This two-source toy model cannot represent the diversity of many historical creole ecologies.

## Responsible experiments

1. Run the same seed with exactly one changed condition. This controls some stochastic variation, although changed event pathways can consume random draws differently.
2. Compare the same stopping round.
3. Repeat with six or more seeds. Six illustrates variability, not a reliable probability estimate.
4. Inspect several measures. A high bilingual share can coexist with very unequal use.
5. Read changing forms alongside probabilities. Crossing the display's 50% threshold can make a small probability change look like a sudden grammatical switch.

Do not infer actual historical dates, real population proficiency, causal estimates, or inevitable futures from these runs.

## Research sources

- Matras, Y., and Sakel, J. (2007). *Investigating the mechanisms of pattern replication in language convergence*. https://doi.org/10.1075/sl.31.4.05mat
- Winford, D. (2005). *Contact-induced changes: Classification and processes*. https://linguistics.osu.edu/sites/linguistics.osu.edu/files/Don-WPL.pdf
- Thomason, S. G. (2007). *Social and linguistic factors as predictors of contact-induced change*. https://websites.umich.edu/~thomason/temp/soclgfac.pdf
- Aikhenvald, A. Y. (2003). *Mechanisms of change in areal diffusion: New morphology and language contact*. https://doi.org/10.1017/S0022226702001937
- Gardani, F. (2020). *Borrowing matter and pattern in morphology. An overview*. https://doi.org/10.1007/s11525-020-09371-5
- Torres, C. J., Xu, W., Li, Y., and Futrell, R. (2025). *Creolization versus code-switching: An agent-based cognitive model for bilingual strategies in language contact*. https://aclanthology.org/2025.cmcl-1.25/
- *A three-state language competition model including language learning and attrition* (2023). https://doi.org/10.3389/fcpxs.2023.1266733
- *Modeling the Emergence of Contact Languages* (2015). https://doi.org/10.1371/journal.pone.0120771
- Godot random generator documentation: https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html

The sources motivate mechanisms and interpretation. They do not justify the game's specific coefficients.

## English-to-Taluma shift challenge (0.1.1)

The English-to-Taluma preset begins with 85% English-origin households and only 5% initially bilingual. Opportunity advantage is set near zero, favoring Taluma in the existing language-choice equation. Contact and mobility are high; home/public separation and founding-language loyalty are low. These are assumptions to explore, not a recipe guaranteed to reproduce a real shift.

The challenge requires an English-majority start with fewer than half Taluma-ready, then 75% Taluma use in each domain averaged over the last 25 rounds. Within English-origin networks, the corresponding minimum is 65%, and at least 75% must be Taluma-ready. New cohorts must also be at least 75% Taluma-ready, after at least 75 rounds, half the population replaced, and cumulative births equal to or exceeding the population. English-origin encounter counts track the speaker's founding network, inherited by replacement learners. They are separate from population-wide use and do not represent ethnic identity.

Learning and bilingualism can precede shift. Keeping English proficiency does not invalidate a shift in everyday use. No existing learning coefficients were changed to force the outcome. The current institution exposure still gives English a small baseline advantage; the opportunity setting favors Taluma through encounter choice. Recent averages reduce sensitivity to a lucky single round. Older 0.1.0 checkpoints remain loadable; new shift evidence needs 25 rounds with the new network metrics.
