extends CanvasLayer

# HUD global (autoload "HUD") : le bouton « i », en bas à gauche.
# Apparaît près de TOUTE stèle (curseur libre) : ROUGE si non visitée, GRIS si visitée.
# Un clic — ou la touche I — déclenche exactement la même chose qu'un clic sur le symbole.

const DIR := "res://UI/buttons/"
const BTN := Vector2(128, 128)

var _info_btn: Control
var _grey: Texture2D
var _red: Texture2D
var _teleporter: Node = null

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
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

	_info_btn = _make_btn("infoButtonRed.png", "i", _on_info)
	hbox.add_child(_info_btn)

func _process(_delta: float) -> void:
	if not _doit_afficher():
		if visible:
			visible = false
		return
	if _info_btn is TextureButton:
		var visite := GameState.a_visite(_teleporter.info_key)
		(_info_btn as TextureButton).texture_normal = _grey if visite else _red
	visible = true

func _doit_afficher() -> bool:
	if _teleporter == null or not is_instance_valid(_teleporter):
		return false
	if get_tree().get_first_node_in_group("player") == null:
		return false
	if get_tree().paused:
		return false
	if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		return false                               # seulement curseur libre
	return true

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
func set_info_from(teleporter: Node) -> void:
	_teleporter = teleporter

func clear_info() -> void:
	_teleporter = null

func _on_info() -> void:
	if _teleporter != null and is_instance_valid(_teleporter) and _teleporter.has_method("declencher"):
		_teleporter.declencher()   # identique au clic sur le symbole

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_I:
		if not get_tree().paused and _teleporter != null:
			_on_info()
			get_viewport().set_input_as_handled()

func _tex(png: String) -> Texture2D:
	var path := DIR + png
	return load(path) if ResourceLoader.exists(path) else null
