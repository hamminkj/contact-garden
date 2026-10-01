extends RefCounted
## Educational stochastic model. Coefficients are game assumptions, not fitted estimates.

const Language = preload("res://language.gd")
const VERSION = "0.1.1"
const DEFAULTS = {
	"population": 144, "english_share": 0.35, "bilingual": 0.20,
	"contact": 0.55, "mobility": 0.35, "prestige": 0.60,
	"domain_split": 0.45, "loyalty": 0.60, "education": 0.40,
	"loan_acceptance": 0.65, "pattern_transfer": 0.45,
	"child_pooling": 0.55, "turnover": 0.70, "seed": 4217
}
const PRESETS = [
	{"name": "Open crossroads", "story": "Families, markets, and schools connect two communities. Can both languages stay in everyday use?", "values": {}},
	{"name": "Two domains", "story": "English has institutional status; Taluma remains a strong home language. Look for stable separation between home and public life.", "values": {"contact": 0.65, "prestige": 0.85, "domain_split": 0.95, "loyalty": 0.95, "education": 0.50, "child_pooling": 0.10}},
	{"name": "New shared variety", "story": "Mixed households and a common marketplace provide overlapping language models to a new generation. Look for shared patterns and home transmission.", "values": {"contact": 0.95, "mobility": 0.80, "domain_split": 0.05, "loyalty": 0.15, "prestige": 0.68, "pattern_transfer": 0.90, "child_pooling": 0.95, "loan_acceptance": 0.95, "bilingual": 0.55}},
	{"name": "Institutional shift", "story": "Public opportunities favor English and home-language support is weak. Observe whether Taluma proficiency survives across cohorts.", "values": {"contact": 0.85, "prestige": 0.98, "domain_split": 0.15, "loyalty": 0.05, "education": 0.0, "child_pooling": 0.35}},
	{"name": "Protected homes", "story": "Strong family networks and bilingual education support Taluma alongside English. Compare this with institutional shift.", "values": {"contact": 0.70, "prestige": 0.80, "domain_split": 0.70, "loyalty": 0.95, "education": 0.95, "child_pooling": 0.20}},
	{"name": "Patterns without loans", "story": "Speakers resist English words in Taluma, but bilingual patterns remain available. Can word order or other grammar change anyway?", "values": {"contact": 0.90, "bilingual": 0.65, "loan_acceptance": 0.0, "pattern_transfer": 0.95, "child_pooling": 0.10, "domain_split": 0.50}},
	{"name": "English to Taluma", "story": "Most households begin English-speaking. Taluma offers community opportunities. Can daily home and public use shift to Taluma and reach new generations?", "values": {"english_share": 0.85, "bilingual": 0.05, "prestige": 0.04, "loyalty": 0.03, "domain_split": 0.0, "contact": 0.95, "mobility": 0.80, "education": 0.20}}
]
const GOALS = ["Explore freely", "Maintain bilingualism", "Sustain diglossia", "Grow a contact variety", "Creole formation laboratory", "Preserve Taluma", "Patterns without loans", "Shift English to Taluma"]

var config: Dictionary
var rng = RandomNumberGenerator.new()
var agents: Array = []
var history: Array = []
var events: Array = []
var messages: Array = []
var tick = 0
var births = 0
var domain_counts = [[0, 0], [0, 0]]
var english_origin_counts = [[0, 0], [0, 0]]
var metrics: Dictionary = {}
var previous_scores: Dictionary = {}
var successes = 0.0
var exchanges = 0
var talk_edges: Array = []
var partner_pools: Array = []

func setup(settings: Dictionary) -> void:
	config = DEFAULTS.duplicate(true)
	config.merge(settings, true)
	rng.seed = int(config.seed)
	agents.clear()
	history.clear()
	events.clear()
	messages.clear()
	tick = 0
	births = 0
	domain_counts = [[0, 0], [0, 0]]
	english_origin_counts = [[0, 0], [0, 0]]
	successes = 0.0
	exchanges = 0
	talk_edges.clear()
	previous_scores.clear()
	var total = int(config.population)
	var english_count = int(round(total * float(config.english_share)))
	for i in range(total):
		var origin = 1 if i >= total - english_count else 0
		var a = _fresh_agent(i, origin)
		a.age = rng.randi_range(9, 45)
		a.q[origin] = rng.randf_range(0.9, 1.0)
		a.q[1 - origin] = rng.randf_range(0.68, 0.88) if rng.randf() < config.bilingual else rng.randf_range(0.03, 0.12)
		agents.append(a)
	_build_networks()
	_update_metrics()
	_event("Start", "Each dot is one speaker. Color shows the language they are most ready to use; a light ring marks a bilingual speaker.")

