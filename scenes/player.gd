extends CharacterBody2D
class_name Player

# TODO remove hardcoded maximum cooldown
const max_cooldown := 0.5

@export var walk_speed := 96
@export var fly_speed := 192
@export var inertia := 3

var alive := false

var shoot1_pressed := false
var shoot1_pressed_time := -self.max_cooldown # milliseconds
var shoot2_pressed := false
var shoot2_pressed_time := -self.max_cooldown # milliseconds

@onready var sprite: Sprite2D = %Sprite2D
@onready var collision_shape: CollisionShape2D = %CollisionShape2D
@onready var weapon_cooldown_timer: Timer = %WeaponCooldownTimer
@onready var fly_cooldown_timer: Timer = %FlyCooldownTimer

@onready var machine_gun: Weapon = %MachineGun
@onready var shotgun: Weapon = %Shotgun
@onready var laser: Weapon = %Laser

@onready var fly_particles: GPUParticles2D = %FlyParticles
@onready var death_particles: GPUParticles2D = %DeathParticles

@onready var hurt_sound: AudioStreamPlayer2D = %HurtSound
@onready var death_sound1: AudioStreamPlayer2D = %DeathSound1
@onready var death_sound2: AudioStreamPlayer2D = %DeathSound2
@onready var fly_sound: AudioStreamPlayer2D = %FlySound
@onready var reloading_sound: AudioStreamPlayer2D = %ReloadingSound

@onready var bullet := preload("res://scenes/bullet.tscn")

func setup() -> void:
	self.alive = true
	self.position = Vector2()
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


func _input(event: InputEvent) -> void:
	var time := Time.get_ticks_msec() / 1000.0

	if event.is_action_pressed(&"shoot1"):
		self.shoot1_pressed = true
		self.shoot1_pressed_time = time

	elif event.is_action_pressed(&"shoot2"):
		self.shoot2_pressed = true
		self.shoot2_pressed_time = time
		if not self.shoot_weapon(self.laser):
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
		if not self.fly_cooldown_timer.is_stopped() or Input.is_action_pressed(&"shoot1"):
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
		var time := Time.get_ticks_msec() / 1000.0
		var held_duration := time - shoot1_pressed_time
		var using_machine_gun: bool = held_duration > machine_gun.cooldown
		if shoot1_currently_pressed and using_machine_gun:
			self.shoot_weapon(self.machine_gun)
		elif not shoot1_currently_pressed and not using_machine_gun:
			if not shoot_weapon(self.shotgun):
				self.reloading_sound.play()
		shoot1_pressed = shoot1_currently_pressed

	elif shoot2_currently_pressed:
		self.shoot_weapon(self.laser)
		shoot2_pressed = shoot2_currently_pressed


func shoot_weapon(weapon: Weapon) -> bool:
	if not self.weapon_cooldown_timer.is_stopped():
		return false
	weapon.fire()
	self.weapon_cooldown_timer.start(weapon.cooldown)
	self.fly_cooldown_timer.start()

#	$ShakeCamera2D.shake(
#		weapon.shake_duration,
#		weapon.shake_amplitude,
#		weapon.shake_amplitude
#	)

	return true


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
