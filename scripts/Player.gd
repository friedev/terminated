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
	var sound: AudioStreamPlayer2D
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
			sound: AudioStreamPlayer2D,
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


enum {
	MACHINE_GUN,
	SHOTGUN,
	LASER
}

# TODO remove hardcoded maximum cooldown
const max_cooldown := 500

@export var walk_speed := 96
@export var fly_speed := 192
@export var inertia := 3
@export var fly_delay := 200 # milliseconds

var alive := false
var last_shot_time := -self.max_cooldown # milliseconds
var last_weapon: Weapon = null
var current_shot_cooldown := 0 # milliseconds
var laser_start := Vector2()
var laser_end := Vector2()

var shoot1_pressed := false
var shoot1_pressed_time := -self.max_cooldown # milliseconds
var shoot2_pressed := false
var shoot2_pressed_time := -self.max_cooldown # milliseconds

@onready var sprite: Sprite2D = %Sprite2D
@onready var collision_shape: CollisionShape2D = %CollisionShape2D
@onready var raycast: RayCast2D = %RayCast2D

@onready var fly_particles: GPUParticles2D = %FlyParticles
@onready var shoot_particles: GPUParticles2D = %ShootParticles
@onready var laser_particles: GPUParticles2D = %LaserParticles
@onready var death_particles: GPUParticles2D = %DeathParticles

@onready var hurt_sound: AudioStreamPlayer2D = %HurtSound
@onready var death_sound1: AudioStreamPlayer2D = %DeathSound1
@onready var death_sound2: AudioStreamPlayer2D = %DeathSound2
@onready var machine_gun_sound: AudioStreamPlayer2D = %MachineGunSound
@onready var shotgun_sound: AudioStreamPlayer2D = %ShotgunSound
@onready var laser_sound: AudioStreamPlayer2D = %LaserSound
@onready var fly_sound: AudioStreamPlayer2D = %FlySound
@onready var reloading_sound: AudioStreamPlayer2D = %ReloadingSound

@onready var bullet := preload("res://scenes/Bullet.tscn")
@onready var base_modulate: Color = self.sprite.modulate
@onready var damage_modulate := Color(2, 2, 2, 1)
@onready var iframe_modulate := Color(1, 1, 1, 0.5)

@onready var weapons := [
	#          Name          DMG CT Speed   Range   CLD  SPRD  KnockB Stun  Laser Sound                  Rand   Color           Particles             SDur Amp
	Weapon.new("Machine Gun", 1, 1, 1500.0, 1536.0, 100, 0.0,  48.0,  0.25, 0,   self.machine_gun_sound, false, Color(1, 1, 1), self.shoot_particles, 0.2, 8),
	Weapon.new("Shotgun",     1, 8, 1500.0, 1536.0, 500, 45.0, 192.0, 0.25, 0,   self.shotgun_sound,     true,  Color(1, 1, 1), self.shoot_particles, 0.4, 10),
	Weapon.new("Laser",       8, 0, 0.0,    1536.0, 500, 0.0,  0.0,   0.25, 250, self.laser_sound,       true,  Color(0, 1, 1), self.laser_particles, .3, 10),
]

func setup() -> void:
	self.alive = true
	self.position = Vector2()
	self.last_shot_time = -self.max_cooldown
	self.current_shot_cooldown = 0
	self.last_weapon = null
	self.shoot1_pressed = false
	self.shoot1_pressed_time = -self.max_cooldown
	self.shoot2_pressed = false
	self.shoot2_pressed_time = -self.max_cooldown
	self.set_process(true)
	self.set_physics_process(true)
	self.set_process_input(true)
	self.sprite.show()
	self.collision_shape.disabled = false
	self.death_particles.emitting = false


func fly_cooling_down() -> bool:
	var time := Time.get_ticks_msec()
	return time - self.last_shot_time < self.current_shot_cooldown + self.fly_delay


func cooling_down() -> bool:
	var time := Time.get_ticks_msec()
	return time - last_shot_time < self.current_shot_cooldown


func _input(event: InputEvent) -> void:
	var time := Time.get_ticks_msec()

	if event.is_action_pressed(&"shoot1"):
		self.shoot1_pressed = true
		self.shoot1_pressed_time = time

	elif event.is_action_pressed(&"shoot2"):
		self.shoot2_pressed = true
		self.shoot2_pressed_time = time
		if not self.shoot_weapon(self.LASER):
			self.reloading_sound.play()


func get_angle_to_mouse() -> float:
	return self.global_position.angle_to_point(
		self.get_global_mouse_position()
	) + PI


