extends Node

# Autoload "GameState" : profil du joueur, progression et réglages.
# Sauvegarde locale dans user://profil.save (JSON lisible). Aucun mot de passe.

const SAVE_PATH := "user://profil.save"

# --- Identité / progression ---
var pseudo := ""
var premiere_entree := true                 # pour n'afficher la boîte d'arrivée qu'une fois
var etapes_visitees: Dictionary = {}         # { "passe": "2026-10-06 15:30", ... }

# --- Réglages de déplacement / caméra ---
var move_speed := 5.0
var sprint_speed := 12.0
var mouse_sensitivity := 0.004
var invert_y := false
var headbob := true          # secousse de caméra à la marche (confort)

# --- Focale (FOV caméra, en degrés) ---
# Godot raisonne en « champ de vision ». Bornes faciles à ajuster ici.
var fov := 40.0
var fov_min := 20.0
var fov_max := 50.0

# --- Audio ---
var volume_master := 1.0

signal etape_marquee(cle: String)           # pour rafraîchir le HUD/menu profil

func _ready() -> void:
	load_game()

# ---------- Progression ----------
func marquer_etape(cle: String) -> void:
	if cle == "" or etapes_visitees.has(cle):
		return
	etapes_visitees[cle] = Time.get_datetime_string_from_system()
	emit_signal("etape_marquee", cle)
	save_game()

func a_visite(cle: String) -> bool:
	return etapes_visitees.has(cle)

func nb_etapes() -> int:
	return etapes_visitees.size()

# ---------- Focale ----------
func set_fov(v: float) -> void:
	fov = clampf(v, fov_min, fov_max)

# ---------- Sauvegarde ----------
func save_game() -> void:
	var data := {
		"pseudo": pseudo,
		"premiere_entree": premiere_entree,
		"etapes_visitees": etapes_visitees,
		"move_speed": move_speed,
		"sprint_speed": sprint_speed,
		"mouse_sensitivity": mouse_sensitivity,
		"invert_y": invert_y,
		"headbob": headbob,
		"fov": fov,
		"volume_master": volume_master,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var txt := f.get_as_text()
	f.close()
	var data = JSON.parse_string(txt)
	if typeof(data) != TYPE_DICTIONARY:
		return
	pseudo = data.get("pseudo", pseudo)
	premiere_entree = data.get("premiere_entree", premiere_entree)
	etapes_visitees = data.get("etapes_visitees", etapes_visitees)
	move_speed = data.get("move_speed", move_speed)
	sprint_speed = data.get("sprint_speed", sprint_speed)
	mouse_sensitivity = data.get("mouse_sensitivity", mouse_sensitivity)
	invert_y = data.get("invert_y", invert_y)
	headbob = data.get("headbob", headbob)
	fov = data.get("fov", fov)
	volume_master = data.get("volume_master", volume_master)

# ---------- Nouveau jeu ----------
func nouveau_jeu(nom: String = "") -> void:
	pseudo = nom
	premiere_entree = true
	etapes_visitees = {}
	save_game()
