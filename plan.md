# Plano — Salas cenográficas de Protocolo de Fuga

## Escopo aprovado
Transformar os seis setores em salas visuais temáticas, mantendo a mecânica atual: perguntas, respostas, progresso, limite de tempo, interação com ATLAS e os três finais não serão redesenhados. As salas são cenográficas; não haverá movimentação de personagem nem novos controles.

## Direção visual
Manter a identidade existente de ficção científica industrial, terminal escuro e acentos ciano. Usar imagens panorâmicas 16:9 com composição de ambiente, sem texto, sem logotipos e sem personagens; a UI continua renderizando texto ao vivo. Os objetos narrativos importantes ficam nas laterais e no fundo, com área central mais calma. Uma sobreposição navy protege o contraste das perguntas.

- **01 — Observação:** sala clínica, vidro unidirecional, cadeira/leito, monitores e porta de contenção; ciano frio. Varredura lenta no vidro e pulso suave dos monitores.
- **02 — Segurança:** checkpoint biométrico, leitor de credenciais, câmeras e comportas; ciano e vermelho. Feixe vertical percorre o corredor e o alerta pulsa.
- **03 — Pesquisa:** laboratório NEXUS, bancadas, câmaras de experimento e sensores; violeta e ciano. Partículas/nós sobem lentamente.
- **04 — Energia:** distribuição elétrica, disjuntores, cabos, módulos e gerador; âmbar e ciano. Um pulso percorre uma linha de circuito.
- **05 — Núcleo:** núcleo suspenso do ATLAS, servidores e anéis de energia/dados; ciano, violeta e vermelho discreto. Núcleo e anéis pulsam lentamente.
- **06 — Evacuação:** airlock, escotilha e rota de saída com luzes-guia; âmbar e ciano. Luzes do piso acendem em sequência rumo à saída.

## Implementação e estrutura
- `assets/rooms/`: seis fundos compactados para uso em runtime.
- `scripts/room_environment.gd`: camada de cenário em tela cheia, escolha do fundo por setor, carregamento assíncrono com fallback e animações ambientais leves e específicas do setor.
- `scripts/main.gd`: informar o setor atual ao cenário nas telas inicial, transições e encerramento; preservar o fluxo de perguntas e a UI.
- `tests/` e `README.md`: checagem pequena de existência/mapeamento e documentação das novas salas; sem alterar `data/questoes.json`.
- `build/web/`: export PWA para verificar que os fundos estão incluídos e carregam sem dependências externas.

As animações serão sutis — varredura, pulsos de luz, partículas/bolhas, fluxo de energia e sinalizadores — sem flashes fortes. O cenário ficará atrás dos controles e não interceptará cliques/toques. A interface mantém os seus layouts de paisagem e responsivo existentes.

## Design system
- **Movimento:** ficção científica industrial narrativa, próxima de um thriller de instalação subterrânea.
- **Princípios:** cada sala comunica sua função rapidamente; cenário não compete com enunciados; os motivos de ATLAS/NEXUS atravessam os setores; movimento ambiental lento e legível.
- **Cores:** navy quase preto como base; ciano da identidade atual; vermelho, violeta e âmbar somente como sinais narrativos de cada sala.
- **Composição:** vista panorâmica de arquitetura, com profundidade e detalhes fora do centro de leitura. Painéis da UI continuam sendo a camada de primeiro plano.
- **Motivos:** portas de contenção, observação através de vidro, linhas de dados/energia e sinalizadores de segurança.
- **Interação:** a troca de setor muda cenário, acento e animação; não acrescenta ações nem altera respostas.
- **Animação:** ciclos lentos, discretos e sem estroboscopia; transições suaves entre setores.
- **Tipografia:** manter fonte, tamanhos, hierarquia e rótulos ao vivo atuais; nenhum texto será rasterizado nos fundos.
- **Essência da marca:** escape room narrativo de matemática e ficção científica para quem gosta de investigação e puzzles; atmosférico, ambíguo e preciso.
- **Voz da marca:** preservar a voz curta, objetiva e ambígua do ATLAS. Exemplos existentes: “Posso orientar sua análise. Não posso escolher por você.” e “Minha leitura dos dados pode estar incompleta.”
- **Logotipo:** manter o título e a marca atuais sem redesenho.
- **Cor-assinatura:** ciano luminoso `#34DCF0`, a cor de sinais e interface do ATLAS.

## Limites técnicos
Godot 4.7.2, renderer Compatibility/WebGL 2, export PWA existente. Imagens serão reduzidas/comprimidas para limitar o aumento de download e não serão carregadas antes de a tela inicial tornar-se interativa. Nenhuma mudança de áudio, banco de questões, navegação, acessibilidade do teclado ou orientação faz parte deste escopo.
