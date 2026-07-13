# ============================================================
# Inventario, rifle e uso de cura
# ============================================================

.text

init_inventory:
    la t0, weapon_type
    li t1, WEAPON_PISTOL
    sw t1, 0(t0)

    la t0, normal_ammo_count
    li t1, RIFLE_START_RESERVE
    sw t1, 0(t0)

    la t0, boss_ammo_count
    sw zero, 0(t0)

    la t0, boss_weapon_owned
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

    li t2, STATE_LEVEL3
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
    la t0, weapon_type
    lw t1, 0(t0)
    li t2, WEAPON_PISTOL
    bne t1, t2, check_shotgun_reload_timer

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
    la t0, sfx_enabled
    lw t0, 0(t0)
    beqz t0, skip_rifle_reload_sfx
    li a7, 31
    ecall

skip_rifle_reload_sfx:
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
    la t0, sfx_enabled
    lw t0, 0(t0)
    beqz t0, skip_shotgun_reload_sfx
    li a7, 31
    ecall

skip_shotgun_reload_sfx:
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
    la t0, sfx_enabled
    lw t0, 0(t0)
    beqz t0, end_handle_heal_input
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
    beq t1, t2, select_pistol_weapon

    li t2, '2'
    beq t1, t2, try_select_shotgun

    li t2, '3'
    bne t1, t2, end_handle_weapon_select_input

    la t0, boss_weapon_owned
    lw t1, 0(t0)
    beqz t1, end_handle_weapon_select_input

    la t0, weapon_type
    li t1, WEAPON_UZI
    sw t1, 0(t0)
    j finish_weapon_selection

try_select_shotgun:
    la t0, shotgun_owned
    lw t1, 0(t0)
    beqz t1, end_handle_weapon_select_input

    la t0, weapon_type
    li t1, WEAPON_SHOTGUN
    sw t1, 0(t0)
    j finish_weapon_selection

select_pistol_weapon:
    la t0, weapon_type
    li t1, WEAPON_PISTOL
    sw t1, 0(t0)

finish_weapon_selection:
    la t0, shoot_request_pending
    sw zero, 0(t0)
    la t0, shoot_hold_timer
    sw zero, 0(t0)
    la t0, player_burst_remaining
    sw zero, 0(t0)
    la t0, player_burst_interval_timer
    sw zero, 0(t0)

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

    li t2, WEAPON_UZI
    beq t1, t2, end_handle_reload_input

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

draw_inventory:
    # Faixa permanente do HUD para arma, municao, cura e recarga.
    addi sp, sp, -8
    sw ra, 0(sp)

    call get_draw_base_address
    sw a0, 4(sp)

    la t0, weapon_type
    lw t1, 0(t0)

    li t2, WEAPON_SHOTGUN
    beq t1, t2, select_inventory_shotgun_label

    li t2, WEAPON_UZI
    beq t1, t2, select_inventory_uzi_label

select_inventory_pistol_label:
    la a0, label_weapon_pistol
    j draw_inventory_weapon_label

select_inventory_shotgun_label:
    la a0, label_weapon_shotgun
    j draw_inventory_weapon_label

select_inventory_uzi_label:
    la a0, label_weapon_uzi

draw_inventory_weapon_label:
    li a1, 8
    li a2, 216
    li a3, COLOR_WHITE
    lw a4, 4(sp)
    call draw_small_text

    la a0, label_municao
    li a1, 72
    li a2, 216
    li a3, COLOR_WHITE
    lw a4, 4(sp)
    call draw_small_text

    la t0, weapon_type
    lw t1, 0(t0)
    li t2, WEAPON_SHOTGUN
    beq t1, t2, draw_shotgun_mag_ammo

    li t2, WEAPON_UZI
    beq t1, t2, draw_uzi_mag_ammo

    la t0, rifle_mag_count
    j draw_mag_ammo_value

draw_shotgun_mag_ammo:
    la t0, shotgun_mag_count

draw_mag_ammo_value:
    lw a0, 0(t0)
    j draw_mag_ammo_number

draw_uzi_mag_ammo:
    li a0, 0

draw_mag_ammo_number:
    li a1, 106
    li a2, 216
    li a3, COLOR_WHITE
    lw a4, 4(sp)
    call draw_small_number

    li a0, '/'
    li a1, 122
    li a2, 216
    li a3, COLOR_WHITE
    lw a4, 4(sp)
    call draw_small_char

    la t0, weapon_type
    lw t1, 0(t0)
    li t2, WEAPON_SHOTGUN
    beq t1, t2, draw_shotgun_total_ammo

    li t2, WEAPON_UZI
    beq t1, t2, draw_uzi_total_ammo

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
    j draw_total_ammo_value

draw_uzi_total_ammo:
    la t0, boss_ammo_count
    lw a0, 0(t0)

draw_total_ammo_value:
    li a1, 128
    li a2, 216
    li a3, COLOR_WHITE
    lw a4, 4(sp)
    call draw_small_number

    la a0, label_cura
    li a1, 8
    li a2, 224
    li a3, COLOR_WHITE
    lw a4, 4(sp)
    call draw_small_text

    la t0, heal_count
    lw a0, 0(t0)
    li a1, 30
    li a2, 224
    li a3, COLOR_WHITE
    lw a4, 4(sp)
    call draw_small_number

    la t0, weapon_type
    lw t1, 0(t0)
    li t2, WEAPON_SHOTGUN
    beq t1, t2, draw_shotgun_reload_timer

    li t2, WEAPON_UZI
    beq t1, t2, end_draw_inventory

    la t0, rifle_reload_timer
    j draw_reload_timer_value

draw_shotgun_reload_timer:
    la t0, shotgun_reload_timer

draw_reload_timer_value:
    lw a0, 0(t0)
    blez a0, end_draw_inventory

    # ceil((frames * 16 ms) / 1000) nunca exibe 0 enquanto a recarga
    # estiver ativa. A area fica limpa pelo background do Town ou pelo
    # clear do frame nos demais mapas.
    li t0, DEBUG_FRAME_DELAY_MS
    mul a0, a0, t0
    addi a0, a0, 999
    li t0, 1000
    div a0, a0, t0

draw_reload_timer_number:
    li a1, 152
    li a2, 216
    li a3, COLOR_WHITE
    lw a4, 4(sp)
    call draw_small_number

end_draw_inventory:
    lw ra, 0(sp)
    addi sp, sp, 8
    ret
