extends Control
## Programmatic visualization, no external assets.

signal speaker_selected(id: int)
const TAL = Color("58c6b2")
const ENG = Color("f2bc70")
const INK = Color("dae6e8")
const GRID = Color("28404c")
const MUTED = Color("8ca4af")
var simulation: RefCounted
var mode = "town"
var selected = -1
var comparison: Array = []
var font: Font
var dot_positions: Array = []

func _ready() -> void:
	font = ThemeDB.fallback_font
	custom_minimum_size = Vector2(500, 270)
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)

func _draw() -> void:
	if simulation == null:
		return
	if mode == "town":
		_draw_town()
	else:
		_draw_chart()

func _draw_town() -> void:
	dot_positions.clear()
	var n = simulation.agents.size()
	var columns = 18
	var rows = int(ceil(float(n) / columns))
	var cell = Vector2((size.x - 40) / columns, (size.y - 65) / rows)
	for i in range(n):
		var pos = Vector2(20 + (i % columns + 0.5) * cell.x, 20 + (floori(float(i) / columns) + 0.5) * cell.y)
		dot_positions.append(pos)
	for edge in simulation.talk_edges:
		draw_line(dot_positions[edge[0]], dot_positions[edge[1]], Color(0.48, 0.63, 0.70, 0.10), 1)
	for i in range(n):
		var a: Dictionary = simulation.agents[i]
		var english = a.q[1] / maxf(0.01, a.q[0] + a.q[1])
		var color = TAL.lerp(ENG, english)
		var radius = minf(cell.x, cell.y) * 0.23
		var p: Vector2 = dot_positions[i]
		draw_circle(p, radius, color)
		if minf(a.q[0], a.q[1]) >= 0.6:
			draw_arc(p, radius + 3, 0, TAU, 24, INK, 1.5)
		if a.age < 9:
			draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), Color("132631"))
		if i == selected:
			draw_arc(p, radius + 6, 0, TAU, 28, Color.WHITE, 2.5)
	draw_string(font, Vector2(16, size.y - 12), "Click a speaker to inspect their repertoire. Square center = new learner.", HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 14, MUTED)

func _draw_chart() -> void:
	var rect = Rect2(48, 24, size.x - 66, size.y - 65)
	for k in range(5):
		var y = rect.end.y - rect.size.y * k / 4.0
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), GRID)
		draw_string(font, Vector2(6, y + 5), "%d%%" % (k * 25), HORIZONTAL_ALIGNMENT_LEFT, 40, 13, MUTED)
	var h: Array = simulation.history
	var max_tick = maxf(1.0, simulation.tick)
	_draw_series(h, "bilingual", TAL, rect, max_tick)
	_draw_series(h, "public_english", ENG, rect, max_tick)
	_draw_series(h, "home_english", Color("a7a0ec"), rect, max_tick)
	if not comparison.is_empty():
		_draw_series(comparison, "bilingual", Color(0.35, 0.78, 0.70, 0.35), rect, max_tick)
	draw_string(font, Vector2(rect.position.x, size.y - 10), "0", HORIZONTAL_ALIGNMENT_LEFT, 50, 13, MUTED)
	draw_string(font, Vector2(rect.end.x - 125, size.y - 10), "%d rounds" % simulation.tick, HORIZONTAL_ALIGNMENT_RIGHT, 125, 13, MUTED)

func _draw_series(h: Array, key: String, color: Color, rect: Rect2, max_tick: float) -> void:
	if h.size() < 2:
		return
	var points = PackedVector2Array()
	for m in h:
		if m.tick > max_tick:
			break
		points.append(Vector2(rect.position.x + rect.size.x * m.tick / max_tick, rect.end.y - rect.size.y * m[key]))
	if points.size() >= 2:
		draw_polyline(points, color, 2.4, true)

func _gui_input(event: InputEvent) -> void:
	if mode != "town" or not event is InputEventMouseButton:
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	var nearest = -1
	var distance = 24.0
	for i in range(dot_positions.size()):
		var d = event.position.distance_to(dot_positions[i])
		if d < distance:
			nearest = i
			distance = d
	if nearest >= 0:
		selected = nearest
		speaker_selected.emit(nearest)
		queue_redraw()
