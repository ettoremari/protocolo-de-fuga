# PROTOCOLO DE FUGA — Instalação Ômega

Versão **2.0** — jogo de escape room narrativo em Godot 4.7.2.

## Premissa

Você desperta na Instalação Ômega após o ATLAS iniciar uma contenção total. Para alcançar a rota de evacuação, será necessário recuperar o controle dos sistemas, resolver validações matemáticas contextualizadas e investigar as contradições do sistema central. A história mantém ambígua a intenção do ATLAS até o fim.

## Campanha

A progressão tem seis setores: **01 Observação**, **02 Segurança**, **03 Pesquisa**, **04 Energia**, **05 Núcleo** e **06 Evacuação**. Os cinco primeiros usam o banco de 50 questões existente, com metas de 1, 2, 2, 3 e 4 respostas corretas. O último apresenta o arquivo confidencial do Projeto Espelho e permite escolher um dos três finais: **A Fuga**, **O Desligamento** ou **A Simulação**.

Os conteúdos matemáticos sustentam a narrativa: princípio fundamental da contagem para códigos; permutação para autenticação; arranjo para registros ordenados; combinação para seleção de módulos; e análise combinatória integrada para investigar possibilidades.

## Interface e recursos

- Interface inspirada em terminal de investigação cyberpunk, com arquivos/setores à esquerda, desafio ao centro e ATLAS/núcleo à direita em paisagem.
- Em aparelhos Android, a orientação é fixa em paisagem. A interface também mantém o layout responsivo para outros formatos de janela.
- O núcleo do ATLAS muda de cor e estado ao longo da campanha; diálogos reagem a respostas certas e erradas.
- Limite de 20 minutos e 10 erros; resolução exibida em caso de erro.
- Vídeos de abertura e de início de missão, música opcional e efeitos visuais de feedback preservados.

## Executar

1. Abra esta pasta no Godot **4.7.2**.
2. Importe `project.godot` e execute `main.tscn`.
3. O preset Android exporta para `build/ProtocoloDeFuga_OMEGA_v2.0.apk` (arm64).

Para exportar um APK de lançamento em outro computador, configure o Android SDK, o JDK e uma chave de assinatura própria no preset Android. O pacote-fonte não inclui a chave privada nem as credenciais usadas para assinar o APK entregue.

## Controles

- Toque/clique para selecionar alternativas, validar respostas e avançar.
- Teclado/tela para digitar resultados numéricos.
- Rolagem/toque para ler arquivos e enunciados extensos.
- O botão **PULAR** encerra os vídeos de introdução.

## Regras

- 50 questões no banco: 10 por cada um dos cinco setores matemáticos.
- Sorteio sem repetição dentro do setor até o banco ser esgotado.
- 12 validações corretas para chegar ao núcleo; erros não apagam acertos.
- Derrota ao atingir 10 erros ou 20 minutos.
- Após o Projeto Espelho, a decisão final seleciona uma das três rotas de encerramento; a avaliação de desempenho altera o texto do epílogo.
