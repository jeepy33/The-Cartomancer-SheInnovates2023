extends Sprite


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.

func initialize(frame):
	self.frame = frame
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_collect_area_entered(area):
	if(area.name == "PlayerHurtbox"):
		area.get_parent().get_parent().add_minor_arcana(self.frame)
		self.queue_free()
