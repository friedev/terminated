extends Node2D

class Wave:
	var time: float # seconds
	var enemies: Array

	@warning_ignore("shadowed_variable")
	func _init(time: float, enemies: Array) -> void:
		self.time = time
		self.enemies = enemies

var waves := [
	Wave.new(0.1, [4, 0, 0, 0, 0]),
	Wave.new(6, [8, 0, 0, 0, 0]),
	Wave.new(8, [8, 0, 0, 0, 0]),
	Wave.new(10, [8, 0, 0, 0, 0]),
	Wave.new(16, [0, 2, 0, 0, 0]),
	Wave.new(22, [16, 0, 0, 0, 0]),
	Wave.new(24, [16, 0, 0, 0, 0]),
	Wave.new(30, [0, 4, 0, 0, 0]),
	Wave.new(36, [16, 0, 0, 0, 0]),
	Wave.new(38, [16, 2, 0, 0, 2]),
	Wave.new(40, [0, 2, 0, 0, 2]),
	Wave.new(44, [16, 0, 0, 0, 4]),
	Wave.new(48, [16, 0, 0, 0, 4]),
	Wave.new(52, [4, 0, 1, 0, 0]),
	Wave.new(56, [4, 0, 1, 0, 0]),
	Wave.new(62, [0, 2, 2, 0, 0]),
	Wave.new(66, [16, 2, 0, 0, 0]),
	Wave.new(68, [0, 0, 2, 0, 2]),
	Wave.new(76, [0, 0, 0, 4, 0]),
	Wave.new(80, [0, 0, 0, 4, 0]),
	Wave.new(90, [16, 0, 0, 0, 0]),
	Wave.new(92, [16, 0, 0, 0, 0]),
	Wave.new(94, [16, 0, 0, 0, 0]),
	Wave.new(96, [16, 0, 0, 0, 0]),
	Wave.new(110, [0, 8, 0, 0, 0]),
	Wave.new(116, [0, 0, 3, 0, 0]),
	Wave.new(126, [0, 0, 0, 8, 0]),
	Wave.new(128, [0, 0, 0, 0, 4]),
	Wave.new(140, [16, 2, 1, 1, 2]),
]

@export var final_wave_initial_delay: float
@export var final_wave_delay_decrement: float
@export var final_wave_min_delay: float

## Dimensions of the arena floor, in tiles.
@export var map_size: Vector2i

@export_group("Internal Nodes")
@export var player: Player
@export var wall_tile_map: TileMapLayer
@export var floor_tile_map: TileMapLayer
@export var spawn_timer: Timer
@export var main_menu: Control
@export var timer_label: Label
@export var fps_label: Label

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

const FLOOR_COORDS := Vector2i(0, 0)
const BORDER_COORDS := Vector2i(9, 0)

var start_time: int
var kills := 0
var wave := 0
var final_wave_delay := final_wave_initial_delay

var flock_center: Vector2
var flock_heading: Vector2

func _ready() -> void:
	assert(
		self.wall_tile_map.tile_set.tile_size == self.floor_tile_map.tile_set.tile_size,
		"Expected wall and floor tile sizes to match"
	)

	self.player.visible = false
	self.player.set_process(false)
	self.player.set_physics_process(false)
	self.player.set_process_input(false)


func setup_tilemap() -> void:
	for x in range(0, self.map_size.x + 2):
		for y in range(0, self.map_size.y + 2):
			var v := Vector2i(x, y)
			self.floor_tile_map.set_cell(v, 0, self.FLOOR_COORDS)
			if x == 0 or x == self.map_size.x + 1 or y == 0 or y == self.map_size.y + 1:
				self.wall_tile_map.set_cell(v, 0, self.BORDER_COORDS)


func setup() -> void:
	self.setup_tilemap()

	# Need to use free here instead of queue free, otherwise player takes damage
	# from an enemy collision when respawning
	self.get_tree().call_group("enemies", "free")
	self.get_tree().call_group("bullets", "free")
	self.get_tree().call_group("debris", "free")
	self.get_tree().call_group("laser_beams", "free")
	self.get_tree().call_group("death_effects", "free")

	self.kills = 0
	self.wave = 0
	self.final_wave_delay = final_wave_initial_delay

	self.player.global_position = Vector2(
		self.floor_tile_map.tile_set.tile_size
		* (self.map_size + Vector2i.ONE * 2)
	) * 0.5
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
	var instance: Enemy = enemy_scene.instantiate()
	var spawn_position: Vector2
	# TODO in theory, we shouldn't need to subtract one from map_size.x/y here
	if randi() % 2 == 0:
		spawn_position = self.floor_tile_map.map_to_local(
			Vector2i(
				randi() % (self.map_size.x - 1),
				0 if randi() % 2 == 0 else self.map_size.y - 1
			) + Vector2i.ONE
		)
	else:
		spawn_position = self.floor_tile_map.map_to_local(
			Vector2i(
				0 if randi() % 2 == 0 else self.map_size.x - 1,
				randi() % self.map_size.y - 1
			) + Vector2i.ONE
		)
	instance.global_position = spawn_position
	instance.player = self.player
	self.add_child(instance)


func _process(_delta: float) -> void:
	# Update timer; stop timer after player dies
	if self.player.alive:
		var milliseconds := Time.get_ticks_msec() - start_time
		@warning_ignore("integer_division")
		var seconds := milliseconds / 1000
		@warning_ignore("integer_division")
		var minutes := seconds / 60
		milliseconds %= 1000
		seconds %= 60
		self.timer_label.text = "%02d:%02d.%03d" % [minutes, seconds, milliseconds]
	else:
		self.main_menu.visible = true

	self.fps_label.text = "FPS: %d" % Engine.get_frames_per_second()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("quit"):
		if self.player.alive:
			self.player.die()
		elif OS.get_name() != "HTML5":
			self.get_tree().quit()
	elif event.is_action_pressed("restart"):
		self.setup()
	elif event.is_action_pressed("fps"):
		self.fps_label.visible = not self.fps_label.visible


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
