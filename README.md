# PROTOCOLO DE FUGA — Escape Room de Análise Combinatória

Protótipo em Python + Pygame, com cinco fases, banco de 50 questões, respostas mistas (alternativas e numéricas), limite de 20 minutos e 10 erros.

## Requisitos
- Python 3.10 ou superior
- Pygame 2.5+

## Instalação
```bash
python -m venv .venv
# Windows:
.venv\Scripts\activate
# Linux/macOS:
source .venv/bin/activate
pip install -r requirements.txt
```

## Executar
```bash
python main.py
```

## Controles
- Enter: iniciar/reiniciar e enviar resposta numérica
- Clique: selecionar alternativa, validar resposta e avançar
- Backspace: apagar caractere da resposta numérica
- Esc: sair

## Regras implementadas
- 5 fases com metas de 1, 2, 2, 3 e 4 acertos (12 no total).
- 10 questões por fase.
- Sorteio sem repetição até esgotar o banco da fase.
- Erros não removem acertos; cada erro apresenta a resolução.
- Derrota ao atingir 10 erros ou 20 minutos.
- Nova partida disponível após vitória ou derrota.
- Janela redimensionável, com layout que acompanha o tamanho da janela.

## Observações
Este é um protótipo inicial. A interface e a mecânica principal estão implementadas; música, efeitos sonoros, imagens próprias e animações mais elaboradas devem ser adicionados na etapa de polimento. Revise pedagogicamente o banco de questões antes da entrega final.
