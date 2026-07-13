# ============================================================
# Logica dos tiros do jogador
# ============================================================

.text

init_bullets:
    li t1, 0

init_bullets_loop:
    li t2, MAX_BULLETS
    beq t1, t2, end_init_bullets

    slli t3, t1, 2

    la t0, bullet_active
    add t4, t0, t3
    sw zero, 0(t4)

    la t0, bullet_damage
    add t4, t0, t3
    sw zero, 0(t4)

    la t0, bullet_dx
    add t4, t0, t3
    sw zero, 0(t4)

    la t0, bullet_dy
    add t4, t0, t3
    sw zero, 0(t4)

    addi t1, t1, 1
    j init_bullets_loop

end_init_bullets:
    la t0, shoot_direction
    li t1, DIR_UP
    sw t1, 0(t0)

    la t0, shoot_hold_timer
    sw zero, 0(t0)

    la t0, shoot_request_pending
    sw zero, 0(t0)

    la t0, player_burst_weapon
    sw zero, 0(t0)

    la t0, player_burst_remaining
    sw zero, 0(t0)

    la t0, player_burst_interval_timer
    sw zero, 0(t0)

    ret

update_bullets:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, game_state
    lw t1, 0(t0)

    li t2, STATE_LEVEL1
    beq t1, t2, update_bullets_state_ok

    li t2, STATE_LEVEL2
    beq t1, t2, update_bullets_state_ok

    li t2, STATE_LEVEL3
    beq t1, t2, update_bullets_state_ok

    li t2, STATE_BOSS
    beq t1, t2, update_bullets_state_ok

    j end_update_bullets

update_bullets_state_ok:
    call update_player_burst
    call check_shoot_input
    call move_bullets

end_update_bullets:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

check_shoot_input:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, key_pressed
    lw t1, 0(t0)
    beqz t1, refresh_player_facing

    la t0, last_key
    lw t1, 0(t0)

    li t2, 'i'
    beq t1, t2, buffer_shoot_up

    li t2, 'k'
    beq t1, t2, buffer_shoot_down

    li t2, 'j'
    beq t1, t2, buffer_shoot_left

    li t2, 'l'
    beq t1, t2, buffer_shoot_right

    j refresh_player_facing

buffer_shoot_up:
    li t1, DIR_UP
    j store_shoot_buffer

buffer_shoot_down:
    li t1, DIR_DOWN
    j store_shoot_buffer

buffer_shoot_left:
    li t1, DIR_LEFT
    j store_shoot_buffer

buffer_shoot_right:
    li t1, DIR_RIGHT

store_shoot_buffer:
    # Um evento durante rajada ativa e descartado, sem formar fila.
    la t0, player_burst_remaining
    lw t2, 0(t0)
    bgtz t2, refresh_player_facing

    la t0, shoot_direction
    sw t1, 0(t0)

    la t0, shoot_request_pending
    li t2, 1
    sw t2, 0(t0)

    la t0, shoot_hold_timer
    li t2, SHOOT_REQUEST_BUFFER_FRAMES
    sw t2, 0(t0)

    la t0, weapon_type
    lw t2, 0(t0)
    li t3, WEAPON_SHOTGUN
    beq t2, t3, fire_single_shotgun_event
    li t3, WEAPON_PISTOL
    beq t2, t3, start_pistol_burst
    li t3, WEAPON_UZI
    beq t2, t3, start_uzi_burst
    j clear_consumed_shoot_event

start_pistol_burst:
    li t3, PISTOL_BURST_SIZE
    j store_new_burst

start_uzi_burst:
    li t3, UZI_BURST_SIZE

store_new_burst:
    la t0, player_burst_weapon
    sw t2, 0(t0)
    la t0, player_burst_direction
    sw t1, 0(t0)
    la t0, player_burst_remaining
    sw t3, 0(t0)
    la t0, player_burst_interval_timer
    sw zero, 0(t0)
    call update_player_facing_direction
    call fire_player_burst_projectile
    j clear_consumed_shoot_event

fire_single_shotgun_event:
    call update_player_facing_direction
    la t0, shoot_direction
    lw a0, 0(t0)
    call spawn_bullet

clear_consumed_shoot_event:
    la t0, shoot_request_pending
    sw zero, 0(t0)
    la t0, shoot_hold_timer
    sw zero, 0(t0)
    j end_check_shoot_input

refresh_player_facing:
    call update_player_facing_direction

