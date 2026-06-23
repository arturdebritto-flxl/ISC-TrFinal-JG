# ============================================================
# Inventario, rifle e uso de cura
# ============================================================

.text

init_inventory:
    la t0, weapon_type
    li t1, WEAPON_NORMAL
    sw t1, 0(t0)

    la t0, normal_ammo_count
    li t1, RIFLE_START_RESERVE
    sw t1, 0(t0)

    la t0, boss_ammo_count
    sw zero, 0(t0)

    la t0, heal_count
    sw zero, 0(t0)

    la t0, rifle_mag_count
    li t1, RIFLE_MAG_SIZE
    sw t1, 0(t0)

    la t0, rifle_reload_timer
    sw zero, 0(t0)

    la t0, rifle_fire_cooldown
    sw zero, 0(t0)

    la t0, shotgun_owned
    sw zero, 0(t0)

    la t0, shotgun_ammo_count
    sw zero, 0(t0)

    la t0, shotgun_mag_count
    sw zero, 0(t0)

    la t0, shotgun_reload_timer
    sw zero, 0(t0)

    la t0, inventory_visible
    li t1, 1
    sw t1, 0(t0)

    ret

update_inventory:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, game_state
    lw t1, 0(t0)

    li t2, STATE_LEVEL1
    beq t1, t2, update_inventory_state_ok

    li t2, STATE_LEVEL2
    beq t1, t2, update_inventory_state_ok

    li t2, STATE_BOSS
    beq t1, t2, update_inventory_state_ok

    j end_update_inventory

update_inventory_state_ok:
    call update_noise_timer
    call update_rifle_timers
    call handle_heal_input
    call handle_weapon_select_input
    call handle_reload_input
    call handle_inventory_input

end_update_inventory:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

update_noise_timer:
    la t0, noise_timer
    lw t1, 0(t0)
    blez t1, end_update_noise_timer
    addi t1, t1, -1
    sw t1, 0(t0)

end_update_noise_timer:
    ret

update_rifle_timers:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, rifle_fire_cooldown
    lw t1, 0(t0)
    blez t1, check_reload_timer
    addi t1, t1, -1
    sw t1, 0(t0)

check_reload_timer:
    la t0, rifle_reload_timer
    lw t1, 0(t0)
    blez t1, maybe_start_auto_reload

    addi t1, t1, -1
    sw t1, 0(t0)
    bnez t1, end_update_rifle_timers

    call finish_rifle_reload
    j check_shotgun_reload_timer

maybe_start_auto_reload:
    la t0, rifle_mag_count
    lw t1, 0(t0)
    bgtz t1, check_shotgun_reload_timer

    la t0, normal_ammo_count
    lw t1, 0(t0)
    blez t1, check_shotgun_reload_timer

    call start_rifle_reload

check_shotgun_reload_timer:
    la t0, shotgun_reload_timer
    lw t1, 0(t0)
    blez t1, maybe_start_auto_shotgun_reload

    addi t1, t1, -1
    sw t1, 0(t0)
    bnez t1, end_update_rifle_timers

    call finish_shotgun_reload
    j end_update_rifle_timers

maybe_start_auto_shotgun_reload:
    la t0, shotgun_owned
    lw t1, 0(t0)
    beqz t1, end_update_rifle_timers

    la t0, weapon_type
    lw t1, 0(t0)
    li t2, WEAPON_SHOTGUN
    bne t1, t2, end_update_rifle_timers

    la t0, shotgun_mag_count
    lw t1, 0(t0)
    bgtz t1, end_update_rifle_timers

    la t0, shotgun_ammo_count
    lw t1, 0(t0)
    blez t1, end_update_rifle_timers

    call start_shotgun_reload

end_update_rifle_timers:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

start_rifle_reload:
    la t0, rifle_reload_timer
    lw t1, 0(t0)
    bgtz t1, end_start_rifle_reload

    li t1, RIFLE_RELOAD_FRAMES
    sw t1, 0(t0)

    li a0, 60
    li a1, 60
    li a2, 115
    li a3, 64
    li a7, 31
    ecall

    la t0, noise_timer
    lw t1, 0(t0)
    li t2, NOISE_RELOAD_FRAMES
    bge t1, t2, end_start_rifle_reload
    sw t2, 0(t0)

end_start_rifle_reload:
    ret

finish_rifle_reload:
    la t0, rifle_mag_count
    lw t1, 0(t0)
    li t2, RIFLE_MAG_SIZE
    bge t1, t2, end_finish_rifle_reload

    sub t3, t2, t1

    la t0, normal_ammo_count
    lw t4, 0(t0)
    blez t4, end_finish_rifle_reload

    ble t4, t3, reload_use_all_reserve

    sub t4, t4, t3
    sw t4, 0(t0)

    la t0, rifle_mag_count
    sw t2, 0(t0)
    j end_finish_rifle_reload

reload_use_all_reserve:
    la t0, rifle_mag_count
    add t1, t1, t4
    sw t1, 0(t0)

    la t0, normal_ammo_count
    sw zero, 0(t0)

