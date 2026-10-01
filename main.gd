extends Control

const Sim = preload("res://simulation.gd")
const Language = preload("res://language.gd")
const Visual = preload("res://visual.gd")
const BG = Color("0e1c24")
const PANEL = Color("162b35")
const TEXT = Color("e5eef0")
const MUTED = Color("a9bcc4")
const TAL = Color("58c6b2")
const ENG = Color("f2bc70")

var sim = Sim.new()
var inputs: Dictionary = {}
var settings: Dictionary = Sim.DEFAULTS.duplicate(true)
var labels: Dictionary = {}
var running = false
var target_tick = 250
var speed = 8.0
var accumulator = 0.0
var selected_speaker = -1
var baseline: Dictionary = {}
var batch_sim: RefCounted
var batch_index = -1
var batch_results: Array = []
var batch_config: Dictionary = {}
var batch_target = 0
var batch_goal = 0
var file_dialog: FileDialog
var file_payload = ""
var file_action = "report"
var tabs: TabContainer
var town: Control
var chart: Control
var language_text: RichTextLabel
var field_text: RichTextLabel
var model_text: RichTextLabel
var inspection: RichTextLabel
var status: Label
var outcome_label: Label
var goals: OptionButton
var presets: OptionButton
var story_label: Label
var seed_input: SpinBox
var duration_input: SpinBox
var run_button: Button
var pause_button: Button
var step_button: Button
var experiment_button: Button
var ensemble_button: Button
var goal_text: Label
var goal_bar: ProgressBar
var pending_label: Label
var batch_text: RichTextLabel
var comparison_text: RichTextLabel
var splash: PanelContainer
var help_dialog: AcceptDialog

func _ready() -> void:
	_build_theme()
	_build_ui()
	sim.setup(settings)
	town.simulation = sim
	chart.simulation = sim
	_refresh()
	_build_splash()

func _build_theme() -> void:
	var t = Theme.new()
	t.default_font_size = 17
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("default_color", "RichTextLabel", TEXT)
	t.set_color("font_color", "OptionButton", TEXT)
	t.set_color("font_color", "SpinBox", TEXT)
	var panel_style = _box(PANEL, 14)
	t.set_stylebox("panel", "PanelContainer", panel_style)
	t.set_stylebox("panel", "TabContainer", _box(PANEL, 12))
	t.set_stylebox("tab_selected", "TabContainer", _box(Color("264653"), 7))
	t.set_stylebox("tab_unselected", "TabContainer", _box(BG, 7))
	t.set_color("font_selected_color", "TabContainer", TEXT)
	t.set_color("font_unselected_color", "TabContainer", MUTED)
	for kind in ["Button", "OptionButton"]:
		t.set_stylebox("normal", kind, _box(Color("24424e"), 7))
		t.set_stylebox("hover", kind, _box(Color("345a64"), 7))
		t.set_stylebox("pressed", kind, _box(Color("477978"), 7))
		t.set_stylebox("disabled", kind, _box(Color("1d323d"), 7))
		t.set_color("font_disabled_color", kind, Color("8297a0"))
	t.set_stylebox("normal", "LineEdit", _box(BG, 6))
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_color("font_color", "PopupMenu", TEXT)
	t.set_stylebox("panel", "PopupMenu", _box(PANEL, 8))
	t.set_stylebox("background", "ProgressBar", _box(BG, 5))
	t.set_stylebox("fill", "ProgressBar", _box(TAL.darkened(0.2), 5))
	t.set_stylebox("slider", "HSlider", _box(Color("2d4957"), 2))
	t.set_stylebox("grabber_area", "HSlider", _box(TAL.darkened(0.3), 2))
	t.set_stylebox("grabber_area_highlight", "HSlider", _box(TAL, 2))
	t.set_color("font_color", "AcceptDialog", TEXT)
	theme = t

func _box(color: Color, radius: int) -> StyleBoxFlat:
	var box = StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box

