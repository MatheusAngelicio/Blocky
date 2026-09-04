# Como criar um novo tema de bloco

Este guia define o processo obrigatório para adicionar um tema ao Blocky. Um
tema é uma identidade visual e de feedback; ele nunca altera as regras da
partida.

## Regras inegociáveis

- O bloco lógico continua sendo um paralelepípedo e usa os mesmos cálculos de
  overlap, Perfect, corte e Recovery de todos os outros temas.
- Não alterar `BlockTower`, `BlockyGameController`, `GameConfig` de gameplay ou
  colliders para atender um tema.
- Cada tema precisa de uma assinatura visual reconhecível. Trocar apenas cores
  ou `roughnessFactor` não cria um tema novo.
- Todo tema precisa de uma animação de encaixe própria. Ela pode ser uma
  variação curta e sutil, mas o conjunto de movimento, duração e escalas deve
  ser diferente de todos os temas existentes.
- O tema deve continuar legível com blocos cortados e pequenos.

## 1. Escreva o briefing visual

Antes de criar código, registre no pedido ou na implementação:

1. o material/objeto que inspira o tema;
2. três sinais visuais que o diferenciam dos temas existentes;
3. a paleta e o acabamento do material;
4. como o bloco reage a um encaixe normal;
5. como Perfect e Perfect Recovery complementam essa reação.

Exemplo de briefing válido: “cerâmica vitrificada, com veios discretos,
borda esmaltada e pequenas imperfeições estáveis; ao encaixar, faz uma leve
inclinação e retorna rapidamente”. “Blocos azuis” não é um briefing suficiente.

## 2. Audite os temas já existentes

Antes de definir o novo, compare-o com `BlockThemeVisual` e
`BlockThemeSceneRenderer`:

| Tema | Assinatura visual | Encaixe normal |
| --- | --- | --- |
| Classic | faces laterais e brilho no topo | pulso padrão |
| Jelly | destaque claro macio | squash/stretch elástico |
| Chocolate | divisões de tablete | assentamento firme |
| Cheese | furos estáveis em topo e laterais | assentamento firme sutil |
| Neon | moldura rosa, base ciano e trilhas de circuito em painel grafite | pulso de energia |

O novo tema não pode repetir a mesma combinação. Se usar uma família de
movimento existente, use parâmetros perceptivelmente diferentes e documente a
diferença. Se isso não produzir uma identidade clara, crie um novo valor em
`BlockImpactMotion` e implemente-o em `SceneFeedbackController`.

## 3. Adicione a identidade declarativa

1. Inclua o valor em `lib/game/block_theme.dart`, com nome em inglês.
2. Crie uma configuração `static const` em
   `lib/scene/block_theme_visual.dart`.
3. Defina ao menos:
   - `surfaceDetail` exclusivo ou uma combinação visual não usada;
   - `BlockImpactVisual` único para encaixes normais;
   - paleta em `BlockColorProgression`;
   - material (`metallicFactor`, `roughnessFactor`, opacidade);
   - feedbacks de Perfect, Recovery, queda e corte somente quando contribuírem
     para a identidade.
4. Registre o tema em `BlockThemeVisual.forTheme`.

O `BlockImpactVisual` controla apenas a representação: o tamanho lógico,
collider e próximo overlap permanecem inalterados.

## 4. Crie o detalhe 3D com custo controlado

1. Adicione um valor em `BlockSurfaceDetail` somente se for necessário.
2. Trate-o em `BlockThemeSceneRenderer.updateDetails`.
3. Crie detalhes em um método específico do tema, por exemplo
   `_createCeramicDetails`.
4. Para variação aleatória, use `_detailSeeds[block]` e recrie a mesma
   sequência após um corte ou redimensionamento.
5. Use geometria compartilhada (`late final`) e materiais reutilizados dentro
   do bloco; não crie texturas ou partículas contínuas sem necessidade.
6. Limite o número de Nodes decorativos. Blocos pequenos devem reduzir ou
   omitir detalhes que perderiam legibilidade.
7. Garanta que detalhes sejam filhos do bloco e permaneçam compatíveis com
   `forget` e `clear` do renderer.

Não use detalhes para mudar a caixa lógica ou o collider da torre.

## 5. Defina uma animação de encaixe diferente

O encaixe normal é disparado por `SceneFeedbackController.playPlacementImpact`.

1. Primeiro, tente expressar a identidade com uma combinação nova de duração,
   escalas horizontal/vertical e rebound em `BlockImpactVisual`.
2. Compare esses valores com todos os temas existentes. Não copie uma
   configuração inteira.
3. Quando precisar de uma sequência diferente de escalas, inclua um novo
   `BlockImpactMotion` e trate-o em `_impactScale` do
   `SceneFeedbackController`.
4. A animação deve terminar restaurando `Vector3.all(1.0)` e nunca mudar
   posição lógica, geometria, collider ou regras de jogo.

Também revise `perfectWobble` e `recoveryGrowthOvershoot` para que Perfect e
Recovery sejam coerentes com a assinatura do tema, sem substituir o feedback
principal do encaixe normal.

## 6. Integre a Home

1. Adicione acento e cores de preview em `lib/app/blocky_colors.dart`.
2. Atualize os `switches` de `themeAccent` e `themePreviewTower`.
3. Adicione o detalhe correspondente em `_ThemeSwatchPainter` de
   `lib/ui/home_screen.dart`.
4. Atualize `_themeName`.

O seletor de temas deve permanecer rolável quando a lista não couber na altura
disponível. Não suponha que a quantidade atual de temas caiba em um dispositivo
específico.

## 7. Teste e revise

1. Atualize `test/widget_test.dart` para incluir o novo valor de `BlockTheme`.
2. Teste que `BlockThemeVisual.forTheme` retorna a configuração correta.
3. Teste a assinatura: detalhe de superfície e `BlockImpactVisual` devem ser
   os planejados e não uma cópia de outro tema.
4. Execute:

   ```bash
   fvm dart format <arquivos alterados>
   fvm flutter analyze
   fvm flutter test
   git diff --check
   ```

5. Faça uma validação visual manual no dispositivo ou simulador escolhido pelo
   responsável pelo projeto, observando blocos completos, cortados, Perfect,
   Recovery e restart.
6. Atualize `docs/GAME_DESIGN.md`, `docs/ARCHITECTURE.md` e
   `docs/DECISIONS.md` se a mudança alterar descrição de tema, estrutura ou
   uma decisão arquitetural.

## Checklist de aprovação

- [ ] Nome, preview e persistência do tema funcionam.
- [ ] A identidade visual continua reconhecível após corte.
- [ ] Os detalhes aleatórios são estáveis e limpos em restart/dispose.
- [ ] O encaixe normal é visualmente distinto de todos os outros temas.
- [ ] Perfect e Recovery mantêm as mesmas regras de gameplay.
- [ ] Não foram criadas dependências ou camadas novas sem necessidade.
- [ ] Análise, testes e revisão de diff passaram.
