extends Control

const BackdropScript := preload("res://scripts/backdrop.gd")
const FxScript := preload("res://scripts/fx.gd")

const TOTAL_TIME := 20 * 60
const MAX_ERRORS := 10
const PHASE_TARGETS := [1, 2, 2, 3, 4]
const PHASE_NAMES := [
	"CONTROLE DE ACESSO",
	"LABORATORIO BIOMETRICO",
	"CENTRAL DE SEGURANCA",
	"COFRE DE DADOS",
	"NUCLEO CENTRAL",
]

var questions := {}
var used := {}
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
var choice_container: VBoxContainer
var main_layout: VBoxContainer
var layout_box: VBoxContainer
var spacer_top: Control
var spacer_bottom: Control
var top_row: HBoxContainer
var video_player: VideoStreamPlayer
var video_skip_button: Button
var video_on_finished: Callable
var backdrop: Control
var fx: Control
var reveal_index := 0
var status_key := ""
var progress_tween: Tween
var low_time_tween: Tween


func _ready() -> void:
	_configure_desktop_window()
	_load_questions()
	_reset()
	_build_ui()
	_setup_music()
	_setup_videos()
	_play_video("res://assets/abertura-final-2.ogv", _show_start)


func _configure_desktop_window() -> void:
	if OS.has_feature("android") or OS.has_feature("ios"):
		return
	DisplayServer.window_set_min_size(Vector2i(800, 600))
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_size(Vector2i(1100, 700))
		var screen_rect := DisplayServer.screen_get_usable_rect(
			DisplayServer.window_get_current_screen()
		)
		var window_size := DisplayServer.window_get_size()
		var window_position := Vector2i(
			screen_rect.position.x + maxi(0, (screen_rect.size.x - window_size.x) / 2),
			screen_rect.position.y + maxi(0, (screen_rect.size.y - window_size.y) / 2),
		)
		DisplayServer.window_set_position(window_position)


func _process(_delta: float) -> void:
	if fx and panel and fx.visible and panel.is_visible_in_tree():
		fx.set_panel(Rect2(panel.global_position - fx.global_position, panel.size))
	_fit_content()
	if state == "playing" or state == "show_error":
		_update_status()
		if started_at_msec > 0 and remaining_seconds() <= 0:
			state = "defeat"
			_show_result(false)


func _load_questions() -> void:
	var file := FileAccess.open("res://data/questoes.json", FileAccess.READ)
	if file == null:
		push_error("Nao foi possivel carregar data/questoes.json")
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_error("Banco de questoes invalido")
		return
	for phase_number in range(1, 6):
		questions[phase_number] = []
	for item in parsed:
		var question := item as Dictionary
		if str(question.get("origem", "")) == "enem":
			continue
		if str(question.get("id", "")).begins_with("ENEM-"):
			continue
		var phase_number := int(question["fase"])
		if questions.has(phase_number):
			questions[phase_number].append(question)


