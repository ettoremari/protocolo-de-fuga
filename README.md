# PROTOCOLO DE FUGA — Escape Room de Análise Combinatória

Protótipo em Python + Pygame, com cinco fases, banco de questões, respostas mistas (alternativas e numéricas), limite de 20 minutos e 10 erros.

## Baixar o jogo

- [Windows (.exe)](https://github.com/ettoremari/protocolo-de-fuga/releases/latest/download/ProtocoloDeFuga.exe)
- [Android (.apk)](https://github.com/ettoremari/protocolo-de-fuga/releases/latest/download/ProtocoloDeFuga.apk)

O APK é uma compilação de depuração para instalação manual.

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

## Executar no Android (Pydroid 3)

1. Instale o **Pydroid 3** pela Google Play.
2. Baixe o projeto pelo botão **Code > Download ZIP** no GitHub e extraia a pasta.
3. No terminal do Pydroid 3, instale a dependência:
   ```bash
   pip install pygame
   ```
4. Abra o arquivo `main.py` dentro da pasta extraída e toque em **Run**.
5. Se o Android perguntar sobre rotação automática, permita a orientação que preferir. A interface detecta telas verticais e horizontais e ajusta os controles.

Na orientação vertical, as respostas numéricas usam um teclado integrado ao jogo; não é necessário abrir o teclado virtual do Android. As alternativas e botões foram ampliados para toque.

Se o Pydroid abrir apenas o editor, confira se o arquivo aberto é o `main.py` da pasta principal do projeto e se a pasta `data` está no mesmo nível.

## Controles
- Enter: iniciar/reiniciar e enviar resposta numérica
- Toque/clique: selecionar alternativa, validar resposta e avançar
- Teclado integrado na tela vertical: inserir números, vírgula e apagar
- Backspace: apagar caractere da resposta numérica com teclado físico
- Esc: sair

## Regras implementadas
- 5 fases com metas de 1, 2, 2, 3 e 4 acertos (12 no total).
- 10 questões por fase.
- Sorteio sem repetição até esgotar o banco da fase.
- Erros não removem acertos; cada erro apresenta a resolução.
- Derrota ao atingir 10 erros ou 20 minutos.
- Nova partida disponível após vitória ou derrota.
- Janela redimensionável, com layout que acompanha o tamanho da janela.

## Observação sobre a versão Android

A interface responsiva foi adicionada, mas a execução ainda precisa ser validada em diferentes tamanhos de tela e versões do Pydroid 3.