func _build_ui() -> void:
	var background = ColorRect.new()
	background.color = BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	add_child(margin)
	var outer = VBoxContainer.new()
	outer.add_theme_constant_override("separation", 14)
	margin.add_child(outer)
	var heading = HBoxContainer.new()
	outer.add_child(heading)
	var titles = VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(titles)
	titles.add_child(_label("CONTACT GARDEN", 30, TEXT))
	titles.add_child(_label("TuJuJu Studios  |  A living language-contact laboratory", 16, MUTED))
	heading.add_child(_button("How to play", _show_help))
	var main_row = HBoxContainer.new()
	main_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_row.add_theme_constant_override("separation", 16)
	outer.add_child(main_row)
	var left_panel = PanelContainer.new()
	left_panel.custom_minimum_size.x = 345
	main_row.add_child(left_panel)
	var left_scroll = ScrollContainer.new()
	left_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_panel.add_child(left_scroll)
	var left = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 10)
	left_scroll.add_child(left)
	left.add_child(_label("Set the starting world", 23))
	presets = OptionButton.new()
	for p in Sim.PRESETS:
		presets.add_item(p.name)
	left.add_child(presets)
	presets.item_selected.connect(_preset_selected)
	story_label = _label(Sim.PRESETS[0].story, 15, MUTED)
	story_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_label.custom_minimum_size.x = 295
	left.add_child(story_label)
	goals = OptionButton.new()
	for g in Sim.GOALS:
		goals.add_item(g)
	left.add_child(_label("Challenge", 17, TAL))
	left.add_child(goals)
	goals.item_selected.connect(func(_id): _refresh())
	_add_slider(left, "english_share", "English starting population", "Share whose initial first repertoire is English. Community identities remain fixed after setup.")
	_add_slider(left, "bilingual", "Initially bilingual", "Chance each speaker starts with readiness in the other language. This is sampled, so actual counts vary.")
	_add_slider(left, "contact", "Cross-community encounters", "Probability an encounter seeks a partner from the other founding community. Home encounters are also filtered by mobility and domain separation.")
	_add_slider(left, "prestige", "English opportunity advantage", "Below 50% favors Taluma in encounter choice; above 50% favors English. English also gets weak baseline institutional exposure. This is a social incentive, not a language quality score.")
	_add_slider(left, "domain_split", "Separate home and public use", "Higher values favor English in public and Taluma in Taluma-origin homes, and reduce repertoire pooling.")
	_add_slider(left, "loyalty", "Home-language commitment", "Supports founding-language use and reduces adoption of foreign features. It does not prevent all change.")
	_add_slider(left, "education", "Bilingual education", "Small repeated proficiency gains in BOTH languages, independent of community origin.")
	var advanced_button = _button("Show more conditions", func(): pass)
	left.add_child(advanced_button)
	var advanced = VBoxContainer.new()
	advanced.visible = false
	left.add_child(advanced)
	advanced_button.pressed.connect(func():
		advanced.visible = not advanced.visible
		advanced_button.text = "Hide more conditions" if advanced.visible else "Show more conditions")
	_add_slider(advanced, "mobility", "Network mobility", "Higher values favor distant partners and mixed home encounters. Lower values favor nearby network partners.")
	_add_slider(advanced, "loan_acceptance", "Allow borrowed word forms", "Controls foreign-word uptake and child lexical pooling. Pattern transfer has its own separate path.")
	_add_slider(advanced, "pattern_transfer", "Grammatical permeability", "Controls imitation, transfer from a dominant repertoire during low-readiness production, and bilingual pattern replication.")
	_add_slider(advanced, "child_pooling", "New-learner input pooling", "How much new learners combine caregiver home input across repertoires. They also regularize frequent variants slightly.")
	_add_slider(advanced, "turnover", "New speakers per cohort", "Share of the fixed population replaced every 25 rounds. One round is an abstract time unit, not a year.")
	var seed_row = HBoxContainer.new()
	left.add_child(seed_row)
	seed_row.add_child(_label("Seed", 16))
	seed_input = SpinBox.new()
	seed_input.min_value = 1
	seed_input.max_value = 999999
	seed_input.value = settings.seed
	seed_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seed_row.add_child(seed_input)
	seed_input.value_changed.connect(func(v): settings.seed = int(v); _pending())
	left.add_child(_button("Choose another seed", func(): seed_input.value = int(Time.get_unix_time_from_system()) % 999999 + 1))
	experiment_button = _button("Start new experiment", _new_experiment)
	left.add_child(experiment_button)
	pending_label = _label("Conditions apply to a new experiment.", 14, MUTED)
	pending_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(pending_label)
	var right = VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	main_row.add_child(right)
	var controls = HBoxContainer.new()
	controls.add_theme_constant_override("separation", 8)
	right.add_child(controls)
	run_button = _button("Run", _run)
	controls.add_child(run_button)
	pause_button = _button("Pause", func(): running = false; _refresh())
	controls.add_child(pause_button)
	step_button = _button("Step", _step)
	controls.add_child(step_button)
	controls.add_child(_label("Stop at", 15))
	duration_input = SpinBox.new()
	duration_input.min_value = 25
	duration_input.max_value = 1000
	duration_input.step = 25
	duration_input.value = 250
	duration_input.custom_minimum_size.x = 100
	controls.add_child(duration_input)
	controls.add_child(_label("rounds", 15))
	var speed_choice = OptionButton.new()
	for title in ["Slow", "Normal", "Fast"]:
		speed_choice.add_item(title)
	speed_choice.select(1)
	speed_choice.item_selected.connect(func(i): speed = [2.0, 8.0, 30.0][i])
	controls.add_child(speed_choice)
	outcome_label = _label("Ready to run", 24)
	right.add_child(outcome_label)
	status = _label("", 15, MUTED)
	right.add_child(status)
	var stat_row = HBoxContainer.new()
	right.add_child(stat_row)
	for key in ["bilingual", "taluma", "english"]:
		var card = PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stat_row.add_child(card)
		var cv = VBoxContainer.new()
		card.add_child(cv)
		var title: String = {"bilingual": "Bilingual speakers", "taluma": "Ready in Taluma", "english": "Ready in English"}[key]
		cv.add_child(_label(title, 15, MUTED))
		var value = _label("0%", 27, TAL if key != "english" else ENG)
		cv.add_child(value)
		labels[key] = value
	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(tabs)
	var town_page = VBoxContainer.new()
	town_page.name = "Town"
	tabs.add_child(town_page)
	town_page.add_child(_label("Taluma: teal    English: gold    Bilingual: light ring", 16, MUTED))
	town = Visual.new()
	town.size_flags_vertical = Control.SIZE_EXPAND_FILL
	town_page.add_child(town)
	town.speaker_selected.connect(func(i): selected_speaker = i; _refresh_inspection())
	inspection = _rich(115)
	town_page.add_child(inspection)
	var timeline_page = VBoxContainer.new()
	timeline_page.name = "Timeline"
	tabs.add_child(timeline_page)
	timeline_page.add_child(_label("Teal: bilingual    Gold: English public use    Purple: English home use", 15, MUTED))
	chart = Visual.new()
	chart.mode = "chart"
	chart.size_flags_vertical = Control.SIZE_EXPAND_FILL
	timeline_page.add_child(chart)
	comparison_text = _rich(95)
	timeline_page.add_child(comparison_text)
	timeline_page.add_child(_button("Pin this run as a comparison", _pin))
	var lab_page = VBoxContainer.new()
	lab_page.name = "Language lab"
	tabs.add_child(lab_page)
	language_text = _rich(0)
	language_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lab_page.add_child(language_text)
	var notes_page = VBoxContainer.new()
	notes_page.name = "Field notes"
	tabs.add_child(notes_page)
	field_text = _rich(0)
	field_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	notes_page.add_child(field_text)
	var ensemble_page = VBoxContainer.new()
	ensemble_page.name = "Experiments"
	tabs.add_child(ensemble_page)
	ensemble_page.add_child(_label("One seed gives one history. Test six possible histories.", 19))
	ensemble_button = _button("Test current conditions with 6 seeds", _start_batch)
	ensemble_page.add_child(ensemble_button)
	batch_text = _rich(0)
	batch_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ensemble_page.add_child(batch_text)
	batch_text.text = "This runs the starting conditions currently shown at left, from round zero to the selected stopping round. It does not alter the visible town.\n\nTry changing one condition, then compare the range of outcomes."
	var model_page = VBoxContainer.new()
	model_page.name = "Model"
	tabs.add_child(model_page)
	model_text = _rich(0)
	model_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	model_page.add_child(model_text)
	model_text.text = _model_notes()
	var goal_panel = PanelContainer.new()
	right.add_child(goal_panel)
	var goal_vbox = VBoxContainer.new()
	goal_panel.add_child(goal_vbox)
	goal_text = _label("", 15)
	goal_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	goal_vbox.add_child(goal_text)
	goal_bar = ProgressBar.new()
	goal_bar.custom_minimum_size.y = 9
	goal_bar.show_percentage = false
	goal_vbox.add_child(goal_bar)
	var bottom = HBoxContainer.new()
	right.add_child(bottom)
	bottom.add_child(_button("Export report", _export_report))
	bottom.add_child(_button("Export timeline CSV", _export_csv))
	bottom.add_child(_button("Save checkpoint", _save_checkpoint))
	bottom.add_child(_button("Load checkpoint", _load_checkpoint))
	help_dialog = AcceptDialog.new()
	help_dialog.title = "How to play Contact Garden"
	help_dialog.dialog_text = "1. Pick a starting world and a challenge.\n2. Change a few conditions at left.\n3. Click Start new experiment, then Run.\n4. Watch the town and inspect individual speakers.\n5. Use Language lab to compare forms and grammar.\n6. Pin a baseline, change one condition, and rerun.\n7. Test six seeds to see whether outcomes vary.\n\nOne round is abstract model time. A cohort enters every 25 rounds.\nReadiness is a model score, not a real language proficiency test.\nThe Model tab explains what the simulation assumes."
	add_child(help_dialog)
	file_dialog = FileDialog.new()
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.use_native_dialog = true
	file_dialog.file_selected.connect(_file_selected)
	add_child(file_dialog)

