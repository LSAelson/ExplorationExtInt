extends CanvasLayer

# HUD global (autoload "HUD") : bouton info (gris/rouge), en bas à gauche.
# Visible seulement en jeu. Le profil se gère via le menu Pause.
# Une stèle / le sol appelle HUD.set_info(key, dest) ; HUD.clear_info() pour éteindre.

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
	hbox.anchor_left = 0.0
	hbox.anchor_right = 0.0
	hbox.anchor_top = 1.0
	hbox.anchor_bottom = 1.0
	hbox.grow_horizontal = Control.GROW_DIRECTION_END
	hbox.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hbox.offset_left = 40
	hbox.offset_bottom = -40
	add_child(hbox)

	_info_btn = _make_btn("infoButtonGrey.png", "i", _on_info)
	_info_btn.disabled = true
	hbox.add_child(_info_btn)

func _process(_delta: float) -> void:
	# N'afficher le HUD qu'en jeu (un joueur présent dans la scène).
	var in_game := get_tree().get_first_node_in_group("player") != null
	if visible != in_game:
		visible = in_game

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

# --- API appelée par les stèles / le sol ---
func set_info(key: String, dest: String) -> void:
	# Pas d'info si vide ou déjà explorée (le thème reste accessible via le profil).
	if key == "" or GameState.a_visite(key):
		clear_info()
		return
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

func _unhandled_input(event: InputEvent) -> void:
	# Touche I : ouvre l'info disponible (le « i » rouge) sans avoir besoin du curseur.
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_I:
		if not get_tree().paused and _key != "":
			_on_info()
			get_viewport().set_input_as_handled()

func _on_info() -> void:
	if _key != "":
		InfoPanel.show_for_stele(_key, _dest)
		clear_info()   # thème exploré -> « i » gris (rallumé par une nouvelle zone)

func _tex(png: String) -> Texture2D:
	var path := DIR + png
	return load(path) if ResourceLoader.exists(path) else null
