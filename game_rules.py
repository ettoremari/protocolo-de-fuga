class EnergySystem:
    """Gerencia a energia da instalação sem depender da interface gráfica."""

    MAXIMUM = 100
    WRONG_ANSWER_COST = 8
    HINT_COST = 15
    PHASE_RECHARGE = 10

    def __init__(self, initial=100):
        self.value = max(0, min(self.MAXIMUM, int(initial)))

    @property
    def status(self):
        if self.value > 50:
            return "Sistemas estáveis"
        if self.value > 25:
            return "Energia instável"
        if self.value > 0:
            return "Falha iminente"
        return "Energia esgotada"

    @property
    def color(self):
        if self.value > 50:
            return (52, 220, 240)
        if self.value > 25:
            return (255, 207, 91)
        return (255, 91, 112)

    def spend(self, amount):
        amount = max(0, int(amount))
        self.value = max(0, self.value - amount)
        return self.value

    def apply_penalty(self, amount=WRONG_ANSWER_COST):
        return self.spend(amount)

    def recharge(self, amount=PHASE_RECHARGE):
        amount = max(0, int(amount))
        self.value = min(self.MAXIMUM, self.value + amount)
        return self.value
