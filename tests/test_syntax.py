from pathlib import Path


def test_godot_project_and_scene_exist():
    project_root = Path(__file__).parents[1]
    assert (project_root / "project.godot").is_file()
    assert (project_root / "main.tscn").is_file()
    assert (project_root / "scripts" / "main.gd").is_file()


def test_godot_layout_has_scroll_and_desktop_window_setup():
    project_root = Path(__file__).parents[1]
    project = (project_root / "project.godot").read_text(encoding="utf-8")
    script = (project_root / "scripts" / "main.gd").read_text(encoding="utf-8")

    assert "window/size/viewport_width=1100" in project
    assert "window/size/viewport_height=700" in project
    assert "window/size/min_width=800" in project
    assert "window/size/min_height=600" in project
    assert "scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO" in script
    assert "DisplayServer.window_set_min_size(Vector2i(800, 600))" in script


def test_godot_has_opening_and_mission_videos():
    project_root = Path(__file__).parents[1]
    script = (project_root / "scripts" / "main.gd").read_text(encoding="utf-8")
    assert "abertura-final-2.ogv" in script
    assert "iniciar-missao.ogv" in script
    assert (project_root / "assets" / "abertura-final-2.ogv").is_file()
    assert (project_root / "assets" / "iniciar-missao.ogv").is_file()


def test_godot_has_previous_pygame_animations():
    project_root = Path(__file__).parents[1]
    script = (project_root / "scripts" / "main.gd").read_text(encoding="utf-8")
    assert "_draw_grid_animation" in script
    assert "scan_y" in script
    assert "_animate_feedback" in script
    assert "_animate_enter" in script


def test_godot_has_menu_return_button():
    project_root = Path(__file__).parents[1]
    script = (project_root / "scripts" / "main.gd").read_text(encoding="utf-8")
    assert "var menu_button: Button" in script
    assert 'menu_button.text = "MENU INICIAL"' in script
    assert "func _return_to_menu()" in script


def test_godot_animations_are_short_and_do_not_move_container_children():
    project_root = Path(__file__).parents[1]
    script = (project_root / "scripts" / "main.gd").read_text(encoding="utf-8")
    assert '"modulate", Color.WHITE, 0.12' in script
    assert '"scale", Vector2.ONE, 0.14' in script
    assert '"modulate", Color(1, 1, 1, 0), 0.18' in script
    assert "control.position" not in script
