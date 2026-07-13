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

    la t0, shotgun_weapon_spawned
    sw zero, 0(t0)

    ret

spawn_powerup_at:
    li t1, 0

find_free_powerup_loop:
    li t2, MAX_POWERUPS
    beq t1, t2, spawn_powerup_failed

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

    li a0, 1
    ret

spawn_powerup_failed:
    li a0, 0
    ret

spawn_powerup_from_enemy_death:
    addi sp, sp, -12
    sw ra, 0(sp)
    sw a0, 4(sp)
    sw a1, 8(sp)

    la t0, game_state
    lw t1, 0(t0)
    li t2, STATE_LEVEL1
    beq t1, t2, enemy_drop_state_ok
    li t2, STATE_LEVEL2
    beq t1, t2, enemy_drop_state_ok
    li t2, STATE_LEVEL3
    beq t1, t2, enemy_drop_state_ok
    li t2, STATE_BOSS
    bne t1, t2, end_spawn_powerup_from_enemy_death

enemy_drop_state_ok:

    call maybe_spawn_shotgun_weapon_drop

    la t0, enemy_kill_counter
    lw t1, 0(t0)
    addi t1, t1, 1
    sw t1, 0(t0)

    # Gate geral preservado do baseline: multiplos de 3 ou 5 recebem drop.
    li t2, DROP_HEAL_INTERVAL
    rem t3, t1, t2
    beqz t3, choose_drop_kind_from_kill

    li t2, DROP_AMMO_INTERVAL
    rem t3, t1, t2
    bnez t3, end_spawn_powerup_from_enemy_death

choose_drop_kind_from_kill:
    li t2, DROP_HEAL_INTERVAL
    rem t3, t1, t2
    beqz t3, spawn_heal_from_kill

    j spawn_ammo_from_kill

spawn_heal_from_kill:
    lw a0, 4(sp)
    lw a1, 8(sp)
    li a2, POWERUP_HEAL
    call spawn_powerup_at
    j end_spawn_powerup_from_enemy_death

spawn_ammo_from_kill:
    lw a0, 4(sp)
    lw a1, 8(sp)
    call select_ammo_powerup_for_level
    call spawn_powerup_at

end_spawn_powerup_from_enemy_death:
    lw ra, 0(sp)
    addi sp, sp, 12
    ret

maybe_spawn_shotgun_weapon_drop:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, current_level
    lw t1, 0(t0)
    li t2, LEVEL_SEWER
    bne t1, t2, end_maybe_spawn_shotgun_weapon_drop

    la t0, shotgun_owned
    lw t1, 0(t0)
    bnez t1, end_maybe_spawn_shotgun_weapon_drop

    la t0, shotgun_weapon_spawned
    lw t1, 0(t0)
    bnez t1, end_maybe_spawn_shotgun_weapon_drop
    li t1, 1
    sw t1, 0(t0)

    li a2, POWERUP_SHOTGUN_WEAPON
    call spawn_powerup_at

end_maybe_spawn_shotgun_weapon_drop:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# Seleciona o tipo de municao somente apos o drop geral e a escolha por municao.
# Saida: a2 = POWERUP_*_AMMO
select_ammo_powerup_for_level:
    li a2, POWERUP_NORMAL_AMMO

    la t0, current_level
    lw t1, 0(t0)
    li t2, LEVEL_SEWER
    beq t1, t2, select_phase2_ammo
    li t2, LEVEL_LABORATORY
    beq t1, t2, select_phase3_ammo
    ret

select_phase2_ammo:
    la t0, enemy_kill_counter
    lw t1, 0(t0)
    li t2, AMMO_WEIGHT_TOTAL
    rem t1, t1, t2
    li t2, AMMO_WEIGHT_PISTOL_PHASE2
    blt t1, t2, end_select_ammo_powerup
    li a2, POWERUP_SHOTGUN_AMMO
    ret

select_phase3_ammo:
    la t0, boss_weapon_owned
    lw t1, 0(t0)
    beqz t1, select_shotgun_ammo_powerup

    la t0, enemy_kill_counter
    lw t1, 0(t0)
    li t2, AMMO_WEIGHT_TOTAL_PHASE3
    rem t1, t1, t2
    li t2, AMMO_WEIGHT_SHOTGUN_PHASE3
    blt t1, t2, select_shotgun_ammo_powerup

    li a2, POWERUP_BOSS_AMMO
    ret

select_shotgun_ammo_powerup:
    li a2, POWERUP_SHOTGUN_AMMO

end_select_ammo_powerup:
    ret

maybe_spawn_laboratory_uzi:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, current_level
    lw t1, 0(t0)
    li t2, LEVEL_LABORATORY
    bne t1, t2, end_maybe_spawn_laboratory_uzi

    la t0, current_wave
    lw t1, 0(t0)
    li t2, 2
    blt t1, t2, end_maybe_spawn_laboratory_uzi

    la t0, boss_weapon_owned
    lw t1, 0(t0)
    bnez t1, end_maybe_spawn_laboratory_uzi

    la t0, boss_weapon_spawned
    lw t1, 0(t0)
    bnez t1, end_maybe_spawn_laboratory_uzi

    li a0, 252
    li a1, 132
    li a2, POWERUP_BOSS_WEAPON
    call spawn_powerup_at
    beqz a0, end_maybe_spawn_laboratory_uzi

    la t0, boss_weapon_spawned
    li t1, 1
    sw t1, 0(t0)

