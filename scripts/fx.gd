extends Control
## Camada de efeitos desenhada por cima da interface.
## Nao intercepta toques (MOUSE_FILTER_IGNORE) e e alimentada pelo main.gd.

const CYAN := Color(0.204, 0.863, 0.941)
const GREEN := Color(0.29, 0.87, 0.5)
const RED := Color(0.96, 0.28, 0.32)
const VIOLET := Color(0.55, 0.55, 1.0)
const GOLD := Color(1.0, 0.79, 0.3)

var t := 0.0
var panel_rect := Rect2()
var has_panel := false

# Moldura
var frame_alpha := 0.0
var frame_target := 0.55
var frame_color := CYAN
var pulse := 0.0
var corners := 0.0

# Flash de tela
var flash_alpha := 0.0
var flash_color := GREEN
var flash_decay := 3.2

# Varredura de setor
var sweep_t := -1.0
var sweep_color := VIOLET

# Particulas
var parts: Array = []
var motes: Array = []
var _motes_ready := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 20


# ---------------------------------------------------------------- API publica

func set_panel(r: Rect2) -> void:
	panel_rect = r
	has_panel = r.size.x > 4.0 and r.size.y > 4.0


func flash(color: Color, strength := 0.35, decay := 3.4) -> void:
	flash_color = color
	flash_alpha = maxf(flash_alpha, strength)
	flash_decay = decay
	ping(color, 0.9)


func ping(color: Color, strength := 0.7) -> void:
	frame_color = color
	pulse = maxf(pulse, strength)
	frame_target = 0.75


func burst(pos: Vector2, color: Color, count := 22, power := 1.0) -> void:
	for i in count:
		var ang := randf() * TAU
		var spd := (60.0 + randf() * 190.0) * power
		parts.append({
			"p": pos + Vector2(randf_range(-14, 14), randf_range(-10, 10)),
			"v": Vector2(cos(ang), sin(ang)) * spd + Vector2(0, -60.0),
			"life": 0.6 + randf() * 0.8,
			"max": 1.4,
			"col": color,
			"r": 2.2 + randf() * 4.4,
		})


func sweep(color: Color) -> void:
	sweep_color = color
	sweep_t = 0.0
	ping(color, 0.8)


func clear_all() -> void:
	parts.clear()
	flash_alpha = 0.0
	sweep_t = -1.0
	pulse = 0.0


# ------------------------------------------------------------------ loop

