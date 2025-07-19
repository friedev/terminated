class_name Main extends Node2D

signal game_started

## Singleton instance.
static var instance: Main

## Dimensions of the arena floor, in tiles.
@export var map_size: Vector2i

@export_group("Internal Nodes")
@export var wall_tile_map: TileMapLayer
@export var floor_tile_map: TileMapLayer
@export var enemy_spawner: EnemySpawner
@export var main_menu: Control

const FLOOR_COORDS := Vector2i(0, 0)
const BORDER_COORDS := Vector2i(9, 0)

var kills := 0

var flock_center: Vector2
var flock_heading: Vector2


func _enter_tree() -> void:
	assert(Main.instance == null)
	Main.instance = self


func _ready() -> void:
	Options.setup()

	assert(
		self.wall_tile_map.tile_set.tile_size == self.floor_tile_map.tile_set.tile_size,
		"Expected wall and floor tile sizes to match"
	)

	self.setup_tilemap()
	self.setup_player_position()

	SignalBus.node_spawned.connect(self._on_node_spawned)

	Player.instance.visible = false
	Player.instance.set_process(false)
	Player.instance.set_physics_process(false)
	Player.instance.set_process_input(false)


func setup_tilemap() -> void:
	for x in range(0, self.map_size.x + 2):
		for y in range(0, self.map_size.y + 2):
			var v := Vector2i(x, y)
			self.floor_tile_map.set_cell(v, 0, self.FLOOR_COORDS)
			if x == 0 or x == self.map_size.x + 1 or y == 0 or y == self.map_size.y + 1:
				self.wall_tile_map.set_cell(v, 0, self.BORDER_COORDS)


func setup_player_position() -> void:
	Player.instance.global_position = Vector2(
		self.floor_tile_map.tile_set.tile_size
		* (self.map_size + Vector2i.ONE * 2)
	) * 0.5


func setup() -> void:
	# Need to use free here instead of queue free, otherwise player takes damage
	# from an enemy collision when respawning
	self.get_tree().call_group("enemies", "free")
	self.get_tree().call_group("bullets", "free")
	self.get_tree().call_group("debris", "free")
	self.get_tree().call_group("laser_beams", "free")
	self.get_tree().call_group("death_effects", "free")

	self.kills = 0

	self.setup_player_position()
	Player.instance.setup()
	Player.instance.visible = true
	Player.instance.set_process(true)
	Player.instance.set_physics_process(true)
	Player.instance.set_process_input(true)

	self.main_menu.visible = false

	Globals.start_ticks = Time.get_ticks_msec()
	self.enemy_spawner.start()
	
	self.game_started.emit()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		self.setup()


func _on_node_spawned(node: Node) -> void:
	self.add_child(node)


func _on_player_died() -> void:
	self.enemy_spawner.stop()
	self.main_menu.show()


func _on_main_menu_play_pressed() -> void:
	self.setup()