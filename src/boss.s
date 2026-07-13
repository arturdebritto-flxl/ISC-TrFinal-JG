# ============================================================
# Logica do boss final
# ============================================================

.text

init_boss:
    la t0, boss_x
    li t1, BOSS_START_X
    sw t1, 0(t0)

    la t0, boss_y
    li t1, BOSS_START_Y
    sw t1, 0(t0)

    la t0, boss_hp
    li t1, BOSS_HP_START
    sw t1, 0(t0)

    la t0, boss_direction
    li t1, DIR_RIGHT
    sw t1, 0(t0)

    la t0, boss_attack_timer
    sw zero, 0(t0)

    la t0, boss_melee_timer
    sw zero, 0(t0)

    la t0, boss_heavy_timer
    sw zero, 0(t0)

    la t0, boss_active
    sw zero, 0(t0)

    ret

update_boss:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, boss_active
    lw t1, 0(t0)
    beqz t1, end_update_boss

    la t0, game_state
    lw t1, 0(t0)
    li t2, STATE_BOSS
    bne t1, t2, end_update_boss

    call update_boss_melee
    li t0, 1
    beq a0, t0, end_update_boss
    bnez a0, update_boss_ranged_attack

    call move_boss

update_boss_ranged_attack:
    call update_boss_heavy_attack

end_update_boss:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

move_boss:
    addi sp, sp, -4
    sw ra, 0(sp)

    # Persegue pelo centro em X. O helper testa limite e obstaculo sem
    # impedir a tentativa independente no eixo Y.
    la t0, boss_x
    lw t1, 0(t0)
    addi t1, t1, 16
    la t0, player_x
    lw t2, 0(t0)
    addi t2, t2, 8
    blt t1, t2, boss_chase_right
    bgt t1, t2, boss_chase_left
    j boss_chase_y

boss_chase_right:
    la t0, boss_x
    lw a0, 0(t0)
    addi a0, a0, BOSS_SPEED
    li a1, DIR_RIGHT
    call try_move_boss_x
    j boss_chase_y

boss_chase_left:
    la t0, boss_x
    lw a0, 0(t0)
    li t3, BOSS_SPEED
    sub a0, a0, t3
    li a1, DIR_LEFT
    call try_move_boss_x

boss_chase_y:
    la t0, boss_y
    lw t1, 0(t0)
    addi t1, t1, 16
    la t0, player_y
    lw t2, 0(t0)
    addi t2, t2, 8
    blt t1, t2, boss_chase_down
    bgt t1, t2, boss_chase_up
    j end_move_boss

boss_chase_down:
    la t0, boss_y
    lw a0, 0(t0)
    addi a0, a0, BOSS_SPEED
    call try_move_boss_y
    j end_move_boss

boss_chase_up:
    la t0, boss_y
    lw a0, 0(t0)
    li t3, BOSS_SPEED
    sub a0, a0, t3
    call try_move_boss_y

end_move_boss:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

try_move_boss_x:
    addi sp, sp, -12
    sw ra, 0(sp)
    sw a0, 4(sp)
    sw a1, 8(sp)
    li t0, BOSS_MIN_X
    blt a0, t0, block_try_move_boss_x
    li t0, BOSS_MAX_X
    bgt a0, t0, block_try_move_boss_x
    la t0, boss_y
    lw a1, 0(t0)
    li a4, BOSS_SIZE
    call is_position_blocked
    bnez a0, block_try_move_boss_x
    lw t1, 4(sp)
    la t0, boss_x
    sw t1, 0(t0)
    lw t1, 8(sp)
    la t0, boss_direction
    sw t1, 0(t0)
    li a0, 1
    j end_try_move_boss_x

block_try_move_boss_x:
    li a0, 0

end_try_move_boss_x:
    lw ra, 0(sp)
    addi sp, sp, 12
    ret

try_move_boss_y:
    addi sp, sp, -8
    sw ra, 0(sp)
    sw a0, 4(sp)
    li t0, BOSS_MIN_Y
    blt a0, t0, block_try_move_boss_y
    li t0, BOSS_MAX_Y
    bgt a0, t0, block_try_move_boss_y
    mv a1, a0
    la t0, boss_x
    lw a0, 0(t0)
    li a4, BOSS_SIZE
    call is_position_blocked
    bnez a0, block_try_move_boss_y
    lw t1, 4(sp)
    la t0, boss_y
    sw t1, 0(t0)
    li a0, 1
    j end_try_move_boss_y