func _process(delta: float) -> void:
	t += delta
	frame_alpha = lerpf(frame_alpha, frame_target, 1.0 - pow(0.02, delta))
	pulse = maxf(0.0, pulse - delta * 1.8)
	corners = lerpf(corners, 1.0 if has_panel else 0.0, 1.0 - pow(0.05, delta))

	if flash_alpha > 0.0:
		flash_alpha = maxf(0.0, flash_alpha - delta * flash_decay)

	if sweep_t >= 0.0:
		sweep_t += delta * 0.55
		if sweep_t > 1.6:
			sweep_t = -1.0

	var i := parts.size() - 1
	while i >= 0:
		var p: Dictionary = parts[i]
		p["life"] -= delta
		if p["life"] <= 0.0:
			parts.remove_at(i)
		else:
			p["v"] = p["v"] + Vector2(0, 320.0) * delta
			p["v"] = p["v"] * (1.0 - 1.6 * delta)
			p["p"] = p["p"] + p["v"] * delta
			parts[i] = p
		i -= 1

	if not _motes_ready and size.x > 10.0:
		_motes_ready = true
		for k in 16:
			motes.append(Vector4(randf() * size.x, randf() * size.y, 0.4 + randf() * 1.4, randf() * TAU))
	for k in motes.size():
		var m: Vector4 = motes[k]
		m.y -= (8.0 + m.z * 6.0) * delta
		if m.y < -8.0:
			m.y = size.y + 8.0
			m.x = randf() * maxf(size.x, 1.0)
		motes[k] = m

	queue_redraw()


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y

	# Flash de tela inteira
	if flash_alpha > 0.001:
		draw_rect(Rect2(Vector2.ZERO, Vector2(w, h)), Color(flash_color.r, flash_color.g, flash_color.b, flash_alpha * 0.42))

	# Moldura do painel
	if has_panel:
		var r := panel_rect
		var glow := 0.16 + 0.28 * pulse + 0.06 * sin(t * 2.0)
		var col := Color(frame_color.r, frame_color.g, frame_color.b, glow * frame_alpha)
		for k in 3:
			var grow := float(k) * 2.0
			draw_rect(Rect2(r.position - Vector2(grow, grow), r.size + Vector2(grow, grow) * 2.0), col, false, 1.6 - float(k) * 0.4)

		# Cantos em L
		var c: float = 26.0
		var cc := Color(frame_color.r, frame_color.g, frame_color.b, (0.45 + 0.35 * pulse) * corners)
		draw_line(r.position + Vector2(-6, -6), r.position + Vector2(c, -6), cc, 2.6)
		draw_line(r.position + Vector2(-6, -6), r.position + Vector2(-6, c), cc, 2.6)
		draw_line(Vector2(r.end.x + 6, r.position.y - 6), Vector2(r.end.x - c, r.position.y - 6), cc, 2.6)
		draw_line(Vector2(r.end.x + 6, r.position.y - 6), Vector2(r.end.x + 6, r.position.y + c), cc, 2.6)
		draw_line(Vector2(r.position.x - 6, r.end.y + 6), Vector2(r.position.x + c, r.end.y + 6), cc, 2.6)
		draw_line(Vector2(r.position.x - 6, r.end.y + 6), Vector2(r.position.x - 6, r.end.y - c), cc, 2.6)
		draw_line(Vector2(r.end.x + 6, r.end.y + 6), Vector2(r.end.x - c, r.end.y + 6), cc, 2.6)
		draw_line(Vector2(r.end.x + 6, r.end.y + 6), Vector2(r.end.x + 6, r.end.y - c), cc, 2.6)

		# Pulso que percorre a borda
		if pulse > 0.01:
			var per := 2.0 * (r.size.x + r.size.y)
			var dist := fmod(t * 420.0, per)
			var p0 := _point_on_perimeter(r, dist)
			var p1 := _point_on_perimeter(r, dist + 90.0)
			draw_line(p0, p1, Color(frame_color.r, frame_color.g, frame_color.b, 0.75 * pulse), 3.0)
			draw_circle(p1, 4.0 + 3.0 * pulse, Color(frame_color.r, frame_color.g, frame_color.b, 0.85 * pulse))

	# Varredura de setor
	if sweep_t >= 0.0:
		var y := lerpf(-120.0, h + 120.0, clampf(sweep_t, 0.0, 1.0))
		var a := clampf(1.0 - absf(sweep_t - 0.6), 0.0, 1.0)
		draw_rect(Rect2(0, y, w, 120.0), Color(sweep_color.r, sweep_color.g, sweep_color.b, 0.10 * a))
		draw_line(Vector2(0, y), Vector2(w, y), Color(sweep_color.r, sweep_color.g, sweep_color.b, 0.65 * a), 2.0)

	# Particulas
	for p in parts:
		var k2: float = clampf(p["life"] / p["max"], 0.0, 1.0)
		var c2: Color = p["col"]
		var pos: Vector2 = p["p"]
		var rad: float = p["r"] * (0.4 + k2 * 0.8)
		draw_circle(pos, rad, Color(c2.r, c2.g, c2.b, 0.85 * k2))
		draw_circle(pos, rad * 2.4, Color(c2.r, c2.g, c2.b, 0.16 * k2))

	# Motas flutuantes
	for m in motes:
		var a3: float = 0.10 + 0.12 * sin(t * 1.3 + m.w)
		draw_circle(Vector2(m.x, m.y), m.z, Color(CYAN.r, CYAN.g, CYAN.b, clampf(a3, 0.03, 0.22)))


func _point_on_perimeter(r: Rect2, d: float) -> Vector2:
	var per := 2.0 * (r.size.x + r.size.y)
	d = fmod(maxf(d, 0.0), per)
	if d < r.size.x:
		return Vector2(r.position.x + d, r.position.y)
	d -= r.size.x
	if d < r.size.y:
		return Vector2(r.end.x, r.position.y + d)
	d -= r.size.y
	if d < r.size.x:
		return Vector2(r.end.x - d, r.end.y)
	d -= r.size.x
	return Vector2(r.position.x, r.end.y - d)
