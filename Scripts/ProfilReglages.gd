extends CanvasLayer

# Panneau fusionné Profil + Réglages (autoload "ProfilReglages").
# Ouvert depuis le menu Pause. Deux onglets : Profil (pseudo + étapes cliquables) / Réglages (curseurs).

const FONT_DIR := "res://UI/fonts/"
const PALE := Color(1.0, 0.98, 0.72)

var _font: Font = null
var _pseudo: LineEdit
var _progress: Label
var _themes: RichTextLabel
var _standalone := false

func _ready() -> void:
	layer = 35
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_font = _find_font()
	_build()

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(960, 660)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.08, 0.11, 0.98)
	sb.border_color = Color(0.5, 0.48, 0.3)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	panel.add_child(col)

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_theme_font_size_override("font_size", 28)
	if _font != null:
		tabs.add_theme_font_override("font", _font)
	col.add_child(tabs)
	tabs.add_child(_build_profil())
	tabs.add_child(_build_reglages())
	tabs.set_tab_title(0, "Profil")
	tabs.set_tab_title(1, "Réglages")

	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_END
	col.add_child(bottom)
	bottom.add_child(_text_button("Fermer", _on_close))

# ---------- Onglet Profil ----------
func _build_profil() -> Control:
	var v := VBoxContainer.new()
	v.name = "ProfilTab"
	v.add_theme_constant_override("separation", 16)

	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", 12)
	r.add_child(_lbl("Pseudo :", 26))
	_pseudo = LineEdit.new()
	_pseudo.placeholder_text = "Explorateur"
	_pseudo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if _font != null:
		_pseudo.add_theme_font_override("font", _font)
	r.add_child(_pseudo)
	v.add_child(r)

	_progress = _lbl("", 24)
	v.add_child(_progress)

	v.add_child(_lbl("Étapes parcourues :", 26))

	_themes = RichTextLabel.new()
	_themes.bbcode_enabled = true
	_themes.scroll_active = true
	_themes.fit_content = false
	_themes.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_themes.custom_minimum_size = Vector2(600, 320)
	_themes.add_theme_font_size_override("normal_font_size", 24)
	if _font != null:
		_themes.add_theme_font_override("normal_font", _font)
	_themes.meta_clicked.connect(_on_theme_clicked)
	v.add_child(_themes)

	return v

# ---------- Onglet Réglages ----------
func _build_reglages() -> Control:
	var scroll := ScrollContainer.new()
	scroll.name = "ReglagesTab"
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 22)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(v)

	_add_slider(v, "Vitesse de marche", 2.0, 12.0, 0.5, GameState.move_speed, _on_speed, false)
	_add_slider(v, "Sensibilité souris", 0.001, 0.01, 0.0005, GameState.mouse_sensitivity, _on_sens, true)
	_add_slider(v, "Focale (défaut)", GameState.fov_min, GameState.fov_max, 1.0, GameState.fov, _on_fov, false)
	_add_slider(v, "Volume", 0.0, 1.0, 0.05, GameState.volume_master, _on_volume, false)

	v.add_child(_check("Inverser l'axe vertical (Y)", GameState.invert_y, _on_invert))
	v.add_child(_check("Secousse de caméra", GameState.headbob, _on_headbob))

	return scroll

# ---------- Callbacks réglages ----------
func _on_speed(x: float) -> void: GameState.move_speed = x
func _on_sens(x: float) -> void: GameState.mouse_sensitivity = x
func _on_fov(x: float) -> void: GameState.set_fov(x)
func _on_volume(x: float) -> void:
	GameState.volume_master = x
	_apply_volume(x)
func _on_invert(on: bool) -> void: GameState.invert_y = on
func _on_headbob(on: bool) -> void: GameState.headbob = on

# ---------- Helpers UI ----------
func _lbl(txt: String, size: int) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_color_override("font_color", PALE)
	l.add_theme_font_size_override("font_size", size)
	if _font != null:
		l.add_theme_font_override("font", _font)
	return l

