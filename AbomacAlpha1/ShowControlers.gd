extends Area2D

onready var label: = $CanvasLayer/Label

func _ready():
	label.set_visible_characters(0)

func _on_ShowControlers_body_entered(body):
	label.set_visible_characters(-1)

func _on_ShowControlers_body_exited(body):
	label.set_visible_characters(0)
