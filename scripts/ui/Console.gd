extends Control
# Bottom-left dev console — no inspector required.

var is_open := true  # always visible

# nodes
var dock: Control              # positions the console (bottom-left box)
var bg: Panel                  # the actual rounded background (no extra padding)
var pad: MarginContainer       # inner padding (so text isn't stuck to edges)
var vbox: VBoxContainer
var log_box: RichTextLabel
var input_box: LineEdit

func _ready() -> void:
	# if you still have a leftover full-screen "Background" node from earlier, kill it
	if has_node("Background"):
		$"Background".queue_free()

	_build_ui()
	_log("(console ready)")

	# always visible + start focused
	visible = true
	await get_tree().process_frame
	input_box.grab_focus()

func _unhandled_key_input(event: InputEvent) -> void:
	# Hitting Enter anywhere jumps focus to the input box.
	if event.is_action_pressed("ui_accept") and get_viewport().gui_get_focus_owner() != input_box:
		input_box.grab_focus()
		accept_event()

# ----------------- UI BUILD -----------------
func _build_ui() -> void:
	# This Control (Console root) should be "Full Rect" in the scene.
	# We'll place a docked Control at bottom-left with a fixed size.
	var W := 520
	var H := 260
	var M := 24

	dock = Control.new()
	dock.name = "Dock"
	add_child(dock)

	dock.anchor_left = 0.0
	dock.anchor_right = 0.0
	dock.anchor_top = 1.0
	dock.anchor_bottom = 1.0
	dock.offset_left = M
	dock.offset_right = M + W
	dock.offset_bottom = -M
	dock.offset_top = -M - H
	dock.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Background: precise rect, no automatic container padding = no grey lip.
	bg = Panel.new()
	bg.name = "Background"
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dock.add_child(bg)

	bg.anchor_left = 0.0
	bg.anchor_right = 1.0
	bg.anchor_top = 0.0
	bg.anchor_bottom = 1.0
	bg.offset_left = 0
	bg.offset_top = 0
	bg.offset_right = 0
	bg.offset_bottom = 0

	var p := StyleBoxFlat.new()
	p.bg_color = Color(0, 0, 0, 0.60)     # change alpha if you want
	p.set_border_width_all(0)
	p.set_corner_radius_all(12)
	p.set_content_margin_all(0)           # <- zero padding so nothing sticks out
	bg.add_theme_stylebox_override("panel", p)

	# Padding container so content isn't glued to the edges
	pad = MarginContainer.new()
	pad.name = "Pad"
	pad.add_theme_constant_override("margin_left", 12)
	pad.add_theme_constant_override("margin_right", 12)
	pad.add_theme_constant_override("margin_top", 10)
	pad.add_theme_constant_override("margin_bottom", 10)
	dock.add_child(pad)

	pad.anchor_left = 0.0
	pad.anchor_right = 1.0
	pad.anchor_top = 0.0
	pad.anchor_bottom = 1.0
	pad.offset_left = 0
	pad.offset_top = 0
	pad.offset_right = 0
	pad.offset_bottom = 0

	# Vertical layout inside the padded area
	vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 6)  # 0 if you want it tighter
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pad.add_child(vbox)

	# Log (fills available space)
	log_box = RichTextLabel.new()
	log_box.name = "LogBox"
	log_box.bbcode_enabled = true
	log_box.scroll_active = true
	log_box.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_box.add_theme_color_override("default_color", Color(1,1,1,1))
	vbox.add_child(log_box)

	# Input (fixed height, draws NO background/border)
	input_box = LineEdit.new()
	input_box.name = "InputBox"
	input_box.placeholder_text = "Enter command… (help, echo <text>, cls)"
	input_box.caret_blink = true
	input_box.editable = true
	input_box.focus_mode = Control.FOCUS_ALL

	input_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input_box.size_flags_vertical = 0
	input_box.custom_minimum_size.y = 40

	# Text colors
	input_box.add_theme_color_override("font_color", Color(1,1,1))
	input_box.add_theme_color_override("caret_color", Color(1,1,1))
	input_box.add_theme_color_override("placeholder_color", Color(0.8,0.8,0.8))

	# ZERO visuals on the LineEdit (no fill, border, or padding)
	var sb := StyleBoxFlat.new()
	
	sb.draw_center = false
	sb.set_border_width_all(0)
	sb.set_corner_radius_all(0)
	sb.set_content_margin_all(0)
	input_box.add_theme_stylebox_override("normal", sb)
	input_box.add_theme_stylebox_override("focus", sb.duplicate())
	input_box.add_theme_stylebox_override("hover", sb.duplicate())
	input_box.add_theme_stylebox_override("read_only", sb.duplicate())

	input_box.clear_button_enabled = false
	input_box.add_theme_constant_override("outline_size", 0)
	input_box.add_theme_constant_override("content_margin_left", 0)
	input_box.add_theme_constant_override("content_margin_right", 0)
	input_box.add_theme_constant_override("content_margin_top", 0)
	input_box.add_theme_constant_override("content_margin_bottom", 0)

	vbox.add_child(input_box)
	input_box.text_submitted.connect(_on_input_box_text_submitted)

# ----------------- COMMANDS -----------------
func _on_input_box_text_submitted(text: String) -> void:
	_execute_command(text)
	input_box.text = ""

func _execute_command(raw: String) -> void:
	var cmd: String = raw.strip_edges()
	if cmd.is_empty(): return

	_log("[color=gray]> %s[/color]" % cmd)

	var parts: PackedStringArray = cmd.split(" ", false)
	if parts.is_empty(): return

	var head: String = parts[0]
	var args: String = ""
	if parts.size() > 1:
		args = " ".join(parts.slice(1, parts.size()))

	match head:
		"help":
			_log("Commands: [b]help[/b], [b]echo <text>[/b], [b]cls[/b]")
		"echo":
			_log(args)
		"cls", "clear":
			log_box.clear()
		_:
			_log("[color=tomato]Unknown command:[/color] %s" % head)

func _log(text: String) -> void:
	log_box.append_text(text + "\n")
	log_box.scroll_to_line(max(0, log_box.get_line_count() - 1))
