extends SceneTree

const Sim = preload("res://simulation.gd")
const Language = preload("res://language.gd")

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var a = Sim.new()
	var b = Sim.new()
	a.setup({"seed": 9143, "population": 48})
	b.setup({"seed": 9143, "population": 48})
	assert(a.metrics.comprehension == 0.0 and a.exchanges == 0, "Setup must not retain previous observations.")
	for round_id in range(80):
		a.step()
		b.step()
	assert(JSON.stringify(a.metrics) == JSON.stringify(b.metrics), "Same seed must reproduce all measures.")
	assert(JSON.stringify(a.agents) == JSON.stringify(b.agents), "Same seed must reproduce agent state.")
	_check_bounds(a)
	var saved = JSON.parse_string(JSON.stringify(a.snapshot(), "", true, true))
	var resumed = Sim.new()
	resumed.restore(saved)
	for round_id in range(20):
		a.step()
		resumed.step()
	assert(a.metrics == resumed.metrics, "Checkpoint continuation must preserve future measures.")
	assert(a.agents == resumed.agents, "Checkpoint continuation must preserve agent state.")
	var no_loans = Sim.new()
	no_loans.setup({"seed": 719, "population": 48, "loan_acceptance": 0.0, "contact": 0.95, "bilingual": 0.8, "pattern_transfer": 0.95, "child_pooling": 0.8})
	for round_id in range(100):
		no_loans.step()
	var tal = no_loans.average_profile(0)
	for word in tal.lex:
		assert(is_zero_approx(word), "Lexical gate must block imported English forms in Taluma.")
	assert(Language.mean(tal.grammar) > 0.0, "Patterns must still have an independent transfer path.")
	_check_bounds(no_loans)
	var different = Sim.new()
	different.setup({"seed": 9144, "population": 48})
	for round_id in range(80):
		different.step()
	assert(JSON.stringify(different.agents) != JSON.stringify(b.agents), "Different seeds under the same conditions must not clone speaker state.")
	for i in range(5):
		assert(Language.form(Language.canonical(true), i) == Language.MEANINGS[i], "English canonical display must match the target meaning.")
	assert(Language.form(Language.canonical(false), 3).ends_with("ka?"), "Taluma question particle must be final.")
	var shift = Sim.new()
	var shift_config: Dictionary = Sim.PRESETS[6].values.duplicate(true)
	shift_config["population"] = 48
	shift.setup(shift_config)
	assert(not shift.goal_status(7).met, "Initial bilingual learning must not award a language shift.")
	for round_id in range(175):
		shift.step()
	_check_bounds(shift)
	for key in ["english_origin_taluma", "english_origin_home_taluma", "english_origin_public_taluma"]:
		assert(shift.metrics[key] >= 0.0 and shift.metrics[key] <= 1.0, "Founding-network measures must remain bounded.")
	# Hold all current readiness values, but remove Taluma's recent daily use.
	for i in range(shift.history.size() - 25, shift.history.size()):
		shift.history[i].home_english = 0.9
		shift.history[i].public_english = 0.9
	assert(not shift.goal_status(7).met, "Taluma readiness alone must not award a daily-use shift.")
	a.setup({"seed": 9143, "population": 48})
	assert(a.metrics.comprehension == 0.0 and a.exchanges == 0, "Reset must clear old encounter counts.")
	print("PASS: native Godot determinism, checkpoint continuation, probability bounds, lexical gate, independent pattern transfer, canonical templates, and language-shift evidence guards.")
	quit(0)

func _check_bounds(s: RefCounted) -> void:
	assert(s.agents.size() == int(s.config.population), "Turnover must conserve population.")
	assert(s.history.size() == s.tick + 1, "Every round must have one history observation.")
	for agent in s.agents:
		for readiness in agent.q:
			assert(readiness >= 0.0 and readiness <= 1.0, "Readiness must remain a probability.")
		for profile in agent.profiles:
			for key in ["lex", "grammar"]:
				for preference in profile[key]:
					assert(preference >= 0.0 and preference <= 1.0, "Preferences must remain probabilities.")
