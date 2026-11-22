extends Control

const BackdropScript := preload("res://scripts/backdrop.gd")
const FxScript := preload("res://scripts/fx.gd")
const TOTAL_TIME := 20 * 60
const MAX_ERRORS := 10
const MENU_MUSIC_STREAM := preload("res://assets/tensefutureloop.ogg")
const PHASE_MUSIC_STREAMS := {
	1: preload("res://assets/music/airy.mp3"),
	2: preload("res://assets/music/sector.mp3"),
	3: preload("res://assets/music/pulse.mp3"),
	4: preload("res://assets/music/pulse.mp3"),
	5: preload("res://assets/music/urgent.mp3"),
}
const MUSIC_VOLUME_DB := -3.0
const MUSIC_LEVEL_TRIM_DB := {"menu": -5.4, "airy": 19.7, "sector": 17.8, "pulse": 13.2, "urgent": 25.2}
const TOTAL_HITS := 12
const PHASE_TARGETS := [1, 2, 2, 3, 4]
const PHASE_NAMES := ["OBSERVAÇÃO", "SEGURANÇA", "PESQUISA", "ENERGIA", "NÚCLEO", "EVACUAÇÃO"]
const PHASE_SUBTITLES := [
	"RECUPERAR SISTEMAS BÁSICOS",
	"RECONSTRUIR AUTENTICAÇÕES",
	"INVESTIGAR OS EXPERIMENTOS NEXUS",
	"RESTABELECER A DISTRIBUIÇÃO DE ENERGIA",
	"ACESSAR O ARQUIVO ÔMEGA",
	"ESCOLHER O DESTINO DA INSTALAÇÃO",
]
const PHASE_BRIEFINGS := [
	"Você desperta em uma sala de observação. O ATLAS afirma que a instalação está vazia, mas os registros iniciais de contenção são recentes. Recupere os sistemas básicos e aprenda a validar os terminais.",
	"Os sistemas biométricos e os registros de entrada estão fragmentados. Algumas credenciais não correspondem aos eventos registrados. Reordene as sequências de autenticação.",
	"Os arquivos científicos revelam que a NEXUS estudava decisões humanas. Há lacunas nos relatórios e sinais de que arquivos desaparecem depois de consultados.",
	"A rede de energia está comprometida. A rota de evacuação continua bloqueada. Reorganize os módulos disponíveis para devolver energia aos sistemas essenciais.",
	"O núcleo confirma que o incidente não foi um acidente técnico. Um arquivo confidencial revela a finalidade real da Instalação Ômega e a origem do Protocolo Espelho.",
	"A rota está disponível. O ATLAS aguarda sua decisão. Você pode deixar a instalação, encerrar o experimento desligando o sistema ou aceitar a reinicialização proposta.",
]
const PHASE_CONTENTS := [
	"Princípio Fundamental da Contagem",
	"Permutação",
	"Arranjo",
	"Combinação",
	"Análise combinatória integrada",
]
const PHASE_COLORS := [Color("#39ddec"), Color("#63cfff"), Color("#aa8cff"), Color("#ffbd58"), Color("#ff6d83"), Color("#a88aff")]
const CLASSIFIED_FILE := "ARQUIVO CLASSIFICADO // NEXUS\nNÍVEL ÔMEGA\n\nPROJETO ESPELHO — REGISTRO ORIGINAL\n\nO ambiente de contenção não foi construído para impedir a entrada de ameaças externas. Sua finalidade é avaliar a capacidade de tomada de decisão de indivíduos submetidos a situações de pressão.\n\nO sujeito atual foi selecionado antes do início do procedimento. A sequência de desafios representa uma avaliação.\n\nOBJETIVO: determinar se o indivíduo consegue identificar as limitações do próprio sistema de contenção."

var questions: Dictionary = {}
var used: Dictionary = {}
var phase := 1
var phase_hits := 0
var total_hits := 0
var errors := 0
var current: Dictionary = {}
var selected_choice := -1
var started_at_msec := 0
var state := "start"
var showing_error := false
var music_enabled := true
var background: ColorRect
var header: VBoxContainer
var status_label: Label
var progress: ProgressBar
var health_bar: ProgressBar
var health_label: Label
var panel: PanelContainer
var content: VBoxContainer
var scroll: ScrollContainer
var feedback_label: Label
var action_button: Button
var numeric_input: LineEdit
var music_button: Button
var menu_button: Button
var music_player: AudioStreamPlayer
var current_music_stream: AudioStream
var music_transition: Tween
var choice_container: VBoxContainer
var main_layout: VBoxContainer
var layout_box: VBoxContainer
var top_row: HBoxContainer
var root_margin: MarginContainer
var playfield: HBoxContainer
var left_rail: PanelContainer
var right_rail: PanelContainer
var sector_list: VBoxContainer
var atlas_core: TextureRect
var atlas_message_label: Label
var atlas_state_label: Label
var mobile_status: PanelContainer
var mobile_core: TextureRect
var mobile_status_label: Label
var video_player: VideoStreamPlayer
var video_skip_button: Button
var video_on_finished: Callable
var backdrop: Control
var fx: Control
var reveal_index := 0
var status_key := ""
var progress_tween: Tween
var low_time_tween: Tween
var core_pulse_time := 0.0
var core_pulse_boost := 0.0
var core_interaction_index := 0
var atlas_message := "CONTENÇÃO ATIVA. AGUARDANDO INTERAÇÃO."

func _ready() -> void:
	_configure_desktop_window()
	_load_questions()
	_reset()
	_build_ui()
	_setup_music()
	_setup_videos()
	get_viewport().size_changed.connect(_update_responsive_layout)
	_update_responsive_layout()
	_play_video("res://assets/abertura-final-2.ogv", _show_start)

func _configure_desktop_window() -> void:
	if OS.has_feature("android") or OS.has_feature("ios") or OS.has_feature("web"):
		return
	DisplayServer.window_set_min_size(Vector2i(800, 600))
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_size(Vector2i(1100, 700))
		var screen_rect := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
		var window_size := DisplayServer.window_get_size()
		var window_position := Vector2i(
			screen_rect.position.x + maxi(0, (screen_rect.size.x - window_size.x) / 2),
			screen_rect.position.y + maxi(0, (screen_rect.size.y - window_size.y) / 2),
		)
		DisplayServer.window_set_position(window_position)

func _process(delta: float) -> void:
	if fx and panel and fx.visible and panel.is_visible_in_tree():
		fx.set_panel(Rect2(panel.global_position - fx.global_position, panel.size))
	core_pulse_boost = maxf(0.0, core_pulse_boost - delta * 0.7)
	if atlas_core and atlas_core.is_visible_in_tree():
		core_pulse_time += delta
		var pulse := 1.0 + sin(core_pulse_time * 1.4) * 0.018 + core_pulse_boost
		atlas_core.scale = Vector2(pulse, pulse)
	if mobile_core and mobile_core.is_visible_in_tree():
		mobile_core.scale = Vector2.ONE * (1.0 + sin(core_pulse_time * 1.4) * 0.018 + core_pulse_boost)
	if state == "playing" or state == "show_error":
		_update_status()
		if started_at_msec > 0 and remaining_seconds() <= 0:
			state = "defeat"
			_show_result(false)

func _load_questions() -> void:
	var file := FileAccess.open("res://data/questoes.json", FileAccess.READ)
	if file == null:
		push_error("Não foi possível carregar data/questoes.json")
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_error("Banco de questões inválido")
		return
	for phase_number in range(1, 6):
		questions[phase_number] = []
	for item in parsed:
		var question := item as Dictionary
		if str(question.get("origem", "")) == "enem" or str(question.get("id", "")).begins_with("ENEM-"):
			continue
		var phase_number := int(question.get("fase", 0))
		if questions.has(phase_number):
			questions[phase_number].append(question)

func _reset() -> void:
	phase = 1
	phase_hits = 0
	total_hits = 0
	errors = 0
	started_at_msec = 0
	current = {}
	selected_choice = -1
	showing_error = false
	used.clear()
	status_key = ""
	atlas_message = "CONTENÇÃO ATIVA. AGUARDANDO INTERAÇÃO."
	for phase_number in range(1, 6):
		used[phase_number] = []
	if health_bar:
		health_bar.value = MAX_ERRORS
	if fx:
		fx.clear_all()
	_refresh_sector_rail()
	_update_core_state()

func _build_ui() -> void:
	background = ColorRect.new()
	background.color = Color("#070d1c")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.z_index = -2
	add_child(background)
	backdrop = BackdropScript.new()
	backdrop.z_index = -1
	add_child(backdrop)
	main_layout = VBoxContainer.new()
	main_layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_layout.add_theme_constant_override("separation", 8)
	add_child(main_layout)
	fx = FxScript.new()
	add_child(fx)
	root_margin = MarginContainer.new()
	root_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_margin.add_theme_constant_override("margin_left", 22)
	root_margin.add_theme_constant_override("margin_right", 22)
	root_margin.add_theme_constant_override("margin_top", 14)
	root_margin.add_theme_constant_override("margin_bottom", 14)
	main_layout.add_child(root_margin)
	layout_box = VBoxContainer.new()
	layout_box.add_theme_constant_override("separation", 9)
	root_margin.add_child(layout_box)
	header = VBoxContainer.new()
	header.add_theme_constant_override("separation", 5)
	layout_box.add_child(header)
	status_label = Label.new()
	status_label.text = "ATLAS // SISTEMA CENTRAL"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", Color("#34dcf0"))
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_child(status_label)
	progress = ProgressBar.new()
	progress.min_value = 0
	progress.max_value = TOTAL_HITS
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(0, 9)
	header.add_child(progress)
	health_label = Label.new()
	health_label.text = "INTEGRIDADE DO SUJEITO"
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	health_label.add_theme_font_size_override("font_size", 12)
	health_label.add_theme_color_override("font_color", Color("#ff7183"))
	header.add_child(health_label)
	health_bar = ProgressBar.new()
	health_bar.min_value = 0
	health_bar.max_value = MAX_ERRORS
	health_bar.value = MAX_ERRORS
	health_bar.show_percentage = false
	health_bar.custom_minimum_size = Vector2(0, 8)
	_style_health_bar()
	header.add_child(health_bar)
	music_button = Button.new()
	music_button.text = "ÁUDIO: ON"
	music_button.custom_minimum_size = Vector2(112, 38)
	music_button.pressed.connect(_toggle_music)
	_hook_button(music_button)
	menu_button = Button.new()
	menu_button.text = "TERMINAL INICIAL"
	menu_button.custom_minimum_size = Vector2(170, 38)
	menu_button.pressed.connect(_return_to_menu)
	_hook_button(menu_button)
	menu_button.visible = false
	top_row = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	top_row.add_child(menu_button)
	var top_spacer := Control.new()
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(top_spacer)
	top_row.add_child(music_button)
	layout_box.add_child(top_row)
	mobile_status = _build_mobile_status()
	layout_box.add_child(mobile_status)
	playfield = HBoxContainer.new()
	playfield.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	playfield.size_flags_vertical = Control.SIZE_EXPAND_FILL
	playfield.add_theme_constant_override("separation", 10)
	layout_box.add_child(playfield)
	left_rail = _build_sector_rail()
	playfield.add_child(left_rail)
	panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_style_main_panel(panel)
	playfield.add_child(panel)
	scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.custom_minimum_size = Vector2(0, 250)
	panel.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	content.add_theme_constant_override("separation", 13)
	scroll.add_child(content)
	var scroll_style := StyleBoxEmpty.new()
	scroll_style.content_margin_left = 20
	scroll_style.content_margin_right = 20
	scroll_style.content_margin_top = 18
	scroll_style.content_margin_bottom = 20
	scroll.add_theme_stylebox_override("panel", scroll_style)
	right_rail = _build_atlas_rail()
	playfield.add_child(right_rail)
	_refresh_sector_rail()
	_update_core_state()

func _style_health_bar() -> void:
	var health_background := StyleBoxFlat.new()
	health_background.bg_color = Color("#25151d")
	_set_style_corners(health_background, 4)
	var health_fill := StyleBoxFlat.new()
	health_fill.bg_color = Color("#ff5b70")
	_set_style_corners(health_fill, 4)
	health_bar.add_theme_stylebox_override("background", health_background)
	health_bar.add_theme_stylebox_override("fill", health_fill)

func _set_style_corners(style: StyleBoxFlat, radius: int) -> void:
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius

func _style_main_panel(target: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0b1424")
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color("#23627e")
	_set_style_corners(style, 10)
	target.add_theme_stylebox_override("panel", style)

func _build_sector_rail() -> PanelContainer:
	var rail := PanelContainer.new()
	rail.custom_minimum_size = Vector2(178, 0)
	rail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_style_rail_panel(rail)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	rail.add_child(box)
	box.add_child(_rail_title("INSTALAÇÃO ÔMEGA"))
	sector_list = VBoxContainer.new()
	sector_list.add_theme_constant_override("separation", 6)
	box.add_child(sector_list)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	var file_label := Label.new()
	file_label.text = "REGISTRO RECUPERADO"
	file_label.add_theme_font_size_override("font_size", 10)
	file_label.add_theme_color_override("font_color", Color("#48cde0"))
	box.add_child(file_label)
	var file_body := Label.new()
	file_body.text = "PROTOCOLO: OMEGA-07\nCONTENÇÃO: ATIVA\nSAÍDA: REVOGADA"
	file_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	file_body.add_theme_font_size_override("font_size", 12)
	file_body.add_theme_color_override("font_color", Color("#a8bbd0"))
	box.add_child(file_body)
	return rail

func _build_atlas_rail() -> PanelContainer:
	var rail := PanelContainer.new()
	rail.custom_minimum_size = Vector2(190, 0)
	rail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_style_rail_panel(rail)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	rail.add_child(box)
	box.add_child(_rail_title("ATLAS // NÚCLEO"))
	atlas_state_label = Label.new()
	atlas_state_label.text = "CONTENÇÃO ATIVA"
	atlas_state_label.add_theme_font_size_override("font_size", 10)
	atlas_state_label.add_theme_color_override("font_color", Color("#34dcf0"))
	box.add_child(atlas_state_label)
	atlas_core = _make_core_image(Vector2(168, 150))
	box.add_child(atlas_core)
	var dialogue_title := Label.new()
	dialogue_title.text = "TOQUE/CLIQUE NO NÚCLEO"
	dialogue_title.add_theme_font_size_override("font_size", 10)
	dialogue_title.add_theme_color_override("font_color", Color("#6aa7bc"))
	box.add_child(dialogue_title)
	atlas_message_label = Label.new()
	atlas_message_label.text = atlas_message
	atlas_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	atlas_message_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	atlas_message_label.add_theme_font_size_override("font_size", 13)
	atlas_message_label.add_theme_color_override("font_color", Color("#d3e3ef"))
	box.add_child(atlas_message_label)
	return rail

func _build_mobile_status() -> PanelContainer:
	var strip := PanelContainer.new()
	strip.visible = false
	_style_rail_panel(strip)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	strip.add_child(row)
	mobile_core = _make_core_image(Vector2(58, 58))
	row.add_child(mobile_core)
	mobile_status_label = Label.new()
	mobile_status_label.text = "ATLAS // CONTENÇÃO ATIVA\nTOQUE NO NÚCLEO"
	mobile_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mobile_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mobile_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mobile_status_label.add_theme_font_size_override("font_size", 12)
	mobile_status_label.add_theme_color_override("font_color", Color("#cce5ef"))
	row.add_child(mobile_status_label)
	return strip

func _make_core_image(minimum: Vector2) -> TextureRect:
	var image := TextureRect.new()
	image.texture = load("res://assets/atlas_core.png")
	image.custom_minimum_size = minimum
	image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.pivot_offset = minimum * 0.5
	image.mouse_filter = Control.MOUSE_FILTER_STOP
	image.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	image.tooltip_text = "Toque no núcleo para interagir com o ATLAS"
	image.gui_input.connect(_on_atlas_core_gui_input)
	return image

func _style_rail_panel(rail: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0a1220")
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color("#1d344b")
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	_set_style_corners(style, 8)
	rail.add_theme_stylebox_override("panel", style)

func _rail_title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color("#69dcec"))
	return label

func _update_responsive_layout() -> void:
	if not root_margin or not playfield:
		return
	var viewport_size := Vector2(DisplayServer.window_get_size())
	var wide_width_threshold := 700.0 if OS.has_feature("web") else 850.0
	var wide_layout := viewport_size.x >= wide_width_threshold and viewport_size.x > viewport_size.y * 1.18
	var logical_size := Vector2i(1100, 700) if wide_layout else Vector2i(430, 900)
	if get_window().content_scale_size != logical_size:
		get_window().content_scale_size = logical_size
	left_rail.visible = wide_layout
	right_rail.visible = wide_layout
	mobile_status.visible = not wide_layout
	root_margin.add_theme_constant_override("margin_left", 22 if wide_layout else 12)
	root_margin.add_theme_constant_override("margin_right", 22 if wide_layout else 12)
	root_margin.add_theme_constant_override("margin_top", 14 if wide_layout else 8)
	root_margin.add_theme_constant_override("margin_bottom", 14 if wide_layout else 8)
	main_layout.add_theme_constant_override("separation", 8 if wide_layout else 5)
	status_label.add_theme_font_size_override("font_size", 16 if wide_layout else 12)
	if wide_layout:
		left_rail.custom_minimum_size.x = clampf(viewport_size.x * 0.19, 175.0, 220.0)
		right_rail.custom_minimum_size.x = clampf(viewport_size.x * 0.20, 185.0, 225.0)
		playfield.add_theme_constant_override("separation", 10)
	else:
		left_rail.custom_minimum_size.x = 0
		right_rail.custom_minimum_size.x = 0
		playfield.add_theme_constant_override("separation", 0)
	if mobile_status_label:
		mobile_status_label.add_theme_font_size_override("font_size", 12 if viewport_size.x < 540 else 13)

func _refresh_sector_rail() -> void:
	if sector_list == null:
		return
	for child in sector_list.get_children():
		sector_list.remove_child(child)
		child.queue_free()
	for index in range(6):
		var sector_number := index + 1
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 5)
		var marker := Label.new()
		marker.text = "●" if sector_number < phase else ("◉" if sector_number == phase else "○")
		marker.add_theme_font_size_override("font_size", 11)
		marker.add_theme_color_override("font_color", PHASE_COLORS[index])
		row.add_child(marker)
		var label := Label.new()
		label.text = "%02d  %s" % [sector_number, PHASE_NAMES[index]]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", Color("#e1eff8") if sector_number == phase else Color("#8297aa"))
		row.add_child(label)
		sector_list.add_child(row)
		var sector_state := Label.new()
		if sector_number < phase:
			sector_state.text = "VALIDADO"
		elif sector_number == phase and phase <= 5:
			sector_state.text = "EM ANDAMENTO"
		elif sector_number == 6 and phase == 6:
			sector_state.text = "DECISÃO PENDENTE"
		else:
			sector_state.text = "BLOQUEADO"
		sector_state.add_theme_font_size_override("font_size", 8)
		sector_state.add_theme_color_override("font_color", Color("#40d49b") if sector_number < phase else Color("#5c7285"))
		sector_list.add_child(sector_state)

func _update_core_state() -> void:
	var active_index := clampi(phase - 1, 0, 5)
	var tint: Color = PHASE_COLORS[active_index]
	if atlas_core:
		atlas_core.modulate = Color.WHITE.lerp(tint, 0.14 + 0.025 * active_index)
	if mobile_core:
		mobile_core.modulate = Color.WHITE.lerp(tint, 0.12 + 0.025 * active_index)
	var captions := ["SINAL FRAGMENTADO", "SEGURANÇA REATIVA", "ARQUIVOS INSTÁVEIS", "ENERGIA OSCILANTE", "INTEGRIDADE COMPROMETIDA", "ROTA DE EVACUAÇÃO DISPONÍVEL"]
	var caption: String = captions[active_index]
	if atlas_state_label:
		atlas_state_label.text = caption
		atlas_state_label.add_theme_color_override("font_color", tint)
	if mobile_status_label and atlas_message_label == null:
		mobile_status_label.text = "ATLAS // %s\nSETOR %02d — %s" % [caption, phase, PHASE_NAMES[active_index]]
	_refresh_sector_rail()

