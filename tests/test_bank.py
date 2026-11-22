import json
from collections import Counter
from pathlib import Path


def _bank():
    return json.loads((Path(__file__).parents[1] / "data" / "questoes.json").read_text(encoding="utf-8"))


def test_bank_has_20_questions_per_math_sector():
    data = _bank()
    assert len(data) == 100
    assert len({question["id"] for question in data}) == 100
    for phase in range(1, 6):
        assert sum(question["fase"] == phase for question in data) == 20


def test_each_question_has_required_fields_and_answer_type():
    data = _bank()
    required = {"id", "fase", "nivel", "conteudo", "enunciado", "tipo_resposta", "alternativas", "resposta", "resolucao"}
    assert all(required.issubset(question) for question in data)
    assert all(question["tipo_resposta"] in {"choice", "numeric"} for question in data)
    assert all(question["resolucao"].strip() for question in data)
    for question in data:
        if question["tipo_resposta"] == "choice":
            assert len(question["alternativas"]) == 4
            assert len(set(map(str, question["alternativas"]))) == 4
            assert sum(str(option) == str(question["resposta"]) for option in question["alternativas"]) == 1
        else:
            assert question["alternativas"] == []


def test_choice_answer_positions_are_balanced():
    positions = Counter()
    for question in _bank():
        if question["tipo_resposta"] != "choice":
            continue
        index = next(i for i, option in enumerate(question["alternativas"]) if str(option) == str(question["resposta"]))
        positions[index] += 1
    assert sorted(positions.values()) == [12, 12, 12, 13]
