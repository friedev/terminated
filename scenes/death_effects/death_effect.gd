extends Node2D
class_name DeathEffect

@export_group("Internal Nodes")
@export var sound: AudioStreamPlayer2D
@export var particles: GPUParticles2D


func _ready():
	self.sound.pitch_scale = 1 + (randf() - 0.5) * 0.25
	self.sound.play()
	self.particles.restart()


func _on_audio_stream_player_2d_finished() -> void:
	self.queue_free()
