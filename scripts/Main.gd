extends Node2D

class Wave:
	var time: float # seconds
	var enemies: Array

	func _init(time: float, enemies: Array):
		self.time = time
		self.enemies = enemies

var waves := [
	Wave.new(0.1, [4,  0, 0, 0, 0]),
	Wave.new(6,   [8,  0, 0, 0, 0]),
	Wave.new(8,   [8,  0, 0, 0, 0]),
	Wave.new(10,  [8,  0, 0, 0, 0]),
	Wave.new(16,  [0,  2, 0, 0, 0]),
	Wave.new(22,  [16, 0, 0, 0, 0]),
	Wave.new(24,  [16, 0, 0, 0, 0]),
	Wave.new(30,  [0,  4, 0, 0, 0]),
	Wave.new(36,  [16, 0, 0, 0, 0]),
	Wave.new(38,  [16, 2, 0, 0, 2]),
	Wave.new(40,  [0,  2, 0, 0, 2]),
	Wave.new(44,  [16, 0, 0, 0, 4]),
	Wave.new(48,  [16, 0, 0, 0, 4]),
	Wave.new(52,  [4,  0, 1, 0, 0]),
	Wave.new(56,  [4,  0, 1, 0, 0]),
	Wave.new(62,  [0,  2, 2, 0, 0]),
	Wave.new(66,  [16, 2, 0, 0, 0]),
	Wave.new(68,  [0,  0, 2, 0, 2]),
	Wave.new(76,  [0,  0, 0, 4, 0]),
	Wave.new(80,  [0,  0, 0, 4, 0]),
	Wave.new(90,  [16, 0, 0, 0, 0]),
	Wave.new(92,  [16, 0, 0, 0, 0]),
	Wave.new(94,  [16, 0, 0, 0, 0]),
	Wave.new(96,  [16, 0, 0, 0, 0]),
	Wave.new(110, [0,  8, 0, 0, 0]),
	Wave.new(116, [0,  0, 3, 0, 0]),
	Wave.new(126, [0,  0, 0, 8, 0]),
	Wave.new(128, [0,  0, 0, 0, 4]),
	Wave.new(140, [16, 2, 1, 1, 2]),
]

@export var final_wave_initial_delay := 10
@export var final_wave_delay_decrement := 1
@export var final_wave_min_delay := 4

@onready var sound_bus_index = AudioServer.get_bus_index("Sound")
@onready var music_bus_index = AudioServer.get_bus_index("Music")

@export var map_radius := 1024
@export var arena_radius := 256

@onready var debris_small := preload("res://scenes/Debris.tscn")
@onready var debris_large := preload("res://scenes/DebrisLarge.tscn")

@onready var enemies := [
	preload("res://scenes/enemies/BasicEnemy.tscn"),
	preload("res://scenes/enemies/StrongEnemy.tscn"),
	preload("res://scenes/enemies/LaserEnemy.tscn"),
	preload("res://scenes/enemies/SplitterEnemy.tscn"),
	preload("res://scenes/enemies/BombEnemy.tscn"),
]

const TILE_HEALTH := 8

var start_time: int
var kills := 0
var wave := 0
var final_wave_delay := final_wave_initial_delay

var flock_center: Vector2
var flock_heading: Vector2

func _ready():
	randomize()

	$Player.visible = false
	$Player.set_process(false)
	$Player.set_physics_process(false)
	$Player.set_process_input(false)

	$MenuLayer/Control/FullscreenCheckBox.button_pressed = OS.get_name() != "HTML5"


func setup():
	var map_tiles = map_radius / $TileMap.tile_set.tile_size.x
	var arena_tiles = arena_radius / $TileMap.tile_set.tile_size.x
	for x in range(-map_tiles, map_tiles + 1):
		for y in range(-map_tiles, map_tiles + 1):
			$FloorTileMap.set_cell(0, Vector2i(x, y), 0, Vector2i(0, 0))
			if abs(x) <= arena_tiles and abs(y) <= arena_tiles:
				$TileMap.set_cell(0, Vector2i(x, y))
			elif abs(x) == map_tiles or abs(y) == map_tiles:
				$TileMap.set_cell(0, Vector2i(x, y), 0, Vector2i(TILE_HEALTH + 1, 0))
			else:
				# TODO use alternative tiles to flip walls for variety
#				var flip_x := randi() % 2 == 0
#				var flip_y := randi() % 2 == 0
				$TileMap.set_cell(0, Vector2i(x, y), 0, Vector2i(TILE_HEALTH, 0))

	# Need to use free here instead of queue free, otherwise player takes damage
	# from an enemy collision when respawning
	for bullet in get_tree().get_nodes_in_group("Bullets"):
		bullet.free()

	for enemy in get_tree().get_nodes_in_group("Enemies"):
		enemy.free()

	for debris in get_tree().get_nodes_in_group("Debris"):
		debris.free()

	kills = 0
	wave = 0
	final_wave_delay = final_wave_initial_delay

	$Player.setup()
	$Player.visible = true
	$Player.set_process(true)
	$Player.set_physics_process(true)
	$Player.set_process_input(true)

	$MenuLayer/Control.visible = false

	$SpawnTimer.wait_time = waves[0].time
	start_time = Time.get_ticks_msec()
	$SpawnTimer.start()


func spawn_wave(index: int):
	for enemy_index in range(len(waves[index].enemies)):
		for _i in range(waves[index].enemies[enemy_index]):
			spawn_enemy(enemies[enemy_index])


func spawn_enemy(enemy_scene):
	# Make sure to update splitter spawn code too (Enemy.gd)
	var instance = enemy_scene.instantiate()
	var padding := 4
	var pos_range = (randf() * 2 - 1) * (arena_radius - padding)
	var pos_binary = (randi() % 2 * 2 - 1) * (arena_radius - padding)
	var x
	var y
	if randi() % 2 == 0:
		x = pos_range
		y = pos_binary
	else:
		x = pos_binary
		y = pos_range
	instance.position = Vector2(x, y)
	instance.add_to_group("Enemies")
	add_child(instance)
	instance.connect("enemy_killed", Callable(self, "_on_enemy_killed"))


func rand_pitch():
	return randf() / 4.0 + 0.875


func _process(delta: float):
	# Call _draw() dynamically
	queue_redraw()

	# Update timer; stop timer after player dies
	if $Player.alive:
		var milliseconds := Time.get_ticks_msec() - start_time
		var seconds := milliseconds / 1000
		var minutes := seconds / 60
		milliseconds %= 1000
		seconds %= 60
		$HUDLayer/Control/TimerLabel.text = "%02d:%02d.%03d" % [minutes, seconds, milliseconds]
	else:
		$MenuLayer/Control.visible = true

	$HUDLayer/Control/FPSLabel.text = "FPS: %d" % Engine.get_frames_per_second()


func _physics_process(delta):
	# Calculate flock parameters here to avoid recomputing for every flockmate
	# Reduces time complexity from O(n^2) to O(n)
	var flock = get_tree().get_nodes_in_group("flock")
	flock_center = Vector2()
	flock_heading = Vector2()
	for flockmate in flock:
		flock_heading += Vector2(1, 0).rotated(flockmate.rotation)
		flock_center += flockmate.position

	if len(flock) > 0:
		flock_heading /= len(flock)
		flock_center /= len(flock)


func _input(event):
	if event.is_action_pressed("quit"):
		if $Player.alive:
			$Player.die()
		elif OS.get_name() != "HTML5":
			get_tree().quit()

	elif event.is_action_pressed("restart"):
		setup()

	elif event.is_action_pressed("fps"):
		$HUDLayer/Control/FPSLabel.visible = !$HUDLayer/Control/FPSLabel.visible


func _on_Timer_timeout():
	if not $Player.alive:
		return

	spawn_wave(wave)

	if wave < len(waves) - 1:
		$SpawnTimer.wait_time = waves[wave + 1].time - waves[wave].time
		wave += 1
	else:
		$SpawnTimer.wait_time = final_wave_delay
		final_wave_delay = max(final_wave_min_delay, final_wave_delay - final_wave_delay_decrement)

	$SpawnTimer.start()


func _on_enemy_killed(enemy):
	if $Player.alive:
		kills += 1

	# Place debris, regardless of cause of death
	var instance: Sprite2D
	if enemy.bomb or enemy.max_health > 1:
		instance = debris_large.instantiate()
	else:
		instance = debris_small.instantiate()

	instance.position = enemy.position
	instance.rotation = randf() * (2 * PI)
	instance.add_to_group("Debris")
	add_child(instance)


func _draw():
	var weapon = $Player.last_weapon
	if weapon != null and weapon.laser_duration > 0:
		var time := Time.get_ticks_msec()
		var power: float = 1.0 - float(time - $Player.last_shot_time) / float(weapon.laser_duration)
		if power > 0.0:
			draw_line($Player.laser_start, $Player.laser_end, weapon.color, 4.0 * power)

	for enemy in get_tree().get_nodes_in_group("Enemies"):
		if enemy.laser and enemy.health > 0:
			if enemy.charging:
				draw_line(enemy.position, enemy.laser_target, enemy.laser_charge_color, 4.0)
			else:
				var time := Time.get_ticks_msec()
				var power: float = 1.0 - float(time - enemy.last_shot_time) / float(enemy.laser_duration)
				if power > 0.0:
					draw_line(enemy.position, enemy.laser_target, enemy.laser_shot_color, 4.0 * power)


func _on_SoundCheckBox_toggled(button_pressed):
	AudioServer.set_bus_mute(sound_bus_index, not button_pressed)


func _on_MusicCheckBox_toggled(button_pressed):
	AudioServer.set_bus_mute(music_bus_index, not button_pressed)


func _on_FullscreenCheckBox_toggled(button_pressed):
	get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (button_pressed) else Window.MODE_WINDOWED


func _on_ScreenShakeCheckbox_toggled(button_pressed):
	$Player/ShakeCamera2D.shake_enabled = button_pressed