end_finish_rifle_reload:
    ret

start_shotgun_reload:
    la t0, shotgun_reload_timer
    lw t1, 0(t0)
    bgtz t1, end_start_shotgun_reload

    li t1, SHOTGUN_RELOAD_FRAMES
    sw t1, 0(t0)

    li a0, 55
    li a1, 70
    li a2, 115
    li a3, 70
    li a7, 31
    ecall

    la t0, noise_timer
    lw t1, 0(t0)
    li t2, NOISE_RELOAD_FRAMES
    bge t1, t2, end_start_shotgun_reload
    sw t2, 0(t0)

end_start_shotgun_reload:
    ret

finish_shotgun_reload:
    la t0, shotgun_mag_count
    lw t1, 0(t0)
    li t2, SHOTGUN_MAG_SIZE
    bge t1, t2, end_finish_shotgun_reload

    sub t3, t2, t1

    la t0, shotgun_ammo_count
    lw t4, 0(t0)
    blez t4, end_finish_shotgun_reload

    ble t4, t3, shotgun_reload_use_all_reserve

    sub t4, t4, t3
    sw t4, 0(t0)

    la t0, shotgun_mag_count
    sw t2, 0(t0)
    j end_finish_shotgun_reload

shotgun_reload_use_all_reserve:
    la t0, shotgun_mag_count
    add t1, t1, t4
    sw t1, 0(t0)

    la t0, shotgun_ammo_count
    sw zero, 0(t0)

end_finish_shotgun_reload:
    ret

unlock_shotgun:
    la t0, shotgun_owned
    lw t1, 0(t0)
    bnez t1, end_unlock_shotgun

    li t1, 1
    sw t1, 0(t0)

    la t0, shotgun_mag_count
    li t1, SHOTGUN_MAG_SIZE
    sw t1, 0(t0)

    la t0, shotgun_ammo_count
    li t1, SHOTGUN_UNLOCK_RESERVE
    sw t1, 0(t0)

    la t0, weapon_type
    li t1, WEAPON_SHOTGUN
    sw t1, 0(t0)

end_unlock_shotgun:
    ret

handle_heal_input:
    la t0, key_pressed
    lw t1, 0(t0)
    beqz t1, end_handle_heal_input

    la t0, last_key
    lw t1, 0(t0)

    li t2, 'h'
    beq t1, t2, try_use_heal

    li t2, 'H'
    bne t1, t2, end_handle_heal_input

try_use_heal:
    la t0, heal_count
    lw t1, 0(t0)
    blez t1, end_handle_heal_input

    la t2, player_lives
    lw t3, 0(t2)
    li t4, PLAYER_MAX_LIVES
    bge t3, t4, end_handle_heal_input

    addi t3, t3, 1
    sw t3, 0(t2)

    addi t1, t1, -1
    sw t1, 0(t0)

    li a0, 84
    li a1, 80
    li a2, 9
    li a3, 80
    li a7, 31
    ecall

end_handle_heal_input:
    ret

handle_weapon_select_input:
    la t0, key_pressed
    lw t1, 0(t0)
    beqz t1, end_handle_weapon_select_input

    la t0, last_key
    lw t1, 0(t0)

    li t2, '1'
    beq t1, t2, select_normal_weapon

    li t2, '2'
    bne t1, t2, end_handle_weapon_select_input

    la t0, shotgun_owned
    lw t1, 0(t0)
    beqz t1, end_handle_weapon_select_input

    la t0, weapon_type
    li t1, WEAPON_SHOTGUN
    sw t1, 0(t0)
    j end_handle_weapon_select_input

select_normal_weapon:
    la t0, weapon_type
    li t1, WEAPON_NORMAL
    sw t1, 0(t0)

end_handle_weapon_select_input:
    ret

handle_reload_input:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, key_pressed
    lw t1, 0(t0)
    beqz t1, end_handle_reload_input

    la t0, last_key
    lw t1, 0(t0)

    li t2, 'r'
    beq t1, t2, try_manual_reload

    li t2, 'R'
    bne t1, t2, end_handle_reload_input

try_manual_reload:
    la t0, weapon_type
    lw t1, 0(t0)
    li t2, WEAPON_SHOTGUN
    beq t1, t2, try_manual_shotgun_reload

    la t0, rifle_mag_count
    lw t1, 0(t0)
    li t2, RIFLE_MAG_SIZE
    bge t1, t2, end_handle_reload_input

    la t0, normal_ammo_count
    lw t1, 0(t0)
    blez t1, end_handle_reload_input

    call start_rifle_reload
    j end_handle_reload_input

try_manual_shotgun_reload:
    la t0, shotgun_owned
    lw t1, 0(t0)
    beqz t1, end_handle_reload_input

    la t0, shotgun_mag_count
    lw t1, 0(t0)
    li t2, SHOTGUN_MAG_SIZE
    bge t1, t2, end_handle_reload_input

    la t0, shotgun_ammo_count
    lw t1, 0(t0)
    blez t1, end_handle_reload_input

    call start_shotgun_reload