func _label(text_value: String, size_value: int = 17, color: Color = TEXT) -> Label:
	var label = Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", size_value)
	label.add_theme_color_override("font_color", color)
	return label

func _rich(height: float) -> RichTextLabel:
	var rich = RichTextLabel.new()
	rich.bbcode_enabled = true
	rich.custom_minimum_size.y = height
	rich.add_theme_font_size_override("normal_font_size", 17)
	rich.add_theme_font_size_override("bold_font_size", 18)
	rich.scroll_active = true
	return rich

func _button(title: String, callback: Callable) -> Button:
	var b = Button.new()
	b.text = title
	b.custom_minimum_size.y = 38
	b.pressed.connect(callback)
	return b

func _add_slider(parent: VBoxContainer, key: String, title: String, description: String) -> void:
	var row = VBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	parent.add_child(row)
	var heading = HBoxContainer.new()
	row.add_child(heading)
	var label = _label(title, 15)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.tooltip_text = description
	heading.add_child(label)
	var value_label = _label("%d%%" % roundi(float(settings[key]) * 100.0), 15, TAL)
	heading.add_child(value_label)
	var slider = HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = float(settings[key]) * 100.0
	slider.custom_minimum_size.y = 24
	slider.tooltip_text = description
	row.add_child(slider)
	inputs[key] = slider
	slider.value_changed.connect(func(v):
		settings[key] = v / 100.0
		value_label.text = "%d%%" % roundi(v)
		_pending())

