extends MeshInstance3D

# Porte coulissante automatique (SF). À attacher sur le maillage de la porte. Attache ce script au nœud de la porte
# (qui contient son maillage ET un collider). À l'approche du joueur elle s'ouvre
# en se déplaçant de "slide_offset" ; elle se referme quand il s'éloigne.

## Déplacement à l'ouverture (ex. (0,2.2,0) = monte ; (1.5,0,0) = coulisse sur le côté).
@export var slide_offset: Vector3 = Vector3(0.0, 2.2, 0.0)
@export var duree: float = 0.45
@export var proximity: float = 2.5
@export var auto_open: bool = true
## Verrouillée tant que cette étape (GameState) n'est pas franchie. Vide = toujours ouvrable.
@export var requiert_etape: String = ""

var _pos_fermee: Vector3
var _ouverte := false
var _tween: Tween

func _ready() -> void:
	_pos_fermee = position
	var area := Area3D.new()
	add_child(area)
	var col := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = proximity
	col.shape = sph
	# centre la zone sur le centre visuel du maillage (le nœud est souvent à l'origine)
	if mesh != null:
		var ab: AABB = get_aabb()
		col.position = ab.position + ab.size * 0.5
	area.add_child(col)
	area.body_entered.connect(_on_enter)
	area.body_exited.connect(_on_exit)

func _on_enter(body: Node) -> void:
	if body.name == "Player" and auto_open:
		ouvrir()

func _on_exit(body: Node) -> void:
	if body.name == "Player" and auto_open:
		fermer()

func ouvrir() -> void:
	if _ouverte or _est_verrouille():
		return
	_ouverte = true
	_anim(_pos_fermee + slide_offset)

func fermer() -> void:
	if not _ouverte:
		return
	_ouverte = false
	_anim(_pos_fermee)

func _anim(cible: Vector3) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "position", cible, duree)

func _est_verrouille() -> bool:
	return requiert_etape != "" and not GameState.a_visite(requiert_etape)