end_check_shoot_input:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# Processa no maximo um projetil da rajada ativa por frame.
update_player_burst:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, player_burst_remaining
    lw t1, 0(t0)
    blez t1, end_update_player_burst

    la t0, key_pressed
    lw t1, 0(t0)
    beqz t1, continue_active_burst
    la t0, last_key
    lw t1, 0(t0)
    li t2, '1'
    beq t1, t2, cancel_active_burst_before_selection
    li t2, '2'
    beq t1, t2, cancel_active_burst_before_selection
    li t2, '3'
    bne t1, t2, continue_active_burst

cancel_active_burst_before_selection:
    la t0, player_burst_remaining
    sw zero, 0(t0)
    la t0, player_burst_interval_timer
    sw zero, 0(t0)
    j end_update_player_burst

continue_active_burst:

    call update_player_facing_direction

    la t0, player_burst_interval_timer
    lw t1, 0(t0)
    blez t1, fire_active_burst_now
    addi t1, t1, -1
    sw t1, 0(t0)
    bgtz t1, end_update_player_burst

fire_active_burst_now:
    call fire_player_burst_projectile

end_update_player_burst:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

fire_player_burst_projectile:
    addi sp, sp, -4
    sw ra, 0(sp)

    # Troca externa de arma tambem cancela defensivamente a rajada.
    la t0, player_burst_weapon
    lw t1, 0(t0)
    la t0, weapon_type
    lw t2, 0(t0)
    bne t1, t2, cancel_player_burst

    la t0, player_burst_direction
    lw a0, 0(t0)
    call spawn_bullet
    beqz a0, cancel_player_burst

    la t0, player_burst_remaining
    lw t1, 0(t0)
    addi t1, t1, -1
    sw t1, 0(t0)
    blez t1, finish_player_burst

    la t0, player_burst_weapon
    lw t1, 0(t0)
    li t2, WEAPON_PISTOL
    beq t1, t2, arm_pistol_burst_interval
    li t2, WEAPON_UZI
    bne t1, t2, cancel_player_burst
    li t1, UZI_BURST_INTERVAL
    j store_burst_interval

arm_pistol_burst_interval:
    li t1, PISTOL_BURST_INTERVAL

store_burst_interval:
    la t0, player_burst_interval_timer
    sw t1, 0(t0)
    j end_fire_player_burst_projectile

finish_player_burst:
    la t0, player_burst_interval_timer
    sw zero, 0(t0)
    j end_fire_player_burst_projectile

cancel_player_burst:
    la t0, player_burst_remaining
    sw zero, 0(t0)
    la t0, player_burst_interval_timer
    sw zero, 0(t0)

end_fire_player_burst_projectile:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

spawn_bullet:
    addi sp, sp, -12
    sw ra, 0(sp)
    sw a0, 4(sp)
    sw zero, 8(sp)

    la t0, weapon_type
    lw t1, 0(t0)
    li t2, WEAPON_SHOTGUN
    beq t1, t2, spawn_shotgun_blast

    li t2, WEAPON_UZI
    beq t1, t2, spawn_uzi_bullet

    li t2, WEAPON_PISTOL
    bne t1, t2, end_spawn_bullet

spawn_pistol_bullet:
    la t0, rifle_reload_timer
    lw t1, 0(t0)
    bgtz t1, end_spawn_bullet

    li a5, WEAPON_PISTOL_DAMAGE
    j prepare_pistol_shot

spawn_uzi_bullet:
    la t0, boss_ammo_count
    lw t1, 0(t0)
    blez t1, end_spawn_bullet
    addi t1, t1, -1
    sw t1, 0(t0)

    la t0, rifle_fire_cooldown
    li t1, UZI_FIRE_DELAY
    sw t1, 0(t0)

    lw a0, 4(sp)
    li a5, WEAPON_UZI_DAMAGE
    li t5, BULLET_SPEED
    call set_cardinal_delta
    call create_bullet_with_delta
    sw a0, 8(sp)
    j end_spawn_bullet

prepare_pistol_shot:
    la t0, rifle_mag_count
    lw t1, 0(t0)
    blez t1, try_start_reload_from_shot
    addi t1, t1, -1
    sw t1, 0(t0)
    j arm_pistol_cooldown

try_start_reload_from_shot:
    call start_rifle_reload
    j end_spawn_bullet

arm_pistol_cooldown:
    la t0, rifle_fire_cooldown
    li t1, RIFLE_FIRE_DELAY
    sw t1, 0(t0)

    li t5, BULLET_SPEED
    call set_cardinal_delta
    call create_bullet_with_delta
    sw a0, 8(sp)
    j end_spawn_bullet

