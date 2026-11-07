extends CanvasLayer
## Autoload "Carte" : carte plein écran des Observations de l'île.
## Ouverte par l'œuf carteObservations (ou la touche M). Met le jeu en pause, curseur libre.
## - Marqueurs placés automatiquement depuis les points d'Observation (Teleporter is_observation).
## - Découverte progressive : verrouillé = caché, débloqué non ouvert = "?", ouvert = nommé.
## - Clic sur un point -> pop-up descriptif + épinglage priorité.

const FONT_DIR := "res://UI/fonts/"
const PALE_YELLOW := Color(1.0, 0.98, 0.72)
const COULEUR_INCONNU := Color(0.55, 0.55, 0.58)
const COULEUR_DECOUVERT := Color(0.95, 0.80, 0.35)
const COULEUR_FAIT := Color(0.45, 0.85, 0.50)
const COULEUR_PRIORITE := Color(0.95, 0.35, 0.35)
const COULEUR_JOUEUR := Color(0.35, 0.80, 0.95)

var _font: Font = null
var _area: Control                 # zone carrée où sont projetés les marqueurs
var _bg: TextureRect               # image de l'île (ou vide)
var _frame: Panel                  # cadre de la zone
var _markers: Control              # conteneur des marqueurs (vidé à chaque ouverture)
var _dot: Control                  # spot joueur
var _aiguille: ColorRect           # orientation du joueur
var _popup: PanelContainer
var _popup_titre: Label
var _popup_corps: Label
var _popup_btn: Button
var _popup_key := ""

# Calibration courante (fournie par la source à l'ouverture)
var _centre := Vector2.ZERO
var _taille := 600.0
var _source: Node = null

func _ready() -> void:
	layer = 22
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_font = _find_font()
	_build()
	get_viewport().size_changed.connect(_relayout)

# ------------------------------------------------------------------ Construction
func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.85)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var titre := Label.new()
	titre.name = "Titre"
	titre.text = "Carte des Observations"
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.add_theme_color_override("font_color", PALE_YELLOW)
	titre.add_theme_font_size_override("font_size", 44)
	if _font != null:
		titre.add_theme_font_override("font", _font)
	titre.set_anchors_preset(Control.PRESET_TOP_WIDE)
	titre.offset_top = 22
	add_child(titre)

	_area = Control.new()
	_area.name = "Area"
	add_child(_area)

	_bg = TextureRect.new()
	_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.modulate = Color(0.12, 0.14, 0.18)   # placeholder si pas d'image
	_area.add_child(_bg)

	_frame = Panel.new()
	_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = PALE_YELLOW
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	_frame.add_theme_stylebox_override("panel", sb)
	_area.add_child(_frame)

	_markers = Control.new()
	_markers.name = "Markers"
	_markers.set_anchors_preset(Control.PRESET_FULL_RECT)
	_markers.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_area.add_child(_markers)

	_dot = Control.new()
	_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_aiguille = ColorRect.new()
	_aiguille.color = COULEUR_JOUEUR
	_aiguille.size = Vector2(3, 16)
	_aiguille.position = Vector2(-1.5, -16)   # part du centre vers le "haut" (avant rotation)
	_aiguille.pivot_offset = Vector2(1.5, 16)
	_dot.add_child(_aiguille)
	var rond := Panel.new()
	rond.size = Vector2(16, 16)
	rond.position = Vector2(-8, -8)
	var sbr := StyleBoxFlat.new()
	sbr.bg_color = COULEUR_JOUEUR
	sbr.set_corner_radius_all(8)
	sbr.border_color = Color.WHITE
	sbr.set_border_width_all(2)
	rond.add_theme_stylebox_override("panel", sbr)
	rond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dot.add_child(rond)
	_area.add_child(_dot)

	var revenir := Button.new()
	revenir.text = "Revenir"
	revenir.flat = true
	revenir.focus_mode = Control.FOCUS_NONE
	revenir.custom_minimum_size = Vector2(240, 60)
	revenir.add_theme_font_size_override("font_size", 32)
	revenir.add_theme_color_override("font_color", PALE_YELLOW)
	revenir.add_theme_color_override("font_hover_color", Color.WHITE)
	if _font != null:
		revenir.add_theme_font_override("font", _font)
	revenir.pressed.connect(fermer)
	revenir.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	revenir.offset_left = -120
	revenir.offset_right = 120
	revenir.offset_top = -84
	revenir.offset_bottom = -24
	add_child(revenir)

	_build_popup()

	func_build_done()

func func_build_done() -> void:
	_relayout()

func _build_popup() -> void:
	_popup = PanelContainer.new()
	_popup.visible = false
	_popup.custom_minimum_size = Vector2(520, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.08, 0.11, 0.97)
	sb.border_color = PALE_YELLOW
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(22)
	_popup.add_theme_stylebox_override("panel", sb)
	_popup.set_anchors_preset(Control.PRESET_CENTER)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	_popup.add_child(vb)

	_popup_titre = Label.new()
	_popup_titre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_popup_titre.add_theme_color_override("font_color", PALE_YELLOW)
	_popup_titre.add_theme_font_size_override("font_size", 34)
	if _font != null:
		_popup_titre.add_theme_font_override("font", _font)
	vb.add_child(_popup_titre)

	_popup_corps = Label.new()
	_popup_corps.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_popup_corps.custom_minimum_size = Vector2(480, 0)
	_popup_corps.add_theme_color_override("font_color", Color(0.9, 0.9, 0.82))
	_popup_corps.add_theme_font_size_override("font_size", 22)
	if _font != null:
		_popup_corps.add_theme_font_override("font", _font)
	vb.add_child(_popup_corps)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 16)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(hb)

	_popup_btn = _mini_bouton("Épingler priorité", _on_toggle_priorite)
	hb.add_child(_popup_btn)
	var fermer_btn := _mini_bouton("Fermer", func(): _popup.visible = false)
	hb.add_child(fermer_btn)

	add_child(_popup)

