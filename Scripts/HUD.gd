extends CanvasLayer

# HUD global (autoload "HUD") : bouton info (gris/rouge) + bouton profil, en haut à droite.
# Une stèle appelle HUD.set_info(key, dest) à l'approche, HUD.clear_info() au départ.

const DIR := "res://UI/"
const BTN := Vector2(128, 128)

var _info_btn: Control
var _grey: Texture2D
var _red: Texture2D
var _key := ""
var _dest := ""

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_grey = _tex("infoButtonGrey.png")
	_red = _tex("infoButtonRed.png")

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	# --- Position du groupe de boutons (ici : bas-gauche) ---
	# Pour changer de coin, joue sur ces ancrages + grow + offsets.
	hbox.anchor_left = 0.0
	hbox.anchor_right = 0.0
	hbox.anchor_top = 1.0
	hbox.anchor_bottom = 1.0
	hbox.grow_horizontal = Control.GROW_DIRECTION_END
	hbox.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hbox.offset_left = 40
	hbox.offset_bottom = -40
	add_child(hbox)

	hbox.add_child(_make_btn("profilButton.png", "Profil", _on_profil))
	_info_btn = _make_btn("infoButtonGrey.png", "i", _on_info)
	_info_btn.disabled = true
	hbox.add_child(_info_btn)

func _make_btn(png: String, fallback: String, cb: Callable) -> Control:
	var path := DIR + png
	if ResourceLoader.exists(path):
		var tb := TextureButton.new()
		tb.texture_normal = load(path)
		tb.ignore_texture_size = true
		tb.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		tb.custom_minimum_size = BTN
		tb.pressed.connect(cb)
		return tb
	var b := Button.new()
	b.text = fallback
	b.custom_minimum_size = BTN
	b.pressed.connect(cb)
	return b

# --- API appelée par les stèles ---
func set_info(key: String, dest: String) -> void:
	_key = key
	_dest = dest
	_set_active(true)

func clear_info() -> void:
	_key = ""
	_dest = ""
	_set_active(false)

func _set_active(active: bool) -> void:
	_info_btn.disabled = not active
	if _info_btn is TextureButton:
		(_info_btn as TextureButton).texture_normal = _red if active else _grey
	else:
		_info_btn.modulate = Color(1.0, 0.4, 0.4) if active else Color.WHITE

func _on_info() -> void:
	if _key != "":
		InfoPanel.show_for_stele(_key, _dest)

func _on_profil() -> void:
	pass  # (plus tard : ouvrir le menu profil)

func _tex(png: String) -> Texture2D:
	var path := DIR + png
	return load(path) if ResourceLoader.exists(path) else null