func _reset() -> void:
	phase = 1
	phase_hits = 0
	total_hits = 0
	errors = 0
	if health_bar:
		health_bar.value = MAX_ERRORS
	started_at_msec = 0
	current = {}
	selected_choice = -1
	showing_error = false
	used = {}
	status_key = ""
	if fx:
		fx.clear_all()
	for phase_number in range(1, 6):
		used[phase_number] = []


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
	main_layout.add_theme_constant_override("separation", 12)
	add_child(main_layout)

	fx = FxScript.new()
	add_child(fx)

	var margin := MarginContainer.new()
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	main_layout.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)
	layout_box = layout

	header = VBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	layout.add_child(header)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.add_theme_color_override("font_color", Color("#34dcf0"))
	header.add_child(status_label)

	progress = ProgressBar.new()
	progress.min_value = 0
	progress.max_value = 12
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(0, 10)
	header.add_child(progress)

	health_label = Label.new()
	health_label.text = "INTEGRIDADE"
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	health_label.add_theme_font_size_override("font_size", 14)
	health_label.add_theme_color_override("font_color", Color("#ff5b70"))
	header.add_child(health_label)

	health_bar = ProgressBar.new()
	health_bar.min_value = 0
	health_bar.max_value = MAX_ERRORS
	health_bar.value = MAX_ERRORS
	health_bar.show_percentage = false
	health_bar.custom_minimum_size = Vector2(0, 10)
	var health_background := StyleBoxFlat.new()
	health_background.bg_color = Color("#25151d")
	health_background.corner_radius_top_left = 5
	health_background.corner_radius_top_right = 5
	health_background.corner_radius_bottom_left = 5
	health_background.corner_radius_bottom_right = 5
	var health_fill := StyleBoxFlat.new()
	health_fill.bg_color = Color("#ff5b70")
	health_fill.corner_radius_top_left = 5
	health_fill.corner_radius_top_right = 5
	health_fill.corner_radius_bottom_left = 5
	health_fill.corner_radius_bottom_right = 5
	health_bar.add_theme_stylebox_override("background", health_background)
	health_bar.add_theme_stylebox_override("fill", health_fill)
	header.add_child(health_bar)

	music_button = Button.new()
	music_button.text = "MUSICA: ON"
	music_button.custom_minimum_size = Vector2(140, 38)
	music_button.pressed.connect(_toggle_music)
	_hook_button(music_button)

	menu_button = Button.new()
	menu_button.text = "MENU INICIAL"
	menu_button.custom_minimum_size = Vector2(160, 38)
	menu_button.pressed.connect(_return_to_menu)
	_hook_button(menu_button)
	menu_button.visible = false

	top_row = HBoxContainer.new()
	top_row.alignment = BoxContainer.ALIGNMENT_END
	top_row.add_child(menu_button)
	var top_spacer := Control.new()
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(top_spacer)
	top_row.add_child(music_button)
	layout.add_child(top_row)

	spacer_top = Control.new()
	spacer_top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(spacer_top)

	panel = PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(panel)

	spacer_bottom = Control.new()
	spacer_bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(spacer_bottom)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#0d1b30")
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color("#225b77")
	panel_style.corner_radius_top_left = 14
	panel_style.corner_radius_top_right = 14
	panel_style.corner_radius_bottom_left = 14
	panel_style.corner_radius_bottom_right = 14
	panel.add_theme_stylebox_override("panel", panel_style)

	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.custom_minimum_size = Vector2(0, 260)
	panel.add_child(scroll)

	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	content.add_theme_constant_override("separation", 14)
	scroll.add_child(content)

	var scroll_style := StyleBoxEmpty.new()
	scroll_style.content_margin_left = 22
	scroll_style.content_margin_right = 22
	scroll_style.content_margin_top = 20
	scroll_style.content_margin_bottom = 22
	scroll.add_theme_stylebox_override("panel", scroll_style)


func _clear_content() -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	content.remove_theme_constant_override("separation")
	content.add_theme_constant_override("separation", 14)
	reveal_index = 0
	if scroll:
		scroll.scroll_vertical = 0


func _make_title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 34)
	label.add_theme_color_override("font_color", Color("#e8f5ff"))
	content.add_child(label)
	_animate_enter(label)
	return label


func _make_label(text: String, size := 22) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("#d8eafa"))
	content.add_child(label)
	_animate_enter(label)
	return label


func _make_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 52)
	button.add_theme_font_size_override("font_size", 20)
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
	var tween := create_tween()
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
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8
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
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	normal.content_margin_top = 10
	normal.content_margin_bottom = 10

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
	if content == null or scroll == null or layout_box == null or header == null or top_row == null:
		return
	var avail: float = layout_box.size.y - header.size.y - top_row.size.y - 44.0
	if avail < 80.0:
		return
	var inner: float = content.get_combined_minimum_size().y + 44.0
	var natural: float = inner
	if natural <= avail - 6.0:
		if content.custom_minimum_size.y > 0.0:
			content.custom_minimum_size = Vector2.ZERO
			content.alignment = BoxContainer.ALIGNMENT_CENTER
		if absf(scroll.custom_minimum_size.y - inner) > 1.0:
			scroll.custom_minimum_size = Vector2(0, inner)
		if panel.size_flags_vertical != Control.SIZE_SHRINK_CENTER:
			panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if spacer_top and not spacer_top.visible:
			spacer_top.visible = true
			spacer_bottom.visible = true
	elif natural > avail + 4.0:
		if panel.size_flags_vertical != Control.SIZE_EXPAND_FILL:
			panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
			content.alignment = BoxContainer.ALIGNMENT_BEGIN
		if absf(scroll.custom_minimum_size.y - 260.0) > 1.0:
			scroll.custom_minimum_size = Vector2(0, 260)
		if spacer_top and spacer_top.visible:
			spacer_top.visible = false
			spacer_bottom.visible = false


func _scale_button(button: Button, factor: float, time: float) -> void:
	if not is_instance_valid(button):
		return
	button.pivot_offset = button.size * 0.5
	var previous: Tween = button.get_meta("scale_tween", null)
	if previous and previous.is_valid():
		previous.kill()
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2(factor, factor), time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	button.set_meta("scale_tween", tween)


func _pop_label(label: Label, color: Color) -> void:
	if label == null or not is_instance_valid(label):
		return
	label.add_theme_color_override("font_color", color)
	var tween := create_tween()
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
	var tween := create_tween()
	tween.tween_property(main_layout, "position", original + Vector2(16, 3), 0.045)
	tween.tween_property(main_layout, "position", original + Vector2(-13, -2), 0.045)
	tween.tween_property(main_layout, "position", original + Vector2(9, 2), 0.045)
	tween.tween_property(main_layout, "position", original + Vector2(-5, 0), 0.045)
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
	if correct:
		fx.ping(Color("#4bdc9b"), 0.8)
	else:
		fx.ping(Color("#ff5b70"), 1.0)
		_shake_ui()