spawn_shotgun_blast:
    la t0, shotgun_owned
    lw t1, 0(t0)
    beqz t1, end_spawn_bullet

    la t0, shotgun_reload_timer
    lw t1, 0(t0)
    bgtz t1, end_spawn_bullet

    la t0, rifle_fire_cooldown
    lw t1, 0(t0)
    bgtz t1, end_spawn_bullet

    la t0, shotgun_mag_count
    lw t1, 0(t0)
    blez t1, try_start_shotgun_reload_from_shot
    addi t1, t1, -1
    sw t1, 0(t0)

    la t0, rifle_fire_cooldown
    li t1, SHOTGUN_FIRE_DELAY
    sw t1, 0(t0)

    li a5, WEAPON_SHOTGUN_DAMAGE
    lw a0, 4(sp)
    li t5, SHOTGUN_BULLET_SPEED
    call set_cardinal_delta
    call create_bullet_with_delta
    sw a0, 8(sp)

    lw a0, 4(sp)
    li t5, SHOTGUN_BULLET_SPEED
    li t6, SHOTGUN_SPREAD_SPEED
    call set_spread_delta_left
    call create_bullet_with_delta
    lw t0, 8(sp)
    or t0, t0, a0
    sw t0, 8(sp)

    lw a0, 4(sp)
    li t5, SHOTGUN_BULLET_SPEED
    li t6, SHOTGUN_SPREAD_SPEED
    call set_spread_delta_right
    call create_bullet_with_delta
    lw t0, 8(sp)
    or t0, t0, a0
    sw t0, 8(sp)
    j end_spawn_bullet

try_start_shotgun_reload_from_shot:
    call start_shotgun_reload
    j end_spawn_bullet

set_cardinal_delta:
    mv a2, zero
    mv a3, zero

    li t1, DIR_UP
    beq a0, t1, delta_up

    li t1, DIR_DOWN
    beq a0, t1, delta_down

    li t1, DIR_LEFT
    beq a0, t1, delta_left

    li t1, DIR_RIGHT
    beq a0, t1, delta_right
    ret

delta_up:
    sub a3, zero, t5
    ret

delta_down:
    mv a3, t5
    ret

delta_left:
    sub a2, zero, t5
    ret

delta_right:
    mv a2, t5
    ret

set_spread_delta_left:
    addi sp, sp, -4
    sw ra, 0(sp)
    call set_cardinal_delta
    li t1, DIR_UP
    beq a0, t1, spread_left_vertical
    li t1, DIR_DOWN
    beq a0, t1, spread_left_vertical

    sub a3, zero, t6
    j end_set_spread_delta_left

spread_left_vertical:
    sub a2, zero, t6

end_set_spread_delta_left:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

set_spread_delta_right:
    addi sp, sp, -4
    sw ra, 0(sp)
    call set_cardinal_delta
    li t1, DIR_UP
    beq a0, t1, spread_right_vertical
    li t1, DIR_DOWN
    beq a0, t1, spread_right_vertical

    mv a3, t6
    j end_set_spread_delta_right

spread_right_vertical:
    mv a2, t6

end_set_spread_delta_right:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

create_bullet_with_delta:
    la t0, bullet_active
    li t1, 0

find_free_bullet_loop:
    li t2, MAX_BULLETS
    beq t1, t2, create_bullet_failed

    slli t3, t1, 2
    add t4, t0, t3
    lw t5, 0(t4)
    beqz t5, create_bullet_here

    addi t1, t1, 1
    j find_free_bullet_loop

create_bullet_here:
    li t5, BULLET_ACTIVE
    sw t5, 0(t4)

    la t0, player_x
    lw t5, 0(t0)
    li t6, DIR_LEFT
    beq a0, t6, spawn_bullet_x_left
    li t6, DIR_RIGHT
    beq a0, t6, spawn_bullet_x_right
    addi t5, t5, 6
    j store_bullet_x

spawn_bullet_x_left:
    addi t5, t5, -3
    j store_bullet_x

spawn_bullet_x_right:
    addi t5, t5, PLAYER_SIZE

store_bullet_x:
    la t0, bullet_x
    add t6, t0, t3
    sw t5, 0(t6)

    la t0, player_y
    lw t5, 0(t0)
    li t6, DIR_UP
    beq a0, t6, spawn_bullet_y_up
    li t6, DIR_DOWN
    beq a0, t6, spawn_bullet_y_down
    addi t5, t5, 6
    j store_bullet_y

spawn_bullet_y_up:
    addi t5, t5, -3
    j store_bullet_y

