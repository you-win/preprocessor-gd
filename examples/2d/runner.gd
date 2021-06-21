extends CanvasLayer

const ExampleScreen: Resource = preload("res://examples/2d/example_screen.tscn")

onready var viewport: Viewport = $ViewportContainer/Viewport

var preprocessor: Reference = load("res://addons/preprocessor-gd/preprocessor.gd").new()

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	preprocessor.excluded_directories.append_array([
		"res://addons",
		"res://.import"
	])
	preprocessor.excluded_files.append_array([
		"res://default_env.tres",
		"res://icon.png",
		"res://.gitignore"
	])
	
	preprocessor.global_state_pass()
	
	var example_screen: Node2D = ExampleScreen.instance()
	preprocessor.insert_directives(example_screen.get_node("Player"))
	
	viewport.add_child(example_screen)

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################


