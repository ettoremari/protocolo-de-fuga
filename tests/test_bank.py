import json
from pathlib import Path

def test_bank_has_10_questions_per_phase():
    data = json.loads((Path(__file__).parents[1] / "data" / "questoes.json").read_text(encoding="utf-8"))
    assert len(data) == 50
    for phase in range(1, 6):
        assert sum(q["fase"] == phase for q in data) == 10

def test_each_question_has_required_fields():
    data = json.loads((Path(__file__).parents[1] / "data" / "questoes.json").read_text(encoding="utf-8"))
    required = {"id", "fase", "nivel", "conteudo", "enunciado", "tipo_resposta", "alternativas", "resposta", "resolucao"}
    assert all(required.issubset(q) for q in data)
    assert all(q["tipo_resposta"] in {"choice", "numeric"} for q in data)
    assert all(q["resolucao"] for q in data)
