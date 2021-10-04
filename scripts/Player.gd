extends KinematicBody2D

signal player_damaged

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
	var light_color: Color
	var light_scale: float
	var light_duration: int # milliseconds
	var particles: Particles2D
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
			light_color: Color,
			light_scale: float,
			light_duration: int,
			particles: Particles2D,
			shake_duration: float,
			shake_amplitude: int):
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
		self.light_color = light_color
		self.light_scale = light_scale
		self.light_duration = light_duration
		self.particles = particles
		self.shake_duration = shake_duration
		self.shake_amplitude = shake_amplitude


onready var weapons := [
	#          Name          DMG CT Speed   Range   CLD  SPRD  KnockB Stun  Laser Sound            Rand   Color           Light Color     LSize LDur Particles        SDur Amp
	Weapon.new("Machine Gun", 1, 1, 1000.0, 1536.0, 100, 0.0,  48.0,  0.25, 0,   $MachineGunSound, false, Color(1, 1, 1), Color(1, 1, 1), 0.25, 100, $ShootParticles, 0.2, 8),
	Weapon.new("Shotgun",     1, 8, 1000.0, 1536.0, 500, 45.0, 192.0, 0.25, 0,   $ShotgunSound,    true,  Color(1, 1, 1), Color(1, 1, 1), 0.5,  100, $ShootParticles, 0.4, 10),
	Weapon.new("Laser",       8, 0, 0.0,    1536.0, 500, 0.0,  0.0,   0.25, 250, $LaserSound,      true,  Color(0, 1, 1), Color(0, 1, 1), 0.5,  200, null,            0.3, 10),
]

enum {
	MACHINE_GUN,
	SHOTGUN,
	LASER
}

const max_cooldown = 500

export var max_health := 5
export var speed := 128

onready var bullet := preload("res://scenes/Bullet.tscn")
onready var main: Node2D = get_tree().get_root().find_node("Main", true, false)
onready var base_modulate: Color = $Sprite.modulate
onready var damage_modulate := Color(2, 2, 2, 1)
onready var iframe_modulate := Color(1, 1, 1, 0.5)

var velocity := Vector2()
var health := max_health
var stun_duration := 0.0 # seconds
var iframe_duration := 0.0 # seconds
# TODO remove hardcoded maximum cooldown
var last_shot_time := -max_cooldown # milliseconds
var last_weapon: Weapon = null
var current_shot_cooldown := 0 # milliseconds
var laser_start := Vector2()
var laser_end := Vector2()

var shoot_pressed := false
var shoot_pressed_time := -max_cooldown # milliseconds


func setup():
	position = Vector2()
	health = max_health
	stun_duration = 0.0
	iframe_duration = 0.0
	last_shot_time = -max_cooldown
	current_shot_cooldown = 0
	last_weapon = null
	shoot_pressed = false
	shoot_pressed_time = -max_cooldown
	set_process(true)
	set_physics_process(true)
	set_process_input(true)
	$Sprite.visible = true
	$LightOccluder2D.visible = true
	$AmbientLight.visible = true
	$CollisionShape2D.disabled = false
	$DeathParticles.emitting = false


func get_input():
	look_at(get_global_mouse_position() - $ShakeCamera2D.position)
	velocity = Vector2()
	if Input.is_action_pressed("right"):
		velocity.x += 1
	if Input.is_action_pressed("left"):
		velocity.x -= 1
	if Input.is_action_pressed("down"):
		velocity.y += 1
	if Input.is_action_pressed("up"):
		velocity.y -= 1
	var magnitude: int = speed
	velocity = velocity.normalized() * magnitude
	
	var shoot_currently_pressed := Input.is_action_pressed("shoot1")
	if shoot_currently_pressed or shoot_pressed:
		var time := OS.get_ticks_msec()
		var held_duration := time - shoot_pressed_time
		var using_machine_gun: bool = held_duration > weapons[MACHINE_GUN].cooldown
		if shoot_currently_pressed and using_machine_gun:
			shoot_weapon(MACHINE_GUN)
		elif not shoot_currently_pressed and not using_machine_gun:
			shoot_pressed = false
			shoot_weapon(SHOTGUN)
	
	# Detects holding down the shoot button
	elif Input.is_action_pressed("shoot2"):
		shoot_weapon(LASER)


func _input(event):
	var time := OS.get_ticks_msec()
	
	if event.is_action_pressed("zoom_in"):
		if $ShakeCamera2D.zoom.x > 0.125:
			$ShakeCamera2D.zoom *= 0.5

	elif event.is_action_pressed("zoom_out"):
		if $ShakeCamera2D.zoom.x < 8.0:
			$ShakeCamera2D.zoom *= 2.0

	# Detects quick taps of the shoot button
	elif event.is_action_pressed("shoot1"):
		shoot_pressed = true
		shoot_pressed_time = time

	elif stun_duration <= 0:
		if Input.is_action_pressed("shoot2"):
			shoot_weapon(LASER)


