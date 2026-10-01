extends RefCounted
## A bounded sentence generator, not a model of unrestricted English.

const CONCEPTS = ["bird", "fish", "fruit", "water", "bread", "house", "boat", "book", "tree", "flower", "stone", "child", "friend", "river", "market", "school", "music", "garden", "road", "star"]
const TALUMA = ["panu", "selo", "mavi", "nua", "telo", "doma", "kavi", "peli", "ranu", "lomi", "taku", "neli", "sami", "nari", "sava", "poma", "liri", "mora", "vanu", "suli"]
const VERBS = ["see", "find", "carry", "want", "like", "bring"]
const TAL_VERBS = ["mira", "nako", "sari", "vemi", "lano", "tavi"]
const PAST = ["saw", "found", "carried", "wanted", "liked", "brought"]
const FEATURE_NAMES = ["Word order", "Plural marking", "Past tense", "Negation", "Questions", "Evidence source"]
const TAL_FEATURES = ["subject > object > verb", "noun + ri", "pa + unchanged verb", "ne before the verb", "ka at the end", "vi = witnessed; su = reported"]
const ENG_FEATURES = ["subject > verb > object", "noun + s (child > children)", "past verb form", "did not + base verb", "Did + subject + base verb?", "optional phrase: I heard that..."]
const MEANINGS = ["I saw birds.", "I found fish.", "I did not carry books.", "Did I want flowers?", "I heard that I brought boats."]

static func probabilities(profile: Dictionary) -> Dictionary:
	return {"lex": profile.lex.duplicate(), "grammar": profile.grammar.duplicate()}

static func form(profile: Dictionary, sample_index: int) -> String:
	# Display the most likely variant for a fixed meaning. No RNG is consumed.
	var case_id = posmod(sample_index, 5)
	var noun_id = [0, 1, 7, 9, 6][case_id]
	var verb_id = [0, 1, 2, 3, 5][case_id]
	var english_noun: bool = profile.lex[noun_id] >= 0.5
	var g: Array = profile.grammar
	var noun: String = CONCEPTS[noun_id] if english_noun else TALUMA[noun_id]
	if g[1] >= 0.5:
		if english_noun:
			noun = "fish" if noun_id == 1 else noun + "s"
		else:
			noun += "s"
	else:
		noun += "-ri"
	# Verb and pronoun origins follow the vocabulary-wide English tendency.
	var english_verb = mean(profile.lex) >= 0.5
	var subject = "I" if english_verb else "mi"
	var base: String = VERBS[verb_id] if english_verb else TAL_VERBS[verb_id]
	var verb = base
	var prefix = ""
	var suffix = ""
	if g[2] >= 0.5:
		verb = PAST[verb_id] if english_verb else base + "-ed"
	else:
		prefix = "pa "
	if case_id == 2:
		if g[3] >= 0.5:
			verb = "did not " + base
			prefix = ""
		else:
			verb = "ne " + verb
	if case_id == 3:
		if g[4] >= 0.5:
			subject = "Did " + subject
			verb = base
			prefix = ""
		else:
			suffix = ""
	if g[5] < 0.5:
		suffix += " su" if case_id == 4 else " vi"
	elif case_id == 4:
		subject = "I heard that " + subject
	if case_id == 3 and g[4] < 0.5:
		suffix += " ka"
	var sentence: String
	if g[0] >= 0.5:
		sentence = subject + " " + prefix + verb + " " + noun + suffix
	else:
		sentence = subject + " " + noun + " " + prefix + verb + suffix
	return sentence + ("?" if case_id == 3 else ".")

static func mean(values: Array) -> float:
	var total = 0.0
	for v in values:
		total += float(v)
	return total / maxf(1.0, values.size())

static func canonical(english: bool) -> Dictionary:
	var lex: Array = []
	var grammar: Array = []
	lex.resize(CONCEPTS.size())
	grammar.resize(FEATURE_NAMES.size())
	lex.fill(1.0 if english else 0.0)
	grammar.fill(1.0 if english else 0.0)
	return {"lex": lex, "grammar": grammar}