func _animate_damage() -> void:
	if health_bar == null:
		return
	health_label.text = "INTEGRIDADE - DANO"
	var health_tween := create_tween()
	health_tween.set_parallel(true)
	health_tween.tween_property(
		health_bar,
		"value",
		MAX_ERRORS - errors,
		0.32,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	health_tween.tween_property(
		health_bar,
		"modulate",
		Color("#ffb3bc"),
		0.08,
	)
	health_tween.chain().tween_property(
		health_bar,
		"modulate",
		Color.WHITE,
		0.24,
	)

	var label_tween := create_tween()
	label_tween.tween_interval(0.5)
	label_tween.tween_callback(func() -> void: health_label.text = "INTEGRIDADE")


func _setup_music() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.stream = load("res://assets/tensefutureloop.ogg")
	if music_player.stream:
		music_player.volume_db = -11
		add_child(music_player)
		music_player.play()


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


func _play_video(path: String, on_finished: Callable) -> void:
	var stream = load(path)
	if stream == null:
		push_error("Nao foi possivel carregar o video: " + path)
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
	music_enabled = !music_enabled
	music_button.text = "MUSICA: ON" if music_enabled else "MUSICA: OFF"
	if music_player:
		music_player.stream_paused = not music_enabled


func _show_start() -> void:
	state = "start"
	if fx:
		fx.clear_all()
	menu_button.visible = false
	progress.visible = false
	health_bar.visible = false
	health_label.visible = false
	top_row.visible = true
	_clear_content()
	status_label.text = "PROTOCOLO DE FUGA  |  v1.2"
	progress.value = 0
	_make_title("ESCAPE ROOM DE ANALISE COMBINATORIA")
	_make_label("Cinco setores. Doze acertos. Dez erros. Limite de vinte minutos.")
	_make_label("Escolha alternativas ou digite respostas numericas para concluir cada fase.")
	_make_button("INICIAR MISSAO", _start_game)


func _start_game() -> void:
	_play_video("res://assets/iniciar-missao.ogv", _begin_game)


func _begin_game() -> void:
	_reset()
	started_at_msec = Time.get_ticks_msec()
	state = "playing"
	menu_button.visible = true
	progress.visible = true
	health_bar.visible = true
	health_label.visible = true
	top_row.visible = true
	_next_question()


func _return_to_menu() -> void:
	menu_button.visible = false
	_reset()
	if fx:
		fx.clear_all()
	scroll.scroll_vertical = 0
	_show_start()


func _next_question() -> void:
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
	current = available.pick_random()
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
	var key := "%d|%d|%d|%d" % [phase, errors, remaining, total_hits]
	if key == status_key:
		return
	status_key = key
	status_label.text = "SETOR %d/5 - %s  |  ERROS %d/10  |  TEMPO %02d:%02d" % [
		phase,
		PHASE_NAMES[phase - 1],
		errors,
		remaining / 60,
		remaining % 60,
	]

	if progress and not is_equal_approx(progress.value, float(total_hits)):
		if progress_tween and progress_tween.is_valid():
			progress_tween.kill()
		progress_tween = create_tween()
		progress_tween.tween_property(progress, "value", total_hits, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	if remaining <= 60 and remaining > 0:
		status_label.add_theme_color_override("font_color", Color("#ff5b70"))
		if fx:
			fx.ping(Color("#ff5b70"), 0.55)
		if low_time_tween and low_time_tween.is_valid():
			low_time_tween.kill()
		low_time_tween = create_tween()
		low_time_tween.tween_property(status_label, "modulate", Color(1, 1, 1, 0.45), 0.18)
		low_time_tween.tween_property(status_label, "modulate", Color.WHITE, 0.5)
	else:
		status_label.add_theme_color_override("font_color", Color("#34dcf0"))


func _show_question() -> void:
	_clear_content()
	state = "playing"
	_update_status()
	_make_title(PHASE_NAMES[phase - 1])
	var meta := _make_label(str(current["conteudo"]).to_upper(), 16)
	meta.add_theme_color_override("font_color", Color("#34dcf0"))
	_make_label(str(current["enunciado"]), 24)

	if str(current["tipo_resposta"]) == "choice":
		choice_container = VBoxContainer.new()
		choice_container.add_theme_constant_override("separation", 8)
		content.add_child(choice_container)
		for index in range(current["alternativas"].size()):
			var choice_button := Button.new()
			choice_button.text = str(current["alternativas"][index])
			choice_button.custom_minimum_size = Vector2(0, 48)
			choice_button.add_theme_font_size_override("font_size", 20)
			choice_button.pressed.connect(_select_choice.bind(index))
			choice_container.add_child(choice_button)
			_hook_button(choice_button)
			_animate_enter(choice_button, 0.18 + index * 0.07)
	else:
		numeric_input = LineEdit.new()
		numeric_input.placeholder_text = "Digite sua resposta"
		numeric_input.custom_minimum_size = Vector2(0, 48)
		numeric_input.add_theme_font_size_override("font_size", 22)
		numeric_input.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER_DECIMAL
		_style_input(numeric_input)
		numeric_input.text_submitted.connect(func(_text: String) -> void: _submit_answer())
		content.add_child(numeric_input)
		_animate_enter(numeric_input, 0.2)

	action_button = _make_button("VALIDAR RESPOSTA", _submit_answer)
	feedback_label = _make_label("", 18)


func _select_choice(index: int) -> void:
	selected_choice = index
	for child in choice_container.get_children():
		var child_tween := create_tween()
		child_tween.tween_property(child, "modulate", Color(0.72, 0.78, 0.85, 1), 0.12)
	var selected_child := choice_container.get_child(index)
	var selected_tween := create_tween()
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
			feedback_label.text = "Selecione uma alternativa."
			return
		answer = str(current["alternativas"][selected_choice])
	else:
		answer = numeric_input.text.strip_edges()
		if answer.is_empty():
			feedback_label.text = "Digite sua resposta."
			return

	answer = answer.replace(",", ".")
	var correct_answer := str(current["resposta"]).strip_edges()
	if _answers_match(answer, correct_answer):
		total_hits += 1
		phase_hits += 1
		_animate_feedback(true)
		feedback_label.text = "ACESSO VALIDADO. RESPOSTA CORRETA."
		_pop_label(feedback_label, Color("#4bdc9b"))
		if phase_hits >= PHASE_TARGETS[phase - 1]:
			if phase == 5:
				state = "victory"
				_show_result(true)
			else:
				state = "phase_complete"
				_show_phase_complete()
		else:
			action_button.text = "PROXIMA QUESTAO"
			action_button.pressed.disconnect(_submit_answer)
			action_button.pressed.connect(_next_question)
	else:
		errors += 1
		showing_error = true
		state = "show_error"
		_animate_feedback(false)
		_animate_damage()
		feedback_label.text = "ACESSO NEGADO.\n\nRESOLUCAO:\n" + str(current["resolucao"])
		_pop_label(feedback_label, Color("#ff5b70"))
		action_button.text = "PROXIMA QUESTAO"
		action_button.pressed.disconnect(_submit_answer)
		action_button.pressed.connect(_advance_from_error)
		if errors >= MAX_ERRORS:
			state = "defeat"
			_show_result(false)
		elif remaining_seconds() <= 0:
			state = "defeat"
			_show_result(false)


func _advance_from_error() -> void:
	if errors >= MAX_ERRORS or remaining_seconds() <= 0:
		_show_result(false)
	else:
		_next_question()


func _show_phase_complete() -> void:
	_clear_content()
	if fx:
		fx.sweep(Color("#8c8cff"))
		fx.burst(size * 0.5, Color("#8c8cff"), 34, 1.15)
	var title := _make_title("SETOR " + str(phase) + " CONCLUIDO")
	title.add_theme_color_override("font_color", Color("#b9b9ff"))
	_make_label("Acesso liberado para o proximo setor.")
	_make_button("AVANCAR DE SETOR", _advance_phase)


func _advance_phase() -> void:
	phase += 1
	phase_hits = 0
	if fx:
		fx.sweep(Color("#34dcf0"))
		fx.ping(Color("#34dcf0"), 0.9)
	_next_question()


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
			for i in 5:
				var spot := Vector2(size.x * (0.2 + 0.15 * i), size.y * (0.3 + 0.1 * (i % 3)))
				fx.burst(spot, Color("#ffc94d"), 24, 1.1)
		else:
			fx.flash(Color("#ff5b70"), 0.5, 1.4)
			fx.ping(Color("#ff5b70"), 1.0)
	var title := _make_title("MISSAO CUMPRIDA" if victory else "CONEXAO PERDIDA")
	title.add_theme_color_override("font_color", Color("#ffd980") if victory else Color("#ff8b96"))
	if victory:
		_make_label("Voce concluiu os cinco setores em %d minutos e %02d segundos." % [
			elapsed_seconds() / 60,
			elapsed_seconds() % 60,
		])
	else:
		_make_label("Acertos: %d/12  |  Erros: %d/10" % [total_hits, errors])
	_make_button("NOVA PARTIDA", _start_game)
