extends DeathEffect

@export_group("Internal Nodes")
@export var particles2: GPUParticles2D

func _ready() -> void:
	super._ready()
	particles2.restart()