func _physics_process(delta: float) -> void:
	var input_velocity := Vector2()
	if Input.is_action_pressed(&"right"):
		input_velocity.x += 1
	if Input.is_action_pressed(&"left"):
		input_velocity.x -= 1
	if Input.is_action_pressed(&"down"):
		input_velocity.y += 1
	if Input.is_action_pressed(&"up"):
		input_velocity.y -= 1

	var new_rotation: float
	if input_velocity.length() != 0:
		var magnitude: float
		var new_velocity := Vector2()
		if self.fly_cooling_down() or Input.is_action_pressed(&"shoot1"):
			new_velocity = input_velocity.normalized()
			magnitude = self.walk_speed
			new_rotation = self.get_angle_to_mouse()
			self.fly_particles.emitting = false
			self.fly_sound.stop()
		else:
			if (
				self.velocity.length() == 0
				or is_equal_approx(
					abs(self.velocity.angle_to(input_velocity)), PI
				)
			):
				new_velocity = input_velocity.normalized()
			else:
				new_velocity = (
					self.velocity.normalized()
					* inertia
					+ input_velocity.normalized()
				).normalized()
			new_rotation = new_velocity.angle()
			magnitude = self.fly_speed
			self.fly_particles.emitting = true
			if not self.fly_sound.playing:
				self.fly_sound.play()
		self.velocity = new_velocity * magnitude
		self.move_and_slide()
	else:
		self.velocity = Vector2()
		new_rotation = get_angle_to_mouse()
		self.fly_particles.emitting = false
		self.fly_sound.stop()
	new_rotation += PI
	# TODO export variable for rotation weight
	self.rotation = lerp_angle(self.rotation, new_rotation, 24 * delta)

	var shoot1_currently_pressed := Input.is_action_pressed(&"shoot1")
	var shoot2_currently_pressed := Input.is_action_pressed(&"shoot2")
	if shoot1_currently_pressed or shoot1_pressed:
		var time := Time.get_ticks_msec()
		var held_duration := time - shoot1_pressed_time
		var using_machine_gun: bool = held_duration > weapons[MACHINE_GUN].cooldown
		if shoot1_currently_pressed and using_machine_gun:
			self.shoot_weapon(MACHINE_GUN)
		elif not shoot1_currently_pressed and not using_machine_gun:
			if not shoot_weapon(SHOTGUN):
				self.reloading_sound.play()
		shoot1_pressed = shoot1_currently_pressed

	elif shoot2_currently_pressed:
		self.shoot_weapon(LASER)
		shoot2_pressed = shoot2_currently_pressed


func shoot_weapon(weapon_index: int) -> bool:
	var weapon: Weapon = weapons[weapon_index]
	var time := Time.get_ticks_msec()
	if self.cooling_down():
		return false

	if weapon.laser_duration > 0:
		self.shoot_laser(
			weapon.damage,
			weapon.max_range,
			weapon.knockback,
			weapon.stun)
	else:
		for _i in weapon.bullet_count:
			self.shoot_bullet(weapon.spread)

	if weapon.particles != null:
		weapon.particles.restart()
	if weapon.sound != null:
		weapon.sound.pitch_scale = 1 + (randf() - 0.5) * 0.25
		weapon.sound.play()
	self.last_shot_time = time
	self.current_shot_cooldown = weapon.cooldown
	self.last_weapon = weapon
	$ShakeCamera2D.shake(
		weapon.shake_duration,
		weapon.shake_amplitude,
		weapon.shake_amplitude
	)
	return true


func shoot_bullet(spread: float) -> void:
	var instance: Bullet = bullet.instantiate()
	instance.position = self.position
	self.get_parent().add_child(instance)
	# look_at() must be called after the instance has entered the tree
	instance.look_at(self.get_global_mouse_position())
	# TODO export variable for distance to stop bullet appearing behind player
	instance.position += Vector2(8, 0).rotated(instance.rotation)
	instance.rotation += (randf() * spread) - (spread * 0.5)
	instance.velocity = (
		self.velocity
		+ Vector2(cos(instance.rotation), sin(instance.rotation))
		* instance.speed
	)


func shoot_laser(damage: int, max_range: float, knockback: float, stun: float) -> void:
	# TODO merge with player laser implementation
	self.raycast.look_at(self.get_global_mouse_position())
	self.raycast.target_position = Vector2(max_range, 0)
	self.raycast.force_raycast_update()
	var collision_point: Vector2
	while self.raycast.is_colliding():
		collision_point = self.raycast.get_collision_point()
		var object_hit = self.raycast.get_collider()
		if object_hit.is_in_group(&"enemies"):
			object_hit.damage_by(
				damage,
				(object_hit.position - self.position).normalized() * knockback,
				stun
			)
			# Don't penetrate large enemies
			if object_hit.max_health > 1:
				break
		elif object_hit is TileMap:
			# TODO merge with other implementations
			var tilemap = object_hit
			var position_hit = (
				collision_point
				+ Vector2(object_hit.tile_set.tile_size.x / 2, 0)
				.rotated(self.raycast.global_rotation)
			)
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
		self.raycast.add_exception(object_hit)
		self.raycast.force_raycast_update()

	self.raycast.clear_exceptions()
	self.laser_start = self.position
	if self.raycast.is_colliding():
		self.laser_end = collision_point
	else:
		self.laser_end = (
			self.raycast.target_position.rotated(self.raycast.global_rotation)
			+ self.position
		)


func die() -> void:
	self.alive = false
	self.set_process(false)
	self.set_physics_process(false)
	self.set_process_input(false)
	self.sprite.hide()
	self.collision_shape.set_deferred(&"disabled", true)
	self.death_sound1.play()
	self.death_sound2.play()
	self.fly_particles.emitting = false
	self.fly_sound.stop()
	self.death_particles.emitting = true
