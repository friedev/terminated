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
const WALL_COORDS := Vector2i(0, 1)

var kills := 0

var flock_center: Vector2
var flock_heading: Vector2


func _enter_tree() -> void:
	assert(Main.instance == null)
	Main.instance = self


func _ready() -> void:
	Options.setup()

	assert(
		wall_tile_map.tile_set.tile_size == floor_tile_map.tile_set.tile_size,
		"Expected wall and floor tile sizes to match"
	)

	setup_tilemap()
	setup_player_position()

	SignalBus.node_spawned.connect(_on_node_spawned)

	Player.instance.visible = false
	Player.instance.set_process(false)
	Player.instance.set_physics_process(false)
	Player.instance.set_process_input(false)


func setup_tilemap() -> void:
	var wall_coords: Array[Vector2i]
	for x in range(-32, map_size.x + 34):
		for y in range(-32, map_size.y + 34):
			var v := Vector2i(x, y)
			if x <= 0 or x > map_size.x or y <= 0 or y > map_size.y:
				wall_coords.append(v)
				wall_tile_map.set_cell(v, 0, WALL_COORDS)
			else:
				floor_tile_map.set_cell(v, 0, FLOOR_COORDS)
	wall_tile_map.set_cells_terrain_connect(wall_coords, 0, 0, false)


func setup_player_position() -> void:
	Player.instance.global_position = Vector2(
		floor_tile_map.tile_set.tile_size
		* (map_size + Vector2i.ONE * 2)
	) * 0.5


func setup() -> void:
	# Need to use free here instead of queue free, otherwise player takes damage
	# from an enemy collision when respawning
	get_tree().call_group("enemies", "free")
	get_tree().call_group("bullets", "free")
	get_tree().call_group("debris", "free")
	get_tree().call_group("laser_beams", "free")
	get_tree().call_group("death_effects", "free")

	kills = 0

	setup_player_position()
	Player.instance.setup()
	Player.instance.visible = true
	Player.instance.set_process(true)
	Player.instance.set_physics_process(true)
	Player.instance.set_process_input(true)

	main_menu.visible = false

	Globals.start_ticks = Time.get_ticks_msec()
	enemy_spawner.start()
	
	game_started.emit()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		setup()


func _on_node_spawned(node: Node) -> void:
	add_child(node)


func _on_player_died() -> void:
	enemy_spawner.stop()
	main_menu.show()


func _on_main_menu_play_pressed() -> void:
	setup()