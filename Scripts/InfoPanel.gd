extends CanvasLayer

# Panneau d'info réutilisable (autoload "InfoPanel").
#  show_for_stele(key, dest)       -> bouton « Explorer » (monde 3D)
#  show_for_observation(key, obs)  -> bouton « Observer » (scène 2D)
#  show_box(key)                   -> simple lecture (profil), sans bouton d'action

const MARGIN := 160
const PALE_YELLOW := Color(1.0, 0.98, 0.72)
const BG_PATH := "res://UI/backgrounds/fondViergeFenetreInfo.jpg"
const BTN_DIR := "res://UI/buttons/"
const FONT_DIR := "res://UI/fonts/"
const OBSERVATION_SCENE := "res://Scenes/Observation.tscn"

var _title: Label
var _subtitle: Label
var _body: Label
var _font: Font = null
var _bcol: VBoxContainer
var _action_btn: Control = null
var _aide_btn: Control = null
var _pending_dest := ""
var _pending_obs := ""
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
	tcol.add_theme_constant_override("separation", 52)
	hbox.add_child(tcol)

	_title = _make_label(56)
	_subtitle = _make_label(36)
	_body = _make_label(28)
	tcol.add_child(_title)
	tcol.add_child(_subtitle)
	tcol.add_child(_body)

	_bcol = VBoxContainer.new()
	_bcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bcol.size_flags_stretch_ratio = 1.0
	_bcol.alignment = BoxContainer.ALIGNMENT_CENTER
	_bcol.add_theme_constant_override("separation", 30)
	hbox.add_child(_bcol)

	# Le bouton d'action (Explorer/Observer) est créé dynamiquement à l'affichage.
	_aide_btn = _make_button("Aide", "aideButton.png", _on_aide)
	_bcol.add_child(_aide_btn)
	_bcol.add_child(_make_button("Revenir", "revenirButton.png", close))

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

func _clear_action() -> void:
	if _action_btn != null and is_instance_valid(_action_btn):
		if _action_btn.get_parent() != null:
			_action_btn.get_parent().remove_child(_action_btn)
		_action_btn.queue_free()
	_action_btn = null

func _set_action(label: String, png: String, cb: Callable) -> void:
	_clear_action()
	_action_btn = _make_button(label, png, cb)
	_bcol.add_child(_action_btn)
	_bcol.move_child(_action_btn, 0)   # au-dessus d'Aide et Revenir

func show_box(key: String) -> void:
	if not InfoData.BOXES.has(key):
		push_warning("InfoPanel : clé inconnue '%s'" % key)
		return
	_current_key = key
	var d: Dictionary = InfoData.BOXES[key]
	_title.text = d.get("titre", "")
	_subtitle.text = d.get("soustitre", "")
	_body.text = d.get("corps", "")
	_clear_action()   # lecture simple : pas de bouton d'action par défaut
	_maj_aide()
	visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func show_for_stele(key: String, dest: String) -> void:
	_pending_key = key
	_pending_dest = dest
	_pending_obs = ""
	show_box(key)
	_set_action("Explorer", "explorerButton.png", _on_explorer)

func show_for_observation(key: String, obs: String) -> void:
	_pending_key = key
	_pending_dest = ""
	_pending_obs = obs
	show_box(key)
	_set_action("Observer", "observerButton.png", _on_observer)

func close() -> void:
	_pending_dest = ""
	_pending_obs = ""
	_pending_key = ""
	visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_explorer() -> void:
	var dest := _pending_dest
	var k := _pending_key
	close()
	if k != "":
		GameState.marquer_etape(k)   # étape marquée en partant explorer le monde 3D
	if dest != "":
		get_tree().change_scene_to_file(dest)

func _on_observer() -> void:
	var obs := _pending_obs
	var retour := ""
	if get_tree().current_scene != null:
		retour = get_tree().current_scene.scene_file_path
	_memoriser_retour_joueur()
	close()
	if obs != "":
		GameState.observation_a_ouvrir = obs
		GameState.scene_retour = retour
		get_tree().change_scene_to_file(OBSERVATION_SCENE)

func _memoriser_retour_joueur() -> void:
	var p = get_tree().get_first_node_in_group("player")
	if p and p.has_method("memoriser_position_retour"):
		p.memoriser_position_retour()

# Message simple (ex. stèle verrouillée) : pas de bouton d'action.
func show_message(titre: String, corps: String, key := "") -> void:
	_current_key = key
	_title.text = titre
	_subtitle.text = ""
	_body.text = corps
	_clear_action()
	_maj_aide()
	visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# Montre le bouton Aide seulement s'il existe une aide pour le thème courant.
func _maj_aide() -> void:
	if _aide_btn != null:
		_aide_btn.visible = InfoData.aide(_current_key) != ""

func _on_aide() -> void:
	var a := InfoData.aide(_current_key)
	if a == "":
		return   # pas d'aide rédigée pour ce thème
	_title.text = "Aide"
	_subtitle.text = InfoData.label(_current_key)
	_body.text = a
