# ============================================================
# Logica do jogador
# ============================================================

.text

init_player:
    la t0, player_x
    li t1, PLAYER_START_X
    sw t1, 0(t0)

    la t0, player_y
    li t1, PLAYER_START_Y
    sw t1, 0(t0)

    la t0, player_direction
    li t1, DIR_DOWN
    sw t1, 0(t0)

    la t0, player_move_facing_direction
    sw t1, 0(t0)

    la t0, player_lives
    li t1, PLAYER_MAX_LIVES
    sw t1, 0(t0)

    la t0, player_moved
    sw zero, 0(t0)

    la t0, move_x_direction
    sw zero, 0(t0)

    la t0, move_x_timer
    sw zero, 0(t0)

    la t0, move_y_direction
    sw zero, 0(t0)

    la t0, move_y_timer
    sw zero, 0(t0)

    ret

update_player:
    addi sp, sp, -16
    sw ra, 0(sp)

    la t0, player_moved
    sw zero, 0(t0)

    la t0, key_pressed
    lw t1, 0(t0)
    beqz t1, apply_axis_buffers

    la t0, last_key
    lw t1, 0(t0)
    li t2, 'w'
    beq t1, t2, buffer_move_up
    li t2, 's'
    beq t1, t2, buffer_move_down
    li t2, 'a'
    beq t1, t2, buffer_move_left
    li t2, 'd'
    beq t1, t2, buffer_move_right
    j apply_axis_buffers

buffer_move_up:
    la t0, move_y_direction
    li t1, -1
    sw t1, 0(t0)
    la t0, move_y_timer
    li t1, MOVE_AXIS_BUFFER_FRAMES
    sw t1, 0(t0)
    li t1, DIR_UP
    j store_move_facing

buffer_move_down:
    la t0, move_y_direction
    li t1, 1
    sw t1, 0(t0)
    la t0, move_y_timer
    li t1, MOVE_AXIS_BUFFER_FRAMES
    sw t1, 0(t0)
    li t1, DIR_DOWN
    j store_move_facing

buffer_move_left:
    la t0, move_x_direction
    li t1, -1
    sw t1, 0(t0)
    la t0, move_x_timer
    li t1, MOVE_AXIS_BUFFER_FRAMES
    sw t1, 0(t0)
    li t1, DIR_LEFT
    j store_move_facing

buffer_move_right:
    la t0, move_x_direction
    li t1, 1
    sw t1, 0(t0)
    la t0, move_x_timer
    li t1, MOVE_AXIS_BUFFER_FRAMES
    sw t1, 0(t0)
    li t1, DIR_RIGHT

store_move_facing:
    la t0, player_move_facing_direction
    sw t1, 0(t0)
    la t0, player_direction
    sw t1, 0(t0)

apply_axis_buffers:
    # Movimento cardinal usa 3 px; diagonal usa 2 px por eixo.
    li t3, PLAYER_SMOOTH_SPEED
    la t0, move_x_timer
    lw t1, 0(t0)
    la t0, move_y_timer
    lw t2, 0(t0)
    blez t1, store_axis_step
    blez t2, store_axis_step
    li t3, 2

store_axis_step:
    sw t3, 4(sp)

    # X e validado primeiro; bloqueio nao impede a tentativa em Y.
    la t0, move_x_timer
    lw t1, 0(t0)
    blez t1, try_move_y_axis
    addi t1, t1, -1
    sw t1, 0(t0)
    la t0, move_x_direction
    lw t2, 0(t0)
    beqz t2, try_move_y_axis
    la t0, player_x
    lw t1, 0(t0)
    lw t3, 4(sp)
    bltz t2, apply_x_left
    add t1, t1, t3
    j clamp_x_candidate

apply_x_left:
    sub t1, t1, t3

clamp_x_candidate:
    li t3, PLAYER_MIN_X
    bge t1, t3, check_x_max
    mv t1, t3
check_x_max:
    li t3, PLAYER_MAX_X
    ble t1, t3, test_x_collision
    mv t1, t3
test_x_collision:
    sw t1, 8(sp)
    mv a0, t1
    la t0, player_y
    lw a1, 0(t0)
    call is_player_position_blocked
    bnez a0, try_move_y_axis
    lw t1, 8(sp)
    la t0, player_x
    sw t1, 0(t0)
    la t0, player_moved
    li t1, 1
    sw t1, 0(t0)

try_move_y_axis:
    la t0, move_y_timer
    lw t1, 0(t0)
    blez t1, finish_player_movement
    addi t1, t1, -1
    sw t1, 0(t0)
    la t0, move_y_direction
    lw t2, 0(t0)
    beqz t2, finish_player_movement
    la t0, player_y
    lw t1, 0(t0)
    lw t3, 4(sp)
    bltz t2, apply_y_up
    add t1, t1, t3
    j clamp_y_candidate

