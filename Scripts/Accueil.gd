extends Control

# Écran d'accueil (scène principale). Boutons-images 360×80 placés en absolu
# selon la maquette Pixelmator (origine milieu-haut de l'image, X centre = 1459).

const UI := "res://UI/"
const BG_PATH := UI + "backgrounds/fondAccueil.jpg"
const FONT_DIR := UI + "fonts/"
const PALE := Color(1.0, 0.98, 0.72)
const HUB := "res://Scenes/pyramideArboree.scn"
const BTN_SIZE := Vector2(360, 80)
const BTN_X := 1350.0   # ajusté définitivement.

var _font: Font = null

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_font = _find_font()
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_build()

func _build() -> void:
	var back := ColorRect.new()
	back.color = Color(0.05, 0.05, 0.08)
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(back)

	if ResourceLoader.exists(BG_PATH):
		var bg := TextureRect.new()
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.texture = load(BG_PATH)
		add_child(bg)

	_add_button("buttons/newGameButton.png", "Nouveau jeu", 275, _on_nouveau)
	var cont := _add_button("buttons/continuerButton.png", "Continuer", 459, _on_continuer)
	if not FileAccess.file_exists(GameState.SAVE_PATH):
		cont.disabled = true
		cont.modulate = Color(1, 1, 1, 0.4)
	_add_button("buttons/reglagesButton.png", "Réglages", 637, _on_reglages)
	_add_button("buttons/quitterButton.png", "Quitter", 813, _on_quitter)

func _add_button(png: String, fallback: String, y: float, cb: Callable) -> BaseButton:
	var path := UI + png
	var ctrl: BaseButton
	if ResourceLoader.exists(path):
		var tb := TextureButton.new()
		tb.texture_normal = load(path)
		tb.ignore_texture_size = true
		tb.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		ctrl = tb
	else:
		var b := Button.new()
		b.text = fallback
		b.flat = true
		b.add_theme_font_size_override("font_size", 40)
		b.add_theme_color_override("font_color", PALE)
		if _font != null:
			b.add_theme_font_override("font", _font)
		ctrl = b
	ctrl.focus_mode = Control.FOCUS_NONE
	ctrl.pressed.connect(cb)
	add_child(ctrl)
	ctrl.position = Vector2(BTN_X, y)
	ctrl.size = BTN_SIZE
	return ctrl

func _on_continuer() -> void:
	get_tree().change_scene_to_file(HUB)

func _on_nouveau() -> void:
	if GameState.nb_etapes() > 0:
		var d := ConfirmationDialog.new()
		d.title = "Nouveau jeu"
		d.dialog_text = "Effacer la progression actuelle et recommencer ?"
		d.confirmed.connect(_demarrer_nouveau)
		add_child(d)
		d.popup_centered()
	else:
		_demarrer_nouveau()

func _demarrer_nouveau() -> void:
	GameState.nouveau_jeu()
	get_tree().change_scene_to_file(HUB)

func _on_reglages() -> void:
	var pr := get_node_or_null("/root/ProfilReglages")
	if pr:
		pr.open(true)

func _on_quitter() -> void:
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
