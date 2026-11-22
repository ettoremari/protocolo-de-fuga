import json
from pathlib import Path


def test_bank_has_10_questions_per_math_sector():
    data = json.loads((Path(__file__).parents[1] / "data" / "questoes.json").read_text(encoding="utf-8"))
    assert len(data) == 50
    for phase in range(1, 6):
        assert sum(question["fase"] == phase for question in data) == 10


def test_each_question_has_required_fields_and_answer_type():
    data = json.loads((Path(__file__).parents[1] / "data" / "questoes.json").read_text(encoding="utf-8"))
    required = {"id", "fase", "nivel", "conteudo", "enunciado", "tipo_resposta", "alternativas", "resposta", "resolucao"}
    assert all(required.issubset(question) for question in data)
    assert all(question["tipo_resposta"] in {"choice", "numeric"} for question in data)
    assert all(question["resolucao"] for question in data)
