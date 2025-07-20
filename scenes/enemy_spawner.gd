class_name EnemySpawner extends Node

@export var starting_difficulty: int
@export var difficulty_per_wave: int
@export var enemy_scenes: Array[PackedScene]

@export_group("Internal Nodes")
@export var spawn_timer: Timer
@export var spawn_shape_cast: ShapeCast2D

var wave := 0
var enemy_prototypes: Dictionary[PackedScene, Enemy]


func _ready() -> void:
	for enemy_scene in enemy_scenes:
		enemy_prototypes[enemy_scene] = enemy_scene.instantiate()


func start() -> void:
	wave = 0
	spawn_wave()
	spawn_timer.start()


func stop() -> void:
	spawn_timer.stop()


func spawn_wave() -> void:
	var difficulty := starting_difficulty + wave * difficulty_per_wave
	spawn_enemies(difficulty)
	wave += 1


func spawn_enemies(max_difficulty: int) -> void:
	var difficulty := 0

	var open_coords: Array[Vector2i]
	for x in range(Main.instance.map_size.x):
		open_coords.append(Vector2i(x + 1, 1))
		open_coords.append(Vector2i(x + 1, Main.instance.map_size.y))
	for y in range(1, Main.instance.map_size.y - 1):
		open_coords.append(Vector2i(1, y + 1))
		open_coords.append(Vector2i(Main.instance.map_size.x, y + 1))

	while difficulty < max_difficulty:
		if len(open_coords) == 0:
			push_warning(
				"Not enough space to spawn enemies; stopping at %d difficulty out of %d max"
				% [difficulty, max_difficulty]
			)
			break

		var spawn_coords := open_coords[randi() % len(open_coords)]
		open_coords.erase(spawn_coords)
		var spawn_position := Main.instance.floor_tile_map.map_to_local(spawn_coords)

		spawn_shape_cast.global_position = spawn_position
		spawn_shape_cast.force_shapecast_update()
		if spawn_shape_cast.is_colliding():
			continue

		var possible_enemy_scenes: Array[PackedScene]

		var total_weight := 0.0
		for enemy_scene in enemy_scenes:
			var enemy_prototype := enemy_prototypes[enemy_scene]
			if wave >= enemy_prototype.min_wave and enemy_prototype.difficulty <= max_difficulty:
				possible_enemy_scenes.append(enemy_scene)
				total_weight += enemy_prototype.weight

		if len(possible_enemy_scenes) == 0:
			push_warning(
				"No more valid enemies to spawn; stopping at %d difficulty out of %d max"
				% [difficulty, max_difficulty]
			)
			break

		var chosen_weight := randf() * total_weight
		var current_weight := 0.0
		for enemy_scene in possible_enemy_scenes:
			current_weight += enemy_prototypes[enemy_scene].weight
			if current_weight > chosen_weight:
				var enemy: Enemy = enemy_scene.instantiate()
				enemy.global_position = spawn_position
				SignalBus.node_spawned.emit(enemy)
				difficulty += enemy.difficulty
				break


func _on_spawn_timer_timeout() -> void:
	spawn_wave()


func _on_player_died() -> void:
	stop()


func _exit_tree() -> void:
	for enemy_scene in enemy_prototypes:
		enemy_prototypes[enemy_scene].queue_free()