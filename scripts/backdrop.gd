extends Control
## Fundo animado: grade em perspectiva, poeira digital, varredura e vinheta.
## Fica atras da interface (z_index negativo) e se redesenha a cada frame.

const CYAN := Color(0.204, 0.863, 0.941)
const DEEP := Color(0.043, 0.078, 0.157)

var t := 0.0
var scan_y := 0.0
var dust: Array = []
var _ready_dust := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = -1


func _process(delta: float) -> void:
	t += delta
	if not _ready_dust and size.x > 10.0:
		_ready_dust = true
		for i in 46:
			dust.append(Vector4(randf() * size.x, randf() * size.y, 6.0 + randf() * 26.0, 0.6 + randf() * 1.6))
	scan_y = fmod(scan_y + delta * 60.0, maxf(size.y, 1.0))
	for i in dust.size():
		var d: Vector4 = dust[i]
		d.y -= d.z * delta
		if d.y < -6.0:
			d.y = size.y + 6.0
			d.x = randf() * maxf(size.x, 1.0)
		dust[i] = d
	queue_redraw()


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w < 10.0 or h < 10.0:
		return

	# Brilho frio vindo de baixo
	for i in 26:
		var r: float = w * (0.35 + float(i) * 0.045)
		draw_circle(Vector2(w * 0.5, h * 1.12), r, Color(CYAN.r, CYAN.g, CYAN.b, 0.0075 * (1.0 - float(i) / 26.0)))

	# Grade em perspectiva
	var horizon: float = h * 0.66
	var vp := Vector2(w * 0.5, horizon - h * 0.08)
	draw_line(Vector2(0, horizon), Vector2(w, horizon), Color(CYAN.r, CYAN.g, CYAN.b, 0.22), 1.5)
	var cols := 12
	for i in range(-cols, cols + 1):
		var xb: float = w * 0.5 + (float(i) / float(cols)) * w * 1.4
		draw_line(vp, Vector2(xb, h + 30.0), Color(CYAN.r, CYAN.g, CYAN.b, 0.13), 1.0)
	var rows := 14
	for i in rows:
		var p: float = fmod(float(i) / float(rows) + fmod(t * 0.03, 1.0 / float(rows)), 1.0)
		var y: float = horizon + pow(p, 2.1) * (h - horizon + 40.0)
		draw_line(Vector2(0, y), Vector2(w, y), Color(CYAN.r, CYAN.g, CYAN.b, 0.07 + 0.26 * p), 1.2)

	# Grade fina de fundo (a antiga, agora mais discreta)
	var step := maxi(34, int(w / 30.0))
	var x := 0
	while x <= int(w):
		draw_line(Vector2(x, 0), Vector2(x, h), Color(0.071, 0.169, 0.267, 0.75), 1.0)
		x += step
	var y2 := 0
	while y2 <= int(h):
		draw_line(Vector2(0, y2), Vector2(w, y2), Color(0.071, 0.169, 0.267, 0.75), 1.0)
		y2 += step

	# Poeira digital
	for i in dust.size():
		var d: Vector4 = dust[i]
		var a: float = clampf(0.16 + 0.18 * sin(t * 1.6 + float(i)), 0.06, 0.42)
		draw_circle(Vector2(d.x, d.y), d.w, Color(CYAN.r, CYAN.g, CYAN.b, a))

	# Linha de varredura
	for i in 6:
		var fade: float = 0.016 * (1.0 - float(i) / 6.0)
		draw_rect(Rect2(0, scan_y + float(i) * 15.0, w, 15.0), Color(CYAN.r, CYAN.g, CYAN.b, fade))
	draw_line(Vector2(0, scan_y + 90.0), Vector2(w, scan_y + 90.0), Color(0.13, 0.44, 0.56, 0.35), 1.2)

	# Barra ciano no topo (identidade original, agora com brilho)
	draw_rect(Rect2(0, 0, w, 4), Color(CYAN.r, CYAN.g, CYAN.b, 0.85))

	# Vinheta
	var steps := 18
	var band: float = h * 0.22 / float(steps)
	for i in steps:
		var a2: float = 0.06 * (1.0 - float(i) / float(steps))
		draw_rect(Rect2(0, i * band, w, band), Color(DEEP.r, DEEP.g, DEEP.b, a2))
		draw_rect(Rect2(0, h - (i + 1) * band, w, band), Color(DEEP.r, DEEP.g, DEEP.b, a2))
