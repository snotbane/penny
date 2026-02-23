
## Handles debug tools for the editor only.
@tool class_name PennyPlugin extends EditorPlugin

const AUTOLOAD_PATH := "res://addons/penny/scripts/Penny.gd"
const AUTOLOAD_NAME = "penny"

const PSH_START_LABEL_DEFAULT := true
const PSH_START_LABEL := {
	&"name": "penny/general/start_label",
	&"type": TYPE_STRING_NAME
}

const PSH_ALLOW_ROLLING_DEFAULT := true
const PSH_ALLOW_ROLLING := {
	&"name": "penny/general/allow_rolling",
	&"type": TYPE_BOOL
}

const PSH_ALLOW_SKIPPING_DEFAULT := true
const PSH_ALLOW_SKIPPING := {
	&"name": "penny/general/allow_skipping",
	&"type": TYPE_BOOL
}

static func init_project_setting(hint: Dictionary, value: Variant) -> void:
	assert(hint.has(&"name"), "Project setting missing name.")
	assert(hint.has(&"type"), "Project setting missing type.")

	if not ProjectSettings.has_setting(hint[&"name"]):
		ProjectSettings.set_setting(hint[&"name"], value)
	ProjectSettings.add_property_info(hint)
	ProjectSettings.set_initial_value(hint[&"name"], value)

func _enable_plugin():
	self.add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)
	# EditorInterface.get_resource_filesystem().resources_reimported.connect(_resources_reimported)

	if not ProjectSettings.has_setting(PSH_START_LABEL[&"name"]):
		ProjectSettings.set_setting(PSH_START_LABEL[&"name"], PSH_START_LABEL_DEFAULT)
	ProjectSettings.add_property_info(PSH_START_LABEL)
	ProjectSettings.set_initial_value(PSH_START_LABEL[&"name"], PSH_START_LABEL_DEFAULT)

	if not ProjectSettings.has_setting(PSH_ALLOW_ROLLING[&"name"]):
		ProjectSettings.set_setting(PSH_ALLOW_ROLLING[&"name"], PSH_ALLOW_ROLLING_DEFAULT)
	ProjectSettings.add_property_info(PSH_ALLOW_ROLLING)
	ProjectSettings.set_initial_value(PSH_ALLOW_ROLLING[&"name"], PSH_ALLOW_ROLLING_DEFAULT)

	if not ProjectSettings.has_setting(PSH_ALLOW_SKIPPING[&"name"]):
		ProjectSettings.set_setting(PSH_ALLOW_SKIPPING[&"name"], PSH_ALLOW_SKIPPING_DEFAULT)
	ProjectSettings.add_property_info(PSH_ALLOW_SKIPPING)
	ProjectSettings.set_initial_value(PSH_ALLOW_SKIPPING[&"name"], PSH_ALLOW_SKIPPING_DEFAULT)

	if not ProjectSettings.has_setting(DecorRegistry.PROJECT_SETTING_HINT[&"name"]):
		ProjectSettings.set_setting(DecorRegistry.PROJECT_SETTING_HINT[&"name"], DecorRegistry.PROJECT_SETTING_DEFAULT_VALUE)
	ProjectSettings.add_property_info(DecorRegistry.PROJECT_SETTING_HINT)
	ProjectSettings.set_initial_value(DecorRegistry.PROJECT_SETTING_HINT[&"name"], DecorRegistry.PROJECT_SETTING_DEFAULT_VALUE)

	configure_input()

	ProjectSettings.save()


func _disable_plugin():
	self.remove_autoload_singleton(AUTOLOAD_NAME)
	# EditorInterface.get_resource_filesystem().resources_reimported.disconnect(_resources_reimported)


func _resources_reimported(resources: PackedStringArray) -> void:
	for path in resources: for ext in Penny.RECOGNIZED_EXTENSIONS:
		if path.ends_with(ext): _penny_resource_reimported(path); break


func _penny_resource_reimported(path: String) -> void:
	ResourceLoader.load(path)


