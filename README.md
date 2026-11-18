# PROTOCOLO DE FUGA — Escape Room de Análise Combinatória

Protótipo em Python + Pygame, com cinco fases, banco de questões, respostas mistas (alternativas e numéricas), limite de 20 minutos, 10 erros e sistema de energia.

## Baixar o jogo

- [Windows (.exe)](https://github.com/ettoremari/protocolo-de-fuga/releases/latest/download/ProtocoloDeFuga.exe)
- [Android (.apk) — versão responsiva mais recente](https://github.com/ettoremari/protocolo-de-fuga/actions/runs/44197229588)

**Android:** abra a página da compilação, localize a seção **Artifacts** e baixe `ProtocoloDeFuga-android-apk`. Extraia o arquivo ZIP e instale o APK no dispositivo. Esta compilação é de depuração para instalação manual; o artefato do GitHub Actions tem prazo de validade.

## Requisitos
- Python 3.10 ou superior
- Pygame 2.5+

## Instalação
```bash
python -m venv .venv
# Windows:
.venv\\Scripts\\activate
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
- Esc/Voltar: abrir o menu principal sem perder o progresso
- No menu principal: toque em **CONTINUAR MISSÃO** para retomar de onde parou

## Regras implementadas
- 5 fases com metas de 1, 2, 2, 3 e 4 acertos (12 no total).
- Banco de questões ampliável, com sorteio sem repetição até esgotar o banco da fase.
- Erros não removem acertos; cada erro apresenta a resolução.
- Energia inicial de 100%; cada resposta errada consome 8 pontos e cada pista opcional consome 15 pontos.\n- Ao concluir um setor, a instalação recupera 10 pontos de energia (limite de 100%).\n- Derrota ao esgotar a energia, atingir 10 erros ou exceder 20 minutos.\n- Uma pista opcional por questão orienta o raciocínio sem revelar a resposta; a resolução completa continua aparecendo após erro.
- Nova partida disponível após vitória ou derrota.
- Janela redimensionável, com layout que acompanha o tamanho da janela.

## Observação sobre a versão Android

A interface responsiva ajusta fontes e componentes conforme a resolução e orientação da tela. Recomenda-se validar em diferentes tamanhos de tela e versões do Android.