apply_y_up:
    sub t1, t1, t3

clamp_y_candidate:
    li t3, PLAYER_MIN_Y
    bge t1, t3, check_y_max
    mv t1, t3
check_y_max:
    li t3, PLAYER_MAX_Y
    ble t1, t3, test_y_collision
    mv t1, t3
test_y_collision:
    sw t1, 12(sp)
    la t0, player_x
    lw a0, 0(t0)
    mv a1, t1
    call is_player_position_blocked
    bnez a0, finish_player_movement
    lw t1, 12(sp)
    la t0, player_y
    sw t1, 0(t0)
    la t0, player_moved
    li t1, 1
    sw t1, 0(t0)

finish_player_movement:
    la t0, player_moved
    lw t1, 0(t0)
    beqz t1, end_update_player
    la t0, noise_timer
    lw t1, 0(t0)
    li t2, NOISE_MOVE_FRAMES
    bge t1, t2, end_update_player
    sw t2, 0(t0)

end_update_player:
    lw ra, 0(sp)
    addi sp, sp, 16
    ret

# ------------------------------------------------------------
# update_player_facing_direction
# Prioridade visual: tiro ativo, movimento no frame, ultima direcao.
# Deve ser chamada depois de update_player e antes de consumir o
# shoot_hold_timer do frame atual.
# ------------------------------------------------------------

update_player_facing_direction:
    la t0, player_burst_remaining
    lw t1, 0(t0)
    bgtz t1, face_burst_direction

    la t0, shoot_request_pending
    lw t1, 0(t0)
    bgtz t1, face_shoot_direction

    la t0, player_moved
    lw t1, 0(t0)
    beqz t1, end_update_player_facing_direction
    la t0, player_move_facing_direction
    lw t1, 0(t0)
    j store_player_facing_direction

face_burst_direction:
    la t0, player_burst_direction
    lw t1, 0(t0)
    j store_player_facing_direction

face_shoot_direction:
    la t0, shoot_direction
    lw t1, 0(t0)

store_player_facing_direction:
    la t0, player_direction
    sw t1, 0(t0)

end_update_player_facing_direction:
    ret

is_player_position_blocked:
    li a4, PLAYER_SIZE
    j is_position_blocked

is_enemy_position_blocked:
    li a4, ENEMY_SIZE

is_position_blocked:
    la t0, current_level
    lw t1, 0(t0)

    li t2, LEVEL_TOWN
    beq t1, t2, check_town_player_obstacles

    li t2, LEVEL_SEWER
    beq t1, t2, check_sewer_player_obstacles

    li t2, LEVEL_LABORATORY
    beq t1, t2, check_laboratory_player_obstacles

    mv a0, zero
    ret

check_town_player_obstacles:
    addi sp, sp, -16
    sw ra, 0(sp)
    sw a0, 4(sp)
    sw a1, 8(sp)
    sw a4, 12(sp)
    add a2, a0, a4
    add a3, a1, a4
    call is_town_external_rect_blocked
    bnez a0, check_town_obstacle_blocked
    lw a0, 4(sp)
    lw a1, 8(sp)
    lw a4, 12(sp)
    la t6, town_collision_aabbs
    li t4, TOWN_COLLISION_AABB_COUNT

check_town_obstacle_loop:
    beqz t4, check_town_obstacles_done
    lw t0, 0(t6)
    lw t1, 4(t6)
    lw t2, 8(t6)
    lw t3, 12(t6)

    add t5, a0, a4
    ble t5, t0, next_town_obstacle
    bge a0, t2, next_town_obstacle
    add t5, a1, a4
    ble t5, t1, next_town_obstacle
    bge a1, t3, next_town_obstacle

check_town_obstacle_blocked:
    li a0, 1
    j finish_check_town_obstacles

next_town_obstacle:
    addi t6, t6, 16
    addi t4, t4, -1
    j check_town_obstacle_loop

check_town_obstacles_done:
    mv a0, zero
finish_check_town_obstacles:
    lw ra, 0(sp)
    addi sp, sp, 16
    ret

# Limites externos do Town, fora da tabela interna. Os segmentos em
# cantos e degraus se sobrepoem em 2 pixels.
# Entrada: a0=x0, a1=y0, a2=x1, a3=y1. Retorno: a0=1 se bloqueado.
is_town_external_rect_blocked:
    bltz a0, town_external_rect_blocked
    bltz a1, town_external_rect_blocked
    li t0, SCREEN_WIDTH
    bgt a2, t0, town_external_rect_blocked
    li t0, SCREEN_HEIGHT
    bgt a3, t0, town_external_rect_blocked

    # [0,134) x [0,9)
    li t2, 134
    ble a2, zero, town_external_rect_2
    bge a0, t2, town_external_rect_2
    li t1, 9
    ble a3, zero, town_external_rect_2
    blt a1, t1, town_external_rect_blocked
