extends DeathEffect

@onready var particles2: GPUParticles2D = %GPUParticles2D2

func _ready() -> void:
	super._ready()
	self.particles2.restart()