func _pending() -> void:
	if pending_label != null:
		pending_label.text = "Changed conditions are pending. Start a new experiment to apply them."
		pending_label.add_theme_color_override("font_color", ENG)

func _preset_selected(id: int) -> void:
	settings = Sim.DEFAULTS.duplicate(true)
	settings.merge(Sim.PRESETS[id].values, true)
	for key in inputs:
		inputs[key].value = float(settings[key]) * 100.0
	seed_input.value = settings.seed
	story_label.text = Sim.PRESETS[id].story
	var default_goals = [1, 2, 4, 0, 5, 6, 7]
	goals.select(default_goals[id])
	_pending()

func _new_experiment() -> void:
	if batch_index >= 0:
		return
	running = false
	if sim.tick > 0 and baseline.is_empty():
		_pin()
	sim.setup(settings)
	selected_speaker = -1
	town.selected = -1
	pending_label.text = "Conditions applied. Press Run to observe this world."
	pending_label.add_theme_color_override("font_color", MUTED)
	_refresh()

func _run() -> void:
	if batch_index >= 0:
		return
	target_tick = int(duration_input.value)
	if sim.tick >= target_tick:
		duration_input.value = minf(1000, sim.tick + 100)
		target_tick = int(duration_input.value)
	running = sim.tick < target_tick
	_refresh()

func _step() -> void:
	if batch_index >= 0:
		return
	running = false
	sim.step()
	_refresh()

func _process(delta: float) -> void:
	if batch_index >= 0:
		_batch_frame()
		return
	if not running:
		return
	accumulator += delta * speed
	var steps = mini(3, int(accumulator))
	if steps <= 0:
		return
	accumulator -= steps
	for k in range(steps):
		if sim.tick >= target_tick:
			running = false
			break
		sim.step()
	if sim.tick >= target_tick:
		running = false
	_refresh()

