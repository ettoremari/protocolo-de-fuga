# PROTOCOLO DE FUGA — Instalação Ômega

Versão **2.3** — jogo de escape room narrativo em Godot 4.7.2.

## Downloads

- [APK Android arm64 — v2.3](https://github.com/ettoremari/protocolo-de-fuga/releases/download/v2.3/ProtocoloDeFuga_v2.3.apk)
- [Executável Windows x86_64 — v2.3](https://github.com/ettoremari/protocolo-de-fuga/releases/download/v2.3/ProtocoloDeFuga_v2.3.exe)
- [Notas e todos os arquivos da release v2.3](https://github.com/ettoremari/protocolo-de-fuga/releases/tag/v2.3)

## Versão Web/PWA para iPhone

[Jogue Protocolo de Fuga no Safari](https://ettoremari.github.io/protocolo-de-fuga/). Para instalar na Tela de Início do iPhone:

1. Abra o link no Safari e toque em **Compartilhar**.
2. Escolha **Adicionar à Tela de Início**.
3. Se a opção **Abrir como App da Web** aparecer, deixe-a ativada e confirme em **Adicionar**.
4. Abra o ícone criado na Tela de Início e use o aparelho em paisagem.

O manifesto do PWA declara modo standalone e orientação paisagem. O export Web/PWA atualizado nesta branch ocupa aproximadamente 61 MiB e requer conexão na primeira carga. Para compatibilidade/performance nos navegadores, esta versão Web pula os dois vídeos Ogg de introdução. A página publicada e os arquivos principais foram verificados, mas ainda não houve teste em um iPhone físico.

## Premissa

Você desperta na Instalação Ômega após o ATLAS iniciar uma contenção total. Para alcançar a rota de evacuação, será necessário recuperar o controle dos sistemas, resolver validações matemáticas contextualizadas e investigar as contradições do sistema central. A história mantém ambígua a intenção do ATLAS até o fim.

## Campanha

A progressão tem seis setores: **01 Observação**, **02 Segurança**, **03 Pesquisa**, **04 Energia**, **05 Núcleo** e **06 Evacuação**. Os cinco primeiros usam um banco de 100 questões, com 20 por setor e metas de 1, 2, 2, 3 e 4 respostas corretas. O último apresenta o arquivo confidencial do Projeto Espelho e permite escolher um dos três finais: **A Fuga**, **O Desligamento** ou **A Simulação**.

Os conteúdos matemáticos sustentam a narrativa: princípio fundamental da contagem para códigos; permutação para autenticação; arranjo para registros ordenados; combinação para seleção de módulos; e análise combinatória integrada para investigar possibilidades.

## Interface e recursos

- Interface inspirada em terminal de investigação cyberpunk, com arquivos/setores à esquerda, desafio ao centro e ATLAS/núcleo à direita em paisagem.
- Em aparelhos Android, a orientação é fixa em paisagem. O PWA declara orientação paisagem e modo standalone; o comportamento de rotação pode variar conforme o iOS/Safari. A interface também mantém o layout responsivo para outros formatos de janela.
- A ordem das alternativas de múltipla escolha é embaralhada a cada exibição; as posições corretas ficam equilibradas no banco.
- Toque/clique no núcleo do ATLAS para receber respostas contextuais; o núcleo pulsa e reage com partículas, e as falas aparecem em efeito de terminal.
- Os seis setores têm salas cenográficas próprias — observação, segurança biométrica, pesquisa NEXUS, energia, núcleo ATLAS e evacuação — com movimentos ambientais discretos ligados à narrativa.
- Setores, pistas recuperadas, o arquivo classificado e os três finais têm revelações progressivas e efeitos visuais próprios.
- Limite de 20 minutos e 10 erros; resolução exibida em caso de erro.
- Vídeos de abertura e de início de missão permanecem nas versões desktop/Android; são omitidos no export Web. Música opcional e efeitos de feedback são preservados.

## Trilha sonora

A música atual **Tense Future Loop**, de gmason, permanece na tela inicial. Durante a campanha, a trilha muda com transições suaves: **Airy** no Setor 01, **Sector** no Setor 02, **Pulse** nos Setores 03 e 04, e **Urgent** no Setor 05.

As quatro faixas dos setores são do pacote [Dark Sci-Fi Audio Pack](https://opengameart.org/content/dark-sci-fi-audio-pack), de **SRG774**, publicado sob **CC0 1.0**. O crédito é voluntário, mas registrado aqui em agradecimento. A licença permite copiar, adaptar, distribuir e usar comercialmente sem exigir atribuição.

O player aplica compensação de ganho individual medida para cada faixa, aproximando o loudness de reprodução a **−21 LUFS** e mantendo os picos previstos abaixo de **−2 dBTP**. Os arquivos originais são preservados; o ganho geral do player passou de −11 dB para −3 dB.

## Executar

1. Abra esta pasta no Godot **4.7.2**.
2. Importe `project.godot` e execute `main.tscn`.
3. O preset Android exporta para `build/ProtocoloDeFuga_OMEGA_v2.3.apk` (arm64).

Para exportar um APK de lançamento em outro computador, configure o Android SDK, o JDK e uma chave de assinatura própria no preset Android. O pacote-fonte não inclui a chave privada nem as credenciais usadas para assinar o APK entregue.

## Controles

- Toque/clique para selecionar alternativas, validar respostas e avançar.
- Toque/clique no núcleo do ATLAS para receber uma mensagem contextual sem alterar o progresso.
- Teclado/tela para digitar resultados numéricos.
- Rolagem/toque para ler arquivos e enunciados extensos.
- O botão **PULAR** encerra os vídeos de introdução.

## Regras

- 100 questões no banco: 20 por cada um dos cinco setores matemáticos.
- Sorteio sem repetição dentro do setor até o banco ser esgotado.
- 12 validações corretas para chegar ao núcleo; erros não apagam acertos.
- Derrota ao atingir 10 erros ou 20 minutos.
- Após o Projeto Espelho, a decisão final seleciona uma das três rotas de encerramento; a avaliação de desempenho altera o texto do epílogo.