func _fresh_agent(id: int, origin: int) -> Dictionary:
	return {"id": id, "origin": origin, "age": 0, "q": [0.1, 0.1],
		"profiles": [Language.canonical(false), Language.canonical(true)],
		"home": [0.0, 0.0], "public": [0.0, 0.0], "cross": 0.0,
		"child": false, "home_model": [0.5, 0.5]}

func step() -> void:
	tick += 1
	domain_counts = [[0, 0], [0, 0]]
	english_origin_counts = [[0, 0], [0, 0]]
	successes = 0.0
	exchanges = 0
	talk_edges.clear()
	for a in agents:
		a.home = [0.0, 0.0]
		a.public = [0.0, 0.0]
	for k in range(agents.size() * 3):
		var speaker_id = rng.randi_range(0, agents.size() - 1)
		var speaker: Dictionary = agents[speaker_id]
		var home = rng.randf() < 0.5
		var listener_id = _partner(speaker_id, home)
		_interact(speaker, agents[listener_id], 0 if home else 1)
		if talk_edges.size() < 22 and not home:
			talk_edges.append([speaker_id, listener_id])
	for a in agents:
		a.age += 1
		var home_total = maxf(1.0, a.home[0] + a.home[1])
		a.home_model = [a.home[0] / home_total, a.home[1] / home_total]
		for lang in range(2):
			var use = a.home[lang] + a.public[lang]
			if use < 1:
				a.q[lang] = maxf(0.0, a.q[lang] - 0.008 * (1.0 - float(config.loyalty) * (1 if lang == a.origin else 0)))
			# Bilingual schooling gives modeled exposure to both systems.
			a.q[lang] = lerpf(a.q[lang], 1.0, 0.018 * float(config.education))
			# Public opportunities give a weaker baseline exposure to English.
			if lang == 1:
				a.q[lang] = lerpf(a.q[lang], 1.0, 0.003 * float(config.prestige))
	if tick % 25 == 0:
		_new_cohort()
		_event("New cohort", "%d new speakers have entered over the whole experiment. Their language models come from caregivers and community encounters." % births)
	_update_metrics()
	_detect_events()

func _partner(speaker_id: int, home: bool) -> int:
	var a: Dictionary = agents[speaker_id]
	var cross_chance = float(config.contact)
	if home:
		cross_chance *= float(config.mobility) * (1.0 - 0.8 * float(config.domain_split))
	var cross = rng.randf() < cross_chance
	var pool_id = 1 if cross else 0
	var candidates: Array = partner_pools[speaker_id][pool_id]
	if candidates.is_empty():
		return posmod(speaker_id + 1, agents.size())
	if rng.randf() > float(config.mobility):
		# Local networks are a window in the fixed town layout.
		var nearby: Array = partner_pools[speaker_id][pool_id + 2]
		if not nearby.is_empty():
			candidates = nearby
	return candidates[rng.randi_range(0, candidates.size() - 1)]

func _build_networks() -> void:
	# Network origin never changes; cache candidate lists once rather than every encounter.
	partner_pools.clear()
	for i in range(agents.size()):
		var pools = [[], [], [], []]
		for j in range(agents.size()):
			if i == j:
				continue
			var pool_id = 1 if agents[i].origin != agents[j].origin else 0
			pools[pool_id].append(j)
			if abs(i - j) <= 18:
				pools[pool_id + 2].append(j)
		partner_pools.append(pools)

