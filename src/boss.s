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

    call move_boss
    call update_boss_melee
    call update_boss_heavy_attack

end_update_boss:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

move_boss:
    la t0, boss_direction
    lw t1, 0(t0)

    li t2, DIR_RIGHT
    beq t1, t2, move_boss_right

    li t2, DIR_LEFT
    beq t1, t2, move_boss_left

    li t1, DIR_RIGHT
    sw t1, 0(t0)
    j move_boss_right

move_boss_right:
    la t0, boss_x
    lw t1, 0(t0)
    li t2, BOSS_SPEED
    add t1, t1, t2
    li t3, BOSS_MAX_X
    bgt t1, t3, clamp_boss_right
    sw t1, 0(t0)
    ret

clamp_boss_right:
    li t1, BOSS_MAX_X
    sw t1, 0(t0)
    la t0, boss_direction
    li t1, DIR_LEFT
    sw t1, 0(t0)
    ret

move_boss_left:
    la t0, boss_x
    lw t1, 0(t0)
    li t2, BOSS_SPEED
    sub t1, t1, t2
    li t3, BOSS_MIN_X
    blt t1, t3, clamp_boss_left
    sw t1, 0(t0)
    ret

clamp_boss_left:
    li t1, BOSS_MIN_X
    sw t1, 0(t0)
    la t0, boss_direction
    li t1, DIR_RIGHT
    sw t1, 0(t0)
    ret

update_boss_melee:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, boss_melee_timer
    lw t1, 0(t0)
    blez t1, check_boss_melee_range
    addi t1, t1, -1
    sw t1, 0(t0)
    j end_update_boss_melee

check_boss_melee_range:
    la t0, boss_x
    lw t1, 0(t0)
    la t0, player_x
    lw t2, 0(t0)
    sub t3, t1, t2
    bgez t3, boss_abs_dx_ok
    sub t3, zero, t3

boss_abs_dx_ok:
    la t0, boss_y
    lw t1, 0(t0)
    la t0, player_y
    lw t2, 0(t0)
    sub t4, t1, t2
    bgez t4, boss_abs_dy_ok
    sub t4, zero, t4

boss_abs_dy_ok:
    add t3, t3, t4
    li t5, BOSS_MELEE_RANGE
    bgt t3, t5, end_update_boss_melee

    la t0, player_lives
    lw t1, 0(t0)
    li t2, BOSS_MELEE_DAMAGE
    sub t1, t1, t2
    sw t1, 0(t0)

    la t0, boss_melee_timer
    li t2, BOSS_MELEE_COOLDOWN
    sw t2, 0(t0)

    blez t1, boss_melee_game_over
    j end_update_boss_melee

boss_melee_game_over:
    call set_state_game_over

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
    lw a0, 0(t0)
    addi a0, a0, 8

    la t0, boss_y
    lw a1, 0(t0)
    addi a1, a1, 16

    li a2, BOSS_HEAVY_PROJECTILE_DX
    li a3, BOSS_PROJECTILE_SPEED

    la t0, player_x
    lw t1, 0(t0)
    la t0, boss_x
    lw t2, 0(t0)
    addi t3, t2, -12
    blt t1, t3, boss_heavy_left
    addi t3, t2, 20
    bgt t1, t3, boss_heavy_right
    j boss_heavy_spawn

boss_heavy_left:
    li a2, -2
    li a3, 0
    j boss_heavy_spawn

boss_heavy_right:
    li a2, BOSS_PROJECTILE_SPEED
    li a3, 0

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