func _refresh() -> void:
	var m = sim.metrics
	for key in labels:
		labels[key].text = "%d%%" % roundi(m[key] * 100.0)
	outcome_label.text = sim.outcome()
	status.text = "Round %d  |  Cohort %d  |  %d speakers  |  Seed %d%s" % [sim.tick, sim.tick / 25, sim.agents.size(), int(sim.config.seed), "  |  Running" if running else ""]
	run_button.disabled = running or batch_index >= 0
	pause_button.disabled = not running
	step_button.disabled = running or batch_index >= 0
	experiment_button.disabled = batch_index >= 0
	ensemble_button.disabled = false
	ensemble_button.text = "Cancel experiment set" if batch_index >= 0 else "Test current conditions with 6 seeds"
	duration_input.editable = not running and batch_index < 0
	var goal = sim.goal_status(goals.selected)
	goal_text.text = ("Challenge achieved. " if goal.met else "Goal: ") + goal.text
	goal_bar.value = float(goal.progress) * 100.0
	goal_bar.visible = goals.selected != 0
	town.queue_redraw()
	chart.queue_redraw()
	_refresh_inspection()
	_refresh_languages()
	_refresh_notes()
	_refresh_comparison()

func _refresh_inspection() -> void:
	if selected_speaker < 0:
		inspection.text = "[b]Observe the town[/b]\nFounding communities occupy different parts of the map. Lines show a sample of recent public encounters. Colors show relative readiness, not the origin of every word."
		return
	var a: Dictionary = sim.agents[selected_speaker]
	inspection.text = "[b]Speaker %d[/b]  |  %s-origin network  |  %s\nTaluma readiness %d%%; English readiness %d%%\nTaluma repertoire: %s\nEnglish repertoire: %s" % [selected_speaker + 1, "Taluma" if a.origin == 0 else "English", "new learner" if a.age < 9 else "experienced speaker", roundi(a.q[0] * 100.0), roundi(a.q[1] * 100.0), Language.form(a.profiles[0], 0), Language.form(a.profiles[1], 0)]

func _refresh_languages() -> void:
	var tal = sim.average_profile(0)
	var eng = sim.average_profile(1)
	var text_value = "[b]One meaning, changing forms[/b]\nThese are modal summaries of speaker preferences, not recordings of an individual sentence. English is a bounded template system. Taluma is invented.\n\n"
	for i in range(5):
		text_value += "[color=#f2bc70]%s[/color]\nStart Taluma: %s\nNow Taluma: [b]%s[/b]\nNow English: [b]%s[/b]\n\n" % [Language.MEANINGS[i], Language.form(Language.canonical(false), i), Language.form(tal, i), Language.form(eng, i)]
	text_value += "[b]Grammar in the Taluma repertoire[/b]\nPercentages show probability mass favoring English-origin variants, not percent of speakers who have abandoned Taluma.\n\n"
	for f in range(Language.FEATURE_NAMES.size()):
		text_value += "%s: %d%% English-patterned\n  Taluma: %s\n  English: %s\n\n" % [Language.FEATURE_NAMES[f], roundi(tal.grammar[f] * 100.0), Language.TAL_FEATURES[f], Language.ENG_FEATURES[f]]
	text_value += "[b]Vocabulary in the Taluma repertoire[/b]\n"
	for i in range(Language.CONCEPTS.size()):
		text_value += "%s / %s: %d%% English-form preference\n" % [Language.TALUMA[i], Language.CONCEPTS[i], roundi(tal.lex[i] * 100.0)]
	language_text.text = text_value

func _refresh_notes() -> void:
	var m = sim.metrics
	var text_value = "[b]Language use by domain[/b]\nEnglish at home: %d%%\nEnglish in public: %d%%\nExpected comprehension: %d%%\n%s\n\n" % [roundi(m.home_english * 100.0), roundi(m.public_english * 100.0), roundi(m.comprehension * 100.0), "Round 0 use is a model expectation, before encounters." if sim.tick == 0 else "Use percentages count the selected language of actual modeled encounters."]
	text_value += "[b]English-origin networks[/b]\nTaluma readiness: %d%%\nTaluma at home: %d%%\nTaluma in public: %d%%\nOrigin tracks founding households and their descendants.\n\n" % [roundi(m.get("english_origin_taluma", 0.0) * 100.0), roundi(m.get("english_origin_home_taluma", 0.0) * 100.0), roundi(m.get("english_origin_public_taluma", 0.0) * 100.0)]
	text_value += "[b]Observed transitions[/b]\n"
	for e in sim.events:
		text_value += "[color=#58c6b2]Round %d: %s[/color]\n%s\n\n" % [e.tick, e.title, e.body]
	text_value += "[b]Recent word encounters[/b]\n"
	for message in sim.messages:
		text_value += "Round %d | %s | speaker %d > %d\n%s repertoire: '%s' for %s. Expected comprehension %d%%.\n\n" % [message.tick, message.domain, message.speaker, message.listener, message.language, message.word, message.meaning, roundi(message.understood * 100.0)]
	field_text.text = text_value