func english_probability(a: Dictionary, b: Dictionary, domain: int) -> float:
	var eng_readiness = 0.07 + sqrt(a.q[1] * b.q[1])
	var tal_readiness = 0.07 + sqrt(a.q[0] * b.q[0])
	var pressure = (float(config.prestige) - 0.5) * 3.0
	if domain == 1:
		pressure += float(config.domain_split) * 2.3
	else:
		var tal_identity = float((1 - a.origin) + (1 - b.origin)) / 2.0
		pressure -= tal_identity * (float(config.loyalty) * 2.7 + float(config.domain_split) * 1.9)
		var english_identity = float(a.origin + b.origin) / 2.0
		pressure += english_identity * float(config.loyalty) * 1.4
	var eng_weight = eng_readiness * exp(pressure)
	return eng_weight / (eng_weight + tal_readiness)

func _interact(a: Dictionary, b: Dictionary, domain: int) -> void:
	var lang = 1 if rng.randf() < english_probability(a, b, domain) else 0
	var concept = rng.randi_range(0, Language.CONCEPTS.size() - 1)
	var produced_lex = float(a.profiles[lang].lex[concept])
	var produced_g: Array = a.profiles[lang].grammar.duplicate()
	var difficulty = 1.0 - float(a.q[lang])
	var imposition = difficulty * float(config.pattern_transfer) * 0.7
	if lang != a.origin:
		produced_lex = lerpf(produced_lex, a.profiles[a.origin].lex[concept], difficulty * 0.7)
		for f in range(produced_g.size()):
			produced_g[f] = lerpf(produced_g[f], a.profiles[a.origin].grammar[f], imposition)
	var word = 1.0 if rng.randf() < produced_lex else 0.0
	var token_g: Array = []
	var agreement = 0.0
	for f in range(produced_g.size()):
		var variant = 1.0 if rng.randf() < produced_g[f] else 0.0
		token_g.append(variant)
		agreement += b.profiles[lang].grammar[f] if variant == 1.0 else 1.0 - b.profiles[lang].grammar[f]
	agreement /= produced_g.size()
	var word_match = b.profiles[lang].lex[concept] if word == 1.0 else 1.0 - b.profiles[lang].lex[concept]
	var understood = clampf(0.15 + 0.50 * float(b.q[lang]) + 0.20 * word_match + 0.15 * agreement, 0.0, 1.0)
	successes += understood
	exchanges += 1
	domain_counts[domain][lang] += 1
	if a.origin == 1:
		english_origin_counts[domain][lang] += 1
	var counter = "home" if domain == 0 else "public"
	a[counter][lang] += 1.0
	b[counter][lang] += 1.0
	if a.origin != b.origin:
		a.cross += 1.0
		b.cross += 1.0
	_learn(b, a, lang, concept, word, token_g, understood)
	# Reciprocal exposure: both parties practice the selected language.
	a.q[lang] = lerpf(a.q[lang], 1.0, 0.004)
	if messages.size() < 6 or rng.randf() < 0.015:
		var example = {"tick": tick, "speaker": a.id + 1, "listener": b.id + 1,
			"domain": "home" if domain == 0 else "public", "language": "English" if lang == 1 else "Taluma",
			"word": Language.CONCEPTS[concept] if word == 1.0 else Language.TALUMA[concept],
			"meaning": Language.CONCEPTS[concept], "understood": understood}
		messages.push_front(example)
		if messages.size() > 14:
			messages.pop_back()

