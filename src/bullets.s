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

    li t2, STATE_BOSS
    beq t1, t2, update_bullets_state_ok

    j end_update_bullets

update_bullets_state_ok:
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
    beqz t1, apply_shoot_buffer

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

    j apply_shoot_buffer

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
    la t0, shoot_direction
    sw t1, 0(t0)

    la t0, shoot_hold_timer
    li t2, PLAYER_SHOOT_HOLD_FRAMES
    sw t2, 0(t0)

apply_shoot_buffer:
    la t0, shoot_hold_timer
    lw t1, 0(t0)
    blez t1, end_check_shoot_input

    addi t1, t1, -1
    sw t1, 0(t0)

    la t0, shoot_direction
    lw a0, 0(t0)
    call spawn_bullet

end_check_shoot_input:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

spawn_bullet:
    addi sp, sp, -8
    sw ra, 0(sp)
    sw a0, 4(sp)

    la t0, weapon_type
    lw t1, 0(t0)
    li t2, WEAPON_SHOTGUN
    beq t1, t2, spawn_shotgun_blast

    la t0, rifle_reload_timer
    lw t1, 0(t0)
    bgtz t1, end_spawn_bullet

    la t0, rifle_fire_cooldown
    lw t1, 0(t0)
    bgtz t1, end_spawn_bullet

    li a5, WEAPON_NORMAL_DAMAGE

    la t0, weapon_type
    lw t1, 0(t0)
    li t2, WEAPON_BOSS
    bne t1, t2, prepare_normal_rifle_shot

    la t0, boss_ammo_count
    lw t1, 0(t0)
    blez t1, prepare_normal_rifle_shot
    addi t1, t1, -1
    sw t1, 0(t0)
    li a5, WEAPON_BOSS_DAMAGE
    li t5, BULLET_SPEED
    call set_cardinal_delta
    call create_bullet_with_delta
    j end_spawn_bullet

prepare_normal_rifle_shot:
    la t0, rifle_mag_count
    lw t1, 0(t0)
    blez t1, try_start_reload_from_shot
    addi t1, t1, -1
    sw t1, 0(t0)
    j arm_rifle_cooldown

try_start_reload_from_shot:
    call start_rifle_reload
    j end_spawn_bullet

arm_rifle_cooldown:
    la t0, rifle_fire_cooldown
    li t1, RIFLE_FIRE_DELAY
    sw t1, 0(t0)

    li t5, BULLET_SPEED
    call set_cardinal_delta
    call create_bullet_with_delta
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

    lw a0, 4(sp)
    li t5, SHOTGUN_BULLET_SPEED
    li t6, SHOTGUN_SPREAD_SPEED
    call set_spread_delta_left
    call create_bullet_with_delta

    lw a0, 4(sp)
    li t5, SHOTGUN_BULLET_SPEED
    li t6, SHOTGUN_SPREAD_SPEED
    call set_spread_delta_right
    call create_bullet_with_delta
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
    beq t1, t2, end_create_bullet_with_delta

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
    addi t5, t5, 4
    la t0, bullet_x
    add t6, t0, t3
    sw t5, 0(t6)

    la t0, player_y
    lw t5, 0(t0)
    addi t5, t5, 4
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
    li a7, 31
    ecall

end_create_bullet_with_delta:
    ret

end_spawn_bullet:
    lw ra, 0(sp)
    addi sp, sp, 8
    ret

move_bullets:
    li t1, 0

move_bullets_loop:
    li t2, MAX_BULLETS
    beq t1, t2, end_move_bullets

    slli t3, t1, 2

    la t0, bullet_active
    add t4, t0, t3
    lw t5, 0(t4)
    beqz t5, next_bullet

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
    ret