spawn_bullet_y_down:
    addi t5, t5, PLAYER_SIZE

store_bullet_y:
    la t0, bullet_y
    add t6, t0, t3
    sw t5, 0(t6)

    la t0, bullet_direction
    add t6, t0, t3
    sw a0, 0(t6)

    la t0, bullet_dx
    add t6, t0, t3
    sw a2, 0(t6)

    la t0, bullet_dy
    add t6, t0, t3
    sw a3, 0(t6)

    la t0, bullet_damage
    add t6, t0, t3
    sw a5, 0(t6)

    la t0, noise_timer
    lw t5, 0(t0)
    li t6, NOISE_SHOT_FRAMES
    bge t5, t6, play_bullet_sfx
    sw t6, 0(t0)

play_bullet_sfx:
    li a0, 76
    li a1, 35
    li a2, 80
    li a3, 72
    la t0, sfx_enabled
    lw t0, 0(t0)
    beqz t0, skip_bullet_sfx
    li a7, 31
    ecall

skip_bullet_sfx:
    li a0, 1
    ret

create_bullet_failed:
    li a0, 0
    ret

end_spawn_bullet:
    lw a0, 8(sp)
    lw ra, 0(sp)
    addi sp, sp, 12
    ret

move_bullets:
    addi sp, sp, -4
    sw ra, 0(sp)
    li t1, 0

move_bullets_loop:
    li t2, MAX_BULLETS
    bge t1, t2, end_move_bullets

    slli t3, t1, 2

    la t0, bullet_active
    add t4, t0, t3
    lw t5, 0(t4)
    beqz t5, next_bullet

    la t0, current_level
    lw t5, 0(t0)
    li t6, LEVEL_TOWN
    bne t5, t6, move_bullet_without_town_obstacles

    addi sp, sp, -4
    sw t1, 0(sp)
    mv a0, t1
    call move_town_bullet_with_substeps
    lw t1, 0(sp)
    addi sp, sp, 4
    slli t3, t1, 2
    beqz a0, deactivate_current_bullet
    j next_bullet

move_bullet_without_town_obstacles:
    slli t3, t1, 2

    la t0, bullet_x
    add t4, t0, t3
    lw t5, 0(t4)
    la t0, bullet_dx
    add t6, t0, t3
    lw t6, 0(t6)
    add t5, t5, t6
    blt t5, zero, deactivate_current_bullet
    li t6, SCREEN_WIDTH
    bge t5, t6, deactivate_current_bullet
    sw t5, 0(t4)

    la t0, bullet_y
    add t4, t0, t3
    lw t5, 0(t4)
    la t0, bullet_dy
    add t6, t0, t3
    lw t6, 0(t6)
    add t5, t5, t6
    blt t5, zero, deactivate_current_bullet
    li t6, SCREEN_HEIGHT
    bge t5, t6, deactivate_current_bullet
    sw t5, 0(t4)
    j next_bullet

deactivate_current_bullet:
    la t0, bullet_active
    add t4, t0, t3
    sw zero, 0(t4)

next_bullet:
    addi t1, t1, 1
    j move_bullets_loop

end_move_bullets:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# Broad phase swept compartilhada; subpassos de 1 pixel so rodam
# quando o segmento possui candidatos internos ou externos.
move_town_bullet_with_substeps:
    addi sp, sp, -24
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    sw s3, 16(sp)
    sw s4, 20(sp)

    slli s0, a0, 2
    la t0, bullet_x
    add t0, t0, s0
    lw s1, 0(t0)
    la t0, bullet_y
    add t0, t0, s0
    lw s2, 0(t0)
    la t0, bullet_dx
    add t0, t0, s0
    lw s3, 0(t0)
    la t0, bullet_dy
    add t0, t0, s0
    lw s4, 0(t0)

    mv a0, s1
    mv a1, s2
    mv a2, s3
    mv a3, s4
    li a4, BULLET_SIZE
    call move_town_projectile_swept
    beqz a0, finish_move_town_bullet_with_substeps

    add t1, s1, s3
    la t0, bullet_x
    add t0, t0, s0
    sw t1, 0(t0)
    add t1, s2, s4
    la t0, bullet_y
    add t0, t0, s0
    sw t1, 0(t0)
    li a0, 1

finish_move_town_bullet_with_substeps:
    lw s4, 20(sp)
    lw s3, 16(sp)
    lw s2, 12(sp)
    lw s1, 8(sp)
    lw s0, 4(sp)
    lw ra, 0(sp)
    addi sp, sp, 24
    ret
