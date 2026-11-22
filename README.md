# PROTOCOLO DE FUGA — Instalação Ômega

Versão **2.2** — jogo de escape room narrativo em Godot 4.7.2.

## Premissa

Você desperta na Instalação Ômega após o ATLAS iniciar uma contenção total. Para alcançar a rota de evacuação, será necessário recuperar o controle dos sistemas, resolver validações matemáticas contextualizadas e investigar as contradições do sistema central. A história mantém ambígua a intenção do ATLAS até o fim.

## Campanha

A progressão tem seis setores: **01 Observação**, **02 Segurança**, **03 Pesquisa**, **04 Energia**, **05 Núcleo** e **06 Evacuação**. Os cinco primeiros usam um banco de 100 questões, com 20 por setor e metas de 1, 2, 2, 3 e 4 respostas corretas. O último apresenta o arquivo confidencial do Projeto Espelho e permite escolher um dos três finais: **A Fuga**, **O Desligamento** ou **A Simulação**.

Os conteúdos matemáticos sustentam a narrativa: princípio fundamental da contagem para códigos; permutação para autenticação; arranjo para registros ordenados; combinação para seleção de módulos; e análise combinatória integrada para investigar possibilidades.

## Interface e recursos

- Interface inspirada em terminal de investigação cyberpunk, com arquivos/setores à esquerda, desafio ao centro e ATLAS/núcleo à direita em paisagem.
- Em aparelhos Android, a orientação é fixa em paisagem. A interface também mantém o layout responsivo para outros formatos de janela.
- A ordem das alternativas de múltipla escolha é embaralhada a cada exibição; as posições corretas ficam equilibradas no banco.
- O núcleo do ATLAS muda de cor e estado ao longo da campanha; diálogos reagem a respostas certas e erradas.
- Limite de 20 minutos e 10 erros; resolução exibida em caso de erro.
- Vídeos de abertura e de início de missão, música opcional e efeitos visuais de feedback preservados.

## Trilha sonora

A música atual **Tense Future Loop**, de gmason, permanece na tela inicial. Durante a campanha, a trilha muda com transições suaves: **Airy** no Setor 01, **Sector** no Setor 02, **Pulse** nos Setores 03 e 04, e **Urgent** no Setor 05.

As quatro faixas dos setores são do pacote [Dark Sci-Fi Audio Pack](https://opengameart.org/content/dark-sci-fi-audio-pack), de **SRG774**, publicado sob **CC0 1.0**. O crédito é voluntário, mas registrado aqui em agradecimento. A licença permite copiar, adaptar, distribuir e usar comercialmente sem exigir atribuição.

## Executar

1. Abra esta pasta no Godot **4.7.2**.
2. Importe `project.godot` e execute `main.tscn`.
3. O preset Android exporta para `build/ProtocoloDeFuga_OMEGA_v2.2.apk` (arm64).

Para exportar um APK de lançamento em outro computador, configure o Android SDK, o JDK e uma chave de assinatura própria no preset Android. O pacote-fonte não inclui a chave privada nem as credenciais usadas para assinar o APK entregue.

## Controles

- Toque/clique para selecionar alternativas, validar respostas e avançar.
- Teclado/tela para digitar resultados numéricos.
- Rolagem/toque para ler arquivos e enunciados extensos.
- O botão **PULAR** encerra os vídeos de introdução.

## Regras

- 100 questões no banco: 20 por cada um dos cinco setores matemáticos.
- Sorteio sem repetição dentro do setor até o banco ser esgotado.
- 12 validações corretas para chegar ao núcleo; erros não apagam acertos.
- Derrota ao atingir 10 erros ou 20 minutos.
- Após o Projeto Espelho, a decisão final seleciona uma das três rotas de encerramento; a avaliação de desempenho altera o texto do epílogo.
