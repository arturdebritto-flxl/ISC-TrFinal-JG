# ============================================================
# Power-ups coletaveis
# ============================================================

.text

init_powerups:
    li t1, 0

init_powerups_loop:
    li t2, MAX_POWERUPS
    beq t1, t2, end_init_powerups

    slli t3, t1, 2
    la t0, powerup_active
    add t4, t0, t3
    sw zero, 0(t4)

    addi t1, t1, 1
    j init_powerups_loop

end_init_powerups:
    la t0, enemy_kill_counter
    sw zero, 0(t0)

    la t0, boss_weapon_spawned
    sw zero, 0(t0)

    la t0, boss_ammo_timer
    sw zero, 0(t0)

    ret

spawn_powerup_at:
    li t1, 0

find_free_powerup_loop:
    li t2, MAX_POWERUPS
    beq t1, t2, end_spawn_powerup_at

    slli t3, t1, 2

    la t0, powerup_active
    add t4, t0, t3
    lw t5, 0(t4)
    beqz t5, create_powerup_here

    addi t1, t1, 1
    j find_free_powerup_loop

create_powerup_here:
    li t5, 1
    sw t5, 0(t4)

    la t0, powerup_x
    add t4, t0, t3
    sw a0, 0(t4)

    la t0, powerup_y
    add t4, t0, t3
    sw a1, 0(t4)

    la t0, powerup_type
    add t4, t0, t3
    sw a2, 0(t4)

end_spawn_powerup_at:
    ret

spawn_powerup_from_enemy_death:
    addi sp, sp, -12
    sw ra, 0(sp)
    sw a0, 4(sp)
    sw a1, 8(sp)

    la t0, enemy_kill_counter
    lw t1, 0(t0)
    addi t1, t1, 1
    sw t1, 0(t0)

    li t2, 5
    rem t3, t1, t2
    beqz t3, spawn_heal_from_kill

    li t2, 3
    rem t3, t1, t2
    beqz t3, spawn_ammo_from_kill

    j end_spawn_powerup_from_enemy_death

spawn_heal_from_kill:
    lw a0, 4(sp)
    lw a1, 8(sp)
    li a2, POWERUP_HEAL
    call spawn_powerup_at
    j end_spawn_powerup_from_enemy_death

spawn_ammo_from_kill:
    lw a0, 4(sp)
    lw a1, 8(sp)
    li a2, POWERUP_NORMAL_AMMO
    call spawn_powerup_at

end_spawn_powerup_from_enemy_death:
    lw ra, 0(sp)
    addi sp, sp, 12
    ret

spawn_boss_powerups:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, boss_weapon_spawned
    lw t1, 0(t0)
    bnez t1, end_spawn_boss_powerups

    li t1, 1
    sw t1, 0(t0)

    li a0, 136
    li a1, 96
    li a2, POWERUP_BOSS_WEAPON
    call spawn_powerup_at

    li a0, 176
    li a1, 96
    li a2, POWERUP_BOSS_AMMO
    call spawn_powerup_at

end_spawn_boss_powerups:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

update_powerups:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, game_state
    lw t1, 0(t0)
    li t2, STATE_BOSS
    bne t1, t2, end_update_powerups

    call spawn_boss_powerups

    la t0, boss_ammo_timer
    lw t1, 0(t0)
    addi t1, t1, 1
    li t2, 180
    blt t1, t2, store_boss_ammo_timer

    sw zero, 0(t0)
    li a0, 220
    li a1, 112
    li a2, POWERUP_BOSS_AMMO
    call spawn_powerup_at
    j end_update_powerups

store_boss_ammo_timer:
    sw t1, 0(t0)

end_update_powerups:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

check_player_powerup_collisions:
    li t1, 0

powerup_collision_loop:
    li t2, MAX_POWERUPS
    beq t1, t2, end_player_powerup_collisions

    slli t3, t1, 2

    la t0, powerup_active
    add t4, t0, t3
    lw t5, 0(t4)
    beqz t5, next_powerup_collision

    la t0, powerup_x
    add t4, t0, t3
    lw a0, 0(t4)

    la t0, powerup_y
    add t4, t0, t3
    lw a1, 0(t4)

    la t0, player_x
    lw a2, 0(t0)

    la t0, player_y
    lw a3, 0(t0)

    li t6, POWERUP_SIZE
    add a4, a0, t6
    ble a4, a2, next_powerup_collision

    li t6, PLAYER_SIZE
    add a4, a2, t6
    bge a0, a4, next_powerup_collision

    li t6, POWERUP_SIZE
    add a4, a1, t6
    ble a4, a3, next_powerup_collision

    li t6, PLAYER_SIZE
    add a4, a3, t6
    bge a1, a4, next_powerup_collision

    la t0, powerup_active
    add t4, t0, t3
    sw zero, 0(t4)

    la t0, powerup_type
    add t4, t0, t3
    lw t5, 0(t4)

    li t6, POWERUP_NORMAL_AMMO
    beq t5, t6, collect_normal_ammo

    li t6, POWERUP_HEAL
    beq t5, t6, collect_heal

    li t6, POWERUP_BOSS_WEAPON
    beq t5, t6, collect_boss_weapon

    li t6, POWERUP_BOSS_AMMO
    beq t5, t6, collect_boss_ammo

    j next_powerup_collision