func _learn(b: Dictionary, a: Dictionary, lang: int, concept: int, word: float, grammar: Array, understood: float) -> void:
	var young = b.age < 9
	var pace = 0.065 if young else 0.014
	b.q[lang] = lerpf(b.q[lang], 1.0, pace * (0.4 + 0.6 * understood))
	var resistance = 1.0 - 0.75 * float(config.loyalty) if lang == b.origin else 1.0
	var lexical_rate = 0.09 if young else 0.018
	var foreign_word = (word >= 0.5) != (lang == 1)
	if foreign_word:
		lexical_rate *= float(config.loan_acceptance) * resistance
	b.profiles[lang].lex[concept] = lerpf(b.profiles[lang].lex[concept], word, lexical_rate)
	var grammatical_rate = (0.024 if young else 0.005) * float(config.pattern_transfer)
	for f in range(grammar.size()):
		var foreign_pattern = (grammar[f] >= 0.5) != (lang == 1)
		var rate = grammatical_rate * resistance if foreign_pattern else grammatical_rate
		# Agreement and tense change more slowly than order or discourse marking.
		if f == 1 or f == 2:
			rate *= 0.65
		b.profiles[lang].grammar[f] = lerpf(b.profiles[lang].grammar[f], grammar[f], rate)
	# Pattern replication crosses repertoires without importing word forms.
	if b.q[0] > 0.45 and b.q[1] > 0.45 and a.origin != b.origin:
		var other = 1 - lang
		var transfer = 0.0025 * float(config.pattern_transfer) * (1.0 - float(config.domain_split))
		if other == b.origin:
			transfer *= resistance
		for f in range(grammar.size()):
			b.profiles[other].grammar[f] = lerpf(b.profiles[other].grammar[f], grammar[f], transfer)
		# Deliberate lexical resistance can block forms but leave this pattern path open.
		var lexical_transfer = transfer * 2.0 * float(config.loan_acceptance)
		b.profiles[other].lex[concept] = lerpf(b.profiles[other].lex[concept], word, lexical_transfer)

func _new_cohort() -> void:
	var replacements: Dictionary = {}
	for i in range(agents.size()):
		if rng.randf() > float(config.turnover):
			continue
		var p: Dictionary = agents[i]
		var q: Dictionary = agents[_partner(i, true)]
		var child = _fresh_agent(i, p.origin)
		child.child = true
		for lang in range(2):
			var caregiver_exposure = (float(p.home_model[lang]) + float(q.home_model[lang])) / 2.0
			# Incoming speakers already carry compressed home/school acquisition.
			var school_input = 0.08 * float(config.education)
			if lang == 1:
				school_input += 0.03 * float(config.prestige)
			child.q[lang] = clampf(0.18 + 0.82 * (p.q[lang] + q.q[lang]) / 2.0 * (0.55 + 0.45 * caregiver_exposure) + school_input, 0.03, 0.98)
			for key in ["lex", "grammar"]:
				for f in range(child.profiles[lang][key].size()):
					var value = (p.profiles[lang][key][f] + q.profiles[lang][key][f]) / 2.0
					var mixed_exposure = _exposure_value(p, key, f) * 0.5 + _exposure_value(q, key, f) * 0.5
					var pooling = float(config.child_pooling) * (1.0 - float(config.domain_split))
					# Block foreign lexical material when loan acceptance is zero.
					if key == "lex":
						pooling *= float(config.loan_acceptance)
					value = lerpf(value, mixed_exposure, pooling)
					# New learners regularize the input slightly; no new grammatical type is invented.
					var exponent = 1.0 + 0.65 * float(config.child_pooling)
					var upper = pow(value, exponent)
					value = upper / (upper + pow(1.0 - value, exponent))
					child.profiles[lang][key][f] = clampf(value, 0.0, 1.0)
		child.home_model = [(p.home_model[0] + q.home_model[0]) / 2.0, (p.home_model[1] + q.home_model[1]) / 2.0]
		replacements[i] = child
	for i in replacements:
		agents[i] = replacements[i]
		births += 1

func _exposure_value(a: Dictionary, key: String, feature: int) -> float:
	var weight = float(a.home_model[1])
	return lerpf(a.profiles[0][key][feature], a.profiles[1][key][feature], weight)

func average_profile(lang: int, children_only: bool = false) -> Dictionary:
	var result = Language.canonical(false)
	var weight_sum = 0.0
	for a in agents:
		if children_only and not a.child:
			continue
		var weight = maxf(0.01, a.q[lang])
		weight_sum += weight
		for key in ["lex", "grammar"]:
			for f in range(result[key].size()):
				result[key][f] += a.profiles[lang][key][f] * weight
	if weight_sum > 0.0:
		for key in ["lex", "grammar"]:
			for f in range(result[key].size()):
				result[key][f] /= weight_sum
	return result

func _update_metrics() -> void:
	var bilingual_count = 0
	var tal_count = 0
	var eng_count = 0
	var young_tal = 0.0
	var young_total = 0.0
	for a in agents:
		if a.q[0] >= 0.6:
			tal_count += 1
		if a.q[1] >= 0.6:
			eng_count += 1
		if minf(a.q[0], a.q[1]) >= 0.6:
			bilingual_count += 1
		if a.child:
			young_total += 1
			young_tal += 1.0 if a.q[0] >= 0.6 else 0.0
	var origin_total = 0.0
	var origin_tal_ready = 0.0
	for a in agents:
		if a.origin == 1:
			origin_total += 1.0
			origin_tal_ready += 1.0 if a.q[0] >= 0.6 else 0.0
	var tal = average_profile(0)
	var eng = average_profile(1)
	var profile_distance = 0.0
	var confidence = 0.0
	var changed_grammar = 0.0
	for f in range(tal.grammar.size()):
		profile_distance += absf(tal.grammar[f] - eng.grammar[f])
		confidence += maxf(tal.grammar[f], 1.0 - tal.grammar[f])
		confidence += maxf(eng.grammar[f], 1.0 - eng.grammar[f])
		changed_grammar += tal.grammar[f] + 1.0 - eng.grammar[f]
	profile_distance /= tal.grammar.size()
	confidence /= tal.grammar.size() * 2.0
	changed_grammar /= tal.grammar.size() * 2.0
	var lex_tal = Language.mean(tal.lex)
	var lex_eng = Language.mean(eng.lex)
	var lexical_mix = maxf(minf(lex_tal, 1.0 - lex_tal), minf(lex_eng, 1.0 - lex_eng)) * 2.0
	var n = float(agents.size())
	metrics = {"tick": tick, "bilingual": bilingual_count / n,
		"taluma": tal_count / n, "english": eng_count / n,
		"home_english": float(domain_counts[0][1]) / maxf(1.0, domain_counts[0][0] + domain_counts[0][1]),
		"public_english": float(domain_counts[1][1]) / maxf(1.0, domain_counts[1][0] + domain_counts[1][1]),
		"overall_english": float(domain_counts[0][1] + domain_counts[1][1]) / maxf(1.0, exchanges),
		"comprehension": successes / maxf(1.0, exchanges),
		"distance": profile_distance, "confidence": confidence,
		"grammar_change": changed_grammar, "taluma_loans": lex_tal,
		"english_loans": 1.0 - lex_eng, "lexical_mix": lexical_mix,
		"young_taluma": young_tal / maxf(1.0, young_total), "new_speakers": young_total / n,
		"births": births, "english_origin_taluma": origin_tal_ready / maxf(1.0, origin_total),
		"english_origin_home_taluma": float(english_origin_counts[0][0]) / maxf(1.0, english_origin_counts[0][0] + english_origin_counts[0][1]),
		"english_origin_public_taluma": float(english_origin_counts[1][0]) / maxf(1.0, english_origin_counts[1][0] + english_origin_counts[1][1])}
	if tick == 0:
		# At setup, expected use replaces absent observation; it is labeled in the UI.
		var homes = 0.0
		var publics = 0.0
		for a in agents:
			homes += english_probability(a, a, 0)
			publics += english_probability(a, a, 1)
		metrics.home_english = homes / n
		metrics.public_english = publics / n
		metrics.overall_english = (homes + publics) / (n * 2.0)
		var origin_home = 0.0
		var origin_public = 0.0
		for a in agents:
			if a.origin == 1:
				origin_home += 1.0 - english_probability(a, a, 0)
				origin_public += 1.0 - english_probability(a, a, 1)
		metrics.english_origin_home_taluma = origin_home / maxf(1.0, origin_total)
		metrics.english_origin_public_taluma = origin_public / maxf(1.0, origin_total)
	history.append(metrics.duplicate(true))