end_handle_reload_input:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

handle_inventory_input:
    la t0, key_pressed
    lw t1, 0(t0)
    beqz t1, end_handle_inventory_input

    la t0, last_key
    lw t1, 0(t0)

    li t2, 'e'
    beq t1, t2, toggle_inventory_visible

    li t2, 'E'
    bne t1, t2, end_handle_inventory_input

toggle_inventory_visible:
    la t0, inventory_visible
    lw t1, 0(t0)
    xori t1, t1, 1
    sw t1, 0(t0)

end_handle_inventory_input:
    ret

draw_inventory:
    # Sprite hook: inventario visual do grupo entra aqui.
    addi sp, sp, -8
    sw ra, 0(sp)

    la t0, inventory_visible
    lw t1, 0(t0)
    beqz t1, end_draw_inventory

    call get_draw_base_address
    sw a0, 4(sp)

    li t2, USE_SPRITE_INVENTORY
    beqz t2, draw_inventory_text_fields

    la t0, weapon_type
    lw t1, 0(t0)

    li t2, WEAPON_SHOTGUN
    beq t1, t2, select_inventory_shotgun_icon

    li t2, WEAPON_BOSS
    beq t1, t2, select_inventory_boss_icon

select_inventory_normal_icon:
    la a2, sprite_weapon_normal_icon
    j draw_inventory_weapon_icon

select_inventory_shotgun_icon:
    la a2, sprite_weapon_shotgun_icon
    j draw_inventory_weapon_icon

select_inventory_boss_icon:
    la a2, sprite_weapon_boss_icon

draw_inventory_weapon_icon:
    li a0, 176
    li a1, 216
    li a3, 16
    li a4, 16
    call draw_sprite_8bpp_fast

draw_inventory_text_fields:
    la a0, label_arma
    li a1, 8
    li a2, 216
    li a3, 0xFF
    lw a4, 4(sp)
    call draw_small_text

    la t0, weapon_type
    lw a0, 0(t0)
    li a1, 30
    li a2, 216
    li a3, 0xFF
    lw a4, 4(sp)
    call draw_small_number

    la a0, label_municao
    li a1, 48
    li a2, 216
    li a3, 0xFF
    lw a4, 4(sp)
    call draw_small_text

    la t0, weapon_type
    lw t1, 0(t0)
    li t2, WEAPON_SHOTGUN
    beq t1, t2, draw_shotgun_mag_ammo

    la t0, rifle_mag_count
    j draw_mag_ammo_value

draw_shotgun_mag_ammo:
    la t0, shotgun_mag_count

draw_mag_ammo_value:
    lw a0, 0(t0)
    li a1, 82
    li a2, 216
    li a3, 0xFF
    lw a4, 4(sp)
    call draw_small_number

    li a0, '/'
    li a1, 98
    li a2, 216
    li a3, 0xFF
    lw a4, 4(sp)
    call draw_small_char

    la t0, weapon_type
    lw t1, 0(t0)
    li t2, WEAPON_SHOTGUN
    beq t1, t2, draw_shotgun_total_ammo

    la t0, rifle_mag_count
    lw t1, 0(t0)
    la t0, normal_ammo_count
    lw a0, 0(t0)
    add a0, a0, t1
    j draw_total_ammo_value

draw_shotgun_total_ammo:
    la t0, shotgun_mag_count
    lw t1, 0(t0)
    la t0, shotgun_ammo_count
    lw a0, 0(t0)
    add a0, a0, t1

draw_total_ammo_value:
    li a1, 102
    li a2, 216
    li a3, 0xFF
    lw a4, 4(sp)
    call draw_small_number

    la a0, label_boss
    li a1, 8
    li a2, 224
    li a3, 0xFF
    lw a4, 4(sp)
    call draw_small_text

    la t0, boss_ammo_count
    lw a0, 0(t0)
    li a1, 30
    li a2, 224
    li a3, 0xFF
    lw a4, 4(sp)
    call draw_small_number

    la a0, label_cura
    li a1, 64
    li a2, 224
    li a3, 0xFF
    lw a4, 4(sp)
    call draw_small_text

    la t0, heal_count
    lw a0, 0(t0)
    li a1, 86
    li a2, 224
    li a3, 0xFF
    lw a4, 4(sp)
    call draw_small_number

    la a0, label_rec
    li a1, 120
    li a2, 224
    li a3, 0xFF
    lw a4, 4(sp)
    call draw_small_text

    la t0, weapon_type
    lw t1, 0(t0)
    li t2, WEAPON_SHOTGUN
    beq t1, t2, draw_shotgun_reload_timer

    la t0, rifle_reload_timer
    j draw_reload_timer_value

draw_shotgun_reload_timer:
    la t0, shotgun_reload_timer

draw_reload_timer_value:
    lw a0, 0(t0)
    li a1, 138
    li a2, 224
    li a3, 0xFF
    lw a4, 4(sp)
    call draw_small_number

end_draw_inventory:
    lw ra, 0(sp)
    addi sp, sp, 8
    ret
