extends CanvasLayer

# Panneau d'info réutilisable (autoload "InfoPanel").
# Usage :  InfoPanel.show_box("present")  ou  InfoPanel.show_for_stele("passe", "res://Scenes/strataWorld.scn")

const MARGIN := 160
const PALE_YELLOW := Color(1.0, 0.98, 0.72)
const BG_PATH := "res://UI/fondViergeFenetreInfo.jpg"
const BTN_DIR := "res://UI/"
const FONT_DIR := "res://UI/fonts/"   # dépose ta police script (.ttf/.otf) ici

var _title: Label
var _subtitle: Label
var _body: Label
var _font: Font = null
var _pending_dest := ""
var _pending_key := ""
var _current_key := ""

func _ready() -> void:
	layer = 20
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_font = _find_font()

	var bg := TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if ResourceLoader.exists(BG_PATH):
		bg.texture = load(BG_PATH)
	else:
		bg.modulate = Color(0.06, 0.06, 0.09)
	add_child(bg)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = MARGIN
	hbox.offset_top = MARGIN
	hbox.offset_right = -MARGIN
	hbox.offset_bottom = -MARGIN
	hbox.add_theme_constant_override("separation", 40)
	add_child(hbox)

	var tcol := VBoxContainer.new()
	tcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tcol.size_flags_stretch_ratio = 2.0
	tcol.alignment = BoxContainer.ALIGNMENT_CENTER
	tcol.add_theme_constant_override("separation", 52)   # +50% d'espace entre les textes
	hbox.add_child(tcol)

	_title = _make_label(56)
	_subtitle = _make_label(36)
	_body = _make_label(28)
	tcol.add_child(_title)
	tcol.add_child(_subtitle)
	tcol.add_child(_body)

	var bcol := VBoxContainer.new()
	bcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bcol.size_flags_stretch_ratio = 1.0
	bcol.alignment = BoxContainer.ALIGNMENT_CENTER
	bcol.add_theme_constant_override("separation", 30)
	hbox.add_child(bcol)

	bcol.add_child(_make_button("Explorer", "explorerButton.png", _on_explorer))
	bcol.add_child(_make_button("Aide", "aideButton.png", _on_aide))
	bcol.add_child(_make_button("Revenir", "revenirButton.png", close))

func _find_font() -> Font:
	var dir := DirAccess.open(FONT_DIR)
	if dir:
		for f in dir.get_files():
			if f.get_extension().to_lower() in ["ttf", "otf", "woff", "woff2"]:
				var r = load(FONT_DIR + f)
				if r is Font:
					return r
	return null

func _make_label(size: int) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_color_override("font_color", PALE_YELLOW)
	l.add_theme_font_size_override("font_size", size)
	if _font != null:
		l.add_theme_font_override("font", _font)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

func _make_button(label: String, png: String, cb: Callable) -> Control:
	var path := BTN_DIR + png
	if ResourceLoader.exists(path):
		var tb := TextureButton.new()
		tb.texture_normal = load(path)
		tb.ignore_texture_size = true
		tb.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		tb.custom_minimum_size = Vector2(360, 80)
		tb.pressed.connect(cb)
		return tb
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(360, 80)
	b.add_theme_font_size_override("font_size", 30)
	b.pressed.connect(cb)
	return b

func show_box(key: String) -> void:
	if not InfoData.BOXES.has(key):
		push_warning("InfoPanel : clé inconnue '%s'" % key)
		return
	_current_key = key
	GameState.marquer_etape(key)   # le thème est « parcouru » dès qu'on ouvre son panneau
	var d: Dictionary = InfoData.BOXES[key]
	_title.text = d.get("titre", "")
	_subtitle.text = d.get("soustitre", "")
	_body.text = d.get("corps", "")
	visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func show_for_stele(key: String, dest: String) -> void:
	_pending_key = key
	_pending_dest = dest
	show_box(key)

func close() -> void:
	_pending_dest = ""
	_pending_key = ""
	visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_explorer() -> void:
	if _pending_dest != "":
		var d := _pending_dest
		close()
		get_tree().change_scene_to_file(d)
	else:
		close()

func _on_aide() -> void:
	var a := InfoData.aide(_current_key)
	if a == "":
		return   # pas d'aide rédigée pour ce thème
	_title.text = "Aide"
	_subtitle.text = InfoData.label(_current_key)
	_body.text = a
