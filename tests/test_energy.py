from game_rules import EnergySystem


def test_energy_starts_full_and_costs_are_defined():
    energy = EnergySystem()
    assert energy.value == 100
    assert energy.WRONG_ANSWER_COST == 8
    assert energy.HINT_COST == 15


def test_wrong_answer_and_hint_cost_energy_without_negative_values():
    energy = EnergySystem(20)
    assert energy.apply_penalty() == 12
    assert energy.spend(15) == 0
    assert energy.spend(10) == 0


def test_phase_recharge_is_capped_at_maximum():
    energy = EnergySystem(95)
    assert energy.recharge() == 100
    energy = EnergySystem(40)
    assert energy.recharge() == 50


def test_energy_status_thresholds():
    assert EnergySystem(80).status == "Sistemas estáveis"
    assert EnergySystem(40).status == "Energia instável"
    assert EnergySystem(10).status == "Falha iminente"
    assert EnergySystem(0).status == "Energia esgotada"