func _process(delta: float):
	if stun_duration > 0:
		$Sprite.modulate = damage_modulate
	elif iframe_duration > 0:
		$Sprite.modulate = iframe_modulate
	else:
		$Sprite.modulate = base_modulate
	
	var time := OS.get_ticks_msec()
	if current_shot_cooldown > 0:
		# TODO add light duration to weapons, so shotgun light doesn't last as long as laser light
		$ShootLight.energy = max(0.0, 1.0 - float(time - last_shot_time) / float(last_weapon.light_duration))


func _physics_process(delta: float):
	if stun_duration <= 0:
		get_input()
	else:
		velocity -= (delta / stun_duration) * velocity
	
	stun_duration -= delta
	iframe_duration -= delta
	
	move_and_slide(velocity)


func shoot_weapon(weapon_index: int):
	var weapon: Weapon = weapons[weapon_index]
	var time := OS.get_ticks_msec()
	if time - last_shot_time >= current_shot_cooldown:
		if weapon.laser_duration > 0:
			shoot_laser(
				weapon.damage,
				weapon.max_range,
				weapon.knockback,
				weapon.stun)
		else:
			for _i in weapon.bullet_count:
				shoot_bullet(
						weapon.damage,
						weapon.bullet_speed,
						weapon.max_range,
						weapon.spread,
						weapon.knockback,
						weapon.stun,
						weapon.color)
			
		if weapon.particles != null:
			weapon.particles.restart()
		if weapon.sound != null:
			if weapon.random_pitch:
				weapon.sound.pitch_scale = randf() + 0.5
			weapon.sound.play()
		$ShootLight.color = weapon.light_color
		$ShootLight.texture_scale = weapon.light_scale
		last_shot_time = time
		current_shot_cooldown = weapon.cooldown
		last_weapon = weapon
		$ShakeCamera2D.shake(weapon.shake_duration, weapon.shake_amplitude, weapon.shake_amplitude)


func shoot_bullet(damage: int, speed: float, max_range: float, spread: float,
		knockback: float, stun: float, color: Color):
	var instance = bullet.instance()
	# TODO fix magic number offset used so that bullet doesn't appear on the
	# back side of player
	instance.position = self.position + Vector2(cos(self.rotation), sin(self.rotation)) * 8
	instance.initial_position = instance.position
	instance.rotation = self.rotation + (randf() * spread) - (spread * 0.5)
	instance.initial_velocity = velocity
	instance.damage = damage
	instance.speed = speed
	instance.max_range = max_range
	instance.knockback = knockback
	instance.stun = stun
	instance.modulate = color
	instance.add_to_group("Bullets")
	main.add_child(instance)


func shoot_laser(damage: int, max_range: float, knockback: float, stun: float):
	$RayCast2D.cast_to = Vector2(max_range, 0)
	$RayCast2D.force_raycast_update()
	var collision_point: Vector2
	while $RayCast2D.is_colliding():
		collision_point = $RayCast2D.get_collision_point()
		var object_hit = $RayCast2D.get_collider()
		if "Enemy" in object_hit.name:
			object_hit.damage(damage, (object_hit.position - self.position).normalized() * knockback, stun)
			if object_hit.health > 0:
				break
		$RayCast2D.add_exception(object_hit)
		$RayCast2D.force_raycast_update()

	$RayCast2D.clear_exceptions()
	laser_start = position
	laser_end = collision_point if $RayCast2D.is_colliding() else $RayCast2D.cast_to.rotated(rotation) + position


func damage(amount: int, knockback = Vector2(), knockback_duration = 0.5, attack_iframe_duration = 1.0):
	if iframe_duration <= 0:
		health -= amount
		
		$HurtSound.pitch_scale = randf() + 0.5
		$HurtSound.play()
		
		if health <= 0:
			die()
		elif knockback_duration > 0:
			stun_duration = knockback_duration
			iframe_duration = attack_iframe_duration
			velocity = knockback 
			$ShakeCamera2D.shake(knockback_duration, 16, 16)
		
		emit_signal("player_damaged")


func die():
	health = 0
	set_process(false)
	set_physics_process(false)
	set_process_input(false)
	$Sprite.visible = false
	$LightOccluder2D.visible = false
	$AmbientLight.visible = false
	$ShootLight.energy = 0.0
	# Directly setting disabled leads to a seemingly harmless debugger error
	# that recommends using call_deferred, so may as well
	$CollisionShape2D.call_deferred("set_disabled", true)
	$DeathSound.play()
	$DeathParticles.emitting = true


func _on_LightTimer_timeout():
	$ShootLight.enabled = false
