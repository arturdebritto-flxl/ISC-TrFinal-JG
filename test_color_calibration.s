# ============================================================
# Teste visual isolado da codificacao de cores do Bitmap Display
# RARS16_Custom1.
#
# Formato comprovado no bytecode do display: BBGGGRRR (BGR233).
# Este arquivo nao faz parte do fluxo normal do jogo.
#
# Bitmap Display:
#   base:        0xFF000000 (frame 0)
#   resolucao:   320 x 240
#   unidade:     1 x 1
#
# Linha superior, da esquerda para a direita:
#   vermelho, verde, azul, branco, cinza
# Linha inferior:
#   amarelo, ciano, magenta, preto opaco, transparente
#
# O ultimo swatch recebe o marcador transparente 0x00 e portanto
# nao escreve pixels: o padrao branco/cinza preparado antes deve
# continuar visivel.
# ============================================================

.eqv FRAMEBUFFER0, 0xFF000000
.eqv SCREEN_WIDTH, 320
.eqv SCREEN_PIXELS, 76800
.eqv SWATCH_SIZE, 40

.text
.globl main

main:
    # Fundo azul-acinzentado escuro para separar os swatches.
    li t0, FRAMEBUFFER0
    li t1, SCREEN_PIXELS
    li t2, 0x49

clear_loop:
    beqz t1, prepare_transparent_checker
    sb t2, 0(t0)
    addi t0, t0, 1
    addi t1, t1, -1
    j clear_loop

prepare_transparent_checker:
    # Padrao sob o swatch transparente: cinza com centro branco.
    li a0, 240
    li a1, 120
    li a2, 0xA4
    li a3, SWATCH_SIZE
    li a4, SWATCH_SIZE
    call fill_rect

    li a0, 250
    li a1, 130
    li a2, 0xFF
    li a3, 20
    li a4, 20
    call fill_rect

    # Linha 1: R, G, B, branco, cinza.
    li a0, 16
    li a1, 40
    li a2, 0x07               # RGB esperado: (255, 0, 0)
    call draw_color_swatch

    li a0, 72
    li a1, 40
    li a2, 0x38               # RGB esperado: (0, 255, 0)
    call draw_color_swatch

    li a0, 128
    li a1, 40
    li a2, 0xC0               # RGB esperado: (0, 0, 255)
    call draw_color_swatch

    li a0, 184
    li a1, 40
    li a2, 0xFF               # RGB esperado: (255, 255, 255)
    call draw_color_swatch

    li a0, 240
    li a1, 40
    li a2, 0xA4               # RGB quantizado: (146, 146, 170)
    call draw_color_swatch

    # Linha 2: amarelo, ciano, magenta, preto, transparente.
    li a0, 16
    li a1, 120
    li a2, 0x3F               # RGB esperado: (255, 255, 0)
    call draw_color_swatch

    li a0, 72
    li a1, 120
    li a2, 0xF8               # RGB esperado: (0, 255, 255)
    call draw_color_swatch

    li a0, 128
    li a1, 120
    li a2, 0xC7               # RGB esperado: (255, 0, 255)
    call draw_color_swatch

    li a0, 184
    li a1, 120
    li a2, 0x01               # preto opaco reservado: (36, 0, 0)
    call draw_color_swatch

    li a0, 240
    li a1, 120
    li a2, 0x00               # transparente: nao escreve
    call draw_color_swatch

    li a7, 10
    ecall

# a0=x, a1=y, a2=byte BGR233. Zero e o marcador transparente.
draw_color_swatch:
    beqz a2, draw_color_swatch_end
    li a3, SWATCH_SIZE
    li a4, SWATCH_SIZE
    j fill_rect

draw_color_swatch_end:
    ret

# a0=x, a1=y, a2=cor, a3=largura, a4=altura.
# Escreve um byte por pixel diretamente no frame 0.
fill_rect:
    li t0, SCREEN_WIDTH
    mul t1, a1, t0
    add t1, t1, a0
    li t2, FRAMEBUFFER0
    add t1, t1, t2
    li t3, 0

fill_rect_row_loop:
    beq t3, a4, fill_rect_end
    mv t4, t1
    li t5, 0

fill_rect_col_loop:
    beq t5, a3, fill_rect_next_row
    sb a2, 0(t4)
    addi t4, t4, 1
    addi t5, t5, 1
    j fill_rect_col_loop

fill_rect_next_row:
    addi t3, t3, 1
    add t1, t1, t0
    j fill_rect_row_loop

fill_rect_end:
    ret
