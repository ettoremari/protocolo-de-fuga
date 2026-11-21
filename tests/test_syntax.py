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