town_external_rect_2:
    # [0,35) x [7,19)
    li t2, 35
    ble a2, zero, town_external_rect_3
    bge a0, t2, town_external_rect_3
    li t1, 7
    ble a3, t1, town_external_rect_3
    li t3, 19
    blt a1, t3, town_external_rect_blocked
town_external_rect_3:
    # [0,19) x [17,28)
    li t2, 19
    ble a2, zero, town_external_rect_4
    bge a0, t2, town_external_rect_4
    li t1, 17
    ble a3, t1, town_external_rect_4
    li t3, 28
    blt a1, t3, town_external_rect_blocked
town_external_rect_4:
    # [0,9) x [26,77)
    li t2, 9
    ble a2, zero, town_external_rect_5
    bge a0, t2, town_external_rect_5
    li t1, 26
    ble a3, t1, town_external_rect_5
    li t3, 77
    blt a1, t3, town_external_rect_blocked
town_external_rect_5:
    # [190,320) x [0,9)
    li t0, 190
    ble a2, t0, town_external_rect_6
    li t1, 9
    ble a3, zero, town_external_rect_6
    blt a1, t1, town_external_rect_blocked
town_external_rect_6:
    # [305,320) x [7,113)
    li t0, 305
    ble a2, t0, town_external_rect_7
    li t1, 7
    ble a3, t1, town_external_rect_7
    li t3, 113
    blt a1, t3, town_external_rect_blocked
town_external_rect_7:
    # [0,9) x [137,230)
    li t2, 9
    ble a2, zero, town_external_rect_8
    bge a0, t2, town_external_rect_8
    li t1, 137
    ble a3, t1, town_external_rect_8
    li t3, 230
    blt a1, t3, town_external_rect_blocked
town_external_rect_8:
    # [0,123) x [228,240)
    li t2, 123
    ble a2, zero, town_external_rect_9
    bge a0, t2, town_external_rect_9
    li t1, 228
    ble a3, t1, town_external_rect_9
    li t3, 240
    blt a1, t3, town_external_rect_blocked
town_external_rect_9:
    # [305,320) x [153,230)
    li t0, 305
    ble a2, t0, town_external_rect_10
    li t1, 153
    ble a3, t1, town_external_rect_10
    li t3, 230
    blt a1, t3, town_external_rect_blocked
town_external_rect_10:
    # [189,320) x [228,240)
    li t0, 189
    ble a2, t0, town_external_rect_clear
    li t1, 228
    ble a3, t1, town_external_rect_clear
    li t3, 240
    blt a1, t3, town_external_rect_blocked

town_external_rect_clear:
    mv a0, zero
    ret
town_external_rect_blocked:
    li a0, 1
    ret

# Movimento swept compartilhado por todos os projeteis do Town.
# Entrada: a0=x, a1=y, a2=dx, a3=dy, a4=tamanho.
# Retorno: a0=1 se todo o segmento estiver livre; a0=0 no impacto.
move_town_projectile_swept:
    addi sp, sp, -56
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    sw s3, 16(sp)
    sw s4, 20(sp)
    sw s5, 24(sp)
    sw s6, 28(sp)
    sw s7, 32(sp)
    sw s8, 36(sp)
    sw s9, 40(sp)
    sw s10, 44(sp)
    sw s11, 48(sp)
    mv s0, a0
    mv s1, a1
    mv s2, a2
    mv s3, a3
    mv s4, a4
    add s5, s0, s2
    add s6, s1, s3

    mv s7, s0
    mv s8, s5
    ble s7, s8, town_swept_x_ordered
    mv s7, s5
    mv s8, s0
town_swept_x_ordered:
    add s8, s8, s4
    mv s9, s1
    mv s10, s6
    ble s9, s10, town_swept_y_ordered
    mv s9, s6
    mv s10, s1
town_swept_y_ordered:
    add s10, s10, s4

    mv a0, s7
    mv a1, s9
    mv a2, s8
    mv a3, s10
    call is_town_external_rect_blocked
    sw a0, 52(sp)

    li s11, 0
    la t6, town_collision_aabbs
    li t5, 0
town_projectile_broad_phase_loop:
    li t4, TOWN_COLLISION_AABB_COUNT
    bge t5, t4, town_projectile_broad_phase_done
    lw a0, 0(t6)
    lw a1, 4(t6)
    lw a2, 8(t6)
    lw a3, 12(t6)
    ble s8, a0, town_projectile_next_broad_candidate
    bge s7, a2, town_projectile_next_broad_candidate
    ble s10, a1, town_projectile_next_broad_candidate
    bge s9, a3, town_projectile_next_broad_candidate
    li t4, 1
    sll t4, t4, t5
    or s11, s11, t4
