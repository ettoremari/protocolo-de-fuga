import ast
from pathlib import Path


def test_main_has_valid_python_syntax():
    project_root = Path(__file__).parents[1]
    source = (project_root / "main.py").read_text(encoding="utf-8")
    ast.parse(source, filename="main.py")