func _contact_evidence() -> Dictionary:
	# A dormant repertoire must not create a contact-variety achievement.
	var best = {"score": 0.0, "confidence": 0.0}
	for lang in range(2):
		var share = metrics.overall_english if lang == 1 else 1.0 - metrics.overall_english
		var readiness = metrics.english if lang == 1 else metrics.taluma
		if share < 0.15 or readiness < 0.35:
			continue
		var profile = average_profile(lang)
		var vocabulary = Language.mean(profile.lex)
		var mixture = minf(vocabulary, 1.0 - vocabulary) * 2.0
		var grammar_shift = Language.mean(profile.grammar)
		if lang == 1:
			grammar_shift = 1.0 - grammar_shift
		var preference_strength = 0.0
		for f in profile.grammar:
			preference_strength += maxf(f, 1.0 - f)
		preference_strength /= profile.grammar.size()
		var score = minf(1.0, mixture / 0.25) * minf(1.0, grammar_shift / 0.16) * minf(1.0, (1.0 - metrics.distance) / 0.65)
		if score > best.score:
			best = {"score": score, "confidence": preference_strength}
	return best

func goal_status(goal: int) -> Dictionary:
	var m = metrics
	var stable = history.size() > 25
	var drift = 1.0
	if stable:
		var old: Dictionary = history[maxi(0, history.size() - 26)]
		drift = absf(m.home_english - old.home_english) + absf(m.public_english - old.public_english)
	var both = minf(m.taluma, m.english)
	var diglossia = m.public_english - m.home_english
	var contact_evidence = _contact_evidence()
	var contact_score = contact_evidence.score
	var child_transmission = m.new_speakers >= 0.5 and births >= agents.size() and tick >= 75
	match goal:
		1:
			return _goal(m.bilingual >= 0.55 and both >= 0.70 and stable and drift < 0.20, "At least 55% bilingual; at least 70% ready in each language; use changes by less than 20 points over 25 rounds.", minf(m.bilingual / 0.55, both / 0.70))
		2:
			return _goal(diglossia >= 0.35 and both >= 0.55 and stable and drift < 0.20, "English public use exceeds home use by 35 points; both languages retain at least 55% ready speakers; recent use is stable.", minf(diglossia / 0.35, both / 0.55))
		3:
			return _goal(contact_score >= 0.99 and contact_evidence.confidence >= 0.60 and stable, "An active repertoire mixes vocabulary and grammar; repertoires converge; modal confidence at least 60%.", contact_score)
		4:
			return _goal(contact_score >= 0.99 and contact_evidence.confidence >= 0.65 and child_transmission and m.home_english > 0.20 and m.home_english < 0.95, "Contact-variety criteria plus at least 50% new speakers, 75 rounds, and home use. This is a creole-like scenario, not a historical diagnosis.", minf(contact_score, minf(m.new_speakers / 0.5, tick / 75.0)))
		5:
			return _goal(m.taluma >= 0.75 and m.young_taluma >= 0.65 and child_transmission, "At least 75% ready in Taluma and 65% of new speakers ready in Taluma, after 75 rounds and one population of births.", minf(m.taluma / 0.75, m.young_taluma / 0.65))
		6:
			var tal_pattern = Language.mean(average_profile(0).grammar)
			return _goal(tal_pattern >= 0.10 and m.taluma_loans <= 0.04 and tick >= 50, "Taluma grammar is at least 10% English-patterned while English-origin vocabulary remains at or below 4%, after 50 rounds.", minf(1.0, tal_pattern / 0.10))
		7:
			var evidence = _taluma_shift_evidence()
			return _goal(evidence.met, "Begin with at least 60% English-origin households and fewer than half Taluma-ready. Over 25 rounds: Taluma at least 75% of home/public use and 65% within English-origin networks. At least 75% Taluma-ready in those networks and new cohorts; 75 rounds and one population of births.", evidence.progress)
	return _goal(false, "Choose a challenge, or explore without a score. Goals describe modeled outcomes and can overlap.", 0.0)

