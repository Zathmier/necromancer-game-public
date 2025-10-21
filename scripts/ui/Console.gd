extends Control

# Built entirely in code — no inspector/setup needed.

var vbox: VBoxContainer
var output_log: RichTextLabel
var input_line: LineEdit

const ACTION_TOGGLE := "toggle_console"
const WIDTH := 600
const HEIGHT := 200
const MARGIN := 16

func _ready() -> void:
	# 1) Keybinds
	_ensure_keybinds()

	# 2) Layout panel bottom-left
	_configure_panel()

	# 3) Build UI if missing (VBox + OutputLog + InputLine)
	_build_ui()

	# 4) Wire signals
	Bus.toggle_console.connect(_on_toggle)
	Bus.console_output.connect(_on_console_output)
	if not input_line.text_submitted.is_connected(_on_InputLine_text_submitted):
		input_line.text_submitted.connect(_on_InputLine_text_submitted)

	# 5) Start hidden
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(ACTION_TOGGLE):
		Bus.request_toggle_console()
		get_viewport().set_input_as_handled()

# ---------- UI BUILD ----------

func _build_ui() -> void:
	# Reuse if already present, else create
	vbox = get_node_or_null("VBoxContainer") as VBoxContainer
	if vbox == null:
		vbox = VBoxContainer.new()
		vbox.name = "VBoxContainer"
		add_child(vbox)

	# Fill the panel with a bit of padding
	vbox.anchor_left = 0.0
	vbox.anchor_top = 0.0
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 8
	vbox.offset_top = 8
	vbox.offset_right = -8
	vbox.offset_bottom = -8
	vbox.add_theme_constant_override("separation", 6)

	# Output log
	output_log = vbox.get_node_or_null("OutputLog") as RichTextLabel
	if output_log == null:
		output_log = RichTextLabel.new()
		output_log.name = "OutputLog"
		vbox.add_child(output_log)

	# Input line
	input_line = vbox.get_node_or_null("InputLine") as LineEdit
	if input_line == null:
		input_line = LineEdit.new()
		input_line.name = "InputLine"
		vbox.add_child(input_line)

	# Size behavior
	output_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	output_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	output_log.scroll_active = true
	output_log.scroll_following = true
	output_log.bbcode_enabled = false
	output_log.custom_minimum_size.y = 140

	input_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input_line.placeholder_text = "type a command… (help, echo …)"

func _configure_panel() -> void:
	# Bottom-left, fixed size WIDTH×HEIGHT
	anchor_left = 0.0
	anchor_right = 0.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = MARGIN
	offset_right = MARGIN + WIDTH
	offset_bottom = -MARGIN
	offset_top = -MARGIN - HEIGHT

# ---------- Keybinds ----------

func _ensure_keybinds() -> void:
	if not InputMap.has_action(ACTION_TOGGLE):
		InputMap.add_action(ACTION_TOGGLE)
	_add_key_if_missing(ACTION_TOGGLE, KEY_F1)


func _add_key_if_missing(action: String, keycode: Key) -> void:
	for e in InputMap.action_get_events(action):
		if e is InputEventKey and e.physical_keycode == keycode:
			return
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	InputMap.action_add_event(action, ev)

# ---------- Hooks ----------

func _on_toggle() -> void:
	visible = not visible
	if visible and is_instance_valid(input_line):
		input_line.grab_focus()

func _on_console_output(text: String) -> void:
	if is_instance_valid(output_log):
		output_log.append_text(text + "\n")

func _on_InputLine_text_submitted(text: String) -> void:
	if text.strip_edges().is_empty():
		return
	# echo the command itself
	_on_console_output("> " + text)
	Bus.send_console(text)
	input_line.clear()
