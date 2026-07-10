# Roedores: RISC of Infection

Roedores: RISC of Infection e um jogo de sobrevivencia feito em RISC-V Assembly para o RARS16_Custom1. O jogador enfrenta roedores infectados em tres ambientes, coleta recursos, troca de armas e tenta sobreviver ate a batalha final.

O jogo usa Bitmap Display `320x240`, unidade `1x1`, cores BGR233 de 8 bits, double buffering e teclado pelo Keyboard Display MMIO.

## Como Rodar

Para executar o jogo, abra o arquivo `main.s` no RARS16_Custom1.

Na interface do RARS, conecte:

- Bitmap Display com largura `320`, altura `240` e unidade `1x1`.
- Keyboard Display MMIO para entrada de teclado.

Depois, monte e execute o programa. O jogo inicia no menu principal.

## Controles

- `SPACE` ou `ENTER`: iniciar no menu e avancar cutscenes.
- `WASD`: mover o jogador.
- `IJKL`: atirar para cima, esquerda, baixo e direita.
- `H/h`: usar cura, se houver medkit no inventario.
- `R/r`: recarregar a arma selecionada durante o gameplay.
- `T/t`: reiniciar a partir das telas de game over ou victory.
- `1`: selecionar a arma normal.
- `2`: selecionar a shotgun depois de coleta-la.
- `3`: selecionar a UZI depois de coleta-la.
- `E/e`: mostrar ou ocultar o inventario.
- `C/c`: avancar para a proxima transicao durante o gameplay.

## Fluxo Do Jogo

O jogo comeca no menu principal. Ao pressionar `SPACE` ou `ENTER`, a primeira cutscene e exibida antes da fase da cidade.

A progressao principal e:

- Menu inicial.
- Cutscene de introducao.
- Fase 1: cidade.
- Cutscene para o esgoto.
- Fase 2: esgoto.
- Cutscene para o laboratorio.
- Fase 3: laboratorio e batalha final.
- Tela de victory ou game over.

Durante menu, cutscenes, game over e victory, o gameplay fica pausado. Nessas telas, `R/r` nao reinicia a partida.

## Objetivo

O objetivo e sobreviver as hordas, coletar recursos no mapa e derrotar o boss final. A partida termina em game over quando as vidas do jogador chegam a zero, ou em victory quando o boss final e derrotado.

## Elementos Do Jogo

- Jogador com vida, direcao, cura, inventario e armas.
- Arma normal com municao e recarga.
- Shotgun desbloqueada por coleta.
- UZI desbloqueada por coleta.
- Medkit para recuperar cura disponivel no inventario.
- Municoes coletaveis para diferentes armas.
- Inimigos com comportamentos variados.
- Boss final com ataques proprios.
- Pontuacao exibida nas telas finais.

## Arquitetura Do Codigo

O arquivo principal e `main.s`. Ele inclui os dados globais, os modulos em `src/`, inicializa o jogo e chama o loop principal.

Principais diretorios e arquivos:

- `main.s`: ponto de entrada do jogo.
- `data/*.s`: dados globais usados durante a partida.
- `src/constants.s`: constantes de estados, fases, entidades, armas e balanceamento.
- `src/game_state.s`: troca entre menu, fases, cutscenes, game over e victory.
- `src/game_loop.s`: loop principal que atualiza e desenha o jogo conforme o estado atual.
- `src/input.s`: leitura de teclado.
- `src/screens.s`: logica de menu, cutscenes, game over, victory e reinicio.
- `src/level_manager.s`: waves, progressao entre fases e ativacao do boss.
- `src/player.s`: movimento, vida, dano e direcao do jogador.
- `src/bullets.s`: tiros do jogador.
- `src/enemies.s`: atualizacao dos inimigos.
- `src/enemy_bullets.s`: projeteis dos inimigos.
- `src/boss.s`: comportamento do boss final.
- `src/collision.s`: colisoes entre jogador, inimigos, tiros e itens.
- `src/powerups.s`: itens coletaveis no chao.
- `src/inventory.s`: armas, municao, cura, selecao e recarga.
- `src/render.s`: desenho das telas, cenarios, entidades, HUD e double buffering.
- `src/hud.s`: informacoes numericas exibidas durante o gameplay.

## Estados Principais

- `STATE_MENU`: menu inicial.
- `STATE_CUTSCENE_INTRO`: cutscene antes da cidade.
- `STATE_LEVEL1`: fase da cidade.
- `STATE_CUTSCENE_LEVEL2`: cutscene antes do esgoto.
- `STATE_LEVEL2`: fase do esgoto.
- `STATE_CUTSCENE_LEVEL3`: cutscene antes do laboratorio.
- `STATE_LEVEL3` / `STATE_BOSS`: laboratorio e boss final.
- `STATE_GAME_OVER`: tela de derrota.
- `STATE_VICTORY`: tela de vitoria.

## Observacoes

O jogo foi organizado em modulos para separar entrada, estado, fases, entidades, inventario, colisoes e renderizacao. Essa divisao facilita a leitura do codigo e mostra a responsabilidade de cada parte do projeto.