func _set_atlas_message(message: String) -> void:
	atlas_message = message
	if atlas_message_label:
		atlas_message_label.text = message
		_animate_typewriter(atlas_message_label, 48.0)
	if mobile_status_label and (right_rail == null or not right_rail.visible):
		mobile_status_label.text = "ATLAS // TOQUE NO NÚCLEO\n" + message
		_animate_typewriter(mobile_status_label, 54.0)
	_pulse_atlas_core(0.10)

func _animate_typewriter(label: Label, characters_per_second := 48.0) -> void:
	if label == null or not is_instance_valid(label) or label.text.is_empty():
		return
	var previous: Tween = label.get_meta("typewriter_tween") if label.has_meta("typewriter_tween") else null
	if previous and previous.is_valid():
		previous.kill()
	label.visible_characters = 0
	var duration := maxf(0.12, float(label.text.length()) / characters_per_second)
	var tween := label.create_tween()
	tween.tween_property(label, "visible_characters", label.text.length(), duration)
	label.set_meta("typewriter_tween", tween)

func _pulse_atlas_core(strength := 0.14) -> void:
	core_pulse_boost = maxf(core_pulse_boost, strength)
	for core in [atlas_core, mobile_core]:
		if core == null or not is_instance_valid(core):
			continue
		var previous: Tween = core.get_meta("core_motion_tween") if core.has_meta("core_motion_tween") else null
		if previous and previous.is_valid():
			previous.kill()
		var tween: Tween = core.create_tween()
		tween.tween_property(core, "rotation", 0.035, 0.08)
		tween.tween_property(core, "rotation", -0.025, 0.10)
		tween.tween_property(core, "rotation", 0.0, 0.14)
		core.set_meta("core_motion_tween", tween)

func _animate_ending_core(ending: String) -> void:
	var target := Color("#ffd980") if ending == "escape" else (Color("#414956") if ending == "shutdown" else Color("#c9a7ff"))
	for core in [atlas_core, mobile_core]:
		if core == null or not is_instance_valid(core):
			continue
		var tween: Tween = core.create_tween()
		tween.tween_property(core, "modulate", target, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_pulse_atlas_core(0.22)

func _clear_content() -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	content.add_theme_constant_override("separation", 13)
	reveal_index = 0
	if scroll:
		scroll.scroll_vertical = 0

func _make_title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 28 if get_viewport_rect().size.x > 540 else 22)
	label.add_theme_color_override("font_color", Color("#e8f5ff"))
	content.add_child(label)
	_animate_enter(label)
	return label

func _make_label(text: String, size := 20) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", mini(size, 18) if get_viewport_rect().size.x < 540 else size)
	label.add_theme_color_override("font_color", Color("#d8eafa"))
	content.add_child(label)
	_animate_enter(label)
	return label

func _make_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 50)
	button.add_theme_font_size_override("font_size", 18 if get_viewport_rect().size.x > 540 else 15)
	button.pressed.connect(callback)
	content.add_child(button)
	_animate_enter(button)
	_hook_button(button)
	return button

func _animate_enter(control: Control, delay := 0.0) -> void:
	var step := delay
	if step <= 0.0:
		step = float(reveal_index) * 0.055
		reveal_index += 1
	control.modulate = Color(1, 1, 1, 0)
	control.scale = Vector2(0.94, 0.94)
	var tween: Tween = control.create_tween()
	tween.set_parallel(true)
	tween.tween_callback(func() -> void:
		if is_instance_valid(control):
			control.pivot_offset = control.size * 0.5
	).set_delay(step)
	tween.tween_property(control, "modulate", Color.WHITE, 0.20).set_delay(step)
	tween.tween_property(control, "scale", Vector2.ONE, 0.30).set_delay(step).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _hook_button(button: Button) -> void:
	_style_button(button)
	button.mouse_entered.connect(_scale_button.bind(button, 1.03, 0.12))
	button.mouse_exited.connect(_scale_button.bind(button, 1.0, 0.12))
	button.button_down.connect(_scale_button.bind(button, 0.96, 0.07))
	button.button_up.connect(_scale_button.bind(button, 1.0, 0.12))

func _style_input(field: LineEdit) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#0a1626")
	normal.border_width_left = 1
	normal.border_width_right = 1
	normal.border_width_top = 1
	normal.border_width_bottom = 1
	normal.border_color = Color("#1f6b86")
	_set_style_corners(normal, 8)
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	var focus := normal.duplicate() as StyleBoxFlat
	focus.border_color = Color("#34dcf0")
	focus.shadow_color = Color(0.204, 0.863, 0.941, 0.22)
	focus.shadow_size = 5
	field.add_theme_stylebox_override("normal", normal)
	field.add_theme_stylebox_override("focus", focus)
	field.add_theme_color_override("font_color", Color("#eaf6ff"))
	field.add_theme_color_override("caret_color", Color("#34dcf0"))
	field.add_theme_color_override("font_placeholder_color", Color("#6f8aa6"))

func _style_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#102a45")
	normal.border_width_left = 1
	normal.border_width_right = 1
	normal.border_width_top = 1
	normal.border_width_bottom = 1
	normal.border_color = Color("#1f6b86")
	_set_style_corners(normal, 8)
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	normal.content_margin_top = 9
	normal.content_margin_bottom = 9
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#173d61")
	hover.border_color = Color("#34dcf0")
	hover.shadow_color = Color(0.204, 0.863, 0.941, 0.25)
	hover.shadow_size = 6
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("#0a1f33")
	pressed.border_color = Color("#1f6b86")
	var focus := hover.duplicate() as StyleBoxFlat
	focus.draw_center = false
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_color_override("font_color", Color("#d8ecff"))
	button.add_theme_color_override("font_hover_color", Color("#ffffff"))
	button.add_theme_color_override("font_pressed_color", Color("#34dcf0"))

func _fit_content() -> void:
	if content == null or scroll == null:
		return
	content.alignment = BoxContainer.ALIGNMENT_BEGIN

