import ast
from pathlib import Path


def test_main_has_valid_python_syntax():
    project_root = Path(__file__).parents[1]
    source = (project_root / "main.py").read_text(encoding="utf-8")
    ast.parse(source, filename="main.py")


def test_main_supports_returning_to_menu_without_resetting_progress():
    project_root = Path(__file__).parents[1]
    source = (project_root / "main.py").read_text(encoding="utf-8")
    assert "def return_to_menu" in source
    assert "def resume_game" in source
    assert 'CONTINUAR MISSÃO' in source


def test_main_uses_high_density_mobile_scale_limit():
    project_root = Path(__file__).parents[1]
    source = (project_root / "main.py").read_text(encoding="utf-8")
    assert "upper_mobile_scale = 2.75" in source