func _pin() -> void:
	baseline = {"config": sim.config.duplicate(true), "metrics": sim.metrics.duplicate(true), "history": sim.history.duplicate(true), "outcome": sim.outcome()}
	chart.comparison = baseline.history
	_refresh_comparison()
	chart.queue_redraw()

func _refresh_comparison() -> void:
	if baseline.is_empty():
		comparison_text.text = "Pin a completed run, change one starting condition, then rerun. A faint teal line shows the baseline bilingual trajectory."
		return
	var b: Dictionary = baseline.metrics
	var changed: Array = []
	for key in sim.config:
		if sim.config[key] != baseline.config.get(key):
			changed.append(key)
	comparison_text.text = "[b]Baseline:[/b] %s, round %d, seed %d\nCurrent bilingual change: %+d points. Taluma readiness change: %+d points.\nChanged conditions: %s%s" % [baseline.outcome, b.tick, int(baseline.config.seed), roundi((sim.metrics.bilingual - b.bilingual) * 100.0), roundi((sim.metrics.taluma - b.taluma) * 100.0), ", ".join(changed) if not changed.is_empty() else "none", "\nDifferent stopping rounds: compare these endpoints cautiously." if sim.tick != b.tick else ""]

func _start_batch() -> void:
	if batch_index >= 0:
		batch_index = -1
		_refresh_batch_text()
		_refresh()
		return
	running = false
	batch_index = 0
	batch_results.clear()
	batch_config = settings.duplicate(true)
	batch_target = int(duration_input.value)
	batch_goal = goals.selected
	batch_sim = Sim.new()
	batch_sim.setup(batch_config)
	_refresh()

func _batch_frame() -> void:
	# Frame-limited processing keeps the UI responsive.
	for k in range(3):
		if batch_sim.tick < batch_target:
			batch_sim.step()
	if batch_sim.tick >= batch_target:
		batch_results.append({"seed": batch_sim.config.seed, "metrics": batch_sim.metrics.duplicate(true), "outcome": batch_sim.outcome(), "met": batch_sim.goal_status(batch_goal).met})
		batch_index += 1
		if batch_index < 6:
			var c = batch_config.duplicate(true)
			c.seed = int(batch_config.seed) + batch_index * 101
			batch_sim.setup(c)
		else:
			batch_index = -1
	_refresh_batch_text()
	if batch_index < 0:
		_refresh()

func _refresh_batch_text() -> void:
	var text_value = "[b]Six histories, same conditions[/b]\nStop: %d rounds. Challenge: %s.\n" % [batch_target, Sim.GOALS[batch_goal]]
	if batch_index >= 0:
		text_value += "Running history %d of 6: round %d.\n" % [batch_index + 1, batch_sim.tick]
	var achieved = 0
	var low = 1.0
	var high = 0.0
	for result in batch_results:
		var m: Dictionary = result.metrics
		achieved += 1 if result.met else 0
		low = minf(low, m.bilingual)
		high = maxf(high, m.bilingual)
		text_value += "\n[b]Seed %d: %s[/b]\nBilingual %d%%; Taluma %d%%; English %d%%.\nChallenge: %s.\n" % [int(result.seed), result.outcome, roundi(m.bilingual * 100.0), roundi(m.taluma * 100.0), roundi(m.english * 100.0), "achieved" if result.met else "not achieved"]
	if batch_index < 0:
		if batch_results.is_empty():
			text_value += "\nCanceled before the first history finished."
		else:
			text_value += "\n[b]Challenge achieved in %d of %d completed histories.[/b]\nBilingual range: %d%% to %d%%.\nThese seeds illustrate variability; they do not establish a real-world probability." % [achieved, batch_results.size(), roundi(low * 100.0), roundi(high * 100.0)]
	batch_text.text = text_value