collect_normal_ammo:
    la t0, normal_ammo_count
    lw t5, 0(t0)
    addi t5, t5, NORMAL_AMMO_GAIN
    sw t5, 0(t0)
    j play_powerup_collect_sfx

finish_collect_normal_ammo:
    j next_powerup_collision

collect_heal:
    la t0, heal_count
    lw t5, 0(t0)
    addi t5, t5, HEAL_GAIN
    sw t5, 0(t0)
    j play_powerup_collect_sfx

finish_collect_heal:
    j next_powerup_collision

collect_boss_weapon:
    la t0, weapon_type
    li t5, WEAPON_BOSS
    sw t5, 0(t0)

    la t0, boss_ammo_count
    lw t5, 0(t0)
    addi t5, t5, BOSS_AMMO_GAIN
    sw t5, 0(t0)
    j play_powerup_collect_sfx

finish_collect_boss_weapon:
    j next_powerup_collision

collect_boss_ammo:
    la t0, boss_ammo_count
    lw t5, 0(t0)
    addi t5, t5, BOSS_AMMO_GAIN
    sw t5, 0(t0)
    j play_powerup_collect_sfx

finish_collect_boss_ammo:
    j next_powerup_collision

play_powerup_collect_sfx:
    li a0, 84
    li a1, 70
    li a2, 10
    li a3, 80
    li a7, 31
    ecall

next_powerup_collision:
    addi t1, t1, 1
    j powerup_collision_loop

end_player_powerup_collisions:
    ret

draw_powerups:
    addi sp, sp, -20
    sw ra, 0(sp)

    li t0, USE_SPRITE_POWERUPS
    bnez t0, draw_powerups_skip_base

    call get_draw_base_address
    sw a0, 4(sp)
    j draw_powerups_begin_loop

draw_powerups_skip_base:
    sw zero, 4(sp)

draw_powerups_begin_loop:
    li t1, 0

draw_powerups_loop:
    li t3, MAX_POWERUPS
    beq t1, t3, end_draw_powerups

    slli t4, t1, 2

    la t0, powerup_active
    add t5, t0, t4
    lw t6, 0(t5)
    beqz t6, next_draw_powerup

    la t0, powerup_x
    add t5, t0, t4
    lw a2, 0(t5)

    la t0, powerup_y
    add t5, t0, t4
    lw a3, 0(t5)

    blt a2, zero, next_draw_powerup
    li t6, POWERUP_SIZE
    add a0, a2, t6
    li t6, SCREEN_WIDTH
    bgt a0, t6, next_draw_powerup

    blt a3, zero, next_draw_powerup
    li t6, POWERUP_SIZE
    add a0, a3, t6
    li t6, SCREEN_HEIGHT
    bgt a0, t6, next_draw_powerup

    la t0, powerup_type
    add t5, t0, t4
    lw t6, 0(t5)

    sw t1, 8(sp)
    sw a2, 12(sp)
    sw a3, 16(sp)

    li t5, USE_SPRITE_POWERUPS
    beqz t5, draw_powerup_fallback_rect

    li t5, POWERUP_HEAL
    beq t6, t5, select_powerup_heal_sprite

    li t5, POWERUP_BOSS_WEAPON
    beq t6, t5, select_powerup_boss_weapon_sprite

    li t5, POWERUP_BOSS_AMMO
    beq t6, t5, select_powerup_boss_ammo_sprite

select_powerup_ammo_sprite:
    la a2, sprite_powerup_ammo
    j draw_selected_powerup_sprite

select_powerup_heal_sprite:
    la a2, sprite_powerup_heal
    j draw_selected_powerup_sprite

select_powerup_boss_weapon_sprite:
    la a2, sprite_powerup_boss_weapon
    j draw_selected_powerup_sprite

select_powerup_boss_ammo_sprite:
    la a2, sprite_powerup_boss_ammo

draw_selected_powerup_sprite:
    lw a0, 12(sp)
    lw a1, 16(sp)
    li a3, POWERUP_SIZE
    li a4, POWERUP_SIZE
    call draw_sprite_8bpp_fast

    lw t1, 8(sp)
    j next_draw_powerup

draw_powerup_fallback_rect:
    lw a0, 12(sp)
    lw a1, 16(sp)
    li a2, POWERUP_SIZE
    li a3, POWERUP_SIZE
    li a4, 0xE7
    lw a5, 4(sp)
    call draw_rect

    lw t1, 8(sp)

next_draw_powerup:
    addi t1, t1, 1
    j draw_powerups_loop

end_draw_powerups:
    lw ra, 0(sp)
    addi sp, sp, 20
    ret
