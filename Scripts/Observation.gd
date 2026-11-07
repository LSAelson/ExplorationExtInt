extends Control

# Scène d'Observation 2D réutilisable. Pilotée par ObservationData + GameState.
# GameState.observation_a_ouvrir = clé ; GameState.scene_retour = scène 3D d'où l'on vient.

const BTN_DIR := "res://UI/buttons/"
const BG_PATH := "res://UI/backgrounds/UIObsBG.jpg"
const FONT_DIR := "res://UI/fonts/"
const GREY_SHADER := "res://Materials/shaders/greyscale.gdshader"
const PALE := Color(1.0, 0.98, 0.72)
const ZONE_POS := Vector2(450, 140)     # zone de contenu dans le fond
const ZONE_SIZE := Vector2(1370, 840)
const IMG_BTN := Vector2(360, 80)

var _font: Font = null
var _od: Node = null
var _grey_mat: ShaderMaterial = null
var _data: Dictionary = {}
var _zone: Control
var _cle := ""

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_font = _find_font()
	_od = get_node_or_null("/root/ObservationData")
	var sh = load(GREY_SHADER)
	if sh:
		_grey_mat = ShaderMaterial.new()
		_grey_mat.shader = sh
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	_cle = GameState.observation_a_ouvrir
	_data = _od.obs(_cle) if _od else {}

	var etape: String = _data.get("etape", _cle)   # étape marquée à l'ouverture
	if etape != "":
		GameState.marquer_etape(etape)

	_build_fond()
	_vue_principale()

func _style(partie: String) -> int:
	return _od.style(_data, partie) if _od else 28

func _build_fond() -> void:
	var back := ColorRect.new()
	back.color = Color(0.05, 0.05, 0.07)
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	if ResourceLoader.exists(BG_PATH):
		var bg := TextureRect.new()
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.texture = load(BG_PATH)
		add_child(bg)
	_zone = Control.new()
	_zone.position = ZONE_POS
	_zone.size = ZONE_SIZE
	add_child(_zone)

func _vider_zone() -> void:
	for c in _zone.get_children():
		c.queue_free()

func _vue_principale() -> void:
	_vider_zone()
	var v := _colonne()
	_zone.add_child(v)

	v.add_child(_label(_data.get("titre", ""), _style("titre")))
	var st: String = _data.get("soustitre", "")
	if st != "":
		v.add_child(_label(st, _style("soustitre")))
	var tx: String = _data.get("texte", "")
	if tx != "":
		v.add_child(_label(tx, _style("texte")))

	v.add_child(_espace(24))
	for section in _data.get("sections", []):
		var sec: Dictionary = section
		var btn := _bouton(sec.get("bouton", "…"), _style("boutons"), sec.get("bouton_image", ""))
		var req: String = sec.get("requiert_etape", "")
		if req != "" and not GameState.a_visite(req):
			_griser(btn, true)   # verrouillée tant que l'étape requise n'est pas franchie
		else:
			btn.pressed.connect(_ouvrir_section.bind(sec))
		v.add_child(btn)

	v.add_child(_espace(24))
	var retour := _bouton("Revenir", _style("boutons"), "revenirButton.png")
	retour.pressed.connect(_revenir)
	v.add_child(retour)

func _ouvrir_section(sec: Dictionary) -> void:
	# Types : "texte" (texte libre) ou "reperes" (citations centralisées). qcm/distribution à venir.
	_vider_zone()
	var v := _colonne()
	_zone.add_child(v)
	v.add_child(_label(sec.get("titre", ""), _style("titre")))
	var t := String(sec.get("type", "texte"))
	if t == "reperes":
		_afficher_reperes(v, sec.get("ids", []))
	elif t == "echelle":
		_afficher_echelle(v, sec)
	else:
		v.add_child(_label(sec.get("texte", ""), _style("texte")))
	v.add_child(_espace(24))
	var back := _bouton("Retour", _style("boutons"), "")
	back.pressed.connect(_vue_principale)
	v.add_child(back)

# Affiche les citations référencées (depuis RepereData) par leurs ids.
func _afficher_reperes(v: Control, ids: Array) -> void:
	var rd := get_node_or_null("/root/RepereData")
	if rd == null:
		return
	for id in ids:
		var r: Dictionary = rd.repere(str(id))
		if r.is_empty():
			continue
		v.add_child(_label("« %s »" % r.get("texte", ""), _style("texte")))
		var aut: String = r.get("auteur", "")
		if aut != "":
			v.add_child(_label("— " + aut, _style("soustitre")))
		v.add_child(_espace(12))

# Section "echelle" : le joueur se place entre deux pôles ; résultat horodaté.
func _afficher_echelle(v: Control, sec: Dictionary) -> void:
	var ligne := HBoxContainer.new()
	ligne.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ligne.add_theme_constant_override("separation", 60)
	ligne.add_child(_colonne_pole(sec.get("pole_gauche", {})))
	ligne.add_child(_colonne_pole(sec.get("pole_droite", {})))
	v.add_child(ligne)
	v.add_child(_espace(20))

	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.custom_minimum_size = Vector2(760, 0)
	slider.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var prec = GameState.resultat(_cle, String(sec.get("id", "echelle")))
	slider.value = (prec.get("valeur", 50) if prec != null else 50)
	v.add_child(slider)

	var retour := _label("", _style("texte"))
	v.add_child(retour)
	var zones: Array = sec.get("zones", [])
	retour.text = _zone_texte(zones, slider.value)
	slider.value_changed.connect(_maj_zone.bind(zones, retour))

	v.add_child(_espace(16))
	var valider := _bouton("Valider", _style("boutons"), "")
	valider.pressed.connect(_valider_echelle.bind(sec, slider, retour))
	v.add_child(valider)

func _colonne_pole(pole: Dictionary) -> VBoxContainer:
	var c := VBoxContainer.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.add_child(_label(String(pole.get("label", "")), _style("soustitre")))
	c.add_child(_label(String(pole.get("texte", "")), _style("texte")))
	return c

func _zone_texte(zones: Array, val: float) -> String:
	for z in zones:
		if val <= float(z.get("max", 100)):
			return String(z.get("texte", ""))
	return ""

func _maj_zone(val: float, zones: Array, retour: Label) -> void:
	retour.text = _zone_texte(zones, val)

func _valider_echelle(sec: Dictionary, slider: HSlider, retour: Label) -> void:
	GameState.enregistrer_resultat(_cle, String(sec.get("id", "echelle")), int(slider.value))
	retour.text = "Position enregistrée : %d %%" % int(slider.value)

func _revenir() -> void:
	var dest: String = GameState.scene_retour
	if dest == "":
		dest = "res://Scenes/pyramideArboree.scn"
	get_tree().change_scene_to_file(dest)

# ---------- Helpers UI ----------
func _colonne() -> VBoxContainer:
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 18)
	return v

func _label(txt: String, size: int) -> Label:
	var l := Label.new()
	l.text = txt
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_color_override("font_color", PALE)
	l.add_theme_font_size_override("font_size", size)
	if _font != null:
		l.add_theme_font_override("font", _font)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

# Bouton image (si "image" existe dans buttons/) sinon bouton texte.
func _bouton(txt: String, size: int, image: String) -> BaseButton:
	if image != "":
		var path := BTN_DIR + image
		if ResourceLoader.exists(path):
			var tb := TextureButton.new()
			tb.texture_normal = load(path)
			tb.ignore_texture_size = true
			tb.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
			tb.custom_minimum_size = IMG_BTN
			tb.focus_mode = Control.FOCUS_NONE
			return tb
	var b := Button.new()
	b.text = txt
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 56)
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", PALE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	if _font != null:
		b.add_theme_font_override("font", _font)
	return b

# Grise un bouton (shader de désaturation) et le désactive.
func _griser(btn: BaseButton, actif: bool) -> void:
	btn.disabled = actif
	if actif and _grey_mat != null:
		btn.material = _grey_mat
	else:
		btn.material = null
	if actif and btn is Button:
		btn.modulate = Color(1, 1, 1, 0.5)   # repli texte

func _espace(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c

func _find_font() -> Font:
	var dir := DirAccess.open(FONT_DIR)
	if dir:
		for f in dir.get_files():
			if f.get_extension().to_lower() in ["ttf", "otf", "woff", "woff2"]:
				var r = load(FONT_DIR + f)
				if r is Font:
					return r
	return null
