# ============================================================
# HUD do jogo
# ============================================================

.text

# ------------------------------------------------------------
# draw_hud
# Desenha informações principais do jogo.
#
# Layout numerico:
#   x=8    score
#   x=80   vidas
#   x=120  level
#   x=160  wave
#   x=200  inimigos restantes
#   x=260  boss_hp, se boss ativo
#
# Entrada: variaveis globais
# Saida: HUD desenhado no frame atual
# Modifica: t0, t1, a0-a4, a7
# ------------------------------------------------------------

draw_hud:
    # Sprite hook: HUD visual pode substituir os numeros.
    addi sp, sp, -8
    sw ra, 0(sp)

    call get_draw_base_address
    sw a0, 4(sp)

    la a0, label_pts
    li a1, 8
    li a2, 8
    li a3, COLOR_WHITE
    lw a4, 4(sp)
    call draw_small_text

    la t0, score
    lw a0, 0(t0)
    li a1, 26
    li a2, 8
    li a3, COLOR_WHITE
    lw a4, 4(sp)
    call draw_small_number

    la a0, label_hp
    li a1, 56
    li a2, 8
    li a3, COLOR_WHITE
    lw a4, 4(sp)
    call draw_small_text

    la t0, player_lives
    lw a0, 0(t0)
    li a1, 72
    li a2, 8
    li a3, COLOR_WHITE
    lw a4, 4(sp)
    call draw_small_number

    la a0, label_hp_max
    li a1, 76
    li a2, 8
    li a3, COLOR_WHITE
    lw a4, 4(sp)
    call draw_small_text

    la a0, label_fase
    li a1, 110
    li a2, 8
    li a3, COLOR_WHITE
    lw a4, 4(sp)
    call draw_small_text

    la t0, current_level
    lw a0, 0(t0)
    li a1, 132
    li a2, 8
    li a3, COLOR_WHITE
    lw a4, 4(sp)
    call draw_small_number

    la a0, label_wave
    li a1, 158
    li a2, 8
    li a3, COLOR_WHITE
    lw a4, 4(sp)
    call draw_small_text

    la t0, current_wave
    lw a0, 0(t0)
    li a1, 180
    li a2, 8
    li a3, COLOR_WHITE
    lw a4, 4(sp)
    call draw_small_number

    la a0, label_rest
    li a1, 206
    li a2, 8
    li a3, COLOR_WHITE
    lw a4, 4(sp)
    call draw_small_text

    la t0, remaining_enemies
    lw a0, 0(t0)
    li a1, 228
    li a2, 8
    li a3, COLOR_WHITE
    lw a4, 4(sp)
    call draw_small_number

    la t0, boss_active
    lw t2, 0(t0)
    beqz t2, end_draw_hud

    la a0, label_boss
    li a1, 260
    li a2, 8
    li a3, COLOR_WHITE
    lw a4, 4(sp)
    call draw_small_text

    la t0, boss_hp
    lw a0, 0(t0)
    li a1, 282
    li a2, 8
    li a3, COLOR_WHITE
    lw a4, 4(sp)
    call draw_small_number

end_draw_hud:
    lw ra, 0(sp)
    addi sp, sp, 8
    ret
