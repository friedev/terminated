extends KinematicBody2D

signal enemy_killed(enemy)

export var acceleration: float
export var max_speed: float
export var max_health: int
export var damage: int
export var attack_knockback: float

export var laser: bool
export var laser_range := 1536.0
export var laser_duration := 250
export var laser_shot_color := Color(1, 0, 0, 1)
export var laser_charge_color := Color(1, 0, 0, 0.5)

export var splitter: bool
export var bomb: bool

# If velocity is below this threshold, face the player instead of facing the velocity
export var velocity_threshold := 10.0

# Can't preload this scene, since that causes Enemy.gd to be loaded, ergo a cyclic reference
const splitter_enemy_path = "res://scenes/SplitterEnemy.tscn"
const max_enemies = 100

onready var main: Node2D = get_tree().get_root().find_node("Main", true, false)
onready var player: KinematicBody2D = get_tree().get_root().find_node("Player", true, false)

onready var base_modulate: Color = $Sprite.modulate
onready var damage_modulate := Color(2, 2, 2, 1)

onready var health := max_health
var velocity := Vector2()
var stun_duration := 0.0

var charging := false
var laser_target := Vector2()
var last_shot_time := -laser_duration


func _ready():
	if laser:
		$CooldownTimer.start()
	$AmbientSound.pitch_scale = randf() + 0.5
	$AmbientSound.play()


func _physics_process(delta: float):
	if acceleration > 0 and max_speed > 0:
		if stun_duration <= 0:
			if velocity.length() > velocity_threshold:
				rotation = velocity.angle()
			else:
				look_at(player.position)
			
			velocity -= Vector2(acceleration, 0).rotated(position.angle_to_point(player.position))
			if velocity.length() > max_speed:
				velocity = velocity.normalized() * max_speed
			
			var collision = move_and_collide(velocity * delta, true, true, true)
			if collision:
				if collision.collider == player:
					player.die()
				elif "Enemy" in collision.collider.name:
					if max_health > 1 and collision.collider.max_health == 1:
						collision.collider.die()
					elif max_health == 1 and collision.collider.max_health > 1:
						die()
			
			velocity = move_and_slide(velocity)
		else:
			velocity -= (delta / stun_duration) * velocity
			stun_duration -= delta
			velocity = move_and_slide(velocity)
	elif not charging:
		look_at(player.position)


func damage(amount: int, knockback = Vector2(), knockback_duration = 0.5):
	# Enemies are NOT invincible while stunned
	health -= amount

	$HurtSound.pitch_scale = randf() + 0.5
	$HurtSound.play()

	if health <= 0:
		die()
	elif knockback_duration > 0:
		stun_duration = knockback_duration
		velocity = knockback


func die():
	health = 0
	set_physics_process(false)
	$Sprite.visible = false
	$CollisionShape2D.disabled = true
	$DeathSound.pitch_scale = randf() + 0.5
	$DeathSound.play()
	$AmbientSound.stop()

	if bomb:
		for body in $BombArea.get_overlapping_bodies():
			if (body == player
					or ("Enemy" in body.name
					and body != self
					and body.health > 0)):
				body.die()
		$BombParticles1.emitting = true
		$BombParticles2.emitting = true
	else:
		$DeathParticles.emitting = true

	$DeathTimer.start()
	emit_signal("enemy_killed", self)


func _on_CooldownTimer_timeout():
	if not laser:
		return
	
	$ChargeTimer.start()
	charging = true
	$RayCast2D.cast_to = Vector2(laser_range, 0)
	laser_target = $RayCast2D.cast_to.rotated(rotation) + position


func _on_ChargeTimer_timeout():
	if not laser or health <= 0:
		return
	
	$CooldownTimer.start()
	charging = false
	
	$RayCast2D.force_raycast_update()
	var collision_point: Vector2
	while $RayCast2D.is_colliding():
		collision_point = $RayCast2D.get_collision_point()
		var object_hit = $RayCast2D.get_collider()
		if object_hit == player or "Enemy" in object_hit.name:
			object_hit.die()
			# TODO just use normal damage when there are bosses
			#if object_hit.health > 0:
			#	break
		$RayCast2D.add_exception(object_hit)
		$RayCast2D.force_raycast_update()

	$RayCast2D.clear_exceptions()
	last_shot_time = OS.get_ticks_msec()
	$LaserSound.pitch_scale = randf() + 0.5
	$LaserSound.play()


func split():
	if not splitter or health <= 0 or player.health <= 0:
		return
	
	if len(get_tree().get_nodes_in_group("Enemies")) < max_enemies:
		var instance = load(splitter_enemy_path).instance()
		instance.position = position + Vector2(8, 0).rotated(randf() * (2 * PI))
		instance.rotation = rotation
		instance.velocity = velocity
		instance.add_to_group("Enemies")
		main.add_child(instance)
		instance.connect("enemy_killed", main, "_on_enemy_killed")


func _on_SplitTimer_timeout():
	split()


func _on_DeathTimer_timeout():
	queue_free()
