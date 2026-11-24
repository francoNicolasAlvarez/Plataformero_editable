class_name LevelNineteenLayout
extends RefCounted
## Nivel 19 (2026-11-18): "GALERÍA" (mundo 4, nivel 4). Ascensión zigzagueante
## de 28 plataformas (paso 480, ancho 190) que mezcla fijas, de vaivén,
## circulares, con pinchos y que se derrumban, con cuatro cornisas anchas
## (arqueros, magos, un respiradero, el control y las hierbas). Un tramo a
## oscuras en el centro, centinela superior y murciélagos.

const LEVEL_WIDTH := 16000.0
const START_WIDTH := 1300.0
const ROUTE_START_X := 1500.0
const ROUTE_STEP := 480.0
const ROUTE_COUNT := 28
const PLATFORM_WIDTH := 190.0
const LEDGE_WIDTH := 420.0
const FINAL_START_X := 14500.0
const PORTAL_POSITION := Vector2(15400.0, 580.0)
const TIERS := [548.0, 450.0, 352.0, 450.0]
const LEDGES := [6, 13, 20, 26]
const CHECKPOINT_INDEX := 13
const HERB_INDICES := [6, 20, 26]
const GALLERY_ROCK := Color("#4f4a63")
const GALLERY_STEP := Color("#6a6486")
const DARK_FROM := 5600.0
const DARK_TO := 9400.0


static func route_x(index: int) -> float:
	return ROUTE_START_X + float(index) * ROUTE_STEP


static func route_y(index: int) -> float:
	return TIERS[index % TIERS.size()]


static func build(level: Node2D) -> void:
	var world := DesertKit.begin(level, "LevelNineteenGenerated")
	CaveKit.backdrop(world, LEVEL_WIDTH, {
		"top": Color("#17122b"), "mid": Color("#2a2147"), "bottom": Color("#41336a"),
		"far": Color("#2e2550"), "ceiling": Color("#1c1633"), "crystal": Color("#d79bff"),
	})
	DesertKit.ground(world, 0.0, START_WIDTH, GALLERY_ROCK)
	DesertKit.ground(world, FINAL_START_X, LEVEL_WIDTH, GALLERY_ROCK, 120.0)
	DesertKit.fall_zone(world, LEVEL_WIDTH, "FallZoneGallery")
	for index in ROUTE_COUNT:
		_build_step(world, index)
	CaveKit.dark_zone(world, DARK_FROM, DARK_TO, "DarkZoneGallery", 280.0)
	DesertKit.bats(world, 5.5, 6.0)
	DesertKit.sentry(world)
	DesertKit.spearman(world, "GalleryGuardA", FINAL_START_X + 500.0, DesertKit.GROUND_TOP)
	DesertKit.spearman(world, "GalleryGuardB", FINAL_START_X + 800.0, DesertKit.GROUND_TOP, true)
	DesertKit.place_player(level)
	DesertKit.finish(level, PORTAL_POSITION, LEVEL_WIDTH)


static func _build_step(world: Node2D, index: int) -> void:
	var x := route_x(index)
	var y := route_y(index)
	if index in LEDGES:
		DesertKit.platform(world, Vector2(x, y), Vector2(LEDGE_WIDTH, 24.0), GALLERY_STEP, Platform.Kind.STATIC, "GalleryLedge%d" % index)
		_populate_ledge(world, index, x, y - 12.0)
		return
	match index % 4:
		0:
			DesertKit.platform(world, Vector2(x, y), Vector2(PLATFORM_WIDTH, 24.0), GALLERY_STEP, Platform.Kind.STATIC, "GalleryStep%d" % index)
		1:
			DesertKit.platform(world, Vector2(x, y), Vector2(PLATFORM_WIDTH, 24.0), GALLERY_STEP, Platform.Kind.HORIZONTAL if index % 8 == 1 else Platform.Kind.CIRCULAR, "GalleryStep%d" % index)
		2:
			CaveKit.crumbling(world, Vector2(x, y), "GalleryCrumbling%d" % index, PLATFORM_WIDTH)
		3:
			DesertKit.platform(world, Vector2(x, y), Vector2(PLATFORM_WIDTH, 24.0), GALLERY_STEP, Platform.Kind.SPIKED if index % 8 == 3 else Platform.Kind.STATIC, "GalleryStep%d" % index)
	if index % 7 == 4:
		DesertKit.saw(world, Vector2(x + ROUTE_STEP * 0.5, y - 150.0), PLATFORM_WIDTH, 1.4)


static func _populate_ledge(world: Node2D, index: int, x: float, top: float) -> void:
	match index:
		6:
			DesertKit.archer(world, "GalleryArcher6", x + 110.0, top)
		13:
			DesertKit.checkpoint(world, x - 140.0, top)
			CaveKit.vent(world, x + 130.0, top, "GalleryVent13", 0.5)
		20:
			DesertKit.mage(world, "GalleryMage20", x + 110.0, top)
			CaveKit.vent(world, x - 120.0, top, "GalleryVent20", 0.0)
		26:
			DesertKit.archer(world, "GalleryArcher26", x + 120.0, top)
			DesertKit.mage(world, "GalleryMage26", x - 120.0, top)
	if index in HERB_INDICES:
		DesertKit.herb(world, x, top)
