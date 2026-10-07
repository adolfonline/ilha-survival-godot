extends Node3D

const PLAYER_SPEED := 6.0
const ISLAND_SIZE := 50.0
var player: CharacterBody3D
var camera: Camera3D
var hud: Label
var quick_menu: PanelContainer
var resources := {"Pedra": 0, "Galho": 0, "Fruta vermelha": 0, "Folha": 0}

func _ready() -> void:
    _build_world()
    _build_player()
    _build_ui()
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_world() -> void:
    var env := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("#8fd3ff")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color.WHITE
    environment.ambient_light_energy = 0.8
    env.environment = environment
    add_child(env)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55, -25, 0)
    sun.light_energy = 1.2
    add_child(sun)

    _add_box("Ilha", Vector3(0, -1, 0), Vector3(ISLAND_SIZE, 2, ISLAND_SIZE), Color("#69a84f"))
    _add_box("Lago", Vector3(-12, 0.05, -10), Vector3(12, 0.12, 9), Color("#318fca"))

    for i in range(10):
        var x := -20.0 + float((i * 17) % 38)
        var z := -18.0 + float((i * 23) % 38)
        if abs(x + 12.0) < 8.0 and abs(z + 10.0) < 6.0:
            continue
        _add_resource(Vector3(x, 0.9, z), "Árvore", Color("#24733d"), 1.2)

    for i in range(8):
        var x := -19.0 + float((i * 13) % 37)
        var z := -17.0 + float((i * 19) % 35)
        _add_resource(Vector3(x, 0.45, z), "Arbusto de frutas", Color("#b52c42"), 0.7)

    for i in range(8):
        var x := -18.0 + float((i * 11) % 35)
        var z := -18.0 + float((i * 29) % 36)
        _add_resource(Vector3(x, 0.35, z), "Pedra", Color("#777b80"), 0.8)

func _add_box(node_name: String, position: Vector3, size: Vector3, color: Color) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.name = node_name
    body.position = position
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    mesh.material_override = _material(color)
    body.add_child(mesh)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
    add_child(body)
    return body

func _add_resource(position: Vector3, resource_name: String, color: Color, radius: float) -> void:
    var area := Area3D.new()
    area.position = position
    area.set_meta("resource_name", resource_name)
    var mesh := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = radius
    sphere.height = radius * 2.0
    mesh.mesh = sphere
    mesh.material_override = _material(color)
    area.add_child(mesh)
    var collision := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = radius
    collision.shape = shape
    area.add_child(collision)
    add_child(area)

func _material(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.9
    return material

func _build_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.position = Vector3(0, 2, 8)
    add_child(player)
    var collision := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.45
    shape.height = 1.8
    collision.shape = shape
    collision.position.y = 0.9
    player.add_child(collision)
    camera = Camera3D.new()
    camera.position = Vector3(0, 1.55, 0)
    player.add_child(camera)
    camera.current = true

func _build_ui() -> void:
    var canvas := CanvasLayer.new()
    add_child(canvas)
    hud = Label.new()
    hud.position = Vector2(24, 20)
    hud.add_theme_font_size_override("font_size", 18)
    canvas.add_child(hud)
    quick_menu = PanelContainer.new()
    quick_menu.position = Vector2(430, 250)
    quick_menu.size = Vector2(420, 220)
    quick_menu.visible = false
    var label := Label.new()
    label.text = "MENU RÁPIDO\n\n1  Picareta    2  Machado    3  Martelo\n4  Pá          5  Enxada     6  Vara de pesca\n7  Fogueira\n\nPressione F para fechar"
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 20)
    quick_menu.add_child(label)
    canvas.add_child(quick_menu)
    _update_hud()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_F:
        quick_menu.visible = not quick_menu.visible
    if event is InputEventKey and event.pressed and event.keycode == KEY_E:
        _collect_nearest()
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        player.rotate_y(-event.relative.x * 0.002)
        camera.rotation.x = clamp(camera.rotation.x - event.relative.y * 0.002, -1.4, 1.4)
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
    if not player:
        return
    var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    var direction := (player.transform.basis * Vector3(input_vector.x, 0, input_vector.y)).normalized()
    player.velocity.x = direction.x * PLAYER_SPEED
    player.velocity.z = direction.z * PLAYER_SPEED
    if not player.is_on_floor():
        player.velocity.y -= 18.0 * delta
    else:
        player.velocity.y = 0
    player.move_and_slide()

func _collect_nearest() -> void:
    var nearest: Area3D
    var distance := 3.0
    for node in get_tree().get_nodes_in_group("collectible"):
        var current_distance: float = player.global_position.distance_to(node.global_position)
        if current_distance < distance:
            nearest = node
            distance = current_distance
    if nearest:
        var resource_name: String = nearest.get_meta("resource_name")
        var key := "Pedra" if resource_name == "Pedra" else ("Fruta vermelha" if resource_name == "Arbusto de frutas" else "Galho")
        resources[key] += 2 if key == "Fruta vermelha" else 1
        nearest.queue_free()
        _update_hud()

func _update_hud() -> void:
    if hud:
        hud.text = "ILHA SURVIVAL  |  E: coletar   F: menu rápido   ESC: liberar mouse\nPedra: %d   Galhos: %d   Frutas: %d   Folhas: %d" % [resources["Pedra"], resources["Galho"], resources["Fruta vermelha"], resources["Folha"]]
