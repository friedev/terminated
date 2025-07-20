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

var mouse_aim := true

var gun_pressed := false
var gun_pressed_time := -max_cooldown # milliseconds

@export var bullet := preload("res://scenes/bullet.tscn")

@export_group("Internal Nodes")
@export var sprite: Sprite2D
@export var collision_shape: CollisionShape2D
@export var aim_line: Line2D

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
	gun_pressed = false
	gun_pressed_time = - max_cooldown
	set_process(true)
	set_physics_process(true)
	set_process_input(true)
	sprite.show()
	collision_shape.disabled = false
	death_particles.emitting = false


func _input(event: InputEvent) -> void:
	var time := Time.get_ticks_msec() / 1000.0

	if event is InputEventMouseMotion:
		mouse_aim = true
	elif (
		event.is_action_pressed("aim_left")
		or event.is_action_pressed("aim_right")
		or event.is_action_pressed("aim_up")
		or event.is_action_pressed("aim_down")
	):
		mouse_aim = false

	if event.is_action_pressed("gun"):
		gun_pressed = true
		gun_pressed_time = time

	elif event.is_action_pressed("laser"):
		if not shoot_weapon(laser):
			reloading_sound.play()
	
	elif event.is_action_pressed("quit"):
		if alive:
			die()


func get_angle_to_mouse() -> float:
	return global_position.angle_to_point(get_global_mouse_position())
	

func get_aim_input() -> Vector2:
	return Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")

	
func get_aim_angle() -> float:
	return get_angle_to_mouse() if mouse_aim else get_aim_input().angle()


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
		if not fly_cooldown_timer.is_stopped() or Input.is_action_pressed("gun"):
			new_velocity = input_velocity.normalized()
			magnitude = walk_speed
			new_rotation = get_aim_angle() + PI
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
		new_rotation = get_aim_angle() + PI
		fly_particles.emitting = false
		fly_sound.stop()
	new_rotation += PI
	# TODO export variable for rotation weight
	rotation = lerp_angle(rotation, new_rotation, 24 * delta)
	aim_line.global_rotation = get_aim_angle()
	aim_line.visible = not mouse_aim and get_aim_input().length() > 0

	var gun_currently_pressed := Input.is_action_pressed("gun")
	if gun_currently_pressed or gun_pressed:
		var time := Time.get_ticks_msec() / 1000.0
		var held_duration := time - gun_pressed_time
		var using_machine_gun: bool = held_duration > machine_gun.cooldown
		if gun_currently_pressed and using_machine_gun:
			shoot_weapon(machine_gun)
		elif not gun_currently_pressed and not using_machine_gun:
			if not shoot_weapon(shotgun):
				reloading_sound.play()
		gun_pressed = gun_currently_pressed
	elif Input.is_action_pressed("laser"):
		shoot_weapon(laser)
	elif Input.is_action_pressed("shotgun"):
		shoot_weapon(shotgun)
	elif Input.is_action_pressed("machine_gun"):
		shoot_weapon(machine_gun)


func shoot_weapon(weapon: Weapon) -> bool:
	if not weapon_cooldown_timer.is_stopped():
		return false
	weapon.fire(get_aim_angle())
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
	aim_line.hide()
	collision_shape.set_deferred("disabled", true)
	death_sound1.play()
	death_sound2.play()
	fly_particles.emitting = false
	fly_sound.stop()
	death_particles.emitting = true
	SignalBus.screen_shake.emit(1.0)
	died.emit()