end_maybe_spawn_laboratory_uzi:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

update_powerups:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, game_state
    lw t1, 0(t0)
    li t2, STATE_LEVEL3
    beq t1, t2, update_laboratory_powerups

    li t2, STATE_BOSS
    bne t1, t2, end_update_powerups

    la t0, boss_active
    lw t1, 0(t0)
    beqz t1, end_update_powerups

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
    j end_update_powerups

update_laboratory_powerups:
    call maybe_spawn_laboratory_uzi

end_update_powerups:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

check_player_powerup_collisions:
    addi sp, sp, -8
    sw ra, 0(sp)
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

    la t0, powerup_type
    add t4, t0, t3
    lw t5, 0(t4)

    li t6, POWERUP_NORMAL_AMMO
    blt t5, t6, next_powerup_collision
    li t6, POWERUP_SHOTGUN_WEAPON
    bgt t5, t6, next_powerup_collision

    la t0, powerup_active
    add t4, t0, t3
    sw zero, 0(t4)

    li t6, POWERUP_NORMAL_AMMO
    beq t5, t6, collect_normal_ammo

    li t6, POWERUP_HEAL
    beq t5, t6, collect_heal

    li t6, POWERUP_BOSS_WEAPON
    beq t5, t6, collect_boss_weapon

    li t6, POWERUP_BOSS_AMMO
    beq t5, t6, collect_boss_ammo

    li t6, POWERUP_SHOTGUN_AMMO
    beq t5, t6, collect_shotgun_ammo

    li t6, POWERUP_SHOTGUN_WEAPON
    beq t5, t6, collect_shotgun_weapon

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
    la t0, boss_weapon_owned
    li t5, 1
    sw t5, 0(t0)

    la t0, boss_ammo_count
    lw t5, 0(t0)
    li t6, 0x7ffffff5
    bgt t5, t6, saturate_boss_weapon_ammo
    addi t5, t5, BOSS_AMMO_GAIN
    j store_boss_weapon_ammo
saturate_boss_weapon_ammo:
    li t5, 0x7fffffff
store_boss_weapon_ammo:
    sw t5, 0(t0)
    j play_powerup_collect_sfx

finish_collect_boss_weapon:
    j next_powerup_collision

collect_boss_ammo:
    la t0, boss_ammo_count
    lw t5, 0(t0)
    li t6, 0x7ffffff5
    bgt t5, t6, saturate_boss_ammo_pickup
    addi t5, t5, BOSS_AMMO_GAIN
    j store_boss_ammo_pickup
saturate_boss_ammo_pickup:
    li t5, 0x7fffffff
store_boss_ammo_pickup:
    sw t5, 0(t0)
    j play_powerup_collect_sfx

collect_shotgun_ammo:
    la t0, shotgun_ammo_count
    lw t5, 0(t0)
    addi t5, t5, SHOTGUN_AMMO_GAIN
    sw t5, 0(t0)
    j play_powerup_collect_sfx

collect_shotgun_weapon:
    sw t1, 4(sp)
    call unlock_shotgun
    lw t1, 4(sp)
    j play_powerup_collect_sfx

finish_collect_boss_ammo:
    j next_powerup_collision

play_powerup_collect_sfx:
    li a0, 84
    li a1, 70
    li a2, 10
    li a3, 80
    la t0, sfx_enabled
    lw t0, 0(t0)
    beqz t0, next_powerup_collision
    li a7, 31
    ecall

next_powerup_collision:
    addi t1, t1, 1
    j powerup_collision_loop

end_player_powerup_collisions:
    lw ra, 0(sp)
    addi sp, sp, 8
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

    li t5, POWERUP_NORMAL_AMMO
    blt t6, t5, next_draw_powerup
    li t5, POWERUP_SHOTGUN_WEAPON
    bgt t6, t5, next_draw_powerup

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

    li t5, POWERUP_SHOTGUN_AMMO
    beq t6, t5, select_powerup_shotgun_ammo_sprite

    li t5, POWERUP_SHOTGUN_WEAPON
    beq t6, t5, select_powerup_shotgun_weapon_sprite

select_powerup_ammo_sprite:
    la a2, sprite_ammo_pistol_pickup
    j draw_selected_new_pickup_sprite

select_powerup_heal_sprite:
    la a2, sprite_medkit_pickup
    j draw_selected_new_pickup_sprite

select_powerup_boss_weapon_sprite:
    la a2, sprite_weapon_boss_icon
    j draw_selected_baseline_powerup_sprite

select_powerup_boss_ammo_sprite:
    la a2, sprite_ammo_uzi_pickup
    j draw_selected_new_pickup_sprite

select_powerup_shotgun_ammo_sprite:
    la a2, sprite_ammo_shotgun_pickup
    j draw_selected_new_pickup_sprite

select_powerup_shotgun_weapon_sprite:
    la a2, sprite_weapon_shotgun_icon
    j draw_selected_baseline_powerup_sprite

draw_selected_new_pickup_sprite:
    lw a0, 12(sp)
    lw a1, 16(sp)
    addi a0, a0, 4
    addi a1, a1, 4
    li a3, 8
    li a4, 8
    call draw_sprite_8bpp_fast

    lw t1, 8(sp)
    j next_draw_powerup

draw_selected_baseline_powerup_sprite:
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
    li a4, COLOR_POWERUP_FALLBACK
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
