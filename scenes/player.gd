class_name Player extends CharacterBody2D

signal died

# TODO remove hardcoded maximum cooldown
const max_cooldown := 0.5

## Singleton instance.
static var instance: Player

@export var walk_speed := 96
@export var fly_speed := 192
@export var inertia := 3

var alive := false

var shoot1_pressed := false
var shoot1_pressed_time := -max_cooldown # milliseconds
var shoot2_pressed := false
var shoot2_pressed_time := -max_cooldown # milliseconds

@export var bullet := preload("res://scenes/bullet.tscn")

@export_group("Internal Nodes")
@export var sprite: Sprite2D
@export var collision_shape: CollisionShape2D

@export var weapon_cooldown_timer: Timer
@export var fly_cooldown_timer: Timer

@export var machine_gun: Weapon
@export var shotgun: Weapon
@export var laser: Weapon

@export var fly_particles: GPUParticles2D
@export var death_particles: GPUParticles2D

@export var hurt_sound: AudioStreamPlayer2D
@export var death_sound1: AudioStreamPlayer2D
@export var death_sound2: AudioStreamPlayer2D
@export var fly_sound: AudioStreamPlayer2D
@export var reloading_sound: AudioStreamPlayer2D


func _enter_tree() -> void:
	assert(Player.instance == null)
	Player.instance = self


func setup() -> void:
	alive = true
	shoot1_pressed = false
	shoot1_pressed_time = - max_cooldown
	shoot2_pressed = false
	shoot2_pressed_time = - max_cooldown
	set_process(true)
	set_physics_process(true)
	set_process_input(true)
	sprite.show()
	collision_shape.disabled = false
	death_particles.emitting = false


func _input(event: InputEvent) -> void:
	var time := Time.get_ticks_msec() / 1000.0

	if event.is_action_pressed("shoot1"):
		shoot1_pressed = true
		shoot1_pressed_time = time

	elif event.is_action_pressed("shoot2"):
		shoot2_pressed = true
		shoot2_pressed_time = time
		if not shoot_weapon(laser):
			reloading_sound.play()
	
	elif event.is_action_pressed("quit"):
		if alive:
			die()


func get_angle_to_mouse() -> float:
	return global_position.angle_to_point(
		get_global_mouse_position()
	) + PI


func _physics_process(delta: float) -> void:
	var input_velocity := Vector2()
	if Input.is_action_pressed("right"):
		input_velocity.x += 1
	if Input.is_action_pressed("left"):
		input_velocity.x -= 1
	if Input.is_action_pressed("down"):
		input_velocity.y += 1
	if Input.is_action_pressed("up"):
		input_velocity.y -= 1

	var new_rotation: float
	if input_velocity.length() != 0:
		var magnitude: float
		var new_velocity := Vector2()
		if not fly_cooldown_timer.is_stopped() or Input.is_action_pressed("shoot1"):
			new_velocity = input_velocity.normalized()
			magnitude = walk_speed
			new_rotation = get_angle_to_mouse()
			fly_particles.emitting = false
			fly_sound.stop()
		else:
			if (
				velocity.length() == 0
				or is_equal_approx(
					absf(velocity.angle_to(input_velocity)), PI
				)
			):
				new_velocity = input_velocity.normalized()
			else:
				new_velocity = (
					velocity.normalized()
					* inertia
					+ input_velocity.normalized()
				).normalized()
			new_rotation = new_velocity.angle()
			magnitude = fly_speed
			fly_particles.emitting = true
			if not fly_sound.playing:
				fly_sound.play()
		velocity = new_velocity * magnitude
		move_and_slide()
	else:
		velocity = Vector2()
		new_rotation = get_angle_to_mouse()
		fly_particles.emitting = false
		fly_sound.stop()
	new_rotation += PI
	# TODO export variable for rotation weight
	rotation = lerp_angle(rotation, new_rotation, 24 * delta)

	var shoot1_currently_pressed := Input.is_action_pressed("shoot1")
	var shoot2_currently_pressed := Input.is_action_pressed("shoot2")
	if shoot1_currently_pressed or shoot1_pressed:
		var time := Time.get_ticks_msec() / 1000.0
		var held_duration := time - shoot1_pressed_time
		var using_machine_gun: bool = held_duration > machine_gun.cooldown
		if shoot1_currently_pressed and using_machine_gun:
			shoot_weapon(machine_gun)
		elif not shoot1_currently_pressed and not using_machine_gun:
			if not shoot_weapon(shotgun):
				reloading_sound.play()
		shoot1_pressed = shoot1_currently_pressed

	elif shoot2_currently_pressed:
		shoot_weapon(laser)
		shoot2_pressed = shoot2_currently_pressed


func shoot_weapon(weapon: Weapon) -> bool:
	if not weapon_cooldown_timer.is_stopped():
		return false
	weapon.fire()
	weapon_cooldown_timer.start(weapon.cooldown)
	fly_cooldown_timer.start()
	SignalBus.screen_shake.emit(weapon.screen_shake)
	return true


func die() -> void:
	alive = false
	set_process(false)
	set_physics_process(false)
	set_process_input(false)
	sprite.hide()
	collision_shape.set_deferred("disabled", true)
	death_sound1.play()
	death_sound2.play()
	fly_particles.emitting = false
	fly_sound.stop()
	death_particles.emitting = true
	SignalBus.screen_shake.emit(1.0)
	died.emit()
