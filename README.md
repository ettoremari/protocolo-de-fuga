# PROTOCOLO DE FUGA - Escape Room de Análise Combinatória

Versão: **1.2**

Jogo educacional convertido para **Godot 4**, com cinco fases, banco de questões, respostas mistas (alternativas e numéricas), limite de 20 minutos e 10 erros.

## Por que Godot

Godot e o motor escolhido para este projeto porque oferece animacao de interface, reproducao de video, audio, responsividade para celular e desktop e exportacao oficial para Android e Windows a partir do mesmo projeto.

## Requisitos

- Godot 4.7 ou superior

## Executar no computador

1. Abra a pasta do projeto no Godot.
2. Importe `project.godot`.
3. Pressione **F6** ou clique em **Executar projeto**.

## Exportar

Os presets ja estao configurados em `export_presets.cfg`:

- Windows Desktop: `build/ProtocoloDeFuga.exe`
- Android: `build/ProtocoloDeFuga.apk`

No Godot, use **Projeto > Exportar** e instale os templates de exportacao correspondentes. Para Android, configure o SDK/JDK no Editor Settings.

## Controles

- Clique/toque: selecionar alternativa, validar resposta e avancar
- Teclado físico ou tela: digitar respostas numéricas
- Roda do mouse/arrasto: percorrer textos longos
- Esc: fechar a janela

## Videos

- `abertura-final-2.ogv` reproduz na abertura do jogo.
- `iniciar-missao.ogv` reproduz ao tocar em **INICIAR MISSÃO**.
- Os arquivos MP4 originais enviados tambem ficam em `assets/` como fonte dos videos.

## Regras

- 5 fases com metas de 1, 2, 2, 3 e 4 acertos (12 no total).
- 10 questões por fase.
- Sorteio sem repeticao ate esgotar o banco da fase.
- Erros nao removem acertos; cada erro apresenta a resolucao.
- Derrota ao atingir 10 erros ou 20 minutos.
- Nova partida disponivel apos vitoria ou derrota.
- Interface responsiva em retrato e paisagem.