func _taluma_shift_evidence() -> Dictionary:
	# Use a whole recent window so a single lucky round cannot award a shift.
	if history.size() < 26:
		return {"met": false, "progress": 0.0}
	var home = 0.0
	var public_use = 0.0
	var origin_home = 0.0
	var origin_public = 0.0
	for i in range(history.size() - 25, history.size()):
		var row: Dictionary = history[i]
		home += 1.0 - row.home_english
		public_use += 1.0 - row.public_english
		origin_home += row.get("english_origin_home_taluma", 0.0)
		origin_public += row.get("english_origin_public_taluma", 0.0)
	home /= 25.0
	public_use /= 25.0
	origin_home /= 25.0
	origin_public /= 25.0
	var readiness = metrics.get("english_origin_taluma", 0.0)
	var qualifying_start = config.english_share >= 0.60 and history[0].english >= 0.60 and history[0].taluma < 0.50
	var transmission = metrics.young_taluma >= 0.75 and metrics.new_speakers >= 0.50 and births >= agents.size() and tick >= 75
	var progress = minf(minf(home, public_use) / 0.75, minf(origin_home, origin_public) / 0.65)
	progress = minf(progress, minf(readiness / 0.75, metrics.young_taluma / 0.75))
	progress = minf(progress, minf(tick / 75.0, births / float(agents.size())))
	if not qualifying_start:
		progress = 0.0
	return {"met": qualifying_start and transmission and readiness >= 0.75 and home >= 0.75 and public_use >= 0.75 and origin_home >= 0.65 and origin_public >= 0.65, "progress": progress}

func _goal(met: bool, text: String, progress: float) -> Dictionary:
	return {"met": met, "text": text, "progress": clampf(progress, 0.0, 1.0)}

func _detect_events() -> void:
	var scores = {"Bilingual networks": metrics.bilingual >= 0.55,
		"Domain separation": metrics.public_english - metrics.home_english >= 0.35,
		"Taluma under pressure": metrics.taluma < 0.35,
		"Patterns spreading": metrics.grammar_change >= 0.10,
		"Vocabulary crossing": metrics.taluma_loans >= 0.15,
		"Repertoires converging": metrics.distance <= 0.65}
	var descriptions = {
		"Bilingual networks": "More than half the town is ready to use both modeled languages. Readiness is not the same as everyday use.",
		"Domain separation": "English public use is at least 35 points higher than English home use. Check whether both languages remain available.",
		"Taluma under pressure": "Fewer than 35% meet the modeled Taluma readiness threshold. Check new speakers and home use.",
		"Patterns spreading": "Average grammatical probabilities have moved away from the starting systems by at least 10 points.",
		"Vocabulary crossing": "English forms account for at least 15% of the average Taluma vocabulary preferences.",
		"Repertoires converging": "The grammatical distance between the two modeled repertoires has fallen below 65%."}
	for key in scores:
		if scores[key] and not previous_scores.get(key, false):
			_event(key, descriptions[key])
	previous_scores = scores

func _event(title: String, body: String) -> void:
	events.push_front({"tick": tick, "title": title, "body": body})
	if events.size() > 35:
		events.pop_back()

func outcome() -> String:
	if tick == 0:
		return "Ready to run"
	if goal_status(7).met:
		return "English-to-Taluma language shift"
	if metrics.taluma < 0.25 and metrics.english > 0.75:
		return "English shift in progress"
	if metrics.public_english - metrics.home_english > 0.35 and minf(metrics.taluma, metrics.english) > 0.55:
		return "Diglossia-like distribution"
	if goal_status(3).met:
		return "Emerging shared contact variety"
	if metrics.bilingual > 0.55:
		return "Broad bilingualism"
	return "Two communities in contact"

func snapshot() -> Dictionary:
	return {"version": VERSION, "config": config.duplicate(true), "tick": tick,
		"agents": agents.duplicate(true), "history": history.duplicate(true),
		"events": events.duplicate(true), "messages": messages.duplicate(true),
		"metrics": metrics.duplicate(true), "births": births, "rng_state": str(rng.state),
		"previous_scores": previous_scores.duplicate(true)}

func restore(data: Dictionary) -> void:
	config = data.config.duplicate(true)
	tick = int(data.tick)
	agents = data.agents.duplicate(true)
	history = data.history.duplicate(true)
	events = data.events.duplicate(true)
	messages = data.messages.duplicate(true)
	metrics = data.metrics.duplicate(true)
	births = int(data.births)
	rng.seed = int(config.seed)
	rng.state = int(data.rng_state)
	previous_scores = data.previous_scores.duplicate(true)
	_build_networks()
