extends CanvasLayer

# Menu Pause global (autoload "PauseMenu").
# Échap : ouvre/ferme le menu — ou ferme d'abord la boîte d'info si elle est ouverte.

const FONT_DIR := "res://UI/fonts/"
const PALE_YELLOW := Color(1.0, 0.98, 0.72)

var _font: Font = null

func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_font = _find_font()
	_build()

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 28)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "Pause"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", PALE_YELLOW)
	title.add_theme_font_size_override("font_size", 72)
	if _font != null:
		title.add_theme_font_override("font", _font)
	vbox.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 24)
	vbox.add_child(spacer)

	vbox.add_child(_btn("Continuer", _on_continue))
	vbox.add_child(_btn("Réglages", _on_settings))
	vbox.add_child(_btn("Quitter", _on_quit))

func _btn(txt: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(360, 72)
	b.add_theme_font_size_override("font_size", 40)
	b.add_theme_color_override("font_color", PALE_YELLOW)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color(0.8, 0.78, 0.5))
	if _font != null:
		b.add_theme_font_override("font", _font)
	b.pressed.connect(cb)
	return b

# --- Échap universel ---
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if InfoPanel.visible:
			InfoPanel.close()
		elif visible:
			_resume()
		else:
			_open()
		get_viewport().set_input_as_handled()

func _open() -> void:
	visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _resume() -> void:
	visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_continue() -> void:
	_resume()

func _on_settings() -> void:
	# Ouvre le panneau Profil + Réglages (prochaine étape). Branché dès qu'il existe.
	var pr := get_node_or_null("/root/ProfilReglages")
	if pr and pr.has_method("open"):
		pr.open()

func _on_quit() -> void:
	GameState.save_game()
	get_tree().quit()

func _find_font() -> Font:
	var dir := DirAccess.open(FONT_DIR)
	if dir:
		for f in dir.get_files():
			if f.get_extension().to_lower() in ["ttf", "otf", "woff", "woff2"]:
				var r = load(FONT_DIR + f)
				if r is Font:
					return r
	return null