block_try_move_boss_y:
    li a0, 0

end_try_move_boss_y:
    lw ra, 0(sp)
    addi sp, sp, 8
    ret

update_boss_melee:
    addi sp, sp, -4
    sw ra, 0(sp)
    li a0, 0

    la t0, boss_active
    lw t1, 0(t0)
    beqz t1, end_update_boss_melee

    la t0, game_state
    lw t1, 0(t0)
    li t2, STATE_BOSS
    bne t1, t2, end_update_boss_melee

    la t0, boss_melee_timer
    lw t6, 0(t0)
    blez t6, check_boss_melee_range
    addi t6, t6, -1
    sw t6, 0(t0)

check_boss_melee_range:
    la t0, boss_x
    lw t1, 0(t0)
    la t0, player_x
    lw t2, 0(t0)
    li t5, BOSS_MELEE_RANGE
    sub t3, t1, t5
    addi t4, t2, PLAYER_SIZE
    ble t4, t3, end_update_boss_melee
    addi t3, t1, BOSS_SIZE
    add t3, t3, t5
    bge t2, t3, end_update_boss_melee

    la t0, boss_y
    lw t1, 0(t0)
    la t0, player_y
    lw t2, 0(t0)
    sub t3, t1, t5
    addi t4, t2, PLAYER_SIZE
    ble t4, t3, end_update_boss_melee
    addi t3, t1, BOSS_SIZE
    add t3, t3, t5
    bge t2, t3, end_update_boss_melee

    bnez t6, boss_melee_in_range_cooldown

    la t0, player_lives
    lw t1, 0(t0)
    li t2, BOSS_MELEE_DAMAGE
    sub t1, t1, t2
    sw t1, 0(t0)

    la t0, boss_melee_timer
    li t2, BOSS_MELEE_COOLDOWN
    sw t2, 0(t0)
    li a0, 1

    blez t1, boss_melee_game_over
    j end_update_boss_melee

boss_melee_in_range_cooldown:
    li a0, 2
    j end_update_boss_melee

boss_melee_game_over:
    call set_state_game_over
    li a0, 1

end_update_boss_melee:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

update_boss_heavy_attack:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, boss_heavy_timer
    lw t1, 0(t0)
    addi t1, t1, 1
    li t2, BOSS_HEAVY_SHOOT_DELAY
    blt t1, t2, store_boss_heavy_timer

    sw zero, 0(t0)

    la t0, boss_x
    lw t5, 0(t0)
    addi t5, t5, 16

    la t0, boss_y
    lw t6, 0(t0)
    addi t6, t6, 16

    la t0, player_x
    lw a2, 0(t0)
    addi a2, a2, 8
    sub a2, a2, t5
    la t0, player_y
    lw a3, 0(t0)
    addi a3, a3, 8
    sub a3, a3, t6

    mv t0, a2
    bgez t0, boss_heavy_dx_abs_ok
    sub t0, zero, t0

boss_heavy_dx_abs_ok:
    mv a4, a3
    bgez a4, boss_heavy_dy_abs_ok
    sub a4, zero, a4

boss_heavy_dy_abs_ok:
    bge t0, a4, boss_heavy_max_ready
    mv t0, a4

boss_heavy_max_ready:
    bnez t0, boss_heavy_normalize
    li a2, 1
    li a3, 0
    li t0, 1

boss_heavy_normalize:
    li t2, BOSS_PROJECTILE_SPEED
    mul a2, a2, t2
    div a2, a2, t0
    mul a3, a3, t2
    div a3, a3, t0

    addi a0, t5, -3
    addi a1, t6, -3

boss_heavy_spawn:
    li a4, ENEMY_PROJECTILE_BOSS_HEAVY
    call spawn_enemy_bullet_typed
    j end_update_boss_heavy_attack

store_boss_heavy_timer:
    sw t1, 0(t0)

end_update_boss_heavy_attack:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret
