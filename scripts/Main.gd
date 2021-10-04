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

export var final_wave_initial_delay := 10
export var final_wave_delay_decrement := 1
export var final_wave_min_delay := 4

onready var sound_bus_index = AudioServer.get_bus_index("Sound")
onready var music_bus_index = AudioServer.get_bus_index("Music")

export var arena_radius := 512
export var spawn_radius := 512

export var health_format_string := "HEALTH: %d/%d"
export var kills_format_string := "KILLS: %d"

onready var gib_small := preload("res://scenes/Gib.tscn")
onready var gib_large := preload("res://scenes/GibLarge.tscn")

onready var enemies := [
	preload("res://scenes/BasicEnemy.tscn"),
	preload("res://scenes/StrongEnemy.tscn"),
	preload("res://scenes/LaserEnemy.tscn"),
	preload("res://scenes/SplitterEnemy.tscn"),
	preload("res://scenes/BombEnemy.tscn"),
]

var start_time: int
var kills := 0
var wave := 0
var final_wave_delay := final_wave_initial_delay

func _ready():
	randomize()
	# OR use a seed, e.g.:
	#seed(123)
	#seed("CorrectHorseBatteryStaple".hash())
	
	for x in range(-arena_radius, arena_radius):
		for y in range(-arena_radius, arena_radius):
			var cellv := Vector2(x, y)
			if (cellv.abs() * $TileMap.cell_size).length() <= arena_radius:
				$TileMap.set_cellv(cellv, 0)
	
	$Player.health = 0
	$Player.visible = false
	$Player.set_process(false)
	$Player.set_physics_process(false)
	$Player.set_process_input(false)
	
	$MenuLayer/Control/FullscreenCheckBox.pressed = OS.get_name() != "HTML5"



func setup():
	# Need to use free here instead of queue free, otherwise player takes damage
	# from an enemy collision when respawning
	for bullet in get_tree().get_nodes_in_group("Bullets"):
		bullet.free()
	
	for enemy in get_tree().get_nodes_in_group("Enemies"):
		enemy.free()
	
	for gib in get_tree().get_nodes_in_group("Gibs"):
		gib.free()
	
	kills = 0
	wave = 0
	final_wave_delay = final_wave_initial_delay
	
	$Player.setup()
	$Player.visible = true
	$Player.set_process(true)
	$Player.set_physics_process(true)
	$Player.set_process_input(true)
	
	$HUDLayer/Control/HealthLabel.text = health_format_string % [$Player.health, $Player.max_health]
	$HUDLayer/Control/KillsLabel.text = kills_format_string % kills
	$MenuLayer/Control.visible = false
	
	$SpawnTimer.wait_time = waves[0].time
	start_time = OS.get_ticks_msec()
	$SpawnTimer.start()


func spawn_wave(index: int):
	for enemy_index in range(len(waves[index].enemies)):
		for _i in range(waves[index].enemies[enemy_index]):
			spawn_enemy(enemies[enemy_index])


func spawn_enemy(enemy_scene):
	# Make sure to update splitter spawn code too (Enemy.gd)
	var instance = enemy_scene.instance()
	var angle = rand_range(0, 2 * PI)
	instance.position = Vector2(cos(angle), sin(angle)) * spawn_radius
	instance.rotation = rand_range(0, 2 * PI)
	instance.add_to_group("Enemies")
	add_child(instance)
	instance.connect("enemy_killed", self, "_on_enemy_killed")


func _process(delta: float):
	# Needed for _draw() to work
	update()
	
	# Update timer; stop timer after player dies
	if $Player.health > 0:
		var milliseconds := OS.get_ticks_msec() - start_time
		var seconds := milliseconds / 1000
		var minutes := seconds / 60
		milliseconds %= 1000
		seconds %= 60
		$HUDLayer/Control/TimerLabel.text = "%02d:%02d.%03d" % [minutes, seconds, milliseconds]
	
	if $Player.stun_duration > 0:
		$HUDLayer/Control/HealthLabel.modulate = Color.red
	else:
		$HUDLayer/Control/HealthLabel.modulate = Color.white
	
	$HUDLayer/Control/FPSLabel.text = "FPS: %d" % Engine.get_frames_per_second()


# If the player leaves the arena, they die
func _on_Area2D_body_exited(body):
	if body == $Player:
		$Player.damage($Player.health)


func _input(event):
	if event.is_action_pressed("quit"):
		if $Player.health > 0:
			$Player.damage($Player.health)
		elif OS.get_name() != "HTML5":
			get_tree().quit()
	
	elif event.is_action_pressed("restart"):
		setup()
	
	elif event.is_action_pressed("fps"):
		$HUDLayer/Control/FPSLabel.visible = !$HUDLayer/Control/FPSLabel.visible

func _on_Timer_timeout():
	if $Player.health == 0:
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
	# If the player is alive, count this enemy death as a kill
	if $Player.health > 0:
		kills += 1
		$HUDLayer/Control/KillsLabel.text = kills_format_string % kills

	# Place gibs, regardless of cause of death
	if $Area2D.overlaps_body(enemy):
		var instance: Sprite
		if enemy.bomb or enemy.max_health > 1:
			instance = gib_large.instance()
		else:
			instance = gib_small.instance()
		
		instance.position = enemy.position
		instance.rotation = randf() * (2 * PI)
		instance.add_to_group("Gibs")
		add_child(instance)


func _draw():
	var weapon = $Player.last_weapon
	if weapon != null and weapon.laser_duration > 0:
		var time := OS.get_ticks_msec()
		var power: float = 1.0 - float(time - $Player.last_shot_time) / float(weapon.laser_duration)
		if power > 0.0:
			draw_line($Player.laser_start, $Player.laser_end, weapon.color, 4.0 * power, false)
	
	for enemy in get_tree().get_nodes_in_group("Enemies"):
		if enemy.laser and enemy.health > 0:
			if enemy.charging:
				draw_line(enemy.position, enemy.laser_target, enemy.laser_charge_color, 1.0, false)
			else:
				var time := OS.get_ticks_msec()
				var power: float = 1.0 - float(time - enemy.last_shot_time) / float(enemy.laser_duration)
				if power > 0.0:
					draw_line(enemy.position, enemy.laser_target, enemy.laser_shot_color, 4.0 * power, false)


func _on_Player_player_damaged():
	$HUDLayer/Control/HealthLabel.text = health_format_string % [$Player.health, $Player.max_health]
	if $Player.health <= 0:
		$MenuLayer/Control.visible = true


func _on_SoundCheckBox_toggled(button_pressed):
	AudioServer.set_bus_mute(sound_bus_index, not button_pressed)


func _on_MusicCheckBox_toggled(button_pressed):
	AudioServer.set_bus_mute(music_bus_index, not button_pressed)


func _on_FullscreenCheckBox_toggled(button_pressed):
	OS.window_fullscreen = button_pressed


func _on_ScreenShakeCheckbox_toggled(button_pressed):
	$Player/ShakeCamera2D.shake_enabled = button_pressed
