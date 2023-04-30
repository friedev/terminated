extends CharacterBody2D
class_name Player

class Weapon:
	var name: String
	var damage: int
	var bullet_count: int
	var bullet_speed: float
	var max_range: float
	var cooldown: int # milliseconds
	var spread: float # radians
	var knockback: float
	var stun: float # seconds
	var laser_duration: int # milliseconds
	var sound: AudioStreamPlayer
	var random_pitch: bool
	var color: Color
	var particles: GPUParticles2D
	var shake_duration: float # seconds
	var shake_amplitude: int

	func _init(
			name: String,
			damage: int,
			bullet_count: int,
			bullet_speed: float,
			max_range: float,
			cooldown: int,
			spread: float, # degrees
			knockback: float,
			stun: float,
			laser_duration: int,
			sound: AudioStreamPlayer,
			random_pitch: bool,
			color: Color,
			particles: GPUParticles2D,
			shake_duration: float,
			shake_amplitude: int):
		self.name = name
		self.damage = damage
		self.bullet_count = bullet_count
		self.bullet_speed = bullet_speed
		self.max_range = max_range
		self.cooldown = cooldown
		self.spread = (spread / 180.0) * PI
		self.knockback = knockback
		self.stun = stun
		self.laser_duration = laser_duration
		self.sound = sound
		self.random_pitch = random_pitch
		self.color = color
		self.particles = particles
		self.shake_duration = shake_duration
		self.shake_amplitude = shake_amplitude


@onready var weapons := [
	#          Name          DMG CT Speed   Range   CLD  SPRD  KnockB Stun  Laser Sound            Rand   Color           Particles        SDur Amp
	Weapon.new("Machine Gun", 1, 1, 1500.0, 1536.0, 100, 0.0,  48.0,  0.25, 0,   $MachineGunSound, false, Color(1, 1, 1), $ShootParticles, 0.2, 8),
	Weapon.new("Shotgun",     1, 8, 1500.0, 1536.0, 500, 45.0, 192.0, 0.25, 0,   $ShotgunSound,    true,  Color(1, 1, 1), $ShootParticles, 0.4, 10),
	Weapon.new("Laser",       8, 0, 0.0,    1536.0, 500, 0.0,  0.0,   0.25, 250, $LaserSound,      true,  Color(0, 1, 1), $LaserParticles, .3, 10),
]

enum {
	MACHINE_GUN,
	SHOTGUN,
	LASER
}

# TODO remove hardcoded maximum cooldown
const max_cooldown = 500

@export var walk_speed := 96
@export var fly_speed := 192
@export var inertia := 3
@export var fly_delay := 200 # milliseconds

@onready var bullet := preload("res://scenes/Bullet.tscn")
@onready var main: Node2D = get_tree().get_root().find_child("Main", true, false)
@onready var base_modulate: Color = $Sprite2D.modulate
@onready var damage_modulate := Color(2, 2, 2, 1)
@onready var iframe_modulate := Color(1, 1, 1, 0.5)

var alive := false
var last_shot_time := -max_cooldown # milliseconds
var last_weapon: Weapon = null
var current_shot_cooldown := 0 # milliseconds
var laser_start := Vector2()
var laser_end := Vector2()

var shoot1_pressed := false
var shoot1_pressed_time := -max_cooldown # milliseconds
var shoot2_pressed := false
var shoot2_pressed_time := -max_cooldown # milliseconds


func setup():
	alive = true
	position = Vector2()
	last_shot_time = -max_cooldown
	current_shot_cooldown = 0
	last_weapon = null
	shoot1_pressed = false
	shoot1_pressed_time = -max_cooldown
	shoot2_pressed = false
	shoot2_pressed_time = -max_cooldown
	set_process(true)
	set_physics_process(true)
	set_process_input(true)
	$Sprite2D.visible = true
	$CollisionShape2D.disabled = false
	$DeathParticles.emitting = false


func fly_cooling_down():
	var time := Time.get_ticks_msec()
	return time - last_shot_time < current_shot_cooldown + fly_delay


func cooling_down():
	var time := Time.get_ticks_msec()
	return time - last_shot_time < current_shot_cooldown


func _input(event):
	var time := Time.get_ticks_msec()

	if event.is_action_pressed("shoot1"):
		shoot1_pressed = true
		shoot1_pressed_time = time

	elif event.is_action_pressed("shoot2"):
		shoot2_pressed = true
		shoot2_pressed_time = time
		if not shoot_weapon(LASER):
			$ClickSound.play()


func get_mouse_position():
	return get_global_mouse_position() - $ShakeCamera2D.position


func get_angle_to_mouse():
	return global_position.angle_to_point(get_mouse_position()) + PI


