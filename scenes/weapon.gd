extends Node2D
class_name Weapon

@export var cooldown: float
@export var screen_shake: float

@export_group("External Nodes")
@export var wielder: CharacterBody2D

@export_group("Internal Nodes")
@export var particles: GPUParticles2D
@export var sound: AudioStreamPlayer2D
@export var projectile_spawn_point: Node2D


func fire(_fire_angle: float) -> void:
	particles.restart()
	sound.pitch_scale = 1 + (randf() - 0.5) * 0.25
	sound.play()
