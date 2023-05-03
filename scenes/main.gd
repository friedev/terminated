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

@export var final_wave_initial_delay: float
@export var final_wave_delay_decrement: float
@export var final_wave_min_delay: float

@export var map_radius: int
@export var arena_radius: int

const debris_small := preload("res://scenes/debris/debris.tscn")
const debris_large := preload("res://scenes/debris/large_debris.tscn")
const crater := preload("res://scenes/debris/crater.tscn")

const enemies: Array[PackedScene] = [
	preload("res://scenes/enemies/basic_enemy.tscn"),
	preload("res://scenes/enemies/strong_enemy.tscn"),
	preload("res://scenes/enemies/laser_enemy.tscn"),
	preload("res://scenes/enemies/basic_enemy.tscn"), # was splitter
	preload("res://scenes/enemies/bomb_enemy.tscn"),
]

const TILE_HEALTH := 8

const FLOOR_COORDS := Vector2i(0, 0)
const DEBRIS_FLOOR_COORDS := Vector2i(self.TILE_HEALTH + 2, 0)
const WALL_COORDS := Vector2i(self.TILE_HEALTH, 0)
const BORDER_COORDS := Vector2i(self.TILE_HEALTH + 1, 0)

var start_time: int
var kills := 0
var wave := 0
var final_wave_delay := final_wave_initial_delay

var flock_center: Vector2
var flock_heading: Vector2

@onready var player: Player = %Player
@onready var tile_map: TileMap = %TileMap
@onready var spawn_timer: Timer = %SpawnTimer
@onready var main_menu: Control = %MainMenu

func _ready() -> void:
	randomize()

	self.player.visible = false
	self.player.set_process(false)
	self.player.set_physics_process(false)
	self.player.set_process_input(false)

	self.setup_tilemap()


func setup_tilemap() -> void:
	var map_tiles = self.map_radius / self.tile_map.tile_set.tile_size.x
	var arena_tiles = self.arena_radius / self.tile_map.tile_set.tile_size.x
	for x in range(-map_tiles, map_tiles + 1):
		for y in range(-map_tiles, map_tiles + 1):
			var v := Vector2i(x, y)
			# Arena center
			if abs(x) <= arena_tiles and abs(y) <= arena_tiles:
				self.tile_map.set_cell(0, v)
				self.tile_map.set_cell(1, v, 0, self.FLOOR_COORDS)
			# Arena border
			elif abs(x) == map_tiles or abs(y) == map_tiles:
				self.tile_map.set_cell(0, v, 0, self.BORDER_COORDS)
				self.tile_map.set_cell(1, v, 0, self.FLOOR_COORDS)
			# Wall area
			else:
				# TODO use alternative tiles to flip walls for variety
#				var flip_x := randi() % 2 == 0
#				var flip_y := randi() % 2 == 0
				self.tile_map.set_cell(0, v, 0, self.WALL_COORDS)
				self.tile_map.set_cell(1, v, 0, self.DEBRIS_FLOOR_COORDS)


func setup() -> void:
	self.setup_tilemap()

	# Need to use free here instead of queue free, otherwise player takes damage
	# from an enemy collision when respawning
	self.get_tree().call_group(&"enemies", &"free")
	self.get_tree().call_group(&"bullets", &"free")
	self.get_tree().call_group(&"debris", &"free")
	self.get_tree().call_group(&"laser_beams", &"free")
	self.get_tree().call_group(&"death_effects", &"free")

	self.kills = 0
	self.wave = 0
	self.final_wave_delay = final_wave_initial_delay

	self.player.setup()
	self.player.visible = true
	self.player.set_process(true)
	self.player.set_physics_process(true)
	self.player.set_process_input(true)

	self.main_menu.visible = false

	self.spawn_timer.wait_time = waves[0].time
	self.start_time = Time.get_ticks_msec()
	self.spawn_timer.start()


func spawn_wave(index: int) -> void:
	for enemy_index in range(len(self.waves[index].enemies)):
		for _i in range(self.waves[index].enemies[enemy_index]):
			self.spawn_enemy(self.enemies[enemy_index])


func spawn_enemy(enemy_scene: PackedScene) -> void:
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
	instance.player = self.player
	self.add_child(instance)


func _process(delta: float) -> void:
	# Update timer; stop timer after player dies
	if self.player.alive:
		var milliseconds := Time.get_ticks_msec() - start_time
		var seconds := milliseconds / 1000
		var minutes := seconds / 60
		milliseconds %= 1000
		seconds %= 60
		%TimerLabel.text = "%02d:%02d.%03d" % [minutes, seconds, milliseconds]
	else:
		self.main_menu.visible = true

	%FPSLabel.text = "FPS: %d" % Engine.get_frames_per_second()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"quit"):
		if self.player.alive:
			self.player.die()
		elif OS.get_name() != "HTML5":
			self.get_tree().quit()
	elif event.is_action_pressed(&"restart"):
		self.setup()
	elif event.is_action_pressed(&"fps"):
		%FPSLabel.visible = !%FPSLabel.visible


func _on_spawn_timer_timeout() -> void:
	if not self.player.alive:
		return

	self.spawn_wave(wave)

	if self.wave < len(self.waves) - 1:
		self.spawn_timer.wait_time = (
			self.waves[self.wave + 1].time - self.waves[self.wave].time
		)
		self.wave += 1
	else:
		self.spawn_timer.wait_time = self.final_wave_delay
		self.final_wave_delay = max(
			self.final_wave_min_delay,
			self.final_wave_delay - self.final_wave_delay_decrement
		)

	self.spawn_timer.start()