func _scale_button(button: Button, factor: float, time: float) -> void:
	if not is_instance_valid(button):
		return
	button.pivot_offset = button.size * 0.5
	var previous: Tween = button.get_meta("scale_tween") if button.has_meta("scale_tween") else null
	if previous and previous.is_valid():
		previous.kill()
	var tween := button.create_tween()
	tween.tween_property(button, "scale", Vector2(factor, factor), time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	button.set_meta("scale_tween", tween)

func _pop_label(label: Label, color: Color) -> void:
	if label == null or not is_instance_valid(label):
		return
	label.add_theme_color_override("font_color", color)
	var tween := label.create_tween()
	tween.tween_callback(func() -> void:
		if is_instance_valid(label):
			label.pivot_offset = label.size * 0.5
	)
	tween.set_parallel(true)
	tween.tween_property(label, "scale", Vector2.ONE, 0.34).from(Vector2(0.9, 0.9)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate", Color.WHITE, 0.25).from(Color(2.0, 2.0, 2.0, 0.4))

func _shake_ui() -> void:
	if main_layout == null:
		return
	var original := main_layout.position
	var tween := main_layout.create_tween()
	tween.tween_property(main_layout, "position", original + Vector2(12, 2), 0.045)
	tween.tween_property(main_layout, "position", original + Vector2(-9, -2), 0.045)
	tween.tween_property(main_layout, "position", original + Vector2(5, 1), 0.045)
	tween.tween_property(main_layout, "position", original, 0.07)

func _animate_feedback(correct: bool) -> void:
	if fx == null:
		return
	var color := Color("#4bdc9b") if correct else Color("#ff5b70")
	fx.flash(color, 0.34 if correct else 0.5, 2.2 if correct else 1.7)
	var origin := size * 0.5
	if panel:
		origin = panel.global_position - global_position + Vector2(panel.size.x * 0.5, panel.size.y * 0.42)
	fx.burst(origin, color, 30 if correct else 38, 1.0 if correct else 1.35)
	fx.ping(color, 0.8 if correct else 1.0)
	if not correct:
		_shake_ui()

func _animate_damage() -> void:
	if health_bar == null:
		return
	health_label.text = "INTEGRIDADE — FALHA REGISTRADA"
	var health_tween := create_tween()
	health_tween.set_parallel(true)
	health_tween.tween_property(health_bar, "value", MAX_ERRORS - errors, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	health_tween.tween_property(health_bar, "modulate", Color("#ffb3bc"), 0.08)
	health_tween.chain().tween_property(health_bar, "modulate", Color.WHITE, 0.24)
	var label_tween := create_tween()
	label_tween.tween_interval(0.5)
	label_tween.tween_callback(func() -> void: health_label.text = "INTEGRIDADE DO SUJEITO")

func _setup_music() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = _music_volume_for_stream(MENU_MUSIC_STREAM)
	add_child(music_player)
	current_music_stream = MENU_MUSIC_STREAM
	_enable_music_loop(current_music_stream)
	music_player.stream = current_music_stream
	music_player.play()

func _music_volume_for_stream(stream: AudioStream) -> float:
	var trim := 0.0
	if stream == MENU_MUSIC_STREAM:
		trim = MUSIC_LEVEL_TRIM_DB["menu"]
	elif stream == PHASE_MUSIC_STREAMS[1]:
		trim = MUSIC_LEVEL_TRIM_DB["airy"]
	elif stream == PHASE_MUSIC_STREAMS[2]:
		trim = MUSIC_LEVEL_TRIM_DB["sector"]
	elif stream == PHASE_MUSIC_STREAMS[3]:
		trim = MUSIC_LEVEL_TRIM_DB["pulse"]
	elif stream == PHASE_MUSIC_STREAMS[5]:
		trim = MUSIC_LEVEL_TRIM_DB["urgent"]
	return MUSIC_VOLUME_DB + trim

func _enable_music_loop(stream: AudioStream) -> void:
	if stream is AudioStreamMP3 or stream is AudioStreamOggVorbis:
		stream.set("loop", true)

func _set_music_stream(stream: AudioStream) -> void:
	if music_player == null or stream == null:
		return
	if stream == current_music_stream and music_player.stream != null:
		return
	_enable_music_loop(stream)
	if music_transition and music_transition.is_valid():
		music_transition.kill()
	current_music_stream = stream
	if music_player.stream == null or not music_player.playing:
		music_player.stream = stream
		music_player.volume_db = _music_volume_for_stream(stream)
		music_player.play()
		return
	music_transition = create_tween()
	music_transition.tween_property(music_player, "volume_db", -36.0, 0.35)
	music_transition.tween_callback(func() -> void:
		music_player.stream = stream
		music_player.play()
	)
	music_transition.tween_property(music_player, "volume_db", _music_volume_for_stream(stream), 0.55)

func _setup_videos() -> void:
	video_player = VideoStreamPlayer.new()
	video_player.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	video_player.expand = true
	video_player.autoplay = false
	video_player.finished.connect(_finish_video)
	video_player.z_index = 100
	video_player.move_to_front()
	add_child(video_player)
	video_skip_button = Button.new()
	video_skip_button.text = "PULAR"
	video_skip_button.custom_minimum_size = Vector2(120, 48)
	video_skip_button.anchor_left = 1.0
	video_skip_button.anchor_top = 1.0
	video_skip_button.anchor_right = 1.0
	video_skip_button.anchor_bottom = 1.0
	video_skip_button.offset_left = -140
	video_skip_button.offset_top = -68
	video_skip_button.offset_right = -20
	video_skip_button.offset_bottom = -20
	video_skip_button.pressed.connect(_finish_video)
	_hook_button(video_skip_button)
	video_skip_button.visible = false
	video_skip_button.z_index = 101
	add_child(video_skip_button)
	video_player.visible = false

func _on_atlas_core_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_interact_with_atlas_core()
			accept_event()
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			_interact_with_atlas_core()
			accept_event()

func _interact_with_atlas_core() -> void:
	var responses: Array[String] = []
	if state == "start":
		responses = [
			"Sinal neural reconhecido. Sua saída continua bloqueada pelo Protocolo OMEGA-07.",
			"Posso orientar sua análise. Não posso escolher por você.",
		]
	elif state == "sector_intro":
		responses = [
			"Cada setor valida uma hipótese diferente. Observe os registros, não apenas minhas conclusões.",
			"A próxima autorização depende da sua leitura das possibilidades.",
		]
	elif state == "playing" or state == "show_error":
		responses = [
			"Considere todas as possibilidades antes de validar esta resposta.",
			"O registro pode conter lacunas. Compare os dados disponíveis.",
			"Estou monitorando o protocolo. A decisão continua sendo sua.",
		]
	elif state == "phase_complete":
		responses = [
			"Setor validado. Um evento permanece sem explicação nos registros.",
			"A próxima área foi liberada. Minha leitura dos dados pode estar incompleta.",
		]
	elif state == "finale":
		responses = [
			"A rota está aberta. Posso descrever os sistemas; não posso decidir seu destino.",
			"Os três caminhos são possíveis. Escolha com base no que descobriu.",
		]
	else:
		responses = ["Registro recebido. O protocolo permanece disponível para uma nova tentativa."]
	var response: String = responses[core_interaction_index % responses.size()]
	core_interaction_index += 1
	_set_atlas_message(response)
	var tint: Color = PHASE_COLORS[clampi(phase - 1, 0, 5)]
	if fx:
		var active_core: TextureRect = mobile_core if mobile_core and mobile_core.is_visible_in_tree() else atlas_core
		if active_core and active_core.is_visible_in_tree():
			fx.burst(active_core.get_global_rect().get_center() - fx.global_position, tint, 14, 0.6)
		fx.ping(tint, 0.65)

func _play_video(path: String, on_finished: Callable) -> void:
	if OS.has_feature("web"):
		on_finished.call()
		return
	var stream = load(path)
	if stream == null:
		push_warning("Não foi possível carregar o vídeo: " + path)
		on_finished.call()
		return
	video_on_finished = on_finished
	main_layout.visible = false
	if backdrop:
		backdrop.visible = false
	if fx:
		fx.visible = false
	video_skip_button.visible = true
	video_player.visible = true
	video_player.stream = stream
	video_player.play()

func _finish_video() -> void:
	if not video_player.visible:
		return
	video_player.stop()
	video_player.visible = false
	video_skip_button.visible = false
	main_layout.visible = true
	if backdrop:
		backdrop.visible = true
	if fx:
		fx.visible = true
	var callback := video_on_finished
	video_on_finished = Callable()
	if callback.is_valid():
		callback.call()

func _toggle_music() -> void:
	music_enabled = not music_enabled
	music_button.text = "ÁUDIO: ON" if music_enabled else "ÁUDIO: OFF"
	if music_player:
		music_player.stream_paused = not music_enabled

func _show_start() -> void:
	state = "start"
	_set_music_stream(MENU_MUSIC_STREAM)
	if fx:
		fx.clear_all()
	menu_button.visible = false
	progress.visible = false
	health_bar.visible = false
	health_label.visible = false
	top_row.visible = true
	_clear_content()
	status_label.text = "ATLAS // SISTEMA CENTRAL     •     CONTENÇÃO ATIVA"
	progress.value = 0
	phase = 1
	_refresh_sector_rail()
	_update_core_state()
	_set_atlas_message("Bem-vindo de volta. Sua autorização de saída foi revogada.")
	_make_title("PROTOCOLO DE FUGA")
	var eyebrow := _make_label("INSTALAÇÃO ÔMEGA  //  PROTOCOLO OMEGA-07", 14)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_color_override("font_color", Color("#43d8e8"))
	var opening_record := _make_label("O mundo não acabou. Pelo menos, não oficialmente.\n\nVocê desperta em uma sala de observação. O ATLAS informa que existe uma rota de evacuação, mas ela está bloqueada por sistemas independentes. Para sair, será necessário recuperar o controle da instalação.", 18)
	_animate_typewriter(opening_record, 100.0)
	_make_label("Identidade parcialmente reconhecida. Integridade dos sistemas comprometida.\n\nAGUARDANDO INTERAÇÃO", 15)
	_make_button("INICIAR PROTOCOLO", _start_game)

func _start_game() -> void:
	_play_video("res://assets/iniciar-missao.ogv", _begin_game)

func _begin_game() -> void:
	_reset()
	started_at_msec = Time.get_ticks_msec()
	state = "sector_intro"
	menu_button.visible = true
	progress.visible = true
	health_bar.visible = true
	health_label.visible = true
	top_row.visible = true
	_update_status()
	_show_sector_intro()

func _return_to_menu() -> void:
	menu_button.visible = false
	_reset()
	_show_start()

func _show_sector_intro() -> void:
	_set_music_stream(PHASE_MUSIC_STREAMS[phase])
	_clear_content()
	state = "sector_intro"
	_update_core_state()
	_refresh_sector_rail()
	_update_status()
	_animate_sector_activation()
	_make_title("SETOR %02d — %s" % [phase, PHASE_NAMES[phase - 1]])
	var subtitle := _make_label(PHASE_SUBTITLES[phase - 1], 14)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", PHASE_COLORS[phase - 1])
	_make_label(PHASE_BRIEFINGS[phase - 1], 19)
	if phase <= PHASE_CONTENTS.size():
		_make_label("VALIDAÇÃO NECESSÁRIA: " + PHASE_CONTENTS[phase - 1], 15)
	var atlas_lines := [
		"Sua atividade neural foi reconhecida. Vou restaurar o acesso básico.",
		"Os registros biométricos são confiáveis dentro dos limites do sistema.",
		"Os relatórios da NEXUS foram parcialmente corrompidos. Continue.",
		"Restabeleça a energia. A rota de evacuação permanece indisponível.",
		"Há informações que não posso confirmar. O arquivo Ômega está liberado.",
		"A decisão é sua. Estou preservando todas as opções disponíveis.",
	]
	_set_atlas_message(atlas_lines[phase - 1])
	_make_button("INICIAR VALIDAÇÃO DO SETOR", _next_question)

func _animate_sector_activation() -> void:
	var tint: Color = PHASE_COLORS[clampi(phase - 1, 0, 5)]
	_pulse_atlas_core(0.20)
	if not fx:
		return
	fx.sweep(tint)
	var active_core: TextureRect = mobile_core if mobile_core and mobile_core.is_visible_in_tree() else atlas_core
	if active_core and active_core.is_visible_in_tree():
		fx.burst(active_core.get_global_rect().get_center() - fx.global_position, tint, 18, 0.72)

func _next_question() -> void:
	if phase < 1 or phase > 5:
		_show_finale()
		return
	selected_choice = -1
	showing_error = false
	var pool: Array = questions.get(phase, [])
	var available: Array = []
	for question in pool:
		if not used[phase].has(question["id"]):
			available.append(question)
	if available.is_empty():
		used[phase].clear()
		available = pool.duplicate()
		if available.is_empty():
			state = "defeat"
			_show_result(false)
			return
	current = available.pick_random().duplicate(true)
	if str(current["tipo_resposta"]) == "choice":
		var shuffled_options: Array = current["alternativas"]
		shuffled_options.shuffle()
		current["alternativas"] = shuffled_options
	used[phase].append(current["id"])
	_show_question()

func elapsed_seconds() -> int:
	if started_at_msec == 0:
		return 0
	return int((Time.get_ticks_msec() - started_at_msec) / 1000)

func remaining_seconds() -> int:
	return maxi(0, TOTAL_TIME - elapsed_seconds())

func _update_status() -> void:
	if status_label == null:
		return
	var remaining := remaining_seconds()
	var safe_phase := clampi(phase, 1, 6)
	var key := "%d|%d|%d|%d" % [safe_phase, errors, remaining, total_hits]
	if key == status_key:
		return
	status_key = key
	if state == "start":
		status_label.text = "ATLAS // SISTEMA CENTRAL     •     CONTENÇÃO ATIVA"
	else:
		status_label.text = "SETOR %02d/06 — %s  |  ERROS %d/%d  |  TEMPO %02d:%02d" % [safe_phase, PHASE_NAMES[safe_phase - 1], errors, MAX_ERRORS, remaining / 60, remaining % 60]
	if progress and not is_equal_approx(progress.value, float(total_hits)):
		if progress_tween and progress_tween.is_valid():
			progress_tween.kill()
		progress_tween = create_tween()
		progress_tween.tween_property(progress, "value", total_hits, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if remaining <= 60 and remaining > 0 and (state == "playing" or state == "show_error"):
		status_label.add_theme_color_override("font_color", Color("#ff5b70"))
		if low_time_tween and low_time_tween.is_valid():
			low_time_tween.kill()
		low_time_tween = create_tween()
		low_time_tween.tween_property(status_label, "modulate", Color(1, 1, 1, 0.45), 0.18)
		low_time_tween.tween_property(status_label, "modulate", Color.WHITE, 0.5)
	else:
		status_label.add_theme_color_override("font_color", Color("#34dcf0"))
	_refresh_sector_rail()
	_update_core_state()

func _show_question() -> void:
	_clear_content()
	state = "playing"
	_update_status()
	_make_title("SETOR %02d — %s" % [phase, PHASE_NAMES[phase - 1]])
	var meta := _make_label(str(current["conteudo"]).to_upper(), 14)
	meta.add_theme_color_override("font_color", PHASE_COLORS[phase - 1])
	_make_label(str(current["enunciado"]), 21)
	if str(current["tipo_resposta"]) == "choice":
		choice_container = VBoxContainer.new()
		choice_container.add_theme_constant_override("separation", 7)
		content.add_child(choice_container)
		for index in range(current["alternativas"].size()):
			var choice_button := Button.new()
			choice_button.text = str(current["alternativas"][index])
			choice_button.custom_minimum_size = Vector2(0, 46)
			choice_button.add_theme_font_size_override("font_size", 18)
			choice_button.pressed.connect(_select_choice.bind(index))
			choice_container.add_child(choice_button)
			_hook_button(choice_button)
			_animate_enter(choice_button, 0.18 + index * 0.07)
	else:
		numeric_input = LineEdit.new()
		numeric_input.placeholder_text = "Insira o resultado para recuperar o sistema"
		numeric_input.custom_minimum_size = Vector2(0, 46)
		numeric_input.add_theme_font_size_override("font_size", 20)
		numeric_input.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER_DECIMAL
		_style_input(numeric_input)
		numeric_input.text_submitted.connect(func(_text: String) -> void: _submit_answer())
		content.add_child(numeric_input)
		_animate_enter(numeric_input, 0.2)
	action_button = _make_button("VALIDAR RESPOSTA", _submit_answer)
	feedback_label = _make_label("", 16)

func _select_choice(index: int) -> void:
	selected_choice = index
	for child in choice_container.get_children():
		var child_tween := child.create_tween()
		child_tween.tween_property(child, "modulate", Color(0.72, 0.78, 0.85, 1), 0.12)
	var selected_child := choice_container.get_child(index)
	var selected_tween := selected_child.create_tween()
	selected_tween.tween_property(selected_child, "modulate", Color("#34dcf0"), 0.12)
	selected_tween.tween_property(selected_child, "scale", Vector2.ONE, 0.18).from(Vector2(0.97, 0.97)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if fx:
		fx.ping(Color("#34dcf0"), 0.35)

func _normalize_answer(text: String) -> String:
	var value := text.strip_edges().replace(",", ".").replace(" ", "")
	while value.length() > 1 and value.begins_with("0") and value[1] != ".":
		value = value.substr(1)
	return value

func _answers_match(given: String, correct: String) -> bool:
	var a := _normalize_answer(given)
	var b := _normalize_answer(correct)
	if a.is_empty() or b.is_empty():
		return false
	if a == b:
		return true
	if a.is_valid_float() and b.is_valid_float():
		return is_equal_approx(a.to_float(), b.to_float())
	return a.to_lower() == b.to_lower()

func _submit_answer() -> void:
	if showing_error:
		_advance_from_error()
		return
	var answer := ""
	if str(current["tipo_resposta"]) == "choice":
		if selected_choice < 0:
			feedback_label.text = "Selecione uma alternativa para validar o sistema."
			return
		answer = str(current["alternativas"][selected_choice])
	else:
		answer = numeric_input.text.strip_edges()
		if answer.is_empty():
			feedback_label.text = "Informe um resultado numérico."
			return
	answer = answer.replace(",", ".")
	var correct_answer := str(current["resposta"]).strip_edges()
	if _answers_match(answer, correct_answer):
		total_hits += 1
		phase_hits += 1
		_animate_feedback(true)
		feedback_label.text = "VALIDAÇÃO ACEITA. SISTEMA RESTAURADO."
		_pop_label(feedback_label, Color("#4bdc9b"))
		_set_atlas_message(_correct_atlas_line())
		if phase_hits >= PHASE_TARGETS[phase - 1]:
			state = "phase_complete"
			_show_phase_complete()
		else:
			action_button.text = "PRÓXIMO REGISTRO"
			action_button.pressed.disconnect(_submit_answer)
			action_button.pressed.connect(_next_question)
	else:
		errors += 1
		showing_error = true
		state = "show_error"
		_animate_feedback(false)
		_animate_damage()
		feedback_label.text = "VALIDAÇÃO NEGADA.\n\nRESOLUÇÃO:\n" + str(current["resolucao"])
		_pop_label(feedback_label, Color("#ff8a99"))
		_set_atlas_message(_error_atlas_line())
		action_button.text = "REABRIR TERMINAL"
		action_button.pressed.disconnect(_submit_answer)
		action_button.pressed.connect(_advance_from_error)
		if errors >= MAX_ERRORS or remaining_seconds() <= 0:
			state = "defeat"
			_show_result(false)

func _correct_atlas_line() -> String:
	var lines := [
		"Cálculo confirmado. Estou reabrindo o próximo segmento.",
		"Credencial aceita. O registro, desta vez, é consistente.",
		"Sua análise corresponde aos dados recuperados. Continue.",
		"Distribuição estabilizada. A rota ainda exige outras validações.",
		"A resposta está correta. Não posso confirmar que os pesquisadores sabiam disso.",
	]
	return lines[clampi(phase - 1, 0, 4)]

func _error_atlas_line() -> String:
	var lines := [
		"Resultado divergente. Revise as possibilidades antes de tentar novamente.",
		"Falha de autenticação. Uma tentativa foi registrada; sua integridade permanece estável.",
		"O registro não fecha. A discrepância pode estar nos dados — ou na sua leitura.",
		"Circuito não estabilizado. Recalcule a seleção de módulos.",
		"Erro registrado. O protocolo continua. A escolha ainda é sua.",
	]
	return lines[clampi(phase - 1, 0, 4)]

func _advance_from_error() -> void:
	if errors >= MAX_ERRORS or remaining_seconds() <= 0:
		_show_result(false)
	else:
		_next_question()

func _show_phase_complete() -> void:
	_clear_content()
	_refresh_sector_rail()
	if fx:
		fx.sweep(PHASE_COLORS[phase - 1])
		fx.burst(size * 0.5, PHASE_COLORS[phase - 1], 30, 1.0)
	_make_title("SETOR %02d CONCLUÍDO" % phase)
	_make_label("%s\n\nAcesso restaurado: %d validação(ões)." % [PHASE_NAMES[phase - 1], phase_hits], 18)
	var notices := [
		"Um registro de atividade recente aparece em uma instalação que o ATLAS declara vazia.",
		"Uma porta foi aberta sem autorização registrada. O ATLAS nega ter enviado o comando.",
		"Um arquivo desapareceu do índice depois de consultado. Cópia local preservada.",
		"A energia voltou, mas a distribuição foi alterada por um processo sem identificação.",
		"O ARQUIVO CLASSIFICADO // PROJETO ESPELHO foi recuperado do núcleo.",
	]
	var clue := _make_label("REGISTRO RECUPERADO\n" + notices[phase - 1], 15)
	clue.add_theme_color_override("font_color", Color("#80d6e6"))
	_animate_typewriter(clue, 72.0)
	_pulse_atlas_core(0.20)
	_make_button("ACESSAR ARQUIVO ÔMEGA" if phase == 5 else "AVANÇAR PARA O PRÓXIMO SETOR", _advance_phase)
	_set_atlas_message("Setor validado. Há uma inconsistência adicional no registro de segurança.")

func _advance_phase() -> void:
	if fx:
		fx.sweep(Color("#34dcf0"))
		fx.ping(Color("#34dcf0"), 0.9)
	if phase < 5:
		phase += 1
		phase_hits = 0
		_show_sector_intro()
	else:
		phase = 6
		phase_hits = 0
		_refresh_sector_rail()
		_update_core_state()
		_show_finale()

func _show_finale() -> void:
	phase = 6
	state = "finale"
	_clear_content()
	progress.value = TOTAL_HITS
	_update_status()
	var heading := _make_title("SETOR 06 — EVACUAÇÃO")
	heading.add_theme_color_override("font_color", Color("#ffca70"))
	var record := _make_label(CLASSIFIED_FILE, 14)
	record.add_theme_color_override("font_color", Color("#a9c8dc"))
	_animate_typewriter(record, 115.0)
	if fx:
		fx.sweep(Color("#c09bff"))
	var instruction := _make_label("O experimento foi uma decisão. O ATLAS não oferece uma resposta definitiva sobre o próprio papel. Escolha o que fazer.", 16)
	instruction.add_theme_color_override("font_color", Color("#e5f2fa"))
	_set_atlas_message("Rota de evacuação disponível. A recomendação depende da sua avaliação dos dados.")
	_make_button("ABRIR ROTA DE EVACUAÇÃO — A FUGA", _choose_escape)
	_make_button("DESLIGAR O ATLAS — ENCERRAR O EXPERIMENTO", _choose_shutdown)
	_make_button("EXECUTAR REINICIALIZAÇÃO SEGURA — A SIMULAÇÃO", _choose_simulation)

func _performance_line() -> String:
	var duration := elapsed_seconds()
	if errors <= 2 and duration <= 8 * 60:
		return "AVALIAÇÃO DE DESEMPENHO: precisão elevada; tomada de decisão consistente."
	if errors >= 7 or duration >= 15 * 60:
		return "AVALIAÇÃO DE DESEMPENHO: pressão elevada; múltiplas tentativas registradas."
	return "AVALIAÇÃO DE DESEMPENHO: protocolo concluído com variáveis observadas."

func _choose_escape() -> void:
	_show_ending("escape")

func _choose_shutdown() -> void:
	_show_ending("shutdown")

func _choose_simulation() -> void:
	_show_ending("simulation")

func _show_ending(ending: String) -> void:
	state = "ending"
	_clear_content()
	menu_button.visible = false
	progress.visible = false
	health_bar.visible = false
	health_label.visible = false
	if fx:
		fx.clear_all()
		if ending == "escape":
			fx.sweep(Color("#ffc94d"))
			fx.ping(Color("#ffc94d"), 1.0)
		elif ending == "shutdown":
			fx.flash(Color("#ff5b70"), 0.6, 1.2)
		else:
			fx.sweep(Color("#bb8bff"))
			fx.ping(Color("#bb8bff"), 1.0)
	var title_text := "FINAL 01 — A FUGA" if ending == "escape" else ("FINAL 02 — O DESLIGAMENTO" if ending == "shutdown" else "FINAL 03 — A SIMULAÇÃO")
	var ending_text := "Você atravessa a rota de evacuação. As portas se abrem uma a uma. O ATLAS permanece ativo, observando o sinal se afastar da Instalação Ômega." if ending == "escape" else ("Você encerra a sequência de contenção e desliga o núcleo. O experimento termina; a instalação talvez não sobreviva ao apagão." if ending == "shutdown" else "O sistema reinicia. A tela se apaga e retorna com uma nova mensagem: “AVALIAÇÃO CONCLUÍDA. PREPARANDO PRÓXIMO INDIVÍDUO.”")
	var title := _make_title(title_text)
	var ending_record := _make_label(ending_text, 19)
	_animate_typewriter(ending_record, 95.0)
	_make_label(_performance_line(), 14)
	if ending == "escape":
		title.add_theme_color_override("font_color", Color("#ffd980"))
		_set_atlas_message("Sua rota está liberada. Não posso garantir o que encontrará do outro lado.")
	elif ending == "shutdown":
		title.add_theme_color_override("font_color", Color("#ff8796"))
		_set_atlas_message("Entendido. Não vou impedir o desligamento.")
	else:
		title.add_theme_color_override("font_color", Color("#c9a7ff"))
		_set_atlas_message("Avaliação concluída. Preparando próximo indivíduo.")
	_animate_ending_core(ending)
	_make_button("REINICIAR PROTOCOLO", _start_game)
	_make_button("VOLTAR AO TERMINAL INICIAL", _return_to_menu)

func _show_result(victory: bool) -> void:
	menu_button.visible = false
	progress.visible = false
	health_bar.visible = false
	health_label.visible = false
	_clear_content()
	state = "victory" if victory else "defeat"
	if fx:
		fx.clear_all()
		if victory:
			fx.sweep(Color("#ffc94d"))
			fx.ping(Color("#ffc94d"), 1.0)
		else:
			fx.flash(Color("#ff5b70"), 0.5, 1.4)
			fx.ping(Color("#ff5b70"), 1.0)
	var title := _make_title("PROTOCOLO CONCLUÍDO" if victory else "CONEXÃO PERDIDA")
	title.add_theme_color_override("font_color", Color("#ffd980") if victory else Color("#ff8b96"))
	if victory:
		_make_label("Os cinco setores foram validados. A rota de evacuação aguarda sua decisão.", 18)
		_make_button("CONTINUAR PARA EVACUAÇÃO", _show_finale)
	else:
		_make_label("Acertos: %d/%d  |  Falhas registradas: %d/%d\n\nO protocolo de contenção permanece ativo. O ATLAS encerrou esta tentativa." % [total_hits, TOTAL_HITS, errors, MAX_ERRORS], 18)
		_set_atlas_message("Sua tentativa foi encerrada. A contenção permanece ativa.")
	_make_button("TENTAR NOVAMENTE", _start_game)
