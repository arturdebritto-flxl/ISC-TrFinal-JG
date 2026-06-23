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

    la t0, player_lives
    li t1, PLAYER_MAX_LIVES
    sw t1, 0(t0)

    la t0, player_moved
    sw zero, 0(t0)

    la t0, player_move_direction
    li t1, DIR_DOWN
    sw t1, 0(t0)

    la t0, player_move_hold_timer
    sw zero, 0(t0)

    ret

update_player:
    addi sp, sp, -12
    sw ra, 0(sp)

    la t0, player_moved
    sw zero, 0(t0)

    la t0, key_pressed
    lw t1, 0(t0)
    beqz t1, apply_move_buffer

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

    j apply_move_buffer

buffer_move_up:
    li t1, DIR_UP
    j store_move_buffer

buffer_move_down:
    li t1, DIR_DOWN
    j store_move_buffer

buffer_move_left:
    li t1, DIR_LEFT
    j store_move_buffer

buffer_move_right:
    li t1, DIR_RIGHT

store_move_buffer:
    la t0, player_move_direction
    sw t1, 0(t0)

    la t0, player_direction
    sw t1, 0(t0)

    la t0, player_move_hold_timer
    li t2, PLAYER_MOVE_HOLD_FRAMES
    sw t2, 0(t0)

apply_move_buffer:
    la t0, player_move_hold_timer
    lw t1, 0(t0)
    blez t1, end_update_player

    addi t1, t1, -1
    sw t1, 0(t0)

    la t0, player_move_direction
    lw t1, 0(t0)

    li t2, DIR_UP
    beq t1, t2, move_player_up

    li t2, DIR_DOWN
    beq t1, t2, move_player_down

    li t2, DIR_LEFT
    beq t1, t2, move_player_left

    li t2, DIR_RIGHT
    beq t1, t2, move_player_right

    j end_update_player

move_player_up:
    la t0, player_y
    lw t1, 0(t0)
    li t2, PLAYER_SMOOTH_SPEED
    sub t1, t1, t2

    li t3, PLAYER_MIN_Y
    blt t1, t3, clamp_player_y_min
    j try_store_player_y

clamp_player_y_min:
    li t1, PLAYER_MIN_Y
    j try_store_player_y

move_player_down:
    la t0, player_y
    lw t1, 0(t0)
    li t2, PLAYER_SMOOTH_SPEED
    add t1, t1, t2

    li t3, PLAYER_MAX_Y
    bgt t1, t3, clamp_player_y_max
    j try_store_player_y

clamp_player_y_max:
    li t1, PLAYER_MAX_Y
    j try_store_player_y

try_store_player_y:
    sw t0, 4(sp)
    sw t1, 8(sp)

    la t2, player_x
    lw a0, 0(t2)
    mv a1, t1
    call is_player_position_blocked

    lw t0, 4(sp)
    lw t1, 8(sp)
    bnez a0, end_update_player

    sw t1, 0(t0)
    j mark_player_moved

move_player_left:
    la t0, player_x
    lw t1, 0(t0)
    li t2, PLAYER_SMOOTH_SPEED
    sub t1, t1, t2

    li t3, PLAYER_MIN_X
    blt t1, t3, clamp_player_x_min
    j try_store_player_x

clamp_player_x_min:
    li t1, PLAYER_MIN_X
    j try_store_player_x

move_player_right:
    la t0, player_x
    lw t1, 0(t0)
    li t2, PLAYER_SMOOTH_SPEED
    add t1, t1, t2

    li t3, PLAYER_MAX_X
    bgt t1, t3, clamp_player_x_max
    j try_store_player_x

clamp_player_x_max:
    li t1, PLAYER_MAX_X
    j try_store_player_x

try_store_player_x:
    sw t0, 4(sp)
    sw t1, 8(sp)

    mv a0, t1
    la t2, player_y
    lw a1, 0(t2)
    call is_player_position_blocked

    lw t0, 4(sp)
    lw t1, 8(sp)
    bnez a0, end_update_player

    sw t1, 0(t0)

mark_player_moved:
    la t0, player_moved
    li t1, 1
    sw t1, 0(t0)

    la t0, noise_timer
    lw t1, 0(t0)
    li t2, NOISE_MOVE_FRAMES
    bge t1, t2, end_update_player
    sw t2, 0(t0)

end_update_player:
    lw ra, 0(sp)
    addi sp, sp, 12
    ret

is_player_position_blocked:
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
    li t0, 72
    li t1, 68
    li t2, 64
    li t3, 10
    jal zero, check_obstacle_rect

check_town_obstacle_2:
    li t0, 184
    li t1, 152
    li t2, 64
    li t3, 10
    jal zero, check_obstacle_rect

check_town_obstacles_done:
    mv a0, zero
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
    li t4, PLAYER_SIZE
    add t5, a0, t4
    ble t5, t0, next_obstacle_rect

    add t5, t0, t2
    bge a0, t5, next_obstacle_rect

    li t4, PLAYER_SIZE
    add t5, a1, t4
    ble t5, t1, next_obstacle_rect

    add t5, t1, t3
    bge a1, t5, next_obstacle_rect

    li a0, 1
    ret

next_obstacle_rect:
    la t4, current_level
    lw t5, 0(t4)

    li t4, LEVEL_TOWN
    beq t5, t4, route_next_town_obstacle

    li t4, LEVEL_SEWER
    beq t5, t4, route_next_sewer_obstacle

    li t4, LEVEL_LABORATORY
    beq t5, t4, route_next_laboratory_obstacle

    mv a0, zero
    ret

route_next_town_obstacle:
    li t4, 72
    beq t0, t4, check_town_obstacle_2
    j check_town_obstacles_done

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
