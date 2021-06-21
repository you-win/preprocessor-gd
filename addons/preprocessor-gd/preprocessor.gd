extends Reference

const BASE_DIRECTORY: String = "res://"
const SELF_NAME: String = "preprocessor.gd"

class GlobalState:
	var defines: Dictionary = {} # String: PoolStringArray

var global_state: GlobalState

var excluded_directories: Array = []
var excluded_files: Array = []

###############################################################################
# Builtin functions                                                           #
###############################################################################

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

static func _parse_file_for_defines(file_path: String, state: GlobalState) -> void:
	var file := File.new()
	if file.open(file_path, File.READ) == OK:
		# Split file into lines
		var code_lines: PoolStringArray = file.get_as_text().split("\n", false)
		
		var current_define_name: String = ""
		var multiline_define: bool = false
		var line_index: int = 0
		while line_index < code_lines.size():
			# Split lines into words
			var code: PoolStringArray = code_lines[line_index].split(" ", false)
			var code_size: int = code.size()
			
			# Defines can be multiline
			var processing_define: bool = false
			if multiline_define:
				processing_define = true
				multiline_define = false # Toggle multiline_define off
			else:
				# Reset if we are no longer processing a define
				current_define_name = ""
			
			var index: int = 0
			while index < code_size:
				var current_word: String = code[index]
				match current_word:
					"#define":
						processing_define = true
					"\\":
						if (index - 1) == code_size:
							multiline_define = true
					_:
						if processing_define:
							if current_define_name.empty():
								current_define_name = current_word
								state.defines[current_define_name] = PoolStringArray()
							else:
								state.defines[current_define_name].push_back(current_word)
				
				index += 1
			
			line_index += 1

static func _insert_directives_into_script(script: Script, state: GlobalState) -> void:
	if not script.has_source_code():
		push_error("Script does not have source code available")
		return
	
	var code_lines: PoolStringArray = script.source_code.split("\n", false)
	var new_source_code: String = ""
	
	var local_file_state := PoolStringArray()
	
	# If
	# Must be defined outside of line loop since if is always multiline
	var processing_if: bool = false
	var has_evaluated_if: bool = false # Eval once
	var is_if_evaluated_true: bool = false # Store value for entirety of if
	var last_if_tag: String = ""
	
	var line_index: int = 0
	while line_index < code_lines.size():
		# Split lines into words, preserve tabs
		var code: PoolStringArray = code_lines[line_index].split(" ")
		var code_size: int = code.size()
		
		var index: int = 0
		while index < code_size:
			var current_word: String = code[index]
			match current_word:
				"\t#if":
					last_if_tag = current_word
					processing_if = true
				"\t#else":
					last_if_tag = current_word
					if not processing_if:
						push_error("Invalid else directive, expected a preceding if")
						return
				"\t#endif":
					processing_if = false
					has_evaluated_if = false
					is_if_evaluated_true = false
				_:
					if processing_if:
						if not has_evaluated_if:
							if state.defines.has(current_word):
								var define_value = state.defines[current_word]
								if define_value.empty():
									is_if_evaluated_true = true
								else:
									push_error("#if does not support inline macros")
									return
							has_evaluated_if = true
							index += 2 # Skip past the if and if define
							continue # Current value is the if define, don't do anything
						
						match last_if_tag:
							"\t#if":
								if is_if_evaluated_true:
									local_file_state.push_back(current_word)
							"\t#else":
								if not is_if_evaluated_true:
									local_file_state.push_back(current_word)
					else:
						local_file_state.push_back(current_word)
			
			index += 1
		
		local_file_state.push_back("\n")
		new_source_code += local_file_state.join(" ")
		local_file_state = PoolStringArray()
		line_index += 1
	
	script.source_code = new_source_code

###############################################################################
# Public functions                                                            #
###############################################################################

func global_state_pass() -> void:
	var dir := Directory.new()
	var current_directory: String = BASE_DIRECTORY
	var directories: Array = []
	
	var gs := GlobalState.new()
	
	while dir.open(current_directory) == OK:
		# Skip '.', '..', and dot files
		dir.list_dir_begin(true, true)
		
		var file_name: String = dir.get_next()
		while file_name != "":
			var path_format: String = "%s/%s"
			if current_directory == BASE_DIRECTORY:
				path_format = "%s%s"
			var absolute_path: String = path_format % [current_directory, file_name]
			
			if dir.current_is_dir():
				if not excluded_directories.has(absolute_path):
					directories.append(absolute_path)
			
			if file_name.get_extension() == "gd":
				if (file_name != SELF_NAME and not excluded_files.has(absolute_path)):
					_parse_file_for_defines(absolute_path, gs)
				
			file_name = dir.get_next()
		
		if not directories.empty():
			current_directory = directories.pop_back()
		else:
			break
	
	global_state = gs

func insert_directives(obj: Object) -> void:
	"""
	We can only insert directives on things that have a script
	(i.e. no primitives)
	"""
	var obj_script: Script = obj.get_script()
	if not obj_script:
		push_error("Unable to get script on object: %s" % obj.name)
		return
	
	_insert_directives_into_script(obj_script, global_state)
	
	obj.set_script(null)
	obj_script.reload()
	obj.set_script(obj_script) # TODO might be unnecessary?
