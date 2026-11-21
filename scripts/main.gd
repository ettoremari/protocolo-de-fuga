extends Control

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
var top_row: HBoxContainer
var video_player: VideoStreamPlayer
var video_skip_button: Button
var video_on_finished: Callable
var grid_overlay: Control
var feedback_overlay: ColorRect
var scan_y := 0.0


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
	if grid_overlay and grid_overlay.visible:
		scan_y = fmod(scan_y + _delta * 35.0, max(grid_overlay.size.y, 1.0))
		grid_overlay.queue_redraw()
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
	started_at_msec = 0
	current = {}
	selected_choice = -1
	showing_error = false
	used = {}
	for phase_number in range(1, 6):
		used[phase_number] = []


func _build_ui() -> void:
	background = ColorRect.new()
	background.color = Color("#070d1c")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	main_layout = VBoxContainer.new()
	main_layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_layout.add_theme_constant_override("separation", 12)
	add_child(main_layout)

	grid_overlay = Control.new()
	grid_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grid_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid_overlay.draw.connect(_draw_grid_animation)
	grid_overlay.z_index = -1
	add_child(grid_overlay)

	feedback_overlay = ColorRect.new()
	feedback_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	feedback_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback_overlay.modulate = Color(1, 1, 1, 0)
	feedback_overlay.z_index = 20
	add_child(feedback_overlay)

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

	header = VBoxContainer.new()
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

	music_button = Button.new()
	music_button.text = "MUSICA: ON"
	music_button.custom_minimum_size = Vector2(140, 38)
	music_button.pressed.connect(_toggle_music)

	menu_button = Button.new()
	menu_button.text = "MENU INICIAL"
	menu_button.custom_minimum_size = Vector2(160, 38)
	menu_button.pressed.connect(_return_to_menu)
	menu_button.visible = false

	top_row = HBoxContainer.new()
	top_row.alignment = BoxContainer.ALIGNMENT_END
	top_row.add_child(menu_button)
	var top_spacer := Control.new()
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(top_spacer)
	top_row.add_child(music_button)
	layout.add_child(top_row)

	panel = PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(panel)

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
	scroll.custom_minimum_size = Vector2(0, 420)
	panel.add_child(scroll)

	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	content.add_theme_constant_override("separation", 14)
	scroll.add_child(content)

	scroll.add_theme_constant_override("margin_left", 20)
	scroll.add_theme_constant_override("margin_right", 20)
	scroll.add_theme_constant_override("margin_top", 18)
	scroll.add_theme_constant_override("margin_bottom", 18)


func _clear_content() -> void:
	for child in content.get_children():
		child.queue_free()
	content.remove_theme_constant_override("separation")
	content.add_theme_constant_override("separation", 14)


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
	return button


func _animate_enter(control: Control, delay := 0.0) -> void:
	control.modulate = Color(1, 1, 1, 0)
	control.scale = Vector2(0.985, 0.985)
	control.pivot_offset = control.size / 2.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(control, "modulate", Color.WHITE, 0.12).set_delay(delay)
	tween.tween_property(control, "scale", Vector2.ONE, 0.14).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _draw_grid_animation() -> void:
	if grid_overlay == null:
		return
	var size := grid_overlay.size
	var step := maxi(28, int(size.x / 35.0))
	for x in range(0, int(size.x) + 1, step):
		grid_overlay.draw_line(Vector2(x, 0), Vector2(x, size.y), Color("#0b1d30"), 1.0)
	for y in range(0, int(size.y) + 1, step):
		grid_overlay.draw_line(Vector2(0, y), Vector2(size.x, y), Color("#0b1d30"), 1.0)
	grid_overlay.draw_line(Vector2(0, scan_y), Vector2(size.x, scan_y), Color("#12394c"), 2.0)
	grid_overlay.draw_rect(Rect2(0, 0, size.x, 5), Color("#34dcf0"))


func _animate_feedback(correct: bool) -> void:
	if feedback_overlay == null:
		return
	feedback_overlay.color = Color("#4bdc9b") if correct else Color("#ff5b70")
	feedback_overlay.modulate = Color(1, 1, 1, 0.22)
	var tween := create_tween()
	tween.tween_property(feedback_overlay, "modulate", Color(1, 1, 1, 0), 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


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
	grid_overlay.visible = false
	feedback_overlay.visible = false
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
	grid_overlay.visible = true
	feedback_overlay.visible = true
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
	menu_button.visible = false
	progress.visible = false
	top_row.visible = true
	_clear_content()
	status_label.text = "PROTOCOLO DE FUGA"
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
	top_row.visible = true
	_next_question()


func _return_to_menu() -> void:
	menu_button.visible = false
	_reset()
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
	status_label.text = "SETOR %d/5 - %s  |  ERROS %d/10  |  TEMPO %02d:%02d" % [
		phase,
		PHASE_NAMES[phase - 1],
		errors,
		remaining_seconds() / 60,
		remaining_seconds() % 60,
	]
	var progress_tween := create_tween()
	progress_tween.tween_property(progress, "value", total_hits, 0.14).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _show_question() -> void:
	_clear_content()
	state = "playing"
	_update_status()
	_make_title(PHASE_NAMES[phase - 1])
	_make_label(str(current["conteudo"]), 16)
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
			_animate_enter(choice_button, index * 0.06)
	else:
		numeric_input = LineEdit.new()
		numeric_input.placeholder_text = "Digite sua resposta"
		numeric_input.custom_minimum_size = Vector2(0, 48)
		numeric_input.add_theme_font_size_override("font_size", 22)
		content.add_child(numeric_input)

	action_button = _make_button("VALIDAR RESPOSTA", _submit_answer)
	feedback_label = _make_label("", 18)


func _select_choice(index: int) -> void:
	selected_choice = index
	for child in choice_container.get_children():
		var child_tween := create_tween()
		child_tween.tween_property(child, "modulate", Color.WHITE, 0.10)
	var selected_child := choice_container.get_child(index)
	var selected_tween := create_tween()
	selected_tween.tween_property(selected_child, "modulate", Color("#34dcf0"), 0.10)


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
	if answer == correct_answer:
		total_hits += 1
		phase_hits += 1
		_animate_feedback(true)
		feedback_label.text = "ACESSO VALIDADO. RESPOSTA CORRETA."
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
		feedback_label.text = "ACESSO NEGADO.\n\nRESOLUCAO:\n" + str(current["resolucao"])
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
	_make_title("SETOR " + str(phase) + " CONCLUIDO")
	_make_label("Acesso liberado para o proximo setor.")
	_make_button("AVANCAR DE SETOR", _advance_phase)


func _advance_phase() -> void:
	phase += 1
	phase_hits = 0
	_next_question()


func _show_result(victory: bool) -> void:
	menu_button.visible = false
	progress.visible = false
	_clear_content()
	state = "victory" if victory else "defeat"
	_make_title("MISSAO CUMPRIDA" if victory else "CONEXAO PERDIDA")
	if victory:
		_make_label("Voce concluiu os cinco setores em %d minutos e %02d segundos." % [
			elapsed_seconds() / 60,
			elapsed_seconds() % 60,
		])
	else:
		_make_label("Acertos: %d/12  |  Erros: %d/10" % [total_hits, errors])
	_make_button("NOVA PARTIDA", _start_game)
