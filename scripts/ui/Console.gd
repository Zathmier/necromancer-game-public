extends Control

@onready var vbox: VBoxContainer = $VBoxContainer
@onready var output_log: RichTextLabel = %OutputLog
@onready var input_line: LineEdit = %InputLine

const ACTION_TOGGLE := "toggle_console"
const WIDTH := 600
const HEIGHT := 200
const MARGIN := 16

func _ready() -> void:
	visible = false

	# 1) Ensure keybinds exist (F1 + `)
	_ensure_keybinds()

	# 2) Layout this panel to bottom-left (600x200) in code
	_configure_layout()

	# 3) Make VBox fill the panel with padding
	_configure_vbox()

	# 4) Hook up backend signals / UI signals
	Bus.toggle_console.connect(_on_toggle)
	Bus.console_output.connect(_on_console_output)
	if not input_line.text_submitted.is_connected(_on_InputLine_text_submitted):
		input_line.text_submitted.connect(_on_InputLine_text_submitted)

	# 5) Scroll settings for the log
	output_log.scroll_active = true
	output_log.scroll_following = true

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(ACTION_TOGGLE):
		Bus.request_toggle_console()
		get_viewport().set_input_as_handled()

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
	Bus.send_output("> " + text)
	Bus.send_console(text)
	input_line.clear()

# ---------- helpers ----------

func _ensure_keybinds() -> void:
	if not InputMap.has_action(ACTION_TOGGLE):
		InputMap.add_action(ACTION_TOGGLE)
	# Add F1
	_add_key_if_missing(ACTION_TOGGLE, KEY_F1)

func _add_key_if_missing(action: String, keycode: Key) -> void:
	for e in InputMap.action_get_events(action):
		if e is InputEventKey and e.physical_keycode == keycode:
			return
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	InputMap.action_add_event(action, ev)

func _configure_layout() -> void:
	# bottom-left anchoring
	anchor_left = 0.0
	anchor_right = 0.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	# offsets: width/height with margins
	offset_left = MARGIN
	offset_right = MARGIN + WIDTH
	offset_bottom = -MARGIN
	offset_top = -MARGIN - HEIGHT

func _configure_vbox() -> void:
	# make VBox fill entire console with 8px inner padding
	vbox.anchor_left = 0.0
	vbox.anchor_top = 0.0
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 8
	vbox.offset_top = 8
	vbox.offset_right = -8
	vbox.offset_bottom = -8
