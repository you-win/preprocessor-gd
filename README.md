# Preprocessor GD
A C-inspired preprocessor for GDScript.

Have you ever wanted to make your Godot project slightly more optimized at the cost of making it near impossible to debug? Then this is the project for you!

Insert basic gcc directives in your GDScript code and this preprocessor will modify the script at runtime, thus making it impossible to debug via the editor! In return, you can possibly eliminate expensive branching operations!

## NOTE
You are almost certainly better off refactoring your code's hot paths instead of relying on this, but I can't stop you from using this.

## Quickstart
Create a new `preprocessor.gd` object. Set excluded files and directories on the `excluded_files` and `excluded_directories` members. These must be absolute paths (e.g. `res://addons/preprocessor-gd/preprocessor.gd`).

Call the `global_state_pass()` method from the `preprocessor` object.

Call `insert_directives(my_object)` on your object that you want to preprocess.

See the files in `examples/2d/` for a demonstration. `examples/2d/runner.tscn` is the main entry point for the preprocessor.

## Implemented Directives

`#define <thing>` - Define something. Macros are technically parsed but not yet supported.

`#if <define exists>` - Check if a define is present. Doesn't currently support actual expressions.

`#else` - The corresponding block to an `#if`.

## Future goals
- [ ] Implement `#elif` and macros.
- [ ] Create temporary files for debugging purposes.

