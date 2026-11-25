# PROTOCOLO DE FUGA — Instalação Ômega

Versão **2.4-preview**, integrada à branch `main` (commit `84e95aa`). Jogo de escape room narrativo desenvolvido em Godot 4.7.2.

## Downloads e instalação

### Android — APK arm64 v2.4-preview

[Baixar APK Android v2.4-preview](https://github.com/ettoremari/protocolo-de-fuga/releases/download/v2.4-preview/ProtocoloDeFuga_OMEGA_v2.4_debug.apk)

1. Baixe o APK em um dispositivo Android arm64.
2. Abra o arquivo baixado. Se solicitado, permita a instalação de aplicativos para o navegador ou gerenciador de arquivos usado no download.
3. Confirme **Instalar** e abra o jogo em orientação paisagem.

**Atenção:** este é um APK de depuração (debug), assinado com uma chave diferente da release v2.3. Ele não atualiza por cima da versão v2.3 instalada. Para testar a prévia, desinstale a versão anterior antes de instalar este APK; desinstalar pode apagar dados locais do aplicativo. Para atualizar sem desinstalar, é necessário um APK assinado com a chave original da release.

### Windows — EXE x86-64 v2.4-preview

[Baixar executável Windows v2.4-preview](https://github.com/ettoremari/protocolo-de-fuga/releases/download/v2.4-preview/ProtocoloDeFuga_v2.4.exe)

Baixe o arquivo e abra-o com duplo clique. É um executável para Windows x86-64 e não requer instalador. Como o arquivo não possui assinatura de código, o Windows pode exibir um aviso de editor desconhecido.

### iPhone e iPad — versão Web/PWA

[Jogue Protocolo de Fuga no Safari](https://ettoremari.github.io/protocolo-de-fuga/). Para adicionar à Tela de Início:

1. Abra o link no **Safari** e toque em **Compartilhar**.
2. Escolha **Adicionar à Tela de Início**.
3. Se aparecer **Abrir como App da Web**, mantenha a opção ativada e confirme em **Adicionar**.
4. Abra o ícone criado e use o aparelho em paisagem.

O PWA declara modo standalone e orientação paisagem. A primeira carga requer conexão e pode levar mais tempo por causa do tamanho dos recursos. Para compatibilidade e desempenho nos navegadores, a versão Web omite os dois vídeos Ogg de introdução. O comportamento de rotação pode variar conforme a versão do iOS/Safari; não foi testado em um iPhone físico.

### Rodar o projeto no Godot

1. Instale o **Godot 4.7.2**.
2. Clone ou baixe este repositório e importe `project.godot` no Godot.
3. Selecione `main.tscn` como cena principal e pressione **Executar Projeto (F6/F5)**.
4. Para exportar, configure os templates de exportação e os SDKs necessários à plataforma. O preset Android gera `build/ProtocoloDeFuga_OMEGA_v2.4.apk` (arm64).

O repositório não contém chave privada nem credenciais de assinatura Android. Uma release Android assinada para atualização in-place requer a chave original da release correspondente.

### Release estável anterior

A versão **v2.3** permanece disponível como release estável assinada. Ela é separada da prévia 2.4:

- [APK Android arm64 — v2.3 estável](https://github.com/ettoremari/protocolo-de-fuga/releases/download/v2.3/ProtocoloDeFuga_v2.3.apk)
- [Executável Windows x86-64 — v2.3](https://github.com/ettoremari/protocolo-de-fuga/releases/download/v2.3/ProtocoloDeFuga_v2.3.exe)
- [Notas e arquivos da release v2.3](https://github.com/ettoremari/protocolo-de-fuga/releases/tag/v2.3)
- [Todos os arquivos da prévia v2.4](https://github.com/ettoremari/protocolo-de-fuga/releases/tag/v2.4-preview)

## Premissa

Você desperta na Instalação Ômega após o ATLAS iniciar uma contenção total. Para alcançar a rota de evacuação, será necessário recuperar o controle dos sistemas, resolver validações matemáticas contextualizadas e investigar as contradições do sistema central. A história mantém ambígua a intenção do ATLAS até o fim.

## Campanha

A progressão tem seis setores: **01 Observação**, **02 Segurança**, **03 Pesquisa**, **04 Energia**, **05 Núcleo** e **06 Evacuação**. Os cinco primeiros usam um banco de **300 questões**, 60 por setor (20 anteriores e 40 novas por tema), mantendo metas de 1, 2, 2, 3 e 4 respostas corretas. Na tela inicial, é possível escolher uma entre cinco dificuldades ou usar todas; cada tema novo tem oito questões de cada dificuldade. O sexto setor apresenta o arquivo confidencial do Projeto Espelho e permite escolher um dos três finais: **A Fuga**, **O Desligamento** ou **A Simulação**.

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

## Controles

- Toque/clique para selecionar alternativas, validar respostas e avançar.
- Toque/clique no núcleo do ATLAS para receber uma mensagem contextual sem alterar o progresso.
- Teclado/tela para digitar resultados numéricos.
- Rolagem/toque para ler arquivos e enunciados extensos.
- O botão **PULAR** encerra os vídeos de introdução.

## Regras

- 300 questões no banco: 60 por cada um dos cinco setores matemáticos; as 200 novas estão balanceadas por tema e dificuldade.
- Seletor de dificuldade no terminal inicial: qualquer dificuldade, fácil, básico, intermediário, avançado ou difícil.
- Uma única bolha informativa aparece no começo de cada um dos seis setores, mantendo o cenário cenográfico à vista.
- Sorteio sem repetição dentro do setor até o banco ser esgotado.
- 12 validações corretas para chegar ao núcleo; erros não apagam acertos.
- Derrota ao atingir 10 erros ou 20 minutos.
- Após o Projeto Espelho, a decisão final seleciona uma das três rotas de encerramento; a avaliação de desempenho altera o texto do epílogo.