func _mini_bouton(txt: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(220, 54)
	b.add_theme_font_size_override("font_size", 24)
	if _font != null:
		b.add_theme_font_override("font", _font)
	b.pressed.connect(cb)
	return b

# ------------------------------------------------------------------ Mise en page
func _relayout() -> void:
	if _area == null:
		return
	var vp := get_viewport().get_visible_rect().size
	var cote: float = min(vp.x - 200.0, vp.y - 240.0)
	cote = max(cote, 200.0)
	_area.size = Vector2(cote, cote)
	_area.position = Vector2((vp.x - cote) * 0.5, (vp.y - cote) * 0.5 + 10.0)

func _find_font() -> Font:
	var dir := DirAccess.open(FONT_DIR)
	if dir:
		for f in dir.get_files():
			if f.get_extension().to_lower() in ["ttf", "otf", "woff", "woff2"]:
				var r = load(FONT_DIR + f)
				if r is Font:
					return r
	return null

# ------------------------------------------------------------------ Projection
func _monde_vers_zone(wx: float, wz: float) -> Vector2:
	var u := (wx - _centre.x) / _taille + 0.5
	var v := (wz - _centre.y) / _taille + 0.5
	return Vector2(u, v) * _area.size

# ------------------------------------------------------------------ Ouverture
func ouvrir(source: Node = null) -> void:
	if source != null:
		_source = source
	if _source == null:
		_source = get_tree().get_first_node_in_group("carte_source")
	var auto := true
	if _source != null and _source.has_method("get_calibration"):
		var cfg: Dictionary = _source.get_calibration()
		_centre = cfg.get("centre", Vector2.ZERO)
		_taille = float(cfg.get("taille", 600.0))
		auto = bool(cfg.get("auto", true))
		var img = cfg.get("image", null)
		if img is Texture2D:
			_bg.texture = img
			_bg.modulate = Color.WHITE
		else:
			_bg.texture = null
			_bg.modulate = Color(0.12, 0.14, 0.18)
	_relayout()
	if auto:
		_auto_ajuster()
	_reconstruire_marqueurs()
	_maj_spot()
	_popup.visible = false
	visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# Cadre automatiquement la carte sur tous les points + le joueur.
func _auto_ajuster() -> void:
	var pts := _collecter_points()
	var mn := Vector2(INF, INF)
	var mx := Vector2(-INF, -INF)
	for p in pts:
		var pos: Vector3 = p["pos"]
		mn.x = min(mn.x, pos.x); mn.y = min(mn.y, pos.z)
		mx.x = max(mx.x, pos.x); mx.y = max(mx.y, pos.z)
	var pj := get_tree().get_first_node_in_group("player")
	if pj is Node3D:
		var pp := (pj as Node3D).global_position
		mn.x = min(mn.x, pp.x); mn.y = min(mn.y, pp.z)
		mx.x = max(mx.x, pp.x); mx.y = max(mx.y, pp.z)
	if mn.x == INF:
		return   # aucun point : on garde la calibration par défaut
	_centre = (mn + mx) * 0.5
	var span: float = max(mx.x - mn.x, mx.y - mn.y)
	_taille = max(span * 1.3, 50.0)   # marge de 30 %

func fermer() -> void:
	_popup.visible = false
	visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func basculer() -> void:
	if visible:
		fermer()
	else:
		ouvrir()

# ------------------------------------------------------------------ Marqueurs
func _reconstruire_marqueurs() -> void:
	for c in _markers.get_children():
		c.queue_free()
	var points := _collecter_points()
	for p in points:
		_ajouter_marqueur(p)

func _collecter_points() -> Array:
	var out: Array = []
	var vus: Array = []
	var scene := get_tree().current_scene
	if scene == null:
		return out
	# Source A : tout point Teleporter marqué Observation (quand tu les câbleras)
	_parcourir(scene, out, vus)
	# Source B : enfants directs du node "observations" (ta structure actuelle)
	var racine := _trouver_observations(scene)
	if racine != null:
		for child in racine.get_children():
			if vus.has(child):
				continue
			var pos = _centroid_meshes(child)   # null si node vide -> pas de marqueur
			if pos == null:
				continue
			var key := str(child.get_meta("cle", child.name))
			out.append({"node": child, "key": key, "requiert": str(child.get_meta("requiert", "")), "pos": pos})
	return out

func _parcourir(n: Node, out: Array, vus: Array) -> void:
	if _est_point_obs(n):
		var key: String = str(n.get("observation_key"))
		var requiert: String = str(n.get("requiert_etape"))
		out.append({"node": n, "key": key, "requiert": requiert, "pos": _position_point(n)})
		vus.append(n)
	for c in n.get_children():
		_parcourir(c, out, vus)

func _trouver_observations(n: Node) -> Node:
	if n.name == "observations":
		return n
	for c in n.get_children():
		var r := _trouver_observations(c)
		if r != null:
			return r
	return null

# Centre géométrique des MeshInstance3D sous un node (ou null si aucun).
func _centroid_meshes(n: Node):
	var somme := Vector3.ZERO
	var cnt := 0
	var stack := [n]
	while not stack.is_empty():
		var m = stack.pop_back()
		if m is MeshInstance3D:
			somme += (m as MeshInstance3D).global_position
			cnt += 1
		for c in m.get_children():
			stack.append(c)
	if cnt == 0:
		return null
	return somme / float(cnt)

func _est_point_obs(n: Node) -> bool:
	if not n.has_method("declencher"):
		return false
	var v = n.get("is_observation")
	return typeof(v) == TYPE_BOOL and v

func _position_point(n: Node) -> Vector3:
	var area := n.get_node_or_null("ProximityArea")
	if area is Node3D:
		return (area as Node3D).global_position
	if n is Node3D:
		return (n as Node3D).global_position
	return Vector3.ZERO

func _ajouter_marqueur(p: Dictionary) -> void:
	var key: String = p["key"]
	var obs: Dictionary = ObservationData.obs(key)
	if obs.is_empty() and not ObservationData.obs(key + "_lecture").is_empty():
		key = key + "_lecture"   # ex. node "grilles" -> clé "grilles_lecture"
		obs = ObservationData.obs(key)
	var etape: String = str(obs.get("etape", ""))
	var requiert: String = p["requiert"]

	var verrouille := requiert != "" and not GameState.a_visite(requiert)
	if verrouille:
		return   # découverte progressive : point verrouillé = caché

	var fait := GameState.resultats.has(key) and not (GameState.resultats[key] as Dictionary).is_empty()
	var decouvert := (etape != "" and GameState.a_visite(etape)) or GameState.est_decouverte(key)
	var prio := GameState.est_priorite(key)

	var col := COULEUR_INCONNU
	if fait:
		col = COULEUR_FAIT
	elif decouvert:
		col = COULEUR_DECOUVERT

	var pos3 : Vector3 = p["pos"]
	var px := _monde_vers_zone(pos3.x, pos3.z)
	if px.x < -20.0 or px.y < -20.0 or px.x > _area.size.x + 20.0 or px.y > _area.size.y + 20.0:
		return   # hors cadre

	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(26, 26)
	btn.size = Vector2(26, 26)
	btn.position = px - Vector2(13, 13)
	if not decouvert:
		btn.text = "?"
		btn.add_theme_font_size_override("font_size", 18)
		btn.add_theme_color_override("font_color", Color.WHITE)
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(13)
	if prio:
		sb.border_color = COULEUR_PRIORITE
		sb.set_border_width_all(4)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.pressed.connect(func(): _ouvrir_popup(key, decouvert, fait))
	_markers.add_child(btn)

	# Étiquette pour les points découverts
	if decouvert:
		var lab := Label.new()
		lab.text = str(obs.get("titre", key))
		lab.add_theme_color_override("font_color", PALE_YELLOW)
		lab.add_theme_font_size_override("font_size", 18)
		if _font != null:
			lab.add_theme_font_override("font", _font)
		lab.position = px + Vector2(16, -12)
		lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_markers.add_child(lab)

# ------------------------------------------------------------------ Pop-up
func _ouvrir_popup(key: String, decouvert: bool, fait: bool) -> void:
	_popup_key = key
	var obs: Dictionary = ObservationData.obs(key)
	if decouvert:
		_popup_titre.text = str(obs.get("titre", key))
		var corps := str(obs.get("soustitre", ""))
		var txt := str(obs.get("texte", ""))
		if txt != "":
			corps += ("\n\n" if corps != "" else "") + txt
		var etat := "✓ Observation complétée" if fait else "○ Non complétée"
		_popup_corps.text = corps + "\n\n" + etat
	else:
		_popup_titre.text = "Point d'Observation"
		_popup_corps.text = "Tu perçois une présence ici, mais tu ne l'as pas encore explorée."
	_maj_bouton_priorite()
	_popup.visible = true

func _on_toggle_priorite() -> void:
	if _popup_key == "":
		return
	GameState.basculer_priorite(_popup_key)
	_maj_bouton_priorite()
	_reconstruire_marqueurs()   # rafraîchit l'anneau de priorité

func _maj_bouton_priorite() -> void:
	if GameState.est_priorite(_popup_key):
		_popup_btn.text = "Retirer priorité"
	else:
		_popup_btn.text = "Épingler priorité"

# ------------------------------------------------------------------ Spot joueur
func _maj_spot() -> void:
	var pj := get_tree().get_first_node_in_group("player")
	if pj == null or not (pj is Node3D):
		_dot.visible = false
		return
	_dot.visible = true
	var p3 := (pj as Node3D).global_position
	_dot.position = _monde_vers_zone(p3.x, p3.z)
	_aiguille.rotation = -(pj as Node3D).rotation.y

func _process(_delta: float) -> void:
	if visible:
		_maj_spot()

# ------------------------------------------------------------------ Entrée
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M:
		if get_tree().get_first_node_in_group("player") == null:
			return
		basculer()
		get_viewport().set_input_as_handled()