func _build_splash() -> void:
	splash = PanelContainer.new()
	splash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	splash.add_theme_stylebox_override("panel", _box(BG, 0))
	add_child(splash)
	var center = CenterContainer.new()
	splash.add_child(center)
	var content = VBoxContainer.new()
	content.custom_minimum_size.x = 670
	content.add_theme_constant_override("separation", 23)
	center.add_child(content)
	content.add_child(_label("TUJUJU STUDIOS", 24, TAL))
	content.add_child(_label("Contact Garden", 56))
	content.add_child(_label("Small encounters. Different language futures.", 25, ENG))
	var intro = _label("Create a world where English and the fictional language Taluma meet. Set the social conditions, watch generations learn, and compare the languages that emerge.\n\nCan you keep both languages alive? Separate public and home use? Help a shared contact variety take root?", 21)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.custom_minimum_size.x = 670
	content.add_child(intro)
	content.add_child(_button("Enter the laboratory", func(): splash.queue_free()))
	content.add_child(_label("An educational simulation with explicit assumptions. Version " + Sim.VERSION, 15, MUTED))

func _show_help() -> void:
	help_dialog.dialog_text = "1. Pick a starting world and a challenge.\n2. Change a few conditions at left.\n3. Click Start new experiment, then Run.\n4. Watch the town and inspect speakers.\n5. Compare forms in Language lab.\n6. Pin a baseline, change one condition, and rerun.\n7. Test six seeds to observe variability.\n\nA round is abstract model time. A cohort enters every 25 rounds.\nReadiness is a model score, not a real proficiency test.\nThe Model tab explains the assumptions."
	help_dialog.popup_centered(Vector2i(720, 450))

func _model_notes() -> String:
	return "[b]What this simulation models[/b]\n144 speakers, two founding networks, two repertoires per speaker, twenty noun meanings, and six grammatical features. Encounter language is chosen from mutual readiness, English opportunity incentives, domain, and identity commitment.\n\nSpeakers sample word forms and grammatical variants from their repertoires. Listeners gain readiness and update preferences. Less-ready speakers can transfer patterns from their stronger founding repertoire. Bilinguals can replicate patterns across repertoires without importing words.\n\nA new cohort enters every 25 rounds. Caregiver input and home language use shape its starting readiness. Input pooling and modest regularization can produce more conventionalized combinations. No rule says that contact must simplify grammar.\n\n[b]Definitions used in the game[/b]\nReady in a language: modeled readiness at least 0.60. Bilingual: both scores meet 0.60. These are not CEFR levels.\nGrammar change: average probability shift away from the original variants. Distance: average difference between repertoire grammar probabilities. Confidence: preference strength for modal variants; it does not measure inter-speaker agreement or historical stability.\nDiglossia-like: sustained public/home functional separation while both repertoires remain available. The game's broad definition does not model the full social history of classic diglossia.\nCreole formation laboratory: a challenge for a transmitted, conventionalizing contact variety. Grammar alone cannot prove that a real language is a creole.\n\n[b]Explicit limits[/b]\nThe coefficients and success thresholds are designer assumptions, not empirically calibrated forecasts. Taluma is fictional. English is restricted to five display templates and six variant contrasts. The model does not generate unrestricted new grammar, sound change, or semantic innovation. It recombines a finite feature pool.\n\nCommunity origin stays fixed; age is compressed; a cohort is not a literal generation. Family ties are sampled network partners, not a persistent genealogy. Comprehension is an expected score, not a parsed meaning test. Social inequality is represented narrowly by language-choice incentives.\n\n[b]Research foundations[/b]\nMatras and Sakel (2007): pattern replication and matter borrowing.\nWinford (2005): agentivity, borrowing, and imposition.\nThomason (2007): social and linguistic predictors.\nAikhenvald (2003): contact can create grammatical distinctions.\nTorres, Xu, Li, and Futrell (2025): agent-based conventionalization and code-switching.\nA three-state language competition model (2023): learning and attrition.\n\nSee MODEL_GUIDE.md for equations, thresholds, source links, and ways to extend the project."

func _export_report() -> void:
	var report = "CONTACT GARDEN | TuJuJu Studios\nModel version " + Sim.VERSION + "\n\n"
	report += "Round: %d\nSeed: %d\nOutcome: %s\nChallenge: %s\nAchieved: %s\n\n" % [sim.tick, int(sim.config.seed), sim.outcome(), Sim.GOALS[goals.selected], str(sim.goal_status(goals.selected).met)]
	report += "INITIAL CONDITIONS\n" + JSON.stringify(sim.config, "  ") + "\n\nFINAL MEASURES\n" + JSON.stringify(sim.metrics, "  ")
	report += "\n\nTALUMA REPERTOIRE EXAMPLES\n"
	for i in range(5):
		report += Language.MEANINGS[i] + " -> " + Language.form(sim.average_profile(0), i) + "\n"
	if not batch_results.is_empty():
		report += "\nSIX-SEED EXPERIMENT\nConditions: " + JSON.stringify(batch_config) + "\nStop: " + str(batch_target) + "\n" + JSON.stringify(batch_results, "  ")
	report += "\n\nInterpretation: this educational model is not a calibrated historical prediction. A creole-like outcome is a model challenge, not a linguistic diagnosis."
	_offer_file("Contact_Garden_Report.txt", report, "report")