func _physics_process(delta: float):
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
		if fly_cooling_down() or (Input.is_action_pressed("shoot1") or Input.is_action_pressed("shoot1")):
			new_velocity = input_velocity.normalized()
			magnitude = walk_speed
			new_rotation = get_angle_to_mouse()
			$FlyParticles.emitting = false
			$FlySound.stop()
		else:
			if velocity.length() == 0 or is_equal_approx(abs(velocity.angle_to(input_velocity)), PI):
				new_velocity = input_velocity.normalized()
			else:
				new_velocity = (velocity.normalized() * inertia + input_velocity.normalized()).normalized()
			new_rotation = new_velocity.angle()
			magnitude = fly_speed
			$FlyParticles.emitting = true
			if not $FlySound.playing:
				$FlySound.play()
		velocity = new_velocity * magnitude
		set_velocity(velocity)
		move_and_slide()
		velocity = velocity
	else:
		velocity = Vector2()
		new_rotation = get_angle_to_mouse()
		$FlyParticles.emitting = false
		$FlySound.stop()
	new_rotation += PI
	# TODO export variable for rotation weight
	rotation = lerp_angle(rotation, new_rotation, 24 * delta)

	var shoot1_currently_pressed := Input.is_action_pressed("shoot1")
	var shoot2_currently_pressed := Input.is_action_pressed("shoot2")
	if shoot1_currently_pressed or shoot1_pressed:
		var time := Time.get_ticks_msec()
		var held_duration := time - shoot1_pressed_time
		var using_machine_gun: bool = held_duration > weapons[MACHINE_GUN].cooldown
		if shoot1_currently_pressed and using_machine_gun:
			shoot_weapon(MACHINE_GUN)
		elif not shoot1_currently_pressed and not using_machine_gun:
			if not shoot_weapon(SHOTGUN):
				$ClickSound.play()
		shoot1_pressed = shoot1_currently_pressed

	elif shoot2_currently_pressed:
		shoot_weapon(LASER)
		shoot2_pressed = shoot2_currently_pressed


func shoot_weapon(weapon_index: int):
	var weapon: Weapon = weapons[weapon_index]
	var time := Time.get_ticks_msec()
	if cooling_down():
		return false

	if weapon.laser_duration > 0:
		shoot_laser(
			weapon.damage,
			weapon.max_range,
			weapon.knockback,
			weapon.stun)
	else:
		for _i in weapon.bullet_count:
			shoot_bullet(weapon.spread)

	if weapon.particles != null:
		weapon.particles.restart()
	if weapon.sound != null:
		weapon.sound.pitch_scale = main.rand_pitch()
		weapon.sound.play()
	last_shot_time = time
	current_shot_cooldown = weapon.cooldown
	last_weapon = weapon
	$ShakeCamera2D.shake(weapon.shake_duration, weapon.shake_amplitude, weapon.shake_amplitude)
	return true


func shoot_bullet(spread: float):
	var instance: Bullet = bullet.instantiate()
	instance.position = self.position
	self.get_parent().add_child(instance)
	# look_at() must be called after the instance has entered the tree
	instance.look_at(get_mouse_position())
	# TODO export variable for distance to stop bullet appearing behind player
	instance.position += Vector2(8, 0).rotated(instance.rotation)
	instance.rotation += (randf() * spread) - (spread * 0.5)
	instance.velocity = (
		self.velocity
		+ Vector2(cos(instance.rotation), sin(instance.rotation))
		* instance.speed
	)


func shoot_laser(damage: int, max_range: float, knockback: float, stun: float):
	# TODO merge with player laser implementation
	$RayCast2D.look_at(get_mouse_position())
	$RayCast2D.target_position = Vector2(max_range, 0)
	$RayCast2D.force_raycast_update()
	var collision_point: Vector2
	while $RayCast2D.is_colliding():
		collision_point = $RayCast2D.get_collision_point()
		var object_hit = $RayCast2D.get_collider()
		if object_hit.is_in_group(&"enemies"):
			object_hit.damage_by(damage, (object_hit.position - self.position).normalized() * knockback, stun)
			# Don't penetrate large enemies
			if object_hit.max_health > 1:
				break
		elif object_hit is TileMap:
			# TODO merge with other implementations
			var tilemap = object_hit
			var position_hit = collision_point + Vector2(object_hit.tile_set.tile_size.x / 2, 0).rotated($RayCast2D.global_rotation)
			var cellv = object_hit.local_to_map(position_hit)
			var tile_id = tilemap.get_cell_atlas_coords(0, cellv).x
			if 0 < tile_id and tile_id < 9:
				var new_tile_id = tile_id - 9
				if new_tile_id <= 0:
					new_tile_id = -1
				# TODOO flip tiles
				#var flip_x = tilemap.is_cell_x_flipped(cellv.x, cellv.y)
				#var flip_y = tilemap.is_cell_y_flipped(cellv.x, cellv.y)
				tilemap.set_cell(0, cellv, 0, Vector2i(new_tile_id, 0))
			break
		$RayCast2D.add_exception(object_hit)
		$RayCast2D.force_raycast_update()

	$RayCast2D.clear_exceptions()
	laser_start = position
	if $RayCast2D.is_colliding():
		laser_end = collision_point
	else:
		laser_end = $RayCast2D.target_position.rotated($RayCast2D.global_rotation) + position


func die():
	alive = false
	set_process(false)
	set_physics_process(false)
	set_process_input(false)
	$Sprite2D.visible = false
	# Directly setting disabled leads to a seemingly harmless debugger error
	# that recommends using call_deferred, so may as well
	$CollisionShape2D.call_deferred("set_disabled", true)
	$DeathSound1.play()
	$DeathSound2.play()
	$FlyParticles.emitting = false
	$FlySound.stop()
	$DeathParticles.emitting = true
