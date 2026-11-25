extends Control
## Cenário panorâmico e animações ambientais dos seis setores.
## Carrega apenas a sala solicitada, em background, sem bloquear a interface.

signal room_texture_ready

const ROOM_TEXTURES := [
	"res://assets/rooms/sector01_observacao.jpg",
	"res://assets/rooms/sector02_seguranca.jpg",
	"res://assets/rooms/sector03_pesquisa.jpg",
	"res://assets/rooms/sector04_energia.jpg",
	"res://assets/rooms/sector05_nucleo.jpg",
	"res://assets/rooms/sector06_evacuacao.jpg",
]
const ROOM_ACCENTS := [
	Color("#34dcee"),
	Color("#ff5369"),
	Color("#b38aff"),
	Color("#ffc05a"),
	Color("#57dff0"),
	Color("#ffbf69"),
]

var sector := 1
var _time := 0.0
var _active_texture: Texture2D
var _previous_texture: Texture2D
var _active_path := ""
var _queued_path := ""
var _transition_progress := 1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = -2
	queue_redraw()


func set_sector(sector_number: int) -> void:
	var next_sector := clampi(sector_number, 1, ROOM_TEXTURES.size())
	sector = next_sector
	var requested_path: String = ROOM_TEXTURES[next_sector - 1]
	if requested_path == _active_path or requested_path == _queued_path:
		return

	_queued_path = requested_path
	var request_error := ResourceLoader.load_threaded_request(requested_path, "Texture2D", false)
	if request_error != OK and request_error != ERR_BUSY:
		_queued_path = ""
		push_warning("Não foi possível iniciar o carregamento do cenário: " + requested_path)
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	if not _queued_path.is_empty():
		var requested_path := _queued_path
		var load_status := ResourceLoader.load_threaded_get_status(requested_path)
		if load_status == ResourceLoader.THREAD_LOAD_LOADED:
			_queued_path = ""
			var loaded_texture := ResourceLoader.load_threaded_get(requested_path) as Texture2D
			if loaded_texture:
				_previous_texture = _active_texture
				_active_texture = loaded_texture
				_active_path = requested_path
				_transition_progress = 0.0
				room_texture_ready.emit()
			else:
				push_warning("O recurso carregado não é uma textura: " + requested_path)
		elif load_status == ResourceLoader.THREAD_LOAD_FAILED or load_status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_queued_path = ""
			push_warning("Falha ao carregar o cenário; o fundo anterior permanece como fallback: " + requested_path)

	if _transition_progress < 1.0:
		_transition_progress = minf(1.0, _transition_progress + delta * 2.4)
		if _transition_progress >= 1.0:
			_previous_texture = null
	queue_redraw()


func _draw() -> void:
	if size.x < 1.0 or size.y < 1.0:
		return

	var bounds := Rect2(Vector2.ZERO, size)
	draw_rect(bounds, Color("#07111f"), true)
	if _previous_texture:
		_draw_cover(_previous_texture, 1.0 - _transition_progress)
	if _active_texture:
		_draw_cover(_active_texture, _transition_progress)

	# Escurece só o bastante para a arquitetura continuar visível sob os painéis.
	draw_rect(bounds, Color(0.008, 0.018, 0.038, 0.30), true)
	_draw_room_animation()


func _draw_cover(texture: Texture2D, alpha: float) -> void:
	if texture == null or alpha <= 0.0 or size.y <= 0.0:
		return
	var texture_size := Vector2(texture.get_size())
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return

	var source := Rect2(Vector2.ZERO, texture_size)
	var target_aspect := size.x / size.y
	var source_aspect := texture_size.x / texture_size.y
	if source_aspect > target_aspect:
		source.size.x = texture_size.y * target_aspect
		source.position.x = (texture_size.x - source.size.x) * 0.5
	else:
		source.size.y = texture_size.x / target_aspect
		source.position.y = (texture_size.y - source.size.y) * 0.5

	draw_texture_rect_region(
		texture,
		Rect2(Vector2.ZERO, size),
		source,
		Color(1.0, 1.0, 1.0, alpha),
		false,
		true,
	)


func _draw_room_animation() -> void:
	var accent: Color = ROOM_ACCENTS[sector - 1]
	var pulse := 0.5 + 0.5 * sin(_time * 1.25)
	match sector:
		1:
			var scan_y := size.y * (0.39 + sin(_time * 0.42) * 0.025)
			draw_rect(Rect2(size.x * 0.14, scan_y, size.x * 0.72, 2.0), _with_alpha(accent, 0.18), true)
			draw_line(Vector2(size.x * 0.18, scan_y + 4.0), Vector2(size.x * 0.82, scan_y + 4.0), _with_alpha(accent, 0.08), 1.0)
			draw_circle(Vector2(size.x * 0.80, size.y * 0.26), 3.0 + pulse * 2.0, _with_alpha(accent, 0.20 + pulse * 0.12))
		2:
			var scan_x := fposmod(_time * 82.0, size.x + 100.0) - 50.0
			draw_rect(Rect2(scan_x, size.y * 0.16, 22.0, size.y * 0.62), Color(1.0, 0.12, 0.20, 0.045), true)
			draw_line(Vector2(scan_x + 11.0, size.y * 0.16), Vector2(scan_x + 11.0, size.y * 0.78), Color(1.0, 0.22, 0.28, 0.28), 1.4)
			draw_circle(Vector2(size.x * 0.88, size.y * 0.20), 3.0 + pulse * 2.0, Color(1.0, 0.16, 0.24, 0.25 + pulse * 0.30))
		3:
			for index in range(12):
				var rise := fposmod(_time * 0.055 + float(index) * 0.091, 1.0)
				var x := size.x * (0.12 + fposmod(float(index) * 0.37, 0.76))
				var y := size.y * (1.0 - rise)
				var mote_alpha := 0.10 + 0.11 * (0.5 + 0.5 * sin(_time + float(index)))
				draw_circle(Vector2(x, y), 1.2 + fposmod(float(index), 2.0) * 0.7, _with_alpha(accent, mote_alpha))
		4:
			var circuit_y := size.y * 0.80
			var line_start := size.x * 0.10
			var line_end := size.x * 0.90
			draw_line(Vector2(line_start, circuit_y), Vector2(line_end, circuit_y), _with_alpha(accent, 0.16), 2.0)
			var pulse_x := line_start + fposmod(_time * 90.0, line_end - line_start)
			draw_circle(Vector2(pulse_x, circuit_y), 4.0 + pulse * 1.5, _with_alpha(accent, 0.42))
		5:
			var core_center := Vector2(size.x * 0.84, size.y * 0.48)
			for ring in range(3):
				var radius := 18.0 + float(ring) * 15.0 + pulse * 4.0
				draw_arc(core_center, radius, 0.0, TAU, 48, _with_alpha(accent, 0.10 + pulse * 0.08), 1.2, true)
			draw_circle(core_center, 3.0 + pulse * 2.0, _with_alpha(accent, 0.24 + pulse * 0.25))
		6:
			for index in range(12):
				var guide_alpha := 0.12 + 0.42 * (0.5 + 0.5 * sin(_time * 1.8 - float(index) * 0.48))
				var x := size.x * (0.16 + float(index) * 0.061)
				draw_rect(Rect2(x, size.y * 0.90, 10.0, 3.0), _with_alpha(accent, guide_alpha), true)


func _with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)
