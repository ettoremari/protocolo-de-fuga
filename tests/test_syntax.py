from pathlib import Path


def _root() -> Path:
    return Path(__file__).parents[1]


def test_godot_project_and_scene_exist():
    root = _root()
    assert (root / "project.godot").is_file()
    assert (root / "main.tscn").is_file()
    assert (root / "scripts" / "main.gd").is_file()
    assert (root / "scripts" / "backdrop.gd").is_file()
    assert (root / "scripts" / "fx.gd").is_file()
    assert (root / "assets" / "atlas_core.png").is_file()


def test_six_sector_progression_and_math_mapping():
    script = (_root() / "scripts" / "main.gd").read_text(encoding="utf-8")
    for name in ("OBSERVAÇÃO", "SEGURANÇA", "PESQUISA", "ENERGIA", "NÚCLEO", "EVACUAÇÃO"):
        assert name in script
    for concept in ("Princípio Fundamental da Contagem", "Permutação", "Arranjo", "Combinação", "Análise combinatória integrada"):
        assert concept in script
    assert "const PHASE_TARGETS := [1, 2, 2, 3, 4]" in script
    assert "const TOTAL_HITS := 12" in script


def test_narrative_project_mirror_and_three_endings():
    script = (_root() / "scripts" / "main.gd").read_text(encoding="utf-8")
    for phrase in ("PROJETO ESPELHO", "ARQUIVO CLASSIFICADO", "AVALIAÇÃO CONCLUÍDA", "FINAL 01", "FINAL 02", "FINAL 03"):
        assert phrase in script
    assert "func _choose_escape()" in script
    assert "func _choose_shutdown()" in script
    assert "func _choose_simulation()" in script
    assert "func _performance_line()" in script


def test_adaptive_landscape_and_portrait_ui():
    script = (_root() / "scripts" / "main.gd").read_text(encoding="utf-8")
    assert "func _update_responsive_layout()" in script
    assert "left_rail.visible = wide_layout" in script
    assert "mobile_status.visible = not wide_layout" in script
    assert "get_window().content_scale_size = logical_size" in script
    assert "window/handheld/orientation=0" in (_root() / "project.godot").read_text(encoding="utf-8")
    assert "ATLAS // NÚCLEO" in script


def test_gameplay_feedback_and_numeric_equivalence():
    script = (_root() / "scripts" / "main.gd").read_text(encoding="utf-8")
    for function in ("_answers_match", "_animate_feedback", "_animate_damage", "_correct_atlas_line", "_error_atlas_line"):
        assert f"func {function}(" in script
    assert "is_equal_approx(" in script
    assert "_answers_match(answer, correct_answer)" in script


def test_reused_opening_media_and_animated_layers():
    root = _root()
    script = (root / "scripts" / "main.gd").read_text(encoding="utf-8")
    assert "abertura-final-2.ogv" in script
    assert "iniciar-missao.ogv" in script
    assert (root / "assets" / "abertura-final-2.ogv").is_file()
    assert (root / "assets" / "iniciar-missao.ogv").is_file()
    assert "BackdropScript" in script and "FxScript" in script
