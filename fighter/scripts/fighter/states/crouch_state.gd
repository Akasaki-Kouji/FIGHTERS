class_name CrouchState
extends FighterState

func enter() -> void:
	fighter.play_anim(&"crouch")
	fighter.velocity.x = 0

func physics_update(_delta: float) -> void:
	var y := fighter.input.axis_y()
	if y <= 0.5:
		machine.change_to(&"Idle")
