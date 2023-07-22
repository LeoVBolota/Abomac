extends CPUParticles2D

onready var TimeCreated = Time.get_ticks_msec()

func _process(_delta):
	if Time.get_ticks_msec() - TimeCreated > 1000:
		queue_free()