func _text_button(txt: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(160, 56)
	b.add_theme_font_size_override("font_size", 28)
	b.add_theme_color_override("font_color", PALE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	if _font != null:
		b.add_theme_font_override("font", _font)
	b.pressed.connect(cb)
	return b

func _add_slider(parent: Control, titre: String, mn: float, mx: float, step: float, val: float, cb: Callable, decimals: bool) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var head := HBoxContainer.new()
	var name_lbl := _lbl(titre, 24)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(name_lbl)
	var val_lbl := _lbl(_fmt(val, decimals), 24)
	val_lbl.custom_minimum_size = Vector2(90, 0)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	head.add_child(val_lbl)
	box.add_child(head)
	var sl := HSlider.new()
	sl.min_value = mn
	sl.max_value = mx
	sl.step = step
	sl.value = val
	sl.custom_minimum_size = Vector2(600, 0)
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.focus_mode = Control.FOCUS_NONE
	sl.value_changed.connect(func(x): val_lbl.text = _fmt(x, decimals))
	sl.value_changed.connect(cb)
	box.add_child(sl)
	parent.add_child(box)

func _check(txt: String, on: bool, cb: Callable) -> CheckButton:
	var c := CheckButton.new()
	c.text = txt
	c.button_pressed = on
	c.focus_mode = Control.FOCUS_NONE
	c.add_theme_font_size_override("font_size", 24)
	c.add_theme_color_override("font_color", PALE)
	if _font != null:
		c.add_theme_font_override("font", _font)
	c.toggled.connect(cb)
	return c

func _fmt(x: float, decimals: bool) -> String:
	return ("%.4f" % x) if decimals else str(int(round(x)))

# ---------- Ouverture / fermeture ----------
func open(standalone := false) -> void:
	_standalone = standalone
	_refresh()
	visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_close() -> void:
	close()

func close() -> void:
	_apply_and_save()
	visible = false
	if _standalone:
		get_tree().paused = false   # ouvert depuis l'accueil : on dépause (pas de Pause derrière)

func _refresh() -> void:
	_pseudo.text = GameState.pseudo
	_progress.text = "%d / %d étapes découvertes" % [GameState.nb_etapes(), InfoData.LABELS.size()]
	_refresh_themes()

func _refresh_themes() -> void:
	var keys := GameState.etapes_visitees.keys()
	if keys.is_empty():
		_themes.text = "[i][color=#999999]Aucune étape parcourue pour l'instant.[/color][/i]"
		return
	var s := ""
	for key in keys:
		var k := str(key)
		var date := str(GameState.etapes_visitees[key])
		s += "• [url=%s][color=#fff9b8]%s[/color][/url]   [color=#888888](%s)[/color]\n" % [k, InfoData.label(k), date]
	_themes.text = s

func _on_theme_clicked(meta) -> void:
	# Ferme les menus et ouvre la page du thème (lecture). Retour au jeu via « Revenir ».
	var key := str(meta)
	visible = false
	var pm := get_node_or_null("/root/PauseMenu")
	if pm:
		pm.visible = false
	InfoPanel.show_box(key)

func _apply_and_save() -> void:
	GameState.pseudo = _pseudo.text
	GameState.save_game()
	var p = get_tree().get_first_node_in_group("player")
	if p and p.has_method("_apply_settings"):
		p._apply_settings()
	_apply_volume(GameState.volume_master)

func _apply_volume(v: float) -> void:
	var bus := AudioServer.get_bus_index("Master")
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, linear_to_db(clampf(v, 0.0001, 1.0)))

# ---------- Échap : ferme ce panneau (retour à la pause) ----------
func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _find_font() -> Font:
	var dir := DirAccess.open(FONT_DIR)
	if dir:
		for f in dir.get_files():
			if f.get_extension().to_lower() in ["ttf", "otf", "woff", "woff2"]:
				var r = load(FONT_DIR + f)
				if r is Font:
					return r
	return null
