extends KinematicBody2D

const SPEED: float = 300.0

var gravity: float = 600.0

var current_velocity: Vector2 = Vector2.ZERO

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	#if TOP_DOWN
	gravity = 0.0
	#endif
	pass

func _physics_process(delta: float) -> void:
	var intended_movement := Vector2.ZERO
	if Input.is_action_pressed("ui_up"):
		intended_movement.y -= 1
	if Input.is_action_pressed("ui_down"):
		intended_movement.y += 1
	if Input.is_action_pressed("ui_left"):
		intended_movement.x -= 1
	if Input.is_action_pressed("ui_right"):
		intended_movement.x += 1
	
	intended_movement *= SPEED
	
	# NOTE we could get rid of the _ready check by moving the gravity addition
	# into the lower if directive.
	#
	# Not doing it for demo purposes
	intended_movement.y += gravity
	
	#if TOP_DOWN
	move_and_slide(intended_movement)
	#else
	move_and_slide(intended_movement, Vector2.UP)
	#endif

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################