func configure_input() -> void:
	if ProjectSettings.get_setting(Penny.SETTING_INPUT_DEBUG_WINDOW) == null:
		var penny_debug_input := InputEventKey.new()
		penny_debug_input.physical_keycode = KEY_D
		penny_debug_input.shift_pressed = true

		ProjectSettings.set_setting(Penny.SETTING_INPUT_DEBUG_WINDOW, {
			"deadzone": Penny.INPUT_DEADZONE_DEFAULT,
			"events": [
				penny_debug_input
			],
		})

	if ProjectSettings.get_setting(Penny.SETTING_INPUT_ADVANCE) == null:
		var penny_advance_input_0 := InputEventKey.new()
		penny_advance_input_0.physical_keycode = KEY_SPACE

		var penny_advance_input_1 := InputEventKey.new()
		penny_advance_input_1.physical_keycode = KEY_Z

		var penny_advance_input_2 := InputEventJoypadButton.new()
		penny_advance_input_2.button_index = JOY_BUTTON_A

		ProjectSettings.set_setting(Penny.SETTING_INPUT_ADVANCE, {
			"deadzone": Penny.INPUT_DEADZONE_DEFAULT,
			"events": [
				penny_advance_input_0,
				penny_advance_input_1,
				penny_advance_input_2,
			]
		})

	if ProjectSettings.get_setting(Penny.SETTING_INPUT_ROLL_BACK) == null:
		var penny_roll_back_input_0 := InputEventMouseButton.new()
		penny_roll_back_input_0.button_index = MOUSE_BUTTON_XBUTTON1

		var penny_roll_back_input_1 := InputEventKey.new()
		penny_roll_back_input_1.physical_keycode = KEY_X

		var penny_roll_back_input_2 := InputEventKey.new()
		penny_roll_back_input_2.physical_keycode = KEY_BACKSPACE

		var penny_roll_back_input_3 := InputEventJoypadButton.new()
		penny_roll_back_input_3.button_index = JOY_BUTTON_LEFT_SHOULDER

		ProjectSettings.set_setting(Penny.SETTING_INPUT_ROLL_BACK, {
			"deadzone": Penny.INPUT_DEADZONE_DEFAULT,
			"events": [
				penny_roll_back_input_0,
				penny_roll_back_input_1,
				penny_roll_back_input_2,
				penny_roll_back_input_3,
			]
		})

	if ProjectSettings.get_setting(Penny.SETTING_INPUT_ROLL_AHEAD) == null:
		var penny_roll_ahead_input_0 := InputEventMouseButton.new()
		penny_roll_ahead_input_0.button_index = MOUSE_BUTTON_XBUTTON2

		var penny_roll_ahead_input_1 := InputEventKey.new()
		penny_roll_ahead_input_1.physical_keycode = KEY_C

		var penny_roll_ahead_input_2 := InputEventKey.new()
		penny_roll_ahead_input_2.button_index = KEY_ENTER

		var penny_roll_ahead_input_3 := InputEventJoypadButton.new()
		penny_roll_ahead_input_3.button_index = JOY_BUTTON_RIGHT_SHOULDER

		ProjectSettings.set_setting(Penny.SETTING_INPUT_ROLL_AHEAD, {
			"deadzone": Penny.INPUT_DEADZONE_DEFAULT,
			"events": [
				penny_roll_ahead_input_0,
				penny_roll_ahead_input_1,
				penny_roll_ahead_input_2,
				penny_roll_ahead_input_3,
			]
		})

	if ProjectSettings.get_setting(Penny.SETTING_INPUT_SCROLL_UP) == null:
		var penny_scroll_up_input_0 := InputEventMouseButton.new()
		penny_scroll_up_input_0.button_index = MOUSE_BUTTON_WHEEL_UP

		var penny_scroll_up_input_1 := InputEventKey.new()
		penny_scroll_up_input_1.physical_keycode = KEY_UP

		var penny_scroll_up_input_2 := InputEventJoypadMotion.new()
		penny_scroll_up_input_2.axis = JOY_AXIS_RIGHT_Y
		penny_scroll_up_input_2.axis_value = -1.0

		ProjectSettings.set_setting(Penny.SETTING_INPUT_SCROLL_UP, {
			"deadzone": Penny.INPUT_DEADZONE_DEFAULT,
			"events": [
				penny_scroll_up_input_0,
				penny_scroll_up_input_1,
				penny_scroll_up_input_2,
			]
		})

	if ProjectSettings.get_setting(Penny.SETTING_INPUT_SCROLL_DOWN) == null:
		var penny_scroll_down_input_0 := InputEventMouseButton.new()
		penny_scroll_down_input_0.button_index = MOUSE_BUTTON_WHEEL_DOWN

		var penny_scroll_down_input_1 := InputEventKey.new()
		penny_scroll_down_input_1.physical_keycode = KEY_DOWN

		var penny_scroll_down_input_2 := InputEventJoypadMotion.new()
		penny_scroll_down_input_2.axis = JOY_AXIS_RIGHT_Y
		penny_scroll_down_input_2.axis_value = +1.0

		ProjectSettings.set_setting(Penny.SETTING_INPUT_SCROLL_DOWN, {
			"deadzone": Penny.INPUT_DEADZONE_DEFAULT,
			"events": [
				penny_scroll_down_input_0,
				penny_scroll_down_input_1,
				penny_scroll_down_input_2,
			]
		})
