from pathlib import Path


def _root() -> Path:
    return Path(__file__).parents[1]


def test_godot_project_and_scene_exist():
    project_root = _root()
    assert (project_root / "project.godot").is_file()
    assert (project_root / "main.tscn").is_file()
    assert (project_root / "scripts" / "main.gd").is_file()
    assert (project_root / "scripts" / "backdrop.gd").is_file()
    assert (project_root / "scripts" / "fx.gd").is_file()


def test_godot_layout_has_scroll_and_desktop_window_setup():
    project_root = _root()
    project = (project_root / "project.godot").read_text(encoding="utf-8")
    script = (project_root / "scripts" / "main.gd").read_text(encoding="utf-8")

    assert "window/size/viewport_width=1100" in project
    assert "window/size/viewport_height=700" in project
    assert "window/size/min_width=800" in project
    assert "window/size/min_height=600" in project
    assert "scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO" in script
    assert "DisplayServer.window_set_min_size(Vector2i(800, 600))" in script


def test_godot_has_opening_and_mission_videos():
    project_root = _root()
    script = (project_root / "scripts" / "main.gd").read_text(encoding="utf-8")
    assert "abertura-final-2.ogv" in script
    assert "iniciar-missao.ogv" in script
    assert (project_root / "assets" / "abertura-final-2.ogv").is_file()
    assert (project_root / "assets" / "iniciar-missao.ogv").is_file()


def test_godot_has_animated_backdrop_layer():
    script = (_root() / "scripts" / "main.gd").read_text(encoding="utf-8")
    backdrop = (_root() / "scripts" / "backdrop.gd").read_text(encoding="utf-8")

    assert "BackdropScript" in script
    assert "backdrop.z_index = -1" in script
    assert "scan_y" in backdrop
    assert "horizon" in backdrop
    assert "dust" in backdrop


def test_godot_has_fx_layer_with_panel_frame():
    script = (_root() / "scripts" / "main.gd").read_text(encoding="utf-8")
    fx = (_root() / "scripts" / "fx.gd").read_text(encoding="utf-8")

    assert "FxScript" in script
    assert "fx.set_panel(" in script
    assert "func flash(" in fx
    assert "func burst(" in fx
    assert "func sweep(" in fx
    assert "func ping(" in fx


def test_godot_animations_are_present():
    script = (_root() / "scripts" / "main.gd").read_text(encoding="utf-8")

    assert "func _animate_feedback(" in script
    assert "func _animate_enter(" in script
    assert "func _animate_damage(" in script
    assert "func _pop_label(" in script
    assert "func _shake_ui(" in script
    assert "func _hook_button(" in script
    assert "reveal_index" in script


def test_godot_answers_accept_numeric_equivalence():
    """O JSON do Godot entrega numeros como float (24 -> "24.0").

    A comparacao textual reprovava toda resposta numerica e toda alternativa.
    """
    script = (_root() / "scripts" / "main.gd").read_text(encoding="utf-8")

    assert "func _answers_match(" in script
    assert "is_valid_float()" in script
    assert "is_equal_approx(" in script
    assert "_answers_match(answer, correct_answer)" in script
    assert "if answer == correct_answer:" not in script


def test_godot_has_menu_return_button():
    script = (_root() / "scripts" / "main.gd").read_text(encoding="utf-8")
    assert "var menu_button: Button" in script
    assert 'menu_button.text = "MENU INICIAL"' in script
    assert "func _return_to_menu()" in script


def test_godot_has_separate_menu_and_video_layers():
    script = (_root() / "scripts" / "main.gd").read_text(encoding="utf-8")
    assert "video_player.z_index = 100" in script
    assert "video_skip_button.z_index = 101" in script
    assert "progress.visible = false" in script


def test_godot_has_damage_health_bar_effect():
    script = (_root() / "scripts" / "main.gd").read_text(encoding="utf-8")
    assert "var health_bar: ProgressBar" in script
    assert "func _animate_damage()" in script
    assert 'health_label.text = "INTEGRIDADE - DANO"' in script


def test_godot_is_version_1_2():
    project_root = _root()
    project = (project_root / "project.godot").read_text(encoding="utf-8")
    export_presets = (project_root / "export_presets.cfg").read_text(encoding="utf-8")
    script = (project_root / "scripts" / "main.gd").read_text(encoding="utf-8")
    assert 'config/version="1.2"' in project
    assert 'version/name="1.2"' in export_presets
    assert "version/code=12" in export_presets
    assert "PROTOCOLO DE FUGA  |  v1.2" in script
