# Roedores: RISC of Infection

Jogo de sobrevivencia em RISC-V Assembly para RARS16_Custom1. O jogador enfrenta hordas de roedores infectados na cidade, no esgoto e no laboratorio ate a batalha final.

O projeto usa Bitmap Display `320x240` com pixels BGR233 de 8 bits, double buffering e Keyboard Display MMIO (KDMMIO). PNGs sao convertidos offline; o runtime usa somente dados Assembly.

## Requisitos

- Java para executar o arquivo JAR.
- RARS16_Custom1.
- Bitmap Display em `320x240`, unidade `1x1`.
- Keyboard Display MMIO conectado.

## Como validar

```powershell
python -m unittest discover
java -jar <RARS_JAR> nc a main.s
java -jar <RARS_JAR> nc me main.s
java -jar <RARS_JAR> nc a test_progression.s
java -jar <RARS_JAR> nc me test_progression.s
java -jar <RARS_JAR> nc me test_runtime_smoke.s
java -jar <RARS_JAR> nc me test_final_adjustments.s
```

## RARS GUI

- Use `main.s` como arquivo principal.
- Use o RARS16_Custom1.
- Conecte o Bitmap Display conforme o projeto da disciplina.
- Conecte o KDMMIO para teclado.
- No menu, `SPACE` ou `ENTER` reinicia a partida e abre a primeira cutscene.

## Checklist manual RARS GUI

- Conectar Bitmap Display.
- Conectar KDMMIO.
- Abrir `main.s`.
- Usar Run.
- `SPACE` ou `ENTER` inicia e avanca cutscenes.
- `WASD` move.
- `IJKL` atira.
- `H` cura.
- Rifle recarrega.
- Echo reage a ruido.
- Spitter atira com range.
- Boss melee funciona.
- Boss projetil grande funciona.
- Power-ups coletam.
- Victory aparece.
- `R` reinicia.

## Controles

- `WASD`: mover.
- `IJKL`: atirar.
- `1`: selecionar rifle.
- `2`: selecionar escopeta quando desbloqueada.
- `3`: selecionar UZI quando desbloqueada.
- `C` ou `c`: avancar para a proxima fase durante o gameplay (cheat de teste).
- `SPACE` ou `ENTER`: iniciar no menu e avancar cutscenes.
- `R`: recarregar a arma selecionada.
- `E`: mostrar ou ocultar inventario.
- `R` ou `T`: reiniciar em game over ou victory.
- `H`: usar cura quando houver item.

## Fases e cutscenes

- Primeira cutscene: depois do menu, antes da cidade.
- Segunda cutscene: entre a cidade e o esgoto.
- Terceira cutscene: entre o esgoto e o laboratorio/boss.

Durante cutscenes o gameplay fica suspenso. Somente `SPACE` ou `ENTER` avanca, e o input e limpo ao sair para evitar acionamento duplicado. As imagens opacas de `320x240` sao convertidas sem resize, suavizacao ou antialiasing por `tools/convert_cutscenes.py`; cada tela gera `76.800` bytes em `assets/generated/cutscenes.s`.

## Power-ups e armas

- Medkit: adiciona cura ao inventario.
- Municoes: pickups separados para arma normal, shotgun e UZI.
- Shotgun: o drop no chao desbloqueia a selecao pela tecla `2`.
- UZI: o drop no chao desbloqueia a selecao pela tecla `3`, sem equipar automaticamente.

## Gameplay atual

- O movimento usa um buffer curto: uma tecla WASD move por alguns frames e depois expira.
- O tiro tambem usa buffer curto: segurar IJKL mantem disparos na direcao escolhida respeitando o cooldown da arma.
- O Echo reage a ruido. Movimento, tiro e recarga aumentam `noise_timer`.
- O Spitter tenta manter distancia: aproxima, recua, faz strafe e so atira dentro do alcance.
- Projeteis inimigos tem vida util, tamanho e dano por tipo.
- O boss tem ataque melee com cooldown e projetil pesado/lento.
- O rifle tem magazine de 40 tiros, disparo rapido e recarga.
- A escopeta e desbloqueada na Sewer e dispara tres projeteis em cone.

## Arquitetura

- `src/enemies.s`: ratos common, Echo, mutant e spitter.
- `src/enemy_bullets.s`: projeteis inimigos.
- `src/boss.s`: boss final separado dos inimigos normais.
- `src/powerups.s`: power-ups coletaveis.
- `src/inventory.s`: arma, municao normal, municao boss e cura.
- `src/hud.s`: informacoes numericas de gameplay.
- `src/screens.s`: menu, cutscenes, game over, victory e reset de partida.
- `src/level_manager.s`: progressao entre town, sewer, laboratory e boss.

## Integracao

Os desenhos principais usam sprites embutidos a partir dos assets do grupo. Para trocar mapas, musica ou telas do grupo, mantenha as interfaces atuais e substitua por dentro dos pontos abaixo:

- `draw_player_square`
- `draw_enemies`
- `draw_boss_square`
- `draw_inventory`
- `draw_powerups`
- `draw_menu_screen`
- `draw_cutscene_screen`
- `draw_game_over_screen`
- `draw_victory_screen`
- `begin_frame`
- `end_frame`

As fases usam IDs em `src/constants.s` e logica em `src/level_manager.s`. Os nomes atuais sao `LEVEL_TOWN`, `LEVEL_SEWER`, `LEVEL_LABORATORY` e `STATE_BOSS`.

## Sistema de renderizacao e sprites

O jogo usa double buffering. `begin_frame` limpa apenas o frame escondido indicado por `draw_frame`; `end_frame` mostra o frame pronto em `VGAFRAMESELECT` e alterna `draw_frame` para o proximo frame escondido.

Regras para qualquer render novo:

- Nenhuma funcao `draw_*` deve alterar `VGAFRAMESELECT`.
- Nenhuma funcao `draw_*` deve limpar a tela inteira.
- Nenhuma funcao `draw_*` deve chamar `frame_delay`.
- Sprites devem desenhar no frame retornado por `get_draw_base_address` ou no frame numerico lido de `draw_frame`.
- Mapas e cenarios entram em `draw_background`, depois de `begin_frame` e antes das entidades.

Para integrar sprites, substitua o corpo destas funcoes sem mudar a interface chamada pelo `game_loop`:

- `draw_player_square`
- `draw_enemies`
- `draw_boss_square`
- `draw_bullets`
- `draw_enemy_bullets`
- `draw_powerups`
- `draw_inventory`
- `draw_hud`

Sprites animados devem usar `animation_frame`. A animacao e visual: `update_animation_frame` alterna entre `SPRITE_FRAME_0` e `SPRITE_FRAME_1` a cada `ANIMATION_FRAME_DELAY` frames e nao muda estado logico do jogo.

Player, ratos, boss, power-ups e icones de armas ja usam sprites. Sprite estatico funciona usando sempre o frame 0. O sprite do inventario do grupo fica em `draw_inventory`.

Checklist visual:

- Menu nao pisca.
- Gameplay nao pisca.
- HUD nao pisca.
- Projetil grande do boss nao escreve fora da tela.
- Sprites futuros nao trocam frame por conta propria.
- `game_loop` continua chamando as mesmas funcoes de desenho.

## Performance dos sprites no RARS

- Sprites devem ser 8bpp em `.byte`, com pixel `0` como transparente.
- Sprites grandes deixam o Bitmap Display do RARS lento; prefira 16x16 para entidades comuns e use tamanhos maiores com cuidado.
- Funcoes `draw_*` nao podem limpar a tela inteira, trocar `VGAFRAMESELECT` ou chamar `frame_delay`.
- `USE_SPRITE_PLAYER`, `USE_SPRITE_ENEMIES`, `USE_SPRITE_BOSS`, `USE_SPRITE_POWERUPS` e `USE_SPRITE_INVENTORY` controlam fallback visual por grupo.
- O inventario spriteado fica desligado por padrao; o inventario numerico continua ativo e pode ser usado para testar performance.
- Para testar fluidez, ligue primeiro o player, depois inimigos, boss, power-ups e por ultimo inventario.

## Balanceamento

Os ajustes principais ficam em `src/constants.s`:

- HP e velocidade dos ratos.
- `NOISE_MOVE_FRAMES`, `NOISE_SHOT_FRAMES`, `NOISE_RELOAD_FRAMES`.
- `RIFLE_MAG_SIZE`, `RIFLE_RELOAD_FRAMES`, `RIFLE_FIRE_DELAY`, `RIFLE_BULLET_SPEED`.
- `SHOTGUN_MAG_SIZE`, `SHOTGUN_FIRE_DELAY`, `SHOTGUN_BULLET_SPEED`, `SHOTGUN_SPREAD_SPEED`.
- `SPITTER_MIN_RANGE`, `SPITTER_MAX_RANGE`, `SPITTER_PROJECTILE_LIFE`.
- `BOSS_MELEE_RANGE`, `BOSS_HEAVY_SHOOT_DELAY`, `BOSS_PROJECTILE_SIZE`.
- HP e delay de ataque do boss.
- Dano da arma normal e da arma boss.
- Ganho de municao normal, municao boss e cura.
- Quantidade de waves e inimigos por wave.

## Checklist

- `main.s` monta.
- `test_progression.s` monta.
- Teste de progressao executa e termina.
- Menu inicia jogo.
- Player move e atira.
- Rifle recarrega depois do magazine.
- Ratos aparecem e sofrem dano.
- Echo reage a ruido.
- Mutant exige mais de um hit normal.
- Spitter reposiciona e dispara projetil com alcance limitado.
- Projetil inimigo tira vida.
- Boss tem melee e projetil pesado.
- Power-ups de municao e cura podem ser coletados.
- Arma e municao boss aparecem na batalha final.
- Inventario numerico atualiza.
- Boss aparece e so ele dispara victory ao morrer.
- Game over aparece quando vidas chegam a zero.
- `R` reinicia para o menu em game over ou victory.
