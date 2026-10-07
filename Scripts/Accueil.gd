extends Control

# Écran d'accueil (scène principale). Nouveau jeu / Continuer / Réglages / Quitter.

const FONT_DIR := "res://UI/fonts/"
const BG_PATH := "res://UI/fondAccueil.jpg"
const PALE := Color(1.0, 0.98, 0.72)
const HUB := "res://Scenes/pyramideArboree.scn"

var _font: Font = null

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_font = _find_font()
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

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

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 20)
	center.add_child(v)

	var title := Label.new()
	title.text = "ExplorationExtInt"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", PALE)
	title.add_theme_font_size_override("font_size", 80)
	if _font != null:
		title.add_theme_font_override("font", _font)
	v.add_child(title)

	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 30)
	v.add_child(sp)

	var cont := _btn("Continuer", _on_continuer)
	cont.disabled = not FileAccess.file_exists(GameState.SAVE_PATH)
	v.add_child(cont)
	v.add_child(_btn("Nouveau jeu", _on_nouveau))
	v.add_child(_btn("Réglages", _on_reglages))
	v.add_child(_btn("Quitter", _on_quitter))

func _btn(txt: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(380, 70)
	b.add_theme_font_size_override("font_size", 40)
	b.add_theme_color_override("font_color", PALE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.45))
	if _font != null:
		b.add_theme_font_override("font", _font)
	b.pressed.connect(cb)
	return b

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
		pr.open(true)   # mode autonome (pas de menu Pause derrière)

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