func _export_csv() -> void:
	var keys: Array = ["tick", "bilingual", "taluma", "english", "home_english", "public_english", "overall_english", "english_origin_taluma", "english_origin_home_taluma", "english_origin_public_taluma", "comprehension", "distance", "confidence", "grammar_change", "taluma_loans", "english_loans", "young_taluma", "new_speakers", "births"]
	var csv = ",".join(keys) + "\n"
	for row in sim.history:
		var values: Array = []
		for key in keys:
			values.append(str(row.get(key, "")))
		csv += ",".join(values) + "\n"
	_offer_file("Contact_Garden_Timeline.csv", csv, "report")

func _save_checkpoint() -> void:
	running = false
	var data = sim.snapshot()
	data["goal"] = goals.selected
	_offer_file("Contact_Garden_Checkpoint.json", JSON.stringify(data, "", true, true), "report")
	_refresh()

func _offer_file(filename: String, payload: String, action: String) -> void:
	if OS.has_feature("web"):
		var js = "(()=>{const b=new Blob([%s],{type:'text/plain;charset=utf-8'});const a=document.createElement('a');const u=URL.createObjectURL(b);a.href=u;a.download=%s;document.body.appendChild(a);a.click();a.remove();setTimeout(()=>URL.revokeObjectURL(u),1000);})()" % [JSON.stringify(payload), JSON.stringify(filename)]
		JavaScriptBridge.eval(js)
		return
	file_payload = payload
	file_action = action
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.current_file = filename
	file_dialog.filters = PackedStringArray(["*." + filename.get_extension() + " ; " + filename.get_extension().to_upper()])
	file_dialog.popup_centered(Vector2i(800, 550))

func _load_checkpoint() -> void:
	running = false
	if OS.has_feature("web"):
		help_dialog.dialog_text = "Loading checkpoints is available in the desktop Godot build. Reports and checkpoint downloads work in web exports."
		help_dialog.popup_centered()
		return
	file_action = "load"
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.filters = PackedStringArray(["*.json ; Contact Garden checkpoint"])
	file_dialog.popup_centered(Vector2i(800, 550))

func _file_selected(path: String) -> void:
	if file_action == "load":
		var source = FileAccess.open(path, FileAccess.READ)
		if source == null:
			_notice("Could not open that checkpoint.")
			return
		var data = JSON.parse_string(source.get_as_text())
		if not _valid_checkpoint(data):
			_notice("This is not a compatible Contact Garden checkpoint.")
			return
		sim.restore(data)
		settings = sim.config.duplicate(true)
		for key in inputs:
			inputs[key].value = float(settings[key]) * 100.0
		seed_input.value = settings.seed
		goals.select(clampi(int(data.get("goal", 0)), 0, Sim.GOALS.size() - 1))
		selected_speaker = -1
		town.selected = -1
		pending_label.text = "Checkpoint loaded. Shown conditions match this experiment."
		pending_label.add_theme_color_override("font_color", MUTED)
		_refresh()
		return
	var destination = FileAccess.open(path, FileAccess.WRITE)
	if destination == null:
		_notice("Could not save the file to that location.")
		return
	destination.store_string(file_payload)
	destination.close()
	_notice("Saved " + path.get_file())

func _valid_checkpoint(data: Variant) -> bool:
	if not data is Dictionary:
		return false
	for key in ["version", "config", "tick", "agents", "history", "events", "messages", "metrics", "births", "rng_state", "previous_scores"]:
		if not data.has(key):
			return false
	if data.version not in [Sim.VERSION, "0.1.0"] or not data.agents is Array or data.agents.size() != 144:
		return false
	for a in data.agents:
		if not a is Dictionary or not a.has("q") or not a.has("profiles"):
			return false
		if a.q.size() != 2 or a.profiles.size() != 2:
			return false
		for p in a.profiles:
			if not p.has("lex") or not p.has("grammar") or p.lex.size() != 20 or p.grammar.size() != 6:
				return false
	return true

func _notice(message: String) -> void:
	help_dialog.dialog_text = message
	help_dialog.popup_centered()