town_projectile_next_broad_candidate:
    addi t6, t6, 16
    addi t5, t5, 1
    j town_projectile_broad_phase_loop

town_projectile_broad_phase_done:
    lw t0, 52(sp)
    or t0, t0, s11
    beqz t0, town_projectile_path_clear

    mv s7, s2
    bgez s7, town_projectile_abs_dx_ready
    sub s7, zero, s7
town_projectile_abs_dx_ready:
    mv t0, s3
    bgez t0, town_projectile_abs_dy_ready
    sub t0, zero, t0
town_projectile_abs_dy_ready:
    bge s7, t0, town_projectile_step_count_ready
    mv s7, t0
town_projectile_step_count_ready:
    beqz s7, town_projectile_path_clear
    li s8, 1

town_projectile_substep_loop:
    mul s9, s2, s8
    div s9, s9, s7
    add s9, s0, s9
    mul s10, s3, s8
    div s10, s10, s7
    add s10, s1, s10

    mv a0, s9
    mv a1, s10
    add a2, s9, s4
    add a3, s10, s4
    call is_town_external_rect_blocked
    bnez a0, town_projectile_path_blocked

    la t6, town_collision_aabbs
    li t5, 0
town_projectile_candidate_substep_loop:
    li t4, TOWN_COLLISION_AABB_COUNT
    bge t5, t4, town_projectile_next_substep
    li t4, 1
    sll t4, t4, t5
    and t4, t4, s11
    beqz t4, town_projectile_skip_narrow_candidate
    lw a0, 0(t6)
    lw a1, 4(t6)
    lw a2, 8(t6)
    lw a3, 12(t6)
    add t0, s9, s4
    ble t0, a0, town_projectile_skip_narrow_candidate
    bge s9, a2, town_projectile_skip_narrow_candidate
    add t0, s10, s4
    ble t0, a1, town_projectile_skip_narrow_candidate
    bge s10, a3, town_projectile_skip_narrow_candidate
    j town_projectile_path_blocked
town_projectile_skip_narrow_candidate:
    addi t6, t6, 16
    addi t5, t5, 1
    j town_projectile_candidate_substep_loop

town_projectile_next_substep:
    addi s8, s8, 1
    ble s8, s7, town_projectile_substep_loop

town_projectile_path_clear:
    li a0, 1
    j finish_move_town_projectile_swept
town_projectile_path_blocked:
    mv a0, zero
finish_move_town_projectile_swept:
    lw s11, 48(sp)
    lw s10, 44(sp)
    lw s9, 40(sp)
    lw s8, 36(sp)
    lw s7, 32(sp)
    lw s6, 28(sp)
    lw s5, 24(sp)
    lw s4, 20(sp)
    lw s3, 16(sp)
    lw s2, 12(sp)
    lw s1, 8(sp)
    lw s0, 4(sp)
    lw ra, 0(sp)
    addi sp, sp, 56
    ret

check_sewer_player_obstacles:
    li t0, 96
    li t1, 44
    li t2, 12
    li t3, 76
    jal zero, check_obstacle_rect

check_sewer_obstacle_2:
    li t0, 212
    li t1, 118
    li t2, 12
    li t3, 76
    jal zero, check_obstacle_rect

check_sewer_obstacles_done:
    mv a0, zero
    ret

check_laboratory_player_obstacles:
    li t0, 144
    li t1, 88
    li t2, 40
    li t3, 36
    jal zero, check_obstacle_rect

check_laboratory_obstacle_2:
    li t0, 40
    li t1, 58
    li t2, 72
    li t3, 10
    jal zero, check_obstacle_rect

check_laboratory_obstacle_3:
    li t0, 208
    li t1, 172
    li t2, 72
    li t3, 10
    jal zero, check_obstacle_rect

check_laboratory_obstacles_done:
    mv a0, zero
    ret

check_obstacle_rect:
    add t5, a0, a4
    ble t5, t0, next_obstacle_rect

    add t5, t0, t2
    bge a0, t5, next_obstacle_rect

    add t5, a1, a4
    ble t5, t1, next_obstacle_rect

    add t5, t1, t3
    bge a1, t5, next_obstacle_rect

    li a0, 1
    ret

next_obstacle_rect:
    la t4, current_level
    lw t5, 0(t4)

    li t4, LEVEL_SEWER
    beq t5, t4, route_next_sewer_obstacle

    li t4, LEVEL_LABORATORY
    beq t5, t4, route_next_laboratory_obstacle

    mv a0, zero
    ret

route_next_sewer_obstacle:
    li t4, 96
    beq t0, t4, check_sewer_obstacle_2
    j check_sewer_obstacles_done

route_next_laboratory_obstacle:
    li t4, 144
    beq t0, t4, check_laboratory_obstacle_2
    li t4, 40
    beq t0, t4, check_laboratory_obstacle_3
    j check_laboratory_obstacles_done
