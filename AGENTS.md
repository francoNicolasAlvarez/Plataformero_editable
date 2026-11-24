# NOTA: proyecto editable (2026-11-20)

Esta carpeta (`Juego_Editable`) es una copia de `Juego` en la que **los niveles
son escenas normales editables en el editor de Godot** (`scenes/levels/level_*.tscn`,
con `baked = true`). Léase `EDITAR_NIVELES.md`. Diferencias respecto al original:
- Los niveles generados por código se conservan en `scenes/levels/generated/`
  (`baked = false`) y `tools/bake_levels.gd` los convierte en escenas con
  `LevelBaker` (`scripts/tools/level_baker.gd`). Hornear sobrescribe las escenas.
- `TestLevel` gana `baked` y `route_points`; `FallZone` gana `zone_size` (editable).
- El HUD de los niveles horneados es una escena compartida
  (`scenes/ui/level_hud.tscn`).
- `level_four_smoke_test` omite las pruebas del controlador de ruta cuando el
  nivel está horneado (el controlador pasa a ser un nodo normal).
- No tiene repositorio git propio (inicializa uno si hace falta).
Todo lo que sigue describe el proyecto original y sigue siendo válido.

# AGENTS.md — Guía para agentes de IA y colaboradores

Este archivo es el punto de entrada obligatorio para cualquier agente de IA
(Claude, opencode, etc.) o persona que continúe el desarrollo del proyecto.
Debes leerlo completo antes de tocar código y **actualizarlo al terminar cada
cambio de funcionalidad** (secciones "Historial", "En progreso" y "Próximos
pasos").

---

## 1. Qué es este proyecto

Videojuego 2D de plataformas **lineal** hecho con **Godot 4.7 (GL
Compatibility) y GDScript**. Jugabilidad inspirada en Super Mario Bros. con
exploración, saltos, enemigos, trampas, controles y un final de juego.

Objetivo del jugador: atravesar los ocho niveles actuales hasta llegar al final
del juego; la hoja de ruta aprobada los ampliará a 40 niveles repartidos en
8 mundos. Cada nivel da tres vidas y es una prueba contrarreloj: al morir se
reaparece en el último control (bandera) activado sin regalar tiempo, y sin
vidas o sin tiempo la partida vuelve al inicio. El nivel alcanzado, el mejor
tiempo y la medalla de cada nivel quedan guardados.

Desarrollo **incremental**: una mecánica por vez, probada antes de continuar.
Nunca implementar varios sistemas a la vez ni reescribir código existente sin
explicar qué se modifica y por qué.

## 2. Cómo ejecutar

Motor (no está en el PATH):
```
C:\Users\Usuario\Downloads\Godot_v4.7.2-stable_win64_console.exe
```

- Abrir proyecto: ejecutar el exe de arriba y elegir la carpeta del proyecto.
- Ejecutar el juego desde CLI: `--path . res://scenes/ui/main_menu.tscn`
- Regenerar caches tras crear/renombrar scripts o escenas (class_name, .uid):
  `--headless --path . --import`
- Suite de tests (todos deben pasar antes de dar por terminado un cambio):
  ```
  Get-ChildItem tests -Filter *.gd | ForEach-Object {
      & "C:\Users\Usuario\Downloads\Godot_v4.7.2-stable_win64_console.exe" `
          --headless --path . --script "res://tests/$($_.Name)" }
  ```
  Alternativa en paralelo: `powershell -File tools/run_tests.ps1`.
  Cada test es un script `SceneTree` autónomo que imprime `[OK]`/`[FALLO]`
  y devuelve exit code 0/1. Las pruebas headless no leen ni escriben el
  guardado (`SaveGame` lo desactiva detectando `headless`).
- Exportar ejecutable de Windows (las plantillas 4.7.2 ya están instaladas
  en `%APPDATA%\Godot\export_templates\4.7.2.stable`):
  ```
  & "C:\Users\Usuario\Downloads\Godot_v4.7.2-stable_win64_console.exe" `
      --headless --path . --export-release "Windows Desktop"
  ```
  Genera `dist/PlataformasRoguelite.exe` (archivo único con el PCK
  embebido, ~104 MB). El preset vive en `export_presets.cfg`.

## 3. Arquitectura actual

```
project.godot        # input map + capas físicas (World/Player/Enemies/PlayerAttack)
scenes/
  ui/main_menu.tscn        # escena inicial: jugar, instrucciones, opciones, salir
  ui/control_guide.tscn    # guía de controles con teclas dibujadas (reutilizable)
  ui/pause_overlay.tscn    # pausa con Enter: congela el SceneTree y muestra guía
  ui/game_complete.tscn    # pantalla final con tiempo total y muertes
  ui/level_results.tscn    # resultados por nivel: tiempo, medalla, muertes y mejor marca
  levels/test_level.tscn   # BASE de los 8 niveles (HUD, jugador, portal, cámara)
  levels/level_one|two|three|four|five|six|seven|eight.tscn  # variantes 1-8
  player/player.tscn       # Player + Health
  enemies/                 # training_dummy, walker, ranged, spread, projectile
  pickups/                 # healing_herb (monedas eliminadas, ver ítem 24)
  world/                   # platform, moving_platform, saw/spike_trap, fall_zone,
                           # exit_portal, checkpoint (bandera de control)
  camera/horizontal_camera.tscn
  decor/                   # árboles, arbustos, nubes, aves, sol (sin colisión)
scripts/
  player/    # player.gd (movimiento, salto/doble salto, caída rápida, gravedad invertida y controles espejo),
             # player_stats.gd,
  enemies/   # jerarquía: TrainingDummy -> RangedEnemy/SpreadEnemy/WalkerEnemy;
             # flying_enemy.gd + flying_spawner.gd (voladores ondulantes),
             # enemy_visual_variant.gd (sombrero triangular y ojos del nivel 7),
             # sky_sentry.gd (centinela superior que dispara cada 2 s)
  levels/    # test_level.gd (controlador común) + layouts generados por código:
             # level_one_extension.gd, level_two_layout.gd, level_three_layout.gd,
             # level_four_layout.gd (gran pozo de plataformas móviles),
             # level_four_route.gd (plataformas del pozo y enemigos a bordo),
             # level_five_layout.gd (cielo con 28 plataformas, voladores y
             # sierras suspendidas),
             # level_six_layout.gd (fortaleza de 20 plataformas, trampas y
             # centinela superior),
             # level_seven_layout.gd (nivel 7 invertido, espejo del nivel 1),
             # level_eight_layout.gd (nivel 8: espejo del nivel 2),
             # platform_spacing.gd (regla de espaciado entre plataformas)
  combat/    # health.gd (vida reutilizable por jugador y enemigos)
  core/      # save_game.gd (nivel guardado + tiempo/muertes, user://save.cfg),
             # gamepad_bindings.gd (mapeo fijo de mando, idempotente),
             # run_timer.gd y medal_rules.gd (contrarreloj),
             # level_registry.gd (8 mundos × 5 niveles)
  ui/        # main_menu.gd, menu_style.gd, menu_backdrop.gd, control_guide.gd (keycaps), pause_overlay.gd,
             # game_complete.gd, level_results.gd, game_settings.gd
  audio/     # sfx.gd (sonidos sintetizados + música procedural por nivel)
  fx/        # particles.gd (class_name Fx: fábrica de partículas procedurales)
  world/, decor/, camera/, pickups/  # decor/mountain_builder.gd: capas de
             # detalle (nieve/cresta/sombra/arbolitos) para las colinas
resources/player/  # player_stats.tres
resources/levels/  # level_config.gd y world_config.gd (configuración declarativa)
assets/fx/spark.svg # textura de punto blanco para todas las partículas
assets/enemies/    # fireball.svg y crossbow_bolt.svg (proyectiles de mago/soldado)
assets/decor/      # tree/bush/cloud/bird/sun.svg (rediseñados con detalle)
tests/       # smoke tests headless, uno por sistema (59 en total)
```

Decisiones clave:
- Los 8 niveles son instancias de una misma escena base; cada variante limpia
  el contenido base y genera su mundo por código (`scripts/levels/*_layout.gd`).
- Los datos sensibles van en `Resource` exportables (`PlayerStats`)
  para reutilizarlos con futuros personajes.
- Comunicación entre sistemas mediante señales de Godot.
- El jugador muere con 3 golpes (cualquier daño normal consume 1 golpe;
  los valores >= 9999 son letales instantáneos: pozos y cronómetro). La
  invulnerabilidad tras recibir daño dura 1 s.
- **Modo plataformas lineal (2026-11-12)**: el objetivo es llegar al final del
  juego; no hay progresión roguelite ni botín permanente. `SaveGame` guarda el
  nivel alcanzado para continuar. Cada nivel da 3 vidas: morir reaparece en el
  último control (bandera) con la vida completa; al quedarse sin vidas o al
  agotar el tiempo se recarga el nivel. El nivel 8 termina en
  `ui/game_complete.tscn`.

Controles (reconfigurables desde Opciones):
A/D o flechas mover · Espacio saltar (otra pulsación en el aire = doble salto,
siempre disponible) · S/Abajo caer rápido · se corre siempre por defecto · Ctrl impulso
rápido hacia delante (no cuenta como salto y atraviesa enemigos y proyectiles) · Enter pausa.
Mando: stick/DPAD mover y caer rápido · A saltar · X impulso · Start pausa (mapeo fijo, ver `GamepadBindings`).
NOTA: el juego es SIN combate: la acción `attack` sigue eliminada
(`no_combat_smoke_test` y `player_smoke_test` lo verifican). El jugador NO lleva objetos
utilizables (ver ítem 63): no existen `item_1`/`item_2`/`inventory`. `player.gd`
conserva `_handle_attack()` sin llamar como código muerto; no reactivarlo sin
actualizar esos tests.

## 4. Historial: lo que ya está HECHO

1. **Personaje jugable completo**: movimiento con aceleración/deceleración
   configurables, salto con altura variable (mantener botón), coyote time,
   jump buffer, carrera, ataque con cooldown y hitbox, animaciones
   procedurales, invulnerabilidad y knockback tras daño, muerte animada.
2. **Doble salto permanente (actualizado 2026-11-12)**: el jugador dispone
   siempre de un impulso aéreo por salto desde el suelo (una pulsación extra
   de salto). Ya no depende de monedas ni de cargas. Ver ítem 23.
3. **Cámara horizontal** suave con límites por nivel y `fixed_y`.
4. **Tres niveles distintos**:
   - Nivel 1 (día, 100 s): recorrido largo con colinas, pozos y plataformas.
   - Nivel 2 (atardecer, 80 s): fosos con plataformas móviles, sierras,
     pinchos y walkers rápidos.
   - Nivel 3 (noche, granja, 75 s): walkers muy rápidos y decoración rural.
   Cada nivel termina en un portal que lleva al siguiente; el nivel 3 vuelve
   al menú principal.
5. **Cuenta regresiva por nivel**: si llega a 0 el jugador muere. Barra de
   progreso del recorrido y cronómetro rojo bajo 10 s.
6. **Enemigos**: TrainingDummy (base con vida/daño por contacto/muerte),
   WalkerEnemy (patrulla), RangedEnemy (proyectil con línea de visión) y
   SpreadEnemy.
7. **Pickups**: hierba curativa (las monedas se eliminaron, ver ítem 24).
8. **HUD**: cronómetro, progreso, cargas de salto, slots de objetos, panel de
   inventario informativo (Tab), mensajes de muerte/completado (el conteo de
   recursos se mantiene interno; ver ítem 14).
9. **Menú principal**: jugar, opciones (brillo, volumen, rebind de teclas con
   guardado en `user://`), contador de partidas.
10. **Progreso permanente mínimo**: `GameProgress` guarda partidas jugadas en
    `user://progress.cfg` (las monedas y las mejoras de vida están eliminadas;
    el campamento futuro usará nuevos recursos).
11. **Audio procedural** (sin assets): saltos, golpes, curación, música.
12. **Último cambio (2026-11, sesión previa + esta sesión)**: eliminados los
    jefes que bloqueaban el avance. El portal está siempre disponible y el
    antiguo `BossEnemy` se convirtió en **`SpreadEnemy`** (enemigo común de
    ráfaga, 40 PV, dispara abanico de 3-5 proyectiles) que aparece
    repartido en los TRES niveles: 6 en nivel 1, 5 en nivel 2 y 4 en nivel 3.
    Ver `scripts/enemies/spread_enemy.gd` y los layouts de cada nivel.
13. **Exportación a ejecutable**: preset "Windows Desktop" en
    `export_presets.cfg` (x86_64, PCK embebido) y plantillas de exportación
    4.7.2 instaladas. Genera `dist/PlataformasRoguelite.exe`, verificado
    arrancando en modo headless y con ventana real (OpenGL).
14. **Último cambio (2026-11-11, primera mitad)**: HUD limpio y pausa. Los
    contadores de recursos/total salieron del HUD (solo queda "Saltos: x/3";
    el conteo interno y el resumen al completar el nivel se mantienen) y el
    slot de objetos muestra solo "Poción x2". La guía de comandos ya no
    aparece durante el juego: existe una guía reutilizable **con teclas
    dibujadas** (`scenes/ui/control_guide.tscn`, keycaps = PanelContainer con
    StyleBoxFlat) que se muestra en el menú principal (2 columnas) y en la
    nueva **pausa con Enter** (`scenes/ui/pause_overlay.tscn`,
    `PROCESS_MODE_ALWAYS`, congela el SceneTree; bloqueada tras morir o
    completar vía `TestLevel.is_run_over()`). Acción `pause` añadida al
    Input Map y a Opciones (rebind con GameSettings). Test nuevo:
    `pause_smoke_test.gd`.
15. **Mover con flechas (2026-11-11)**: `game_settings.gd` re-agrega las
    flechas ←/→ como teclas extra de `move_left`/`move_right` tras cada
    rebind (constante `EXTRA_KEYS`), así el jugador siempre puede moverse
    con A/D o flechas aunque reasigne las principales. La guía muestra los
    keycaps de flecha. NOTA: incluido en el exe de `dist/` desde la re-exportación del 2026-11-11.
16. **Regla de espaciado entre plataformas (2026-11-11, última)**: cualquier
    hueco entre dos plataformas debe medir >= 1.5x el tamaño del jugador en
    el eje del hueco (45 px horizontal por ancho 30, 72 px vertical por
    altura 48); si dos plataformas se tocan o se solapan en un eje, ese eje
    no tiene hueco y se tolera (suelo continuo, plataformas apiladas). Las
    plataformas móviles quedan excluidas. Implementado como helper estático
    `scripts/levels/platform_spacing.gd` (`PlatformSpacing`) + test
    `tests/platform_spacing_smoke_test.gd` que valida la regla en sí y
    recorre los 3 niveles (0 violaciones, la suite completa de 18 tests
    pasa). Para cumplirla se rediseñaron las alturas/posiciones de las
    plataformas de la escena base (`Platform1-6` en tiers 548/440), las
    secciones y arena del nivel 1 (6 plataformas por sección en tiers
    548/440/330), la escalera del nivel 2 (6 peldaños por sección, pasos de
    96 px) y las pasarelas/islas del nivel 3 (tiers 556/460/364).
    Arreglos de bugs descubiertos al aplicar la regla:
    - El portal del nivel 3 estaba a 686 px del último suelo → INALCANZABLE
      (nivel incompletable). El suelo final pasa de `[10860, 1280]` a
      `[11285, 2130]` (centro/ancho), llegando hasta x=12350; el portal se
      queda en x=12150 y la cámara en 12600 sin cambios.
    - Cuatro walkers del nivel 3 nacían sobre pozos (x 2150, 4450, 6850 y
      9350) y caían al vacío: movidos a suelo firme (2450, 4000, 7500,
      9700). La moneda en x=11900 también flotaba sobre el vacío y ahora
      apoya en el suelo ampliado.
    - Plataformas móviles del nivel 2 a y=600 dejaban solo ~29 px de hueco
      respecto al suelo (el jugador no cabía): ahora y=556 (hueco ~73 px).
    - Moneda de tierra del nivel 1 en `start+620` flotaba sobre el pozo de
      las secciones con pozo de 288 px: movida a `start+560`.
    NOTA: incluido en el exe de `dist/` desde la re-exportación del 2026-11-11.
17. **Pulido visual (2026-11-11, última)**: cinco mejoras de presentación
    aplicadas de una en una con la suite en verde tras cada una:
    - **Vestido de plataformas**: `platform.gd` crea en `_refresh()` dos
      hijos `TopHighlight` (color base `lightened(0.22)`, alto
      `clamp(y*0.22, 2, 5)`) y `BottomShadow` (base `darkened(0.45)` al 65%
      de alpha, alto `clamp(y*0.16, 2, 4)`); se recrean con `get_node_or_null`
      así el patrón es idempotente. `MovingPlatform` NO hereda de `Platform`
      y queda sin vestido (igual que queda fuera de la regla de espaciado).
    - **Squash & stretch + polvo del jugador**: `player.gd` escala `$Visual`
      (nuevo `visual_root`) con `_squash(escala, duración)` (tween que siempre
      vuelve a `Vector2.ONE`); salto (0.84, 1.18)/0.14 s, aterrizaje
      comprime según la velocidad de caída capturada antes de
      `move_and_slide()` (`_fall_speed`). Polvo `DustPuff` (CPUParticles2D
      one-shot, se reutiliza con `restart()`) al saltar y aterrizar; se
      cancela el tween al morir. Sombra `Shadow` (Polygon2D) en `player.tscn`
      a los pies, igual que los enemigos.
    - **Chispas y auras**: `scripts/fx/particles.gd` (`class_name Fx`,
      RefCounted, todo estático) configura CPUParticles2D por código con la
      única textura `assets/fx/spark.svg`: `make_dust` (jugador),
      `make_sparkle` (destello continuo de moneda y hierba), `make_burst`
      (estallido al recoger; se cuelga del PADRE del pickup porque el pickup
      hace `queue_free()` inmediato y se autolibera por timer) y
      `make_portal_aura` (aura cian ascendente del portal). OJO: en Godot 4.7
      el área de emisión rectangular de CPUParticles2D es
      `emission_rect_extents` (no `emission_box_extents`).
    - **Paralaje**: fondos con `Parallax2D` (sin `repetition_size`; la banda
      visible se cubre a mano: ventana visible = [sC - ancho_pantalla/2,
      sC + ancho_pantalla/2] en el espacio de la capa). Nivel 1:
      `BackgroundDecor` de la base pasa de Node2D a Parallax2D (escala 0.3,
      z -16, detrás de las colinas estáticas de la extensión que quedan a
      z -14) con 12 colinas (Hill5-12 clones a +2900/+5800) y las nubes
      migran de las secciones a `CloudParallax` (escala 0.55, z -8, 11
      nubes). El sol ya iba fijo en pantalla por script (`screen_sun.gd`,
      top_level) y no se toca. Nivel 2: `HillParallax` (0.3) y `CloudParallax`
      (0.55, z -8) dentro de `LevelTwoGenerated` con posiciones compactadas
      a la banda visible. Nivel 3: `StarParallax` (0.08, estrellas solo en
      x [0,2200]), `MoonParallax` (0.02) y `HillParallax` (0.3). La
      variación por run de `_apply_run_variation` sigue funcionando (itera
      los hijos Polygon2D de BackgroundDecor).
    - Test nuevo: `visual_polish_smoke_test.gd` (22 comprobaciones: vestido,
      sombra/polvo/squash, chispas, aura y capas Parallax2D de los tres
      niveles).
    NOTA: incluido en el exe de `dist/` desde la re-exportación del 2026-11-11.
18. **Disparo horizontal sin apuntar (2026-11-11, última)**: los enemigos a
    distancia ya NO apuntan al jugador. `RangedEnemy._shoot()` ahora recibe
    solo `direction` y construye `aim = Vector2(direction, 0)`: el proyectil
    vuela siempre en horizontal hacia el lado en que esté el jugador (se
    esquiva saltando o cambiando de altura). El `SpreadEnemy` mantiene su
    abanico (3 disparos a ±10° alrededor de la horizontal; 5 a ±20° por debajo
    del 50% de vida) con la misma firma `_shoot(direction)`. No cambian los
    chequeos de rango (|offset.x| <= shoot_range, |offset.y| <= 170), el
    cooldown, ni la línea de visión (el rayo sigue mirando AL jugador para
    decidir si dispara; solo la trayectoria del proyectil es horizontal).
    Test actualizado: `enemy_ranged_smoke_test.gd` (ahora 14 comprobaciones:
    jugador en repisa a otra altura -> proyectil horizontal que pasa por
    debajo sin golpear; jugador a la misma altura -> 1 golpe consumido; y
    abanico horizontal del SpreadEnemy). El test de LOS no cambió.
    NOTA: el exe de `dist/` fue exportado ANTES de este cambio y NO lo
    incluye; re-exportar cuando se pida.
19. **Rediseño de enemigos y ambiente (2026-11-11, última)**:
    - **Sombrero mejicano pisable** en dummy y walker: se añade
      `HeadShape` (RectangleShape2D 68×10 en y −32) y el daño baja a
      36×38 en (0,5); el jugador puede posarse sobre la cabeza sin daño y
      el sombrero (ala 72×14, copa, banda con zigzag, pompones) tapa la
      antigua cabeza. HealthBar a −66/−58. Walker conserva patrulla,
      `FloorAhead`, mask 3 y paleta morada.
    - **RangedEnemy → mago azul**: túnica con dobladillo zigzag, cinturón,
      mangas, barba, cejas y `WizardHat` (ala + cono doblado + banda +
      estrella); bastón con orbe de fuego. HealthBar a −70/−62. Dispara
      bolas de fuego (`assets/enemies/fireball.svg`) con estela de llamas
      (`FlameTrail`) y estallido naranja al impactar.
    - **SpreadEnemy → soldado medieval**: malla, tabardo rojo con emblema,
      hombreras, `Helmet` con penacho y `Crossbow` (culata, arco, cuerda,
      virote). HealthBar a −78/−70. Dispara virotes
      (`assets/enemies/crossbow_bolt.svg`) sin estela y sin giro.
      Colisión 56×80 y daño 64×82 intactos (sigue dañando al pisarlo).
    - **`enemy_projectile.gd`**: `enum Style { FIRE, BOLT }` con
      `use_fire_style()`/`use_bolt_style()` idempotentes (helper
      `apply_style()`); `particles.gd` gana `make_fire_trail()` y
      `_fire_ramp()`. TRAMPA: `Gradient.remove_point()` falla con
      `points.size() <= 1`; rellenar con `ramp.offsets`/`ramp.colors`.
      `energy_orb.svg` eliminado.
    - **Ambiente SVG**: `tree` (raíces, corteza, ramas, frutas),
      `bush` (racimos, bayas, florecitas, briznas), `cloud` (bultos,
      borde iluminado), `bird` (alas por capas, cola, patas con dedos) y
      `sun` (dos capas de rayos + halos). Canvas y anclajes intactos.
    - **Colinas con detalle**: `scripts/decor/mountain_builder.gd`
      (`MountainBuilder.decorate()`, idempotente, crea `MountainDetail`
      con cima de nieve en zigzag, cresta iluminada, ladera en sombra y
      arbolitos lejanos). Enganchado en `_decorate_base_hills` (solo
      variante 1), `_add_hill` de la extensión del nivel 1, las colinas
      del nivel 2 (sin nieve) y las del nivel 3 (con nieve).
    - **Nivel 3**: cráteres en la luna; silo con remate, franja de luz y
      puerta; molino con buje, puerta, ventana y velas en las aspas;
      vallas con remates puntiagudos; cultivos con espigas doradas; heno
      con vetas y bandas.
    - Tests: `enemy_visual_smoke_test.gd` nuevo (15 comprobaciones),
      `enemy_ranged_smoke_test.gd` ampliado a 18 (FIRE+FlameTrail, BOLT
      sin estela) y `decor_detail_smoke_test.gd` nuevo (16). Suite
      completa: 21/21.
    NOTA: el exe de `dist/` NO incluye los ítems 18 y 19; re-exportar
    cuando se pida.
20. **Enemigos humanoides sin barras de vida (2026-11-11, última)**:
    - **Barra de vida eliminada** de los 4 enemigos (nodos `HealthBar`,
      StyleBox y referencias en `training_dummy.gd`); el nodo `Health` y la
      lógica de daño/muerte se mantienen.
    - **Humanoides proporcionales** (~48 px, escala del jugador): piernas,
      brazos, manos, torso, cuello, cabeza y ojos con rectángulos
      (pixel-art procedural, sin curvas). Dummy rojo/marrón, walker morado.
      Colisiones y daños intactos.
    - **Sombrero simplificado**: `SombreroDome` (domo) + `SombreroBrimLine`
      (línea de 70×3.5). Eliminados banda con zigzag, pompones y ala ovalada.
    - **Mago**: cada disparo lanza 3 bolas de fuego en abanico horizontal de
      ±10° (`RangedEnemy.FIREBALL_COUNT` y `FIREBALL_SPREAD_DEG`). Sigue con
      túnica, barba, sombrero de mago y bastón; ahora con piernas visibles.
    - **Arquero** (`SpreadEnemy`): una sola flecha por disparo a 300 px/s
      (más rápida que la bola de fuego a 240). Proyectil con forma de flecha
      (`crossbow_bolt.svg` rediseñado, 32×12). Se reduce su escala al resto:
      colisión 32×48 (antes 56×80) y daño 36×38 en (0,5) (antes 64×82).
    - Tests: `enemy_visual_smoke_test.gd` 25 comprobaciones (sombrero simple,
      humanoides, sin barras) y `enemy_ranged_smoke_test.gd` 23 (ráfaga de 3
      del mago y flecha única más rápida del arquero). Suite: 21/21.
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se
    pida.
21. **Enemigos más grandes, instrucciones y HUD (2026-11-12)**:
    - **Sin escalado de disparo en niveles posteriores**: se eliminaron los
      overrides `shoot_interval 1.05` y `projectile_speed 280` del mago en
      `level_two_layout.gd` (el nivel 2 usa los valores base 1.7 s / 240);
      se conserva `shoot_range 520`. El nivel 3 nunca tuvo overrides.
    - **Enemigos +25%**: los 4 enemigos llevan `Visual.scale = (1.25, 1.25)`
      y `Visual.position.y = -6` (los pies siguen a +24 con la colisión
      intacta). Los sombreros de dummy/walker van dentro del Visual con
      pivote `(0,-25)` y `scale = 0.6` (tamaño neto 0.75, es decir 25% más
      pequeños) y `HeadShape` sube a y −42 para que el jugador siga
      posándose sobre el domo.
    - **Menú — Instrucciones**: nuevo botón `INSTRUCCIONES` (antes de
      MEJORAS) y panel `InstructionsPanel` con guía de controles en 2
      columnas + secciones OBJETIVO, OBJETOS DEL NIVEL (moneda, hierba,
      portal, plataformas, pinchos, enemigos), TIEMPO (100/80/75/90 s) e ITEMS
      (poción Q, doble salto, inventario Tab). Esc/Volver cierra. El panel
      principal se compacta (márgenes 18, separación 10, botones 44) para
      que quepa el botón nuevo. La guía del panel principal se retiró el
      2026-11-12 (solo queda en Instrucciones y en la pausa).
    - **HUD**: `LevelProgress` pasa a **borde blanco**, interior **gris
      claro** y relleno **gris oscuro**, `show_percentage = false`; nuevo
      `ProgressLabel` (hijo, anclado a toda la barra) con letras negras
      "PROGRESO DE NIVEL  n%", actualizado en `_update_progress_bar()`.
    - **Cartel de nivel**: `_show_level_banner()` crea un `LevelBanner`
      ("NIVEL n · DÍA/ATARDECER/NOCHE") centrado al empezar y lo desvanece
      con un tween (1.2 s + 0.6 s de fade, se autolibera).
    - **Menú**: la línea de progreso permanente pasa a
      "Monedas: N · Partidas: N · Mejor: N" (sin nodos nuevos).
    - **Audio**: `Sfx.start_music()` registra el reproductor con
      `add_child.call_deferred` y arranca en su señal `ready`, eliminando el
      error "Parent node is busy setting up children" al entrar al nivel.
    - Tests: `menu_smoke_test.gd` 30 comprobaciones (instrucciones ocultas,
      botón, guía, textos, abrir/cerrar y línea de progreso),
      `timer_progress_smoke_test.gd` 11 (marcador de progreso, porcentaje y
      cartel de nivel) y `enemy_visual_smoke_test.gd`
      29 (escala 1.25 del cuerpo y sombrero neto 0.75). Suite: 21/21.
    NOTA: el exe de `dist/` NO incluye los ítems 18-21; re-exportar cuando se
    pida.
22. **Nivel 4 "El Gran Pozo" (2026-11-12)**:
    - **Gorro del mago más pequeño**: `WizardHat` pasa a `scale 0.7` con
      pivote en la base (`position (0,-7.8)`): ala 52→36 px y copa 20→14 px,
      sin moverse de la cabeza.
    - **Plataformas móviles nuevas**: `moving_platform.gd` gana
      `circle_radius`/`circle_speed` (órbita) y `rotation_speed` (giro sobre
      su eje); el vaivén lineal/diagonal sigue usando `travel`/`speed`
      (niveles 2/3 intactos).
    - **Nivel 4**: `level_four.tscn` (variante 4, "ABISMO", 90 s) y
      `level_four_layout.gd`. Solo hay dos islas firmes (inicio 0..1900 y
      final 10100..12400 separadas por un pozo de 8200 px con una única
      `FallZonePit`); todo el centro se cruza por una cadena directa de 31
      plataformas móviles (grupo `main_route`, x de 2140 en pasos de 260)
      que alternan vertical (travel y 80), diagonal (±70, 55), circular
      (r=55) y giratoria (0.7 rad/s), más 6 plataformas opcionales con
      monedas a y=430. Escenario: cielo abisal, colinas con parallax 0.3 y
      rocas flotantes decorativas. El nivel 3 ahora continúa hacia el 4 y el
      4 vuelve al menú. Texto de TIEMPO del menú ampliado con 90 s.
    - **Regla de alcance**: las trayectorias de plataformas consecutivas del
      tramo principal se solapan o quedan a ≤300 px (constante
      `MAX_JUMP_DISTANCE`), validado muestreando 40 puntos por trayectoria.
      El test también exige que la primera/última plataforma estén al alcance
      de los bordes de las islas, que existan los 4 movimientos, que los
      walkers solo patrullen suelo firme y que el portal/cámara cubran el
      final.
    - Tests: `level_four_smoke_test.gd` nuevo (30 comprobaciones),
      `level_three_smoke_test.gd` actualizado (continúa al nivel 4),
      `platform_spacing_smoke_test.gd` incluye el nivel 4. Suite: 22/22.
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se
    pida.
23. **Doble salto permanente y caída rápida (2026-11-12)**:
    - **Sin monedas de salto ni marcadores**: `coin.gd` ya solo suma
      recursos (`add_double_jump_charge` eliminado de `player.gd`, junto con
      `double_jumps`, `MAX_DOUBLE_JUMPS`, la señal `double_jumps_changed` y
      el nodo `HUD/Resources`). El `JumpsInfo` del inventario es ahora texto
      fijo: "Doble salto: disponible siempre en el aire. Abajo/S: caer
      rápido."
    - **Doble salto siempre disponible**: `_handle_jump()` permite un salto
      aéreo mientras `_jumps_used < 2`; el suelo/coyote lo reinicia. Un
      tercer salto en el aire no impulsa.
    - **Caída rápida**: nueva acción `move_down` (S + flecha abajo, también
      rebindable en Opciones; `GameSettings.CONTROLS/EXTRA_KEYS`). En el aire
      fija `velocity.y` a `stats.fast_fall_speed` (nuevo export de
      `PlayerStats`, 900) y cancela la carga del salto. En el suelo no hace
      nada (no hay crouch).
    - **Instrucciones**: la guía de controles añade la fila "Caer rápido"
      (teclas S y ↓, 11 keycaps) y la fila de salto pasa a "Saltar / doble
      salto"; el menú de Instrucciones actualiza OBJETOS (moneda solo
      recurso) e ITEMS (doble salto permanente, caída rápida, Tab).
    - Tests actualizados: `player_smoke_test` 31 (move_down, doble salto
      permanente, sin tercer salto, caída rápida), `jump_control_smoke_test`
      11, `pickup_smoke_test` 7, `inventory_smoke_test` 17,
      `exit_smoke_test` 9, `menu_smoke_test` 31, `pause_smoke_test` 18
      (11 keycaps). Suite: 22/22.
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se
    pida.
24. **Ajustes de juego (2026-11-12)**: tres cambios pedidos tras probar:
    - **Daño por contacto fiable**: `training_dummy.gd` añade
      `_check_contact_damage()` (recorre `damage_area.get_overlapping_bodies()`
      cada frame de física) y lo llaman también `walker_enemy.gd` y
      `ranged_enemy.gd` al final de su `_physics_process`. Antes solo se usaba
      la señal `body_entered`: si el jugador seguía pegado al enemigo al
      terminar la invulnerabilidad no volvía a recibir daño. El área de daño
      del walker pasa de 36×38 a 44×38 (el borde superior sigue en y −14, así
      el sombrero continúa siendo pisable).
    - **Nivel 2 sin el primer walker**: en la sección inicial se omite el
      walker de suelo en `start_x + 560` (se conserva el de `+1420`); el
      eliminado patrullaba hasta el punto de salida y golpeaba al jugador
      inmóvil. `level_two_smoke_test.gd` comprueba que no haya walkers de
      suelo a menos de 900 px del spawn.
    - **Monedas eliminadas por completo**: borrados
      `scenes/pickups/coin.tscn`, `scripts/pickups/coin.gd`, sus spawns en
      `test_level.tscn` y en los cuatro layouts, `_reduce_coin_density`, el
      intercambio de monedas de `_apply_run_variation`, el sonido `coin` de
      `sfx.gd` y las menciones del menú/instrucciones. `GameProgress` deja de
      contar monedas y "mejor run": solo guarda `runs` (`add_run_result()`
      sin parámetro). El mensaje de nivel completado es solo
      "NIVEL n COMPLETADO" (sin recursos ni total) y el HUD/inventario y el
      menú muestran únicamente "Partidas: n". Las plataformas opcionales del
      nivel 4 se mantienen (antes tenían monedas encima).
    - Tests: `pickup_smoke_test` reescrito (7 comprobaciones: escena de
      moneda borrada, 0 monedas en los 4 niveles, hierba sigue curando),
      `enemy_patrol_smoke_test` 7 (contacto continuo vuelve a dañar),
      `level_two_smoke_test` 27, `exit_smoke_test` 10,
      `menu_smoke_test` 31, `visual_polish_smoke_test` 21,
      `level_one_layout_smoke_test` 18, `level_three_smoke_test` 24,
      `level_four_smoke_test` 30, `inventory_smoke_test` 17. Suite: 22/22.
    NOTA: el exe de `dist/` NO incluye los ítems 18-24; re-exportar cuando se
    pida.
25. **Modo plataformas lineal: checkpoints, vidas, guardado y final
    (2026-11-12)**: seis mejoras acordadas tras descartar el roguelite.
    - **Capa roguelite eliminada**: borrado `scripts/core/game_progress.gd`
      (sustituido por `scripts/core/save_game.gd`, `class_name SaveGame`),
      botón MEJORAS del menú y contador de partidas. El menú queda en Jugar /
      Instrucciones / Opciones / Salir y muestra "NIVEL n DE 4".
    - **Checkpoints y vidas**: `scripts/world/checkpoint.gd` +
      `scenes/world/checkpoint.tscn` (Area2D mask 2, grupo `checkpoints`,
      señal `activated`); al pisarlo cura toda la vida y fija el punto de
      reaparición. Tres vidas por nivel; al morir se reaparece en el último
      control tras 1,2 s con la vida completa; sin vidas se recarga el nivel
      tras 2,2 s. Checkpoints: nivel 1 en x 3200/9100/16500, nivel 2 en
      3700/8600/10900, nivel 3 en 3100/8200/12000 y nivel 4 en 1700/10750
      (islas de inicio y final). `Player.revive(spawn_position)` restaura el
      cuerpo sin recargar la escena. El ítem 26 redujo los controles a uno por
      nivel a mitad del recorrido.
    - **HUD**: `HUD/HealthIcons` (corazones `♥`/`♡`), `HUD/LivesLabel`
      ("VIDAS: n") y `HUD/DamageFlash` (ColorRect rojo con tween). El daño
      también sacude la cámara (`HorizontalCamera.shake()`); al reaparecer se
      llama `snap_to_target()`. La etiqueta de muerte distingue
      "HAS MUERTO", "SIN VIDAS" y "TIEMPO AGOTADO". El panel principal del
      menú ya no muestra la guía de controles (queda solo en Instrucciones y
      en la pausa).
    - **Guardado simple**: `SaveGame` (user://save.cfg) guarda nivel, tiempo
      total, muertes y completado; Jugar continúa el nivel guardado y, si la
      partida estaba completada, empieza una nueva. Completar un nivel guarda
      el siguiente y el tiempo se acumula sin duplicarse al morir
      (`_account_time()`).
    - **Pantalla final**: `scenes/ui/game_complete.tscn` +
      `scripts/ui/game_complete.gd` con tiempo total formateado, muertes,
      botones JUGAR DE NUEVO (reinicia estadísticas), MENÚ y SALIR.
      `level_four.tscn` apunta a ella.
    - **Presentación**: fundido a negro al empezar y entre escenas (CanvasLayer
      layer 90 creado por código), música procedural distinta por nivel
      (`Sfx.start_music(level_index)`: raíz/tempo/arpegio cambian; el
      reproductor persiste en la raíz) y créditos en la pantalla final.
    - **Legibilidad**: sierras con parpadeo de aviso (`warmup_time`, 0,6 s)
      antes de moverse y pinchos con brillo pulsante.
    - Tests: `checkpoint_smoke_test` nuevo (10), `game_complete_smoke_test`
      nuevo (11), `survival_smoke_test` 22 (corazones, flash, respawn, vidas),
      `timer_progress_smoke_test` 12, `exit_smoke_test` 11 (guarda nivel 2),
      `menu_smoke_test` 30 (sin mejoras, sin guía en el panel principal,
      nivel guardado),
      `level_two/three/four` 28/25/31 (checkpoints y final). Suite: 24/24.
    NOTA: el exe de `dist/` NO incluye este cambio ni los ítems 18-24;
    re-exportar cuando se pida.
26. **Ajuste de checkpoints, vidas y tiempo de respawn (2026-11-12)**:
    - **Un checkpoint por nivel a mitad del recorrido**: nivel 1 en x=11500
      (extensión del nivel), nivel 2 en x=6700, nivel 3 en x=6000 y nivel 4 en
      x=6000. En el gran pozo se añadió una **isla de descanso estática**
      (300×80 en y=720, superficie a y=680) sobre la zona de caída para alojar
      el control sin tocar la ruta móvil; ahora hay 3 islas firmes (inicio,
      descanso central y final).
    - **3 vidas por nivel**: se mantiene la cantidad; el HUD muestra
      "VIDAS: n" y los corazones siguen representando los 2 golpes de vida.
    - **Tiempo al reaparecer**: al revivir en un control se suman solo 10 s;
      si al morir quedaban 20 s o menos, el tiempo restante pasa a 30 s.
      Nunca supera el límite del nivel. Sustituye la regla anterior del 25 %.
    - **Fundido/transición de música**: `Sfx.start_music(level, fade_in)` entra
      con fundido, `Sfx.stop_music(fade_out)` baja el volumen y detiene el
      reproductor; imagen y música se funden a la vez en las transiciones de
      nivel, menú y pantalla final (`SceneFade` centraliza los cambios de
      escena desde menús/pantalla final).
    - **Agentes opencode**: `.opencode/agent/` define subagentes por área
      (`player-survival`, `levels-world`, `enemies-hazards`, `ui-flow`,
      `audio-fx`, `core-save`, `testing`) con instrucciones específicas y la
      obligación de correr la suite completa.
    - Tests: `checkpoint_smoke_test` 12 (1 control, cura, respawn, reglas de
      tiempo +10/30), `level_two` 28, `level_three` 25, `level_four` 33
      (3 islas y control central). Suite: 24/24.
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se pida.
27. **Inventario real (2026-11-12)**: el panel de Tab deja de ser informativo.
    - **`scripts/player/inventory.gd`** (`class_name Inventory`,
      RefCounted): fuente de verdad de cantidades y espacios rápidos. Enum
      `Category { PERMANENT, USABLE }`, catálogo `ITEMS` (poción, doble salto,
      caída rápida), `SLOT_COUNT=2` y `SLOT_ACTIONS=["item_1","item_2"]`.
      API: `add_item`, `consume`, `count`, `usable_items`, `permanent_items`,
      `unlock_permanent`, `equip`, `slot_item`, `slot_label`; señal `changed`.
    - **Jugador**: `Player.inventory` sustituye al contador suelto; `potions`
      pasa a getter de solo lectura sobre el inventario. `use_quick_slot(0/1)`
      usa el objeto equipado (Q/E) y `use_potion()` sigue existiendo como
      atajo. Al agotarse una poción su espacio rápido queda vacío; al añadir
      otra se auto-equipa en el primer hueco.
    - **Controles**: nueva acción `item_2` (E) en el Input Map, Opciones y
      guía de controles (ahora 12 keycaps). `attack` sigue sin existir; los
      tests de no-combate verifican que `item_2` es un espacio de objeto.
    - **HUD**: `ItemSlots` muestra `Q <objeto> - E <objeto>`; el panel de Tab
      separa `UTILIZABLES` y `PERMANENTES` y muestra los dos espacios rápidos
      (`PotionInfo`, `JumpsInfo`, `MetaInfo` reutilizados).
    - **Instrucciones**: el texto de ITEMS explica Q/E, las categorías y que
      Tab abre el inventario real.
    - Tests: `inventory_smoke_test` reescrito (37 comprobaciones),
      `pause_smoke_test` 18 (12 keycaps), `no_combat_smoke_test` 7,
      `player_smoke_test` 31, `menu_smoke_test` 31. Suite: 24/24.
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se pida.
28. **Nivel 4 poblado y walkers más rápidos (2026-11-13)**:
    - **WalkerEnemy**: nueva constante `MOVE_SPEED_SCALE = 1.25` aplicada a
      `velocity.x`; afecta a todos los walkers de todos los niveles sin tocar
      sus overrides de `patrol_speed`. RangedEnemy y SpreadEnemy (los que
      disparan) no cambian.
    - **Nivel 4**: además de los 4 walkers de salida/llegada, se añadió un
      walker en la isla de descanso central (x=6000, patrulla 95) y tres
      guardias SpreadEnemy (dos fijos en la isla de descanso en 5920/6080 y
      uno en la llegada en 11600) más otro en la salida (x=1000). Los guardias
      de la isla tienen `patrol_speed=0` para no caer al pozo.
    - Tests: `level_four_smoke_test` 36 (walkers >= 5, walker en la isla
      central, SpreadEnemy >= 4, ningún walker en el aire) y
      `enemy_patrol_smoke_test` 8 (escala de velocidad). Suite: 25/25.
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se pida.
29. **Ración, mando y selección de nivel (2026-11-13)**:
    - **Ración (E)**: nuevo objeto utilizable en `Inventory.ITEMS` (categoría
      USABLE, descripción "Añade 5 s al cronómetro"). El jugador empieza con
      1 (`starting_rations`), se auto-equipa en E y `use_quick_slot(1)` la
      consume y emite `item_used("ration")`. `TestLevel._on_item_used()` suma
      `RATION_TIME_BONUS = 5.0` segundos sin superar `time_limit`.
    - **Mando**: `scripts/core/gamepad_bindings.gd` (`class_name
      GamepadBindings`) mapea stick/DPAD y botones A/X/LB/RB/Back/Start a las
      acciones de juego. `GameSettings.ensure_loaded()` lo aplica y
      `_set_action_key()` lo re-aplica tras cada rebind para no perder el
      mando. Test nuevo `gamepad_smoke_test` (18 comprobaciones).
    - **Selección de nivel**: fila `LevelSelect` creada por código en el menú
      (botones 1-4 antes de Jugar); `SaveGame.start_at_level()` reinicia
      tiempo/muertes/completado y guarda el nivel elegido. Tests de menú
      ampliados a 34 comprobaciones.
    - Tests: `inventory_smoke_test` 43 (ración, señal y +5 s),
      `menu_smoke_test` 34, `gamepad_smoke_test` 18, `level_four` 36,
      `enemy_patrol` 8. Suite: 25/25.
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se pida.
30. **Legibilidad de controles y trampas (2026-11-13)**:
    - **Descanso en checkpoints**: al activar una bandera,
      `TestLevel._show_checkpoint_banner()` muestra durante ~1,8 s el aviso
      "CONTROL ACTIVADO / DESCANSO · VIDA RESTAURADA" sobre el HUD. El control
      sigue curando toda la vida y fijando el punto de reaparición.
    - **Trampas**: ya existían el parpadeo de aviso de las sierras
      (`warmup_time`) y el brillo pulsante de los pinchos; ahora un test
      dedicado comprueba ambos comportamientos.
    - Tests: `checkpoint_smoke_test` 13 (aviso de descanso),
      `hazard_legibility_smoke_test` nuevo (7 comprobaciones). Suite: 26/26.
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se pida.
31. **Nivel 4: plataformas en streaming y enemigos a bordo (2026-11-13)**:
    - **Máximo 6 plataformas activas**: nuevo `scripts/levels/level_four_route.gd`
      (`class_name LevelFourRoute`) sustituye las 31 plataformas simultáneas.
      La ruta conserva 31 huecos (`ROUTE_COUNT`) y 4 movimientos, pero solo
      mantiene 6 nodos vivos: al avanzar el jugador la plataforma más antigua
      se recicla al siguiente hueco. Al reaparecer, la ruta se recoloca
      alrededor del jugador (detecta retrocesos >900 px). Los huecos y
      trayectorias son funciones estáticas para que el test valide el alcance
      completo sin instanciar 31 nodos.
    - **30% más rápidas**: `LevelFourRoute.SPEED_SCALE = 1.3` multiplica la
      velocidad de vaivén, órbita y giro. Se eliminan las 6 plataformas
      opcionales de y=430.
    - **Enemigos a bordo**: los `SpreadEnemy` de las plataformas son hijos de
      plataformas no giratorias (`gravity=0`, `patrol_speed=0`, posición local
      `(0,-35)`) y viajan con ellas. Se eliminan el walker y los dos guardias
      de la isla de descanso; el control central queda despejado. Se añaden
      walkers en la salida/llegada (6 en total) y se mantienen los 2 arqueros
      de las islas.
    - Tests: `level_four_smoke_test` 49 (6 activas, reciclado, recolocación,
      alcance de los 31 huecos, 4 movimientos, enemigos a bordo y control
      limpio). Suite: 26/26.
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se pida.
32. **Inicio del nivel 4 despejado (2026-11-13)**:
    - **Jugador al borde izquierdo**: `LevelFourLayout.PLAYER_START = (70, 600)`
      coloca al jugador pegado al extremo izquierdo de la isla inicial y
      `camera.snap_to_target()` recoloca la cámara tras construir el nivel.
    - **Sin enemigos en la mitad izquierda**: se eliminan el walker de x=700 y
      el arquero de x=1000; la salida conserva dos walkers en x=1350 y x=1700
      (mitad derecha). `START_SAFE_X = 1100` documenta el límite.
    - Tests: `level_four_smoke_test` 49 (inicio en el borde y 0 enemigos con
      x < 1100). Suite: 26/26.
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se pida.
33. **Corrección del reciclado del nivel 4 (2026-11-13)**:
    - **Plataformas giratorias recolocadas sin tocar `sync_to_physics`**:
      teletransportar una giratoria con sync activo deja el cuerpo físico en
      la transformación vieja, y desactivar sync mueve el nodo pero deja la
      colisión en el sitio anterior (el jugador atraviesa la plataforma
      visible). `LevelFourRoute._recycle_platform()` devuelve `bool`: si el
      hueco destino es giratorio descarta la plataforma vieja
      (`_discard_platform()`) y crea una nueva con `_spawn_slot()` (así nodo y
      cuerpo físico nacen alineados); si no gira, reutiliza la plataforma con
      `teleport_to()`. `MovingPlatform.teleport_to()` solo reinicia `_origin`,
      `_time`, `_base_rotation`, `rotation` y `position`; nunca cambia sync.
    - **Guardias anclados**: `RangedEnemy` gana `anchored`; cuando está activo
      no ejecuta gravedad ni `move_and_slide()` y solo comprueba el daño por
      contacto. Los guardias de plataforma lo activan, así mantienen su
      posición local `(0,-35)` en lugar de despegarse y flotar.
    - **Proyectiles fuera de la plataforma**: `_projectile_parent()` sube por
      los padres hasta salir de un nodo del grupo `moving_platforms`. Las
      flechas/bolas de los guardias ya no se crean como hijas de la
      plataforma y dejan de viajar/desaparecer con ella.
    - Tests: `level_four_smoke_test` 57 (plataformas recicladas en su hueco,
      colisión física alineada con el cuerpo, giro tras reciclado, guardias
      anclados y proyectiles en el mundo). Suite: 26/26.
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se pida.
34. **Nivel 4 sin límite de plataformas y giro limitado (2026-11-13)**:
    - **Todas las plataformas activas**: `LevelFourRoute` deja de reciclar y
      de hacer desaparecer plataformas. La ruta queda en 17 huecos
      (`ROUTE_STEP = 480`) y todos existen a la vez; `get_active_slot_indices()`
      devuelve la ruta completa. Se eliminan `MAX_ACTIVE`, el reciclado y la
      recolocación por retroceso.
    - **Sin solapes**: el paso de 480 px y los recorridos reducidos (diagonal
      ±65 px, órbita 50 px) mantienen disjuntas las trayectorias consecutivas;
      el test comprueba que los rangos horizontales no se cruzan y que el
      hueco entre bordes sigue siendo <= 300 px.
    - **Inclinación máxima 30°**: `MovingPlatform` ya no da vueltas completas;
      `rotation = base + sin(t * rotation_speed) * PI/6`, así ninguna
      plataforma (incluidas las giratorias estáticas) supera ±30°.
    - Tests: `level_four_smoke_test` 57 (todas activas, sin reciclado, sin
      solapes, inclinación <= 30°, colisión alineada, guardias anclados y
      proyectiles en el mundo). Suite: 26/26.
    NOTA: el exe de `dist/` se re-exportó con este cambio.

35. **Magos, densidad del nivel 3 y reinicio al nivel 1 (2026-11-13)**:
    - **Magos recuperados**: nivel 3 en x=3300/6400/8800 y nivel 4 en
      x=1200/12200, fuera de las zonas seguras y del control central.
    - **Nivel 3 más legible**: los walkers de suelo bajan de 20 a 14
      posiciones (se quitan 1550, 3850, 5950, 8750, 11050 y 11350).
    - **Game over y tiempo agotado**: `TestLevel._restart_from_first_level()`
      usa `SaveGame.start_at_level(SaveGame.FIRST_LEVEL)` y
      `FIRST_LEVEL_PATH`; con vidas restantes se mantiene la reaparición en
      el control. HUD: "SIN VIDAS - Volviendo al nivel 1..." y
      "TIEMPO AGOTADO - Volviendo al nivel 1...".
    - Tests: `survival_smoke_test` 24, `timer_progress_smoke_test` 13,
      `level_three_smoke_test` 26, `level_four_smoke_test` 58. README
      actualizado.
36. **Niveles 5 y 6, plataformas modulares y voladores (2026-11-13)**:
    - **Asset modular de plataformas**: `scripts/world/platform.gd` pasa a
      `AnimatableBody2D` con `enum Kind { STATIC, HORIZONTAL, CIRCULAR,
      SPIKED, ROTATING }`. Vaivén con `travel`/`speed`, órbita horaria con
      `circle_radius`/`circle_speed`, giro limitado a ±30° y pinchos solo en
      los bordes (`SpikeLeft`/`SpikeRight`, centro libre). `platform.tscn`
      cambia su tipo de nodo y conserva el vestido visual. `PlatformSpacing`
      excluye las plataformas móviles del asset.
    - **Voladores**: `scripts/enemies/flying_enemy.gd` + escena (criatura
      alada, 20 PV, daño por contacto, sin gravedad ni colisión con el
      mundo); `scripts/enemies/flying_spawner.gd` los crea fuera del borde
      visible, alterna lado y permite altura aleatoria o la del jugador. La
      cámara se añade al grupo `camera` para localizar el centro de pantalla.
    - **Nivel 5 "CIELO"**: `level_five.tscn` + `level_five_layout.gd`, 110 s.
      Islas de inicio/final, 21 plataformas de ruta (paso 480, ancho 190,
      huecos ~290), los cinco tipos, un control en el índice 9, dos hierbas y
      un `FlyingSpawner` cada 4 s a altura aleatoria (150-520). Solo hay
      voladores como enemigos.
    - **Nivel 6 "FORTALEZA"**: `level_six.tscn` + `level_six_layout.gd`,
      120 s. 14 plataformas (paso 740, ancho 260, huecos de 480 px que
      exigen doble salto), pinchos en los bordes, 3 sierras patrullando y 2
      plataformas giratorias; control en el índice 6 y dos hierbas. Sin
      enemigos fijos: el reto son las trampas y los saltos.
    - **Integración**: `level_four.tscn` encadena al 5, el 5 al 6 y el 6 a
      `game_complete`; `SaveGame.LAST_LEVEL = 6`; el menú ofrece 6 niveles y
      las instrucciones muestran 110/120 s; `MOODS` añade CIELO y FORTALEZA.
    - Tests nuevos: `level_five_smoke_test` 34, `level_six_smoke_test` 44,
      `platform_asset_smoke_test` 15 y `flying_enemy_smoke_test` 9.
      Actualizados: `level_four_smoke_test` 58, `menu_smoke_test` 35,
      `platform_spacing_smoke_test` 22 (incluye niveles 5/6). Suite: 30/30.
    NOTA: el exe de `dist/` se re-exportó con los ítems 35-36.
37. **Menú de pausa completo, pinchos sobre suelo y vuelo duplicado
    (2026-11-16)**:
    - **Pausa con menú**: `scenes/ui/pause_overlay.tscn` pasa de una guía
      simple a tres paneles (`MenuPanel`, `GuidePanel`, `SettingsPanel`).
      El menú ofrece CONTINUAR, GUÍA, CONFIGURACIÓN, VOLVER AL MENÚ PRINCIPAL
      y SALIR. La guía reutiliza `ControlGuide` en una columna (12 keycaps);
      Configuración replica brillo, volumen, rebinding y restaurar controles
      del menú principal. `scripts/ui/pause_overlay.gd` conserva la pausa con
      Enter y sigue bloqueada al morir/completar; volver al menú reanuda el
      árbol y usa `SceneFade`, y Salir cierra el juego.
    - **Brillo en pausa**: se aplica al `CanvasModulate` del nivel mediante
      `GameSettings.apply_brightness()`, no a una capa nueva.
    - **Pinchos solo en suelo**: en `level_two_layout.gd` se eliminan los
      cuatro pinchos del fondo de los fosos y el de x=5450 se mueve a x=5800
      (isla de tierra 5620-7000). Los pinchos de borde de las plataformas
      `Platform.Kind.SPIKED` siguen permitidos. Tests: `level_two` 29 y
      `hazard_legibility` 7 validan que no haya pinchos sueltos en el aire.
    - **Vuelo más amplio y rápido**: `FlyingEnemy.wave_amplitude` pasa de
      42 a 84 y `wave_frequency` de 2.2 a 4.4 (+100 % de recorrido vertical y
      de velocidad de oscilación). `flying_enemy_smoke_test` 11 comprueba los
      valores base.
    - **Tests**: `pause_smoke_test` 38 (menú, guía, configuración, paneles que
      caben en pantalla, cancelación de rebinding, reanudar y bloqueo tras
      morir),
      `level_two_smoke_test` 29, `flying_enemy_smoke_test` 11 y
      `hazard_legibility_smoke_test` 7. Suite completa: 30/30.
    NOTA: el exe de `dist/` se re-exportó con los ítems 18-37.
38. **Contornos negros en formas geométricas básicas (2026-11-16)**:
    - **Objetivo**: mejorar la legibilidad de las trampas y estructuras
      dibujadas con polígonos planos. Se añadió un contorno negro cerrado
      (`Line2D`, 2-3.5 px, unión y extremos redondeados) a las plataformas,
      plataformas móviles, pinchos, sierras, controles (base, mástil y
      bandera) y portal (borde exterior, anillo medio y núcleo).
    - **Plataformas dinámicas**: `platform.gd` crea/actualiza `Outline` en
      `_refresh()` con los mismos límites que `platform_size`; así el
      contorno sigue el tamaño y queda por encima del vestido visual.
    - **Animaciones intactas**: los contornos son hijos de los polígonos en
      controles, portal y sierras, por lo que acompañan al recoloreo, al
      pulso del portal y al giro de la sierra. El pincho mantiene su pulso
      de `Visual` y el contorno queda fijo.
    - **Tests**: `visual_polish_smoke_test` pasa a 55 comprobaciones
      (existencia, cierre y color negro de 11 contornos, además del ajuste
      dinámico del contorno de plataforma). Suite completa: 30/30.
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se
    pida.
39. **Murciélagos al borde visible y resistencia del jugador (2026-11-16)**:
    - **Despawn por pantalla**: `FlyingEnemy` elimina `lifetime` y usa
      `despawn_margin` (48 px) + `_visible_world_rect()` (Camera2D actual,
      zoom y `get_screen_center_position()`). Desaparece al cruzar el borde
      visible en su dirección, no por tiempo ni distancia.
    - **Tres golpes**: `scenes/player/player.tscn` sube
      `Health.max_health` a 3; el HUD dibuja tres corazones de forma
      dinámica (`test_level.gd`).
    - **Invulnerabilidad 1 s**: `PlayerStats.invulnerability_time` pasa de
      0.5 a 1.0 tanto en el recurso como en el valor por defecto.
    - Tests: `flying_enemy_smoke_test` 12 (borde derecho e izquierdo con
      Camera2D), `survival_smoke_test` 26 (tres golpes y HUD),
      `checkpoint` 13, `healing` 5, `inventory` 43, `pickup` 7,
      `enemy_patrol` 8, `enemy_ranged` 23, `enemy_visual` 29 y `level_two`
      29 ajustados a las nuevas esperas de 1 s. Suite: 30/30.
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se
    pida.
40. **Texturas procedurales de plataformas (2026-11-16)**:
    - **Helper reutilizable**: `scripts/world/platform_texture.gd`
      (`class_name PlatformTexture`) crea/actualiza `TextureDetail` con vetas
      horizontales y motas deterministas de baja opacidad. Usa semilla basada
      en tamaño/color, no necesita assets y se inserta debajo de los remates y
      del contorno.
    - **Cobertura**: `Platform._refresh()` aplica la textura a las plataformas
      estáticas, móviles, circulares, giratorias y con pinchos de los seis
      niveles; `MovingPlatform._ready()` hace lo mismo con su tamaño y color
      del nivel 4.
    - Tests: `visual_polish_smoke_test` pasa a 62 comprobaciones (textura en
      plataforma fija y móvil, opacidad sutil, adaptación al ancho y orden
      bajo el contorno). Suite completa: 30/30.
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se
    pida.
41. **Niveles 5 y 6 ampliados, sierras aéreas y centinela (2026-11-16)**:
    - **Nivel 5**: recorrido de 28 plataformas (antes 21), ancho 17000 px,
      portal en 16400, control en el índice 13, hierbas en 5/18/24 y cuatro
      sierras suspendidas en los índices 4/10/17/23. El tipo de plataforma
      alterna seis variantes (con más pinchos) y el fondo crece a 12 colinas,
      16 nubes, 7 aves y rocas flotantes adicionales.
    - **Nivel 6**: recorrido de 20 plataformas (antes 14), ancho 18000 px,
      portal en 17400, control en el índice 10 y hierbas en 5/13/19. Suma
      cinco sierras de suelo (1/5/9/14/18) y cinco suspendidas
      (2/6/10/14/17), además del centinela superior.
    - **Sierras**: `saw_trap.gd` dibuja una rueda de 12 dientes (radios 27/18)
      y un `PathGuide` (`Line2D`, `top_level`) con el recorrido completo.
      `move_range` sigue siendo la mitad del trayecto; las suspendidas usan
      `PLATFORM_SIZE.x`, así su recorrido mide el doble del ancho de una
      plataforma normal.
    - **Centinela**: `SkySentry` + escena, grupo `sky_sentries`, se mantiene en
      el centro del borde superior de la cámara, oscila ligeramente y dispara
      cada 2 s un proyectil apuntado a 260 px/s. No tiene vida ni colisión.
      Aparece en el nivel 6.
    - Tests: `level_five_smoke_test` 39, `level_six_smoke_test` 55 y
      `sky_sentry_smoke_test` 9. Suite completa: 31/31.
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se
    pida.


42. **Ajustes del centinela, voladores, pozos y mago azul (2026-11-16)**:
    - **Centinela**: `SkySentry` dispara 5 proyectiles en un cono de 70°
      equidistante y apuntado al jugador (antes 10); se ancla en la esquina
      superior derecha de la cámara (`right_margin` 120, `top_margin` 80) y
      su visual crece a escala 1.75.
    - **Voladores del nivel 5**: `FlyingSpawner` lanza uno cada 3 s (antes 4)
      con retardo inicial 1.5 s, altura aleatoria 110-560, lado y margen
      aleatorios; los murciélagos entran en el grupo `flying_enemies` y
      `TestLevel._on_player_died()` los limpia con
      `FlyingSpawner.clear_flying_enemies()`.
    - **Contacto fiable**: se ampliaron las `DamageArea` de flying (46x32),
      ranged (40x50) y spread (40x40) para que el daño por contacto se note
      con los cuerpos más pequeños.
    - **Nivel 5**: se eliminaron las aves decorativas del layout.
    - **Nivel 6**: la capa de montañas (`HillParallax`) gana un suelo que
      llega al borde inferior (y 650-720) y el suelo inicial baja hasta 720;
      se añadió `GiantCreatureParallax` (0.05, z -28) con la silueta negra
      de una criatura gigante, haz de luz azul y ojo en forma de luna
      creciente (el haz se recorta en y=640, sin salir de pantalla).
    - **Pozos mortales**: la `FallZone` de los niveles 5 y 6 medía 14000 px
      centrada en x=6800 y dejaba sin protección los últimos huecos (hasta
      x≈16000); ahora se centra en el nivel y su forma cubre todo el ancho
      (`LEVEL_WIDTH + 800`, alto 120). Tests de regresión añadidos.
    - **Mago azul y sonidos**: `fireball.svg` pasa a paleta azul/cian (orbe
      de energía), la estela y el estallido al impactar también son azules y
      el `Glow` se tiñe de azul. Nuevos sonidos procedurales en `sfx.gd`:
      `magic` (orbe del mago), `arrow` (flecha del arquero) y `sentry`
      (descarga del centinela); cada enemigo usa el suyo.
    - Tests: `sky_sentry` 16, `flying_enemy` 14, `level_five` 41,
      `level_six` 58 y `enemy_ranged` 25 (incluye comprobación de sonidos
      distintos). Suite completa: 31/31.
    NOTA: el exe de `dist/` se re-exportó con los ítems 18-42.

43. **Ataque rojo del centinela del nivel 6 (2026-11-16)**:
    - **Textura propia**: `assets/enemies/sentry_bolt.svg` (orbe rojo/naranja) se reserva para el centinela; el mago conserva el orbe azul del ítem 42.
    - **`EnemyProjectile`**: nuevos `use_sentry_style()` / `is_sentry_style()` (idempotentes) y `impact_color`. El centinela usa textura, `Glow`, estela y estallido rojos; el mago sigue azul y el arquero no lleva estela.
    - **`Fx`**: `make_sentry_trail()`, `apply_sentry_trail()` y `_sentry_ramp()` (blanco → rojo → rojo transparente); `make_fire_trail()` mantiene el degradado azul y ambos comparten `_make_trail()`.
    - **Disparo**: `SkySentry._shoot_at_player()` aplica el estilo rojo a los 5 proyectiles del cono.
    - Tests: `sky_sentry_smoke_test` 28 (estilo, textura, estela e impacto rojos) y `enemy_ranged_smoke_test` 26 (el mago no usa el estilo rojo). Suite completa: 31/31. El test del centinela deja de ser intermitente (sin bob y más espera al mover la cámara).
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se pida.

44. **Todos los niveles a 70 segundos (2026-11-16)**:
    - `TestLevel.time_limit` por defecto pasa de 100 a 70 y las seis escenas (`level_one` a `level_six`) fijan `time_limit = 70.0`, antes 100/80/75/90/110/120.
    - El HUD base muestra `TIEMPO: 70` y el texto de TIEMPO de Instrucciones queda unificado: "Los seis niveles tienen 70 segundos."
    - Tests ajustados: `level_one_layout`, `level_four`, `level_five`, `level_six`, `timer_progress` y `menu` (comprueba que las instrucciones digan 70). La ración sigue sumando 5 s y el reaparecer +10/30 s sigue sin superar el nuevo límite.
    - Suite completa: 31/31.
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se pida.

45. **Nivel 7 invertido "INVERSO" (2026-11-16)**:
    - **Gravedad invertida reutilizable**: `Player` gana `inverted_gravity` y `configure_gravity()` (llamada también desde el layout porque el `_ready()` del jugador ya pasó cuando se construye el nivel). Invierte `up_direction`, gravedad, salto, caída rápida, animación, polvo y sombra. `TrainingDummy` (base de walker/ranged/spread) añade el mismo flag y voltea sombra, `HeadShape` y área de daño; los dos scripts con movimiento aplican el signo a la gravedad y el walker invierte su rayo de suelo.
    - **`EnemyVisualVariant`**: helper estático idempotente (`scripts/enemies/enemy_visual_variant.gd`) que oculta sombreros originales (`SombreroDome*`, `WizardHat`, `ArcherHood`), añade `Visual/Level7Hat` (triángulo amarillo con contorno negro) y reescribe ojos a almendras inclinadas (comisura externa más alta), ocultando cejas del mago. Solo lo llama el nivel 7, así que los niveles 1-6 no cambian.
    - **`LevelSevenLayout`**: réplica vertical del nivel 1 (`y' = 720 - y`): techo continuo, 12 secciones con pozos, seis plataformas por sección, mismos tiers, área inicial, herencias visuales y base del nivel 1, enemigos y hierbas; el reciclado de alturas respeta la regla de espaciado. Un control en x=11500 a y=128, portal en (21850,140), `FallZoneInverted` a todo el ancho por encima del techo y cámara 0..22400.
    - **Integración**: `level_six.tscn` encadena al nuevo `level_seven.tscn`, que termina en `game_complete.tscn`. `SaveGame.LAST_LEVEL = 7`, menú con selector 1-7, instrucciones actualizadas y quinto tema procedural en `Sfx._build_music()`.
    - Tests: `level_seven_smoke_test` nuevo (414 comprobaciones: gravedad, apoyo en techo, salto hacia abajo, techo/portal/control/zona mortal, 39 enemigos con triángulo y ojos, etc.), `menu_smoke_test` 35 (selector de 7), `level_six_smoke_test` 58 (nueva cadena), `platform_spacing_smoke_test` 24 (incluye nivel 7) y `jump_control_smoke_test` 11 (regresión de impulso mantenido). Suite completa: 32/32.
    NOTA: el exe de `dist/` se re-exportó con los ítems 18-45.

46. **Nivel 8 espejo del nivel 2 y controles invertidos (2026-11-16)**:
    - **`LevelTwoLayout.build(level, mirror_width)`**: el generador del nivel 2 acepta un ancho de espejo opcional (por defecto `-1`, sin cambios). Todas las posiciones se transforman con `x' = ancho - x` mediante `_mx()`/`_mv()`, incluidas colinas, nubes, árboles, suelo, pasos, sierras, pinchos, plataformas móviles, enemigos, hierbas, control y portal. El `travel.x` de las plataformas móviles también cambia de signo.
    - **`LevelEightLayout`**: nivel 8 de 13400 px que reutiliza el layout del nivel 2 con espejo, renombra el mundo a `LevelEightGenerated`, coloca al jugador en `(12780, 600)` (espejo del spawn original) y fuerza `camera.snap_to_target()` tras moverlo. Portal en `(450, 580)`, recorrido hacia la izquierda y un control en `x=6700`.
    - **Controles invertidos**: `Player.inverted_controls` y `configure_controls()` invierten solo el eje horizontal (D/flecha derecha mueven a la izquierda; A/flecha izquierda a la derecha). Al pasar por las acciones del Input Map, el mando queda invertido igual. El sprite inicial mira a la izquierda. No afecta a salto, caída rápida ni objetos.
    - **Integración**: `level_seven.tscn` encadena al nuevo `level_eight.tscn`, que termina en `game_complete.tscn`. `SaveGame.LAST_LEVEL = 8`, menú con selector 1-8, instrucciones actualizadas y sexto tema procedural en `Sfx._build_music()`.
    - Tests: `level_eight_smoke_test` nuevo (71 comprobaciones: spawn a la derecha, portal a la izquierda, suelo/plataformas móviles/sierras/pinchos/enemigos/hierbas reflejados, control central y dirección real del movimiento), `level_two_smoke_test` 29 (regresión sin espejo), `level_seven_smoke_test` 414 (nueva cadena), `menu_smoke_test` 35 y `platform_spacing_smoke_test` 26. Suite completa: 33/33.
    NOTA: el exe de `dist/` se re-exportó con los ítems 18-46.

47. **Fase 1 auditada y Fase 2 contrarreloj (2026-11-17)**:
    - **Auditoría previa**: se entregó un informe sin tocar código con sistemas reutilizables, cambios necesarios, arquitectura para 40 niveles, organización de enemigos/obstáculos/gimmicks, cronograma, riesgos y estrategia de tests. El usuario autorizó continuar con la Fase 2.
    - **`scripts/core/run_timer.gd`** (`class_name RunTimer`): separa `elapsed` (tiempo real, base de la medalla) de `remaining` (cuenta regresiva del HUD). `tick()` sigue corriendo mientras el jugador está muerto; la pausa del SceneTree lo congela al no llamarse `_process()`.
    - **`scripts/core/medal_rules.gd`** (`class_name MedalRules`): `NONE/BRONCE/PLATA/ORO`, `for_time()`, `rank()`, `is_better()` y `display()`. Umbrales por nivel exportados en `test_level.gd`: 35/50/70 s por defecto.
    - **Sin bonuses de tiempo**: se eliminaron las reglas de reaparición +10/30 s y el bonus de ración +5 s. La ración ahora activa `Player.apply_speed_boost()` (×1.35 durante 5 s) sin tocar el cronómetro.
    - **HUD y resultados**: nuevo `HUD/MedalLabel` con medalla proyectada y tiempo con centésimas; al completar, el cartel indica `MEDALLA ...` y se llama a `SaveGame.record_level_result()`.
    - **`SaveGame` ampliado**: secciones `level_N` con `best_time`, `medal`, `deaths` y `completed`; API `record_level_result`, `get_best_time`, `get_medal`, `get_level_deaths`, `is_level_completed`, `medal_count`, `total_best_time` y `format_time_precise`. Los saves antiguos siguen cargando el progreso de la expedición.
    - **Tests**: `time_medal_smoke_test` nuevo (16 comprobaciones); `checkpoint`, `inventory`, `timer_progress` y `exit` actualizados. Suite completa: **34/34**.
    - `SaveGame.LAST_LEVEL` sigue en 8: la expansión a 40 niveles/8 mundos corresponde a fases posteriores.
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se pida.

48. **Fase 3 inicial — registro de niveles y resultados (2026-11-17)**:
    - **Configuración declarativa**: `resources/levels/level_config.gd`
      (`class_name LevelConfig`) guarda número, mundo, posición, nombre, escena,
      límite y umbrales de medalla. `resources/levels/world_config.gd`
      (`class_name WorldConfig`) agrupa cinco niveles y un color de acento.
    - **`scripts/core/level_registry.gd`** (`class_name LevelRegistry`): define
      8 mundos × 5 niveles (40 entradas) y expone búsquedas, listados, rutas,
      estado de implementación y siguiente nivel implementado. Los ocho niveles
      creados ocupan los primeros ocho huecos secuenciales; el resto aparece
      como "POR CONSTRUIR" sin ruta cargable.
    - **Menú**: el selector pasa de 8 botones sueltos a un `ScrollContainer` con
      dos columnas de mundos (40 botones con códigos `m-n`). Los niveles
      pendientes están desactivados. El rótulo muestra "NIVEL n DE 40 · MUNDO
      m DE 8" y Jugar usa la ruta del registro.
    - **Guardado y cadena**: `SaveGame.LAST_LEVEL` pasa de 8 a 40. Tras completar
      un nivel se calcula el destino con `LevelRegistry.next_implemented_level()`,
      así el nivel 8 sigue terminando en la pantalla final aunque ya existan 40
      huecos. `SaveGame` guarda el último resultado (`last_result_*`) en memoria
      para la pantalla de resultados.
    - **Pantalla de resultados**: `scenes/ui/level_results.tscn` +
      `scripts/ui/level_results.gd` muestran tiempo con centésimas, medalla,
      muertes, mejor marca y botones SIGUIENTE NIVEL / REPETIR / MENÚ. El portal
      lleva a esta pantalla antes de continuar.
    - **Tests**: `level_registry_smoke_test` (69) y `level_results_smoke_test`
      (11) nuevos; `menu_smoke_test` ampliado a 43. Suite completa: **36/36**.
    - Queda pendiente calibrar umbrales por nivel y poblar los 32 niveles nuevos;
      las escenas de los mundos 3-8 todavía no existen.
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se pida.

49. **Rediseño del menú principal (2026-11-17)**: solo se añadió; lo que ya
    funcionaba no se tocó.
    - **Cinco botones**: INICIO (pasa a "CONTINUAR · NIVEL n" si hay progreso
      guardado), SELECCIÓN DE NIVEL, CÓMO JUGAR, OPCIONES y CERRAR JUEGO. La
      selección de nivel (40 botones, 8 mundos, bloqueados los no creados)
      pasó del panel principal a `LevelSelectPanel` (mismos nombres de nodo
      `Level%dButton`/`World%dBox`); muestra mejor marca y medalla del nivel
      enfocado y un punto de medalla en cada botón. Nombre del botón nuevo:
      `SelectLevelButton` (no usar `LevelSelectButton`: choca con el patrón
      `Level*Button` de los tests).
    - **Estilo**: `scripts/ui/menu_style.gd` (`MenuStyle`, paleta cielo/pradera/
      tinta/ámbar/ocre, estados normal/hover=foco/presionado/desactivado) y
      `scripts/ui/menu_backdrop.gd` (`MenuBackdrop`: cielo, sol, nubes,
      colinas, árboles y jugador corriendo con los assets existentes). La
      luna/estrellas antiguas quedan ocultas, no borradas.
    - **Opciones**: música y efectos por separado (buses `Music`/`SFX`
      creados por `GameSettings.ensure_audio_buses()`), pantalla completa y
      controles en 2 columnas para que el panel quepa en 648 px. Brillo y
      volumen general se mantienen.
    - **Salida con confirmación** (`QuitPanel`; Esc en el menú también pide
      confirmar), transición de 0,15 s entre paneles y sonidos de foco/
      confirmación (`ui`, `ui_confirm`).
    - **Errores corregidos**: el objetivo decía "completa los seis" niveles;
      Esc cerraba el juego sin avisar; el foco y el hover no se distinguían.
    - Tests: `menu_ui_smoke_test` nuevo (37) y `menu_smoke_test` 43 (rutas y
      textos nuevos). Suite: 37/37.
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se pida.

50. **Desbloqueo por mundos con pasada seguida (2026-11-17)**: el mundo n+1
    solo se abre al completar TODOS los niveles (creados) del mundo n seguidos
    en una misma pasada. Cada nivel se puede practicar suelto desde la
    selección, pero eso no desbloquea nada.
    - **`SaveGame`**: `cleared_worlds`, `world_run`/`world_run_progress` (pasada
      activa, persistida en `[run]`), `last_world_cleared`, y la API
      `is_world_unlocked`, `is_level_unlocked`, `is_world_cleared`,
      `mark_world_cleared`, `unlock_hint`. Una pasada empieza al elegir el
      primer nivel de un mundo abierto (`start_at_level`, `begin_new_run` o
      entrar por la cadena con `set_level`); empezar en otro nivel es práctica.
      `record_level_result` la avanza solo si el nivel completado es el
      esperado en orden; saltarse el orden la invalida y el game over/tiempo
      agotado la reinicia (`start_at_level(1)`). Morir con vidas restantes no
      la rompe. Los mundos superados se guardan en `[worlds]`; las partidas
      antiguas se migran respetando los mundos ya alcanzados.
    - **Menú**: los niveles de mundos bloqueados salen desactivados, la
      etiqueta del mundo dice BLOQUEADO/SUPERADO, el panel muestra
      `UnlockRuleLabel` y, al enfocar un nivel bloqueado, qué mundo superar.
      INICIO vuelve al nivel 1 si el nivel guardado está bloqueado.
    - **Resultados**: muestra "PASADA DEL MUNDO n: k/total", el aviso de mundo
      superado o el de práctica; si el mundo siguiente sigue bloqueado el botón
      pasa a VOLVER AL MENÚ. `TestLevel` no avanza el nivel guardado a un
      mundo bloqueado.
    - Tests: `world_unlock_smoke_test` nuevo (22), `menu_ui_smoke_test` 43 y
      `menu_smoke_test` 43 (marca el mundo 1 superado). Suite: 38/38.
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se pida.

51. **Niveles 9 "RUINAS" y 10 "TEMPLO" (2026-11-17)**: completan el mundo 2
    (2-4 y 2-5); ya hay 10 niveles jugables, todos de 70 s.
    - **Nivel 9** (`level_nine.tscn` + `level_nine_layout.gd`, 15800 px):
      templo en ruinas al atardecer. Inicio, 9 tramos de suelo de 1120 px y
      una isla final separados por fosos de 280 px, con una única `FallZone`
      a todo el ancho. Cada sección lleva escalones de piedra y un puente
      sobre el foso (fijo, de vaivén o circular según `index % 3`), caminantes
      y, rotando por sección, pinchos / arquero sobre las ruinas y sierra /
      mago en el suelo. Control en la sección 4 y hierbas en 2/5/7.
    - **Nivel 10** (`level_ten.tscn` + `level_ten_layout.gd`, 16600 px):
      ascensión zigzagueante de 24 plataformas en cuatro alturas
      (550/450/350/250, desnivel máximo 100 px), con los cinco tipos del asset
      modular, cuatro altares anchos (arquero y mago alternos, el de la
      hierba sin enemigo), cuatro sierras suspendidas y murciélagos cada 4 s.
      Control en el índice 12 y portal en la isla final.
    - **Integración**: `LevelRegistry.IMPLEMENTED_LEVELS` con 9 y 10; cadena
      8 -> 9 -> 10 -> pantalla final; `MOODS` y `_prepare_level_nine/ten` en
      `test_level.gd`; temas de música propios para 9 y 10 (los niveles 1-8
      conservan los suyos). Superar el mundo 2 (regla de pasada seguida)
      exige ahora los 5 niveles, 6-10; el mundo 3 sigue sin niveles.
    - Tests: `level_nine_smoke_test` (31) y `level_ten_smoke_test` (30)
      nuevos; actualizados `level_registry`, `level_eight`, `level_results`,
      `menu`, `menu_ui`, `world_unlock` y `platform_spacing` (incluye 9 y 10).
      Suite: 40/40.
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se pida.

52. **Nivel 9 más difícil: plataformas altas, más proyectiles y rocas
    (2026-11-17)**:
    - **Plataformas altas**: cada sección suma una plataforma a 330 px
      (`TIER_TOP`, x0+1000) y otra a 220 px (`TIER_PEAK`, x0+560); la regla de
      espaciado se cumple.
    - **Más enemigos de proyectil**: 8 arqueros y 8 magos (antes 3 y 3), en
      suelo, escalones, la plataforma de 330 y la de 220.
    - **Rocas que caen**: `scripts/world/falling_rock.gd` (`FallingRock`,
      construida por código) y `scripts/world/rockfall_spawner.gd`
      (`RockfallSpawner`). Un marcador rojo parpadeante (grupo `rock_warnings`)
      avisa 1,5 s en la superficie de impacto; después la roca aparece sobre el
      borde superior de la pantalla y cae a 1500 px/s, quita un golpe al jugador
      y se rompe contra el primer suelo/plataforma. El generador lanza una cada
      2,2 s (mitad sobre el jugador, 30 % de dobles), solo con el jugador entre
      x 1500 y 14200, y no crea nada sobre fosos. `TestLevel._on_player_died()`
      las limpia.
    - **Enemigo ya existente añadido**: murciélagos (`FlyingSpawner`) cada 5 s.
      No se encontró en el repositorio una "lista" de enemigos nuevos; se usó el
      volador, que el nivel 9 aún no tenía.
    - Tests: `rockfall_smoke_test` nuevo (19), `level_nine_smoke_test` 36.
      Suite: 41/41.
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se pida.

53. **Nivel 9: rocas por delante x3 y bruto lanzarrocas (2026-11-17)**:
    - **Rocas por delante**: `RockfallSpawner` ya no apunta al jugador; el
      punto de impacto es siempre `player.x + ahead_direction * [min_ahead
      (80), max_ahead (480)]` y la segunda roca de un par cae aún más
      adelante (`double_gap`). **Triple de rocas**: `ROCK_INTERVAL = 2.2 / 3`
      (≈0,73 s).
    - **Enemigo nuevo `BruteEnemy`** (`scripts/enemies/brute_enemy.gd`,
      `scenes/enemies/brute_enemy.tscn`, extiende `TrainingDummy`): persona
      fornida con ropa roja, 30 % más alta que el resto (colisión 44x62,4 y
      silueta x1,625 frente a 32x48 y x1,25). Inmóvil y de pie junto a una pila
      de rocas; lanza un peñasco a 45 grados cada 2,2 s si el jugador está entre
      120 y 560 px. La velocidad inicial se calcula con v² = g·d²/(dy+d)
      (g = 1200, entre 480 y 950 px/s) para que la parábola pase por el jugador.
    - **`ThrownBoulder`** (`scripts/enemies/thrown_boulder.gd`): proyectil con
      gravedad propia (`fall_gravity`; `gravity` choca con Area2D), diámetro 72
      px = 1,5 x los 48 px del modelo del jugador, quita un golpe y se rompe al
      chocar. **`RockPile`** (`scripts/world/rock_pile.gd`): dos bloques sólidos
      (altura total 88 px) sobre los que se puede saltar.
    - **Nivel 9**: tres brutos con su pila en las secciones 1, 4 y 7 (bruto a
      x0+700, pila a x0+585).
    - Tests: `brute_enemy_smoke_test` nuevo (23), `rockfall_smoke_test` 22 y
      `level_nine_smoke_test` 40. Nota: un objeto liberado no es `== null` en
      GDScript; comprobar con `is_instance_valid`. Suite: 42/42.
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se pida.

54. **Babosa saltarina y nivel 10 más difícil (2026-11-17)**:
    - **Enemigo nuevo `SlugEnemy`** (`scripts/enemies/slug_enemy.gd`,
      `scenes/enemies/slug_enemy.tscn`, extiende `TrainingDummy`): permanece
      quieta y salta con tres alturas (velocidades 340/470/600 px/s, nunca la
      misma dos veces seguidas). Antes de saltar se agacha 0,4 s (aviso
      legible). Con el jugador a menos de 480 px salta hacia su posición
      aproximada (error de +-50 px, 75 % de las veces); si no, salta en el
      sitio. Un rayo comprueba que haya suelo donde aterrizaría y, si no lo hay,
      salta en el sitio (no se lanza a un foso). Variante `double_jump`
      (naranja): dos saltos seguidos antes de detenerse. Señal
      `jumped(jump_speed, horizontal_speed)`. Estados: IDLE, WINDUP, AIR,
      LANDING.
    - **Nivel 10 con cambios como los del 9**: cuatro plataformas altas a 150 px
      (`TempleSkyStep*`, con un arquero cada una), 6 arqueros y 2 magos más sobre
      la ruta, `RockfallSpawner` (por delante, cada 0,73 s, solo entre x 1700 y
      14600), dos brutos con su pila (uno en el altar 2 y otro de guardián en la
      isla final) y cuatro babosas (altar 1 normal, altar 3 y una de las dos de
      la isla final de doble salto).
    - Tests: `slug_enemy_smoke_test` nuevo (18, tarda ~1 min) y
      `level_ten_smoke_test` 41. Trampa: las lambdas de GDScript capturan los
      números por valor; los contadores de los tests van en arrays. Suite: 43/43.
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se pida.

55. **Tres enemigos nuevos, viento y nivel 11 "VIENTO" (2026-11-17)**:
    - **`SpearmanEnemy`** (lancero de patrulla): patrulla su plataforma sin
      caerse (rayo al suelo), y al detectar al jugador (280 px, +-90 px de
      altura) se detiene 0,5 s en postura de preparación (lanza hacia atrás,
      cuerpo amarillento), da una estocada horizontal de 0,14 s con hitbox de
      120 px a media altura (se salta) y queda 0,9 s recuperándose. Variante
      `narrow`: casi no patrulla (30 px) y su lanza llega a 150 px.
    - **`OrbEnemy`** (orbe perseguidor): suspendido (sin gravedad, motion
      FLOATING); dentro de 380 px persigue en línea recta con aceleración
      progresiva (50 -> 320 px/s); al chocar con una plataforma queda aturdido
      0,8 s (apagado) y se reactiva empezando despacio; si el jugador se aleja
      (x1,5) vuelve a quedar suspendido. Variante `axis = VERTICAL`: solo se
      mueve en vertical y reacciona cuando el jugador pasa por su columna.
    - **`BlastJumperEnemy`** (saltador explosivo, `shock_wave.gd`): quieto hasta
      detectar al jugador (420 px); se comprime y parpadea en rojo 0,7 s, salta
      rápido (parábola de ~0,72 s hacia la posición del jugador, acotada y sin
      saltar al vacío) y al aterrizar crea una `ShockWave` a ras de suelo
      (150 px en 0,4 s) que daña una vez si el jugador tiene los pies a ras de
      suelo dentro del radio; se esquiva saltando. Reposo 2,5 s. Variante
      `long_jump` (morada): alcance 540 px, onda de 190 px, preparación de 1,1 s
      y reposo de 3 s.
    - **Viento**: `scripts/world/wind_field.gd` (`WindField`) con tramos
      `{from, to, speed}` y ráfagas (40-100 %, periodo 7 s) que escribe
      `Player.wind_speed` cada frame de física; `player.gd` lo suma antes de
      `move_and_slide()` (en el suelo pesa `WIND_GROUND_FACTOR = 0,35`) y lo
      resta después, sin acumularse. Dibuja rayas de viento y la etiqueta
      "VIENTO »»»/«««" en una capa propia.
    - **Nivel 11 "VIENTO"** (3-1, `level_eleven.tscn` + `level_eleven_layout.gd`,
      17000 px, 70 s): 34 plataformas (paso 400, huecos de 180 px, cuatro
      alturas), cinco fortines anchos (checkpoint en el 17), los cinco tipos de
      plataforma, cuatro sierras suspendidas, tres tramos de viento (en contra
      -115, a favor +110, en contra -130), 4 arqueros y 4 magos, 3 lanceros (2
      estrechos), 3 orbes (1 vertical), 2 saltadores (1 de salto largo) y tres
      hierbas. Cadena 10 -> 11 -> pantalla final; `LevelRegistry` con el nivel
      11; música propia (índice 8). Superar el mundo 3 solo exige este nivel por
      ahora.
    - Tests: `spearman_enemy_smoke_test` (17), `orb_enemy_smoke_test` (15),
      `blast_jumper_smoke_test` (19), `wind_smoke_test` (12) y
      `level_eleven_smoke_test` (38) nuevos; actualizados `level_registry`,
      `level_results`, `level_ten`, `menu_ui` y `platform_spacing` (incluye el
      nivel 11). Trampas: `ShockWave` fija `ground_y` en su primer frame de
      física (la posición se asigna tras `add_child`); un nodo liberado es igual
      a `null` en GDScript. Suite: 48/48.
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se pida.

56. **Niveles 12-15, mundo 3 "DESIERTO" (2026-11-17)**: completan el mundo 3
    (3-2 a 3-5); ya hay 15 niveles jugables de 70 s. Cadena 11 -> 12 -> 13 -> 14
    -> 15 -> pantalla final; `LevelRegistry` con los nombres DUNAS, OASIS, CAÑÓN
    y TORMENTA; música propia por nivel (índices 9-12 en `Sfx._build_music`).
    Superar el mundo 3 (pasada seguida) exige ahora los cinco niveles 11-15.
    - **`scripts/levels/desert_kit.gd` (`DesertKit`)**: utilidades compartidas
      (cielo con capas lejanas "dunes"/"pyramids"/"mesas", palmeras, suelo,
      plataformas del asset modular, enemigos, trampas, viento, rocas,
      murciélagos y centinela). Los niveles 12-15 solo describen su diseño; los
      generadores de los niveles 1-11 no se tocaron.
    - **Nivel 12 DUNAS** (16600 px): diez tramos de suelo con fosos de 300 px,
      escalones y puente sobre cada foso (fijo/vaivén/circular), viento en tres
      tramos (+100, -125, +110), 7 lanceros (2 estrechos), 5 saltadores (2 de
      salto largo), 2 orbes (1 vertical), arqueros, magos y sierras. Control en
      la sección 5.
    - **Nivel 13 OASIS** (15400 px): lago de 32 plataformas casi todas móviles,
      seis islas anchas (arqueros, magos, control, hierbas y dos brutos con
      pila), murciélagos cada 4,5 s, tres orbes, tres sierras suspendidas y
      viento suave (<= 75 px/s).
    - **Nivel 14 CAÑÓN** (16000 px): zigzag de 34 plataformas en cinco alturas
      (de 550 a 150 px), cinco repisas anchas (2 saltadores, 1 bruto con pila,
      control y hierbas), rocas por delante x3, centinela, viento fuerte, 3
      lanceros estrechos, arqueros, magos, 3 orbes y 3 sierras.
    - **Nivel 15 TORMENTA** (17000 px, final del mundo): cuatro tramos con fosos
      (lanceros, babosa, saltadores, orbe, bruto), ruta de 18 plataformas con
      viento, rocas, murciélagos y centinela, y una isla final custodiada por un
      bruto con pila, una babosa de doble salto, un saltador de salto largo y dos
      lanceros. Las alturas de la ruta (548/440/332) coinciden con las de los
      escalones para cumplir la regla de espaciado.
    - Tests: `desert_levels_smoke_test` nuevo (117 comprobaciones de los cuatro
      niveles); actualizados `level_registry`, `level_results`, `level_eleven`,
      `menu_ui` y `platform_spacing`. `level_six_smoke_test` puede fallar de
      forma intermitente si hay otros procesos de Godot en paralelo.
      Suite: 49/49.
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se pida.

57. **Modo de pruebas con todo desbloqueado (2026-11-17)**:
    `SaveGame.DEV_UNLOCK_ALL = true` hace que `is_world_unlocked()` devuelva
    siempre `true` fuera de headless, así el selector de niveles queda abierto
    para buscar errores. Los tests headless siguen validando la regla real de
    pasada seguida. Poner la constante en `false` antes de exportar la versión
    final. Los tests relacionados siguen en verde.

58. **Centinela: proyectiles persistentes y 25 % menos disparos
    (2026-11-17)**: `SkySentry` fija `lifetime = 30 s` en sus proyectiles
    (red de seguridad), de modo que solo desaparecen al chocar con suelo,
    plataforma o jugador; el resto de enemigos conserva sus 3 s. El intervalo
    pasa de 2 s a 2/0.75 ≈ 2,67 s. Tests `sky_sentry` y `level_six` ajustados.

59. **Cuenta regresiva reiniciada al morir (2026-11-17)**: `RunTimer.
    reset_countdown()` devuelve `remaining` al límite completo y
    `TestLevel._respawn_player()` lo llama en cada reaparición. El tiempo real
    (`elapsed`, base de la medalla) sigue acumulándose, así que morir no
    mejora la medalla. Sin vidas o con tiempo agotado se sigue volviendo al
    nivel 1. `checkpoint_smoke_test` actualizado.

60. **Orbe perseguidor con giro limitado (2026-11-18)**: `OrbEnemy` gana
    `turn_speed` (1,8 rad/s ≈ 100°/s) y un rumbo `_heading` que solo rota
    hacia el jugador a esa velocidad (`_steer_toward()`); la velocidad se
    aplica sobre el rumbo, así conserva inercia y se esquiva con cambios
    bruscos de dirección. Con el jugador pegado a él describe órbitas en vez
    de alcanzarlo al instante (radio ≈ velocidad/giro). El orbe de eje
    vertical no cambia. `orb_enemy_smoke_test` ampliado (inercia y giro
    posterior).

61. **Elección al quedarse sin vidas (2026-11-18)**: al acabarse las tres
    vidas `TestLevel` muestra "SIN VIDAS" y, tras 1,2 s, el panel
    `HUD/GameOverChoice` con `RetryLevelButton` ("REINTENTAR NIVEL n") y, si
    el nivel no es el primero de su grupo, `RestartGroupButton` ("EMPEZAR
    «mundo» DESDE EL NIVEL m"). Ambos llaman a `SaveGame.start_at_level()` y
    cargan la escena por `LevelRegistry.scene_path_for()`; el cronómetro se
    detiene mientras se elige. `first_level_of_group()` da el primer nivel del
    mundo. El tiempo agotado conserva el comportamiento anterior (vuelve al
    nivel 1). `survival_smoke_test` actualizado (32 comprobaciones).

62. **Rediseño del HUD por zonas (2026-11-18)**: `scripts/ui/hud_layout.gd`
    (`HudLayout.apply()`, llamado desde `TestLevel._ready()`) divide la
    pantalla (1152x648) en barra superior (46 px), franja inferior (26 px) y
    área central libre. Barra superior: izquierda corazones y vidas, centro
    cuenta regresiva y barra de progreso, derecha `LevelInfo` ("NIVEL n ·
    ambiente", nodo nuevo) y medalla; franja inferior: `PortalHint` a la
    izquierda y `ItemSlots` a la derecha. Textos más pequeños (timer 20,
    medalla 11) sobre paneles oscuros `TopBar`/`BottomBar` con borde de acento.
    Los nodos existentes conservan nombre y ruta. En el área central solo
    quedan mensajes temporales (cartel de nivel, control activado, muerte).
    `MOODS` pasa a constante de clase. Antes `ItemSlots` quedaba fuera de
    pantalla (y=660 con alto 648). Test nuevo `hud_layout_smoke_test` (17).

63. **Eliminados los objetos utilizables del jugador (2026-11-18)**: fuera
    poción, ración, inventario (Tab), espacios rápidos Q/E y el impulso de
    velocidad. Borrados `scripts/player/inventory.gd` y
    `tests/inventory_smoke_test.gd`; `player.gd` pierde `inventory`, `potions`,
    `use_quick_slot`, `use_potion`, `apply_speed_boost`, las señales
    `inventory_changed`/`item_used` y los exports de pociones/raciones. Las
    acciones `item_1`, `item_2` e `inventory` salen del Input Map, de
    `GameSettings` (controles y Opciones), de `GamepadBindings` (LB/RB/Back) y
    de la guía de controles (ahora 9 keycaps). El HUD pierde `ItemSlots` y
    `InventoryPanel`; las instrucciones del menú (sección "HABILIDADES Y
    VIDAS") y el README ya no los mencionan. Se conservan la hierba curativa
    del mundo, el doble salto y la caída rápida (habilidades, no objetos). Los
    ítems históricos 27, 29, 47 y anteriores describen lo que existió.
    Tests actualizados: `gamepad`, `menu`, `no_combat`, `player`, `pause`,
    `hud_layout`.

64. **Señales de ataque y lancero en abanico (2026-11-18)**:
    - **Lancero**: alcance +50 % (`REACH` 180, `REACH_NARROW` 225 px, medidos
      desde el cuerpo) y estocada en abanico de 90° (±45°, `fan_points()`;
      hitbox `CollisionPolygon2D` en `SpearHitbox`). `FanIndicator` dibuja el
      sector en rojo translúcido durante la preparación y en dorado al golpear;
      la lanza es más larga. Ya no se esquiva saltando dentro del abanico: hay
      que quedar por encima de 45°, fuera del alcance o pasar durante la
      recuperación.
    - **Señales por enemigo** (un primer intento con un "!" genérico,
      `AttackTelegraph`, se retiró a petición del usuario y su script y test
      se borraron):
      - **Mago** (`RangedEnemy`): `EnergyCharge` (`scripts/fx/energy_charge.gd`,
        mezcla aditiva) sobre el orbe del bastón: núcleo que crece y chispas que
        convergen, y el `OrbGlow` se agranda; 0,6 s antes del disparo.
      - **Arquero** (`SpreadEnemy`): flecha `NockedArrow` encajada en el arco;
        se retrae `BOW_MAX_PULL` (10 px), la cuerda forma una V y la punta
        brilla; desaparece al disparar. Ganchos virtuales de `RangedEnemy`:
        `_setup_telegraph()`, `_telegraph_update(progress)`,
        `_telegraph_end()`.
      - **Centinela** (`SkySentry`): `SentryRings`
        (`scripts/fx/sentry_rings.gd`, nodo `ChargeRings`): tres círculos que
        parten del mismo radio y se cierran sobre el ojo en 0,4 / 0,8 / 1,2 s
        (rápido, medio, lento); al cerrarse el último (1,2 s) dispara.
      - **Bruto** (`BruteEnemy`): roca `FeetRock` a sus pies (delante) y todo
        el cuerpo tiembla (`shake_amplitude` 3 px, crece con el aviso) los 0,8 s
        previos al lanzamiento.
      - Saltador explosivo y lancero conservan sus avisos propios (compresión y
        parpadeo rojo; postura y abanico). Slug, orbe, voladores y caminantes no
        tienen ataque propio salvo contacto.
    - Tests: `attack_telegraph_smoke_test` reescrito (24) y
      `spearman_enemy_smoke_test` (21).

65. **Caída rápida clavada, sin línea de visión y ataques más lentos
    (2026-11-18)**:
    - **Caída rápida**: tras una caída rápida, mantener S/abajo en el suelo deja
      al jugador clavado (`_fast_fall_planted`, velocidad horizontal 0) hasta
      soltar la tecla.
    - **Sin línea de visión**: `RangedEnemy` (mago y arquero) ya no comprueba
      `LineOfSight`; dispara (con su aviso) siempre que el jugador esté en su
      alcance, aunque haya una pared en medio.
    - **Frecuencia al 50 %**: mago/arquero 3,4 s (nivel 1: 3,0 s), bruto 4,4 s,
      saltador explosivo 5 s (largo 6 s), centinela 5,33 s y lancero con
      `attack_cooldown` 1,55 s tras recuperarse.
    - **Lancero**: la estocada dura 0,1 s y es un barrido: la lanza parte hacia
      delante y gira hasta 90° (vertical); el abanico pasa a cubrir de la
      horizontal a la vertical (`SWEEP_ANGLE_DEG`).
    - Tests: `enemy_los_smoke_test` reescrito (la pared no bloquea),
      `spearman_enemy_smoke_test` 23, `sky_sentry`/`level_six` ajustados.
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se pida.

66. **Correr por defecto, impulso, orbe vertical y pantalla de muerte
    (2026-11-18)**:
    - **Correr por defecto**: se corre siempre (`run_speed`); la acción `run`
      desaparece y su sitio lo ocupa `dash` (Ctrl; mando X; rebindable en
      Opciones como "Impulso").
    - **Impulso** (`Player._handle_dash_input()/_run_dash()`, `PlayerStats`
      `dash_speed` 1140, `dash_time` 0,36 (~410 px, el triple del primer ajuste), `dash_cooldown` 0,4): empuje
      horizontal hacia donde mira el jugador, sin gravedad en el aire. En el
      aire consume el doble salto (`_jumps_used = 2`): no se puede usar si ya
      se hizo doble salto, y después no se puede volver a saltar en el aire
      hasta tocar suelo. En el suelo está siempre disponible. Instrucciones,
      guía de controles y README actualizados.
    - **Orbe vertical**: `OrbEnemy` con `axis = VERTICAL` ya no sigue al
      jugador; sube y baja sin parar (`vertical_range` 140, `vertical_speed`
      120) alrededor de su posición inicial y rebota al chocar.
    - **Pantalla de muerte**: `scripts/ui/game_over_screen.gd`
      (`GameOverScreen`, nodo `HUD/GameOverChoice`). Al perder las tres vidas
      (0,6 s tras "SIN VIDAS") la pantalla se desvanece a negro en 1 s, aparece
      un resplandor rojizo y un panel con tres corazones vacíos, título, resumen
      (nivel, tiempo, muertes) y botones: REINTENTAR NIVEL, EMPEZAR «mundo»
      DESDE EL NIVEL m (si el nivel no abre su grupo), VOLVER AL NIVEL 1 (si el
      nivel no es el 1 ni el grupo empieza en él), VOLVER AL MENÚ PRINCIPAL y
      CERRAR JUEGO.
    - Tests: `player_smoke_test` 34 (dash), `orb_enemy` 19, `gamepad` 15,
      `survival` 41 (fundido, botones). Suite: 50/50.
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se pida.

67. **Muros laterales, reinicio al morir, estela y automatización
    (2026-11-18)**:
    - **Muros invisibles**: `TestLevel._add_boundary_walls()` crea
      `BoundaryWalls/LeftWall|RightWall` en los límites de la cámara; ya no se
      puede salir por la izquierda del inicio y morir fuera de pantalla.
    - **Reinicio al morir**: `TestLevel._reset_hazards()` elimina proyectiles
      (grupo `enemy_projectiles`), peñascos, ondas, rocas y avisos; los
      murciélagos desaparecen y todos los `TrainingDummy` vuelven a su
      posición local inicial (`reset_to_start()`, anotada con
      `_record_start` al final del frame) con su máquina de estados
      reiniciada (`_reset_state()` por enemigo); `SkySentry.reset()`.
    - **Estela del impulso**: copias translúcidas del sprite (`DashAfterimage`,
      grupo `dash_afterimages`) que se desvanecen en 0,28 s.
    - **Automatización**: `tools/run_tests.ps1` ejecuta la suite en paralelo
      (`-Jobs 3`) con resumen y exit code; `all_levels_smoke_test` recorre solo
      todos los niveles de `LevelRegistry.implemented_levels()`. No se añadió
      GUT/GdUnit: el patrón de smoke tests propio cubre lo necesario y la regla
      del proyecto evita dependencias externas.
    - Tests: `death_reset_smoke_test` (9) y `all_levels_smoke_test` (105)
      nuevos. Suite: 52/52.
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se pida.

68. **Medallas calibradas por nivel (2026-11-18)**: `MedalRules.
    thresholds_for_route(distancia, run_speed, límite)` calcula los umbrales a
    partir de la longitud real del recorrido (distancia al portal / velocidad
    de correr = tiempo "par"): oro = par x 1,35, plata = par x 1,7 (máx.
    límite-3 s, y siempre >= 3 s por encima del oro) y bronce = límite del
    nivel (70 s). `TestLevel._calibrate_medals()` los aplica al arrancar, así
    los niveles largos (1 y 7: oro 54 s) ya no comparten el listón de los
    cortos (nivel 3: oro 29,5 s). Los valores fijos 35/50/70 de
    `LevelRegistry` solo quedan como valores por defecto de niveles sin crear.
    `player_smoke_test` pasa a teletransportar al jugador a terreno abierto
    antes de la prueba de dirección (el impulso triple podía llegar al portal
    y congelarlo: era un fallo intermitente del test, no del juego).
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se pida.

69. **Fase 4: obstáculos con ciclo y zonas con efecto (2026-11-18)**:
    - **`Hazard`** (`scripts/world/hazard.gd`, Node2D): máquina de estados
      común IDLE -> WARNING -> ACTIVE -> COOLDOWN con `warning_time`,
      `active_time`, `cooldown_time`, `initial_delay` y `auto_cycle`;
      `tick()` público, `trigger()`, `reset()` y ganchos `_on_state_entered`,
      `_on_active_tick`, `_on_reset`. Grupo `hazards`.
    - **`SteamVent`** (respiradero): aviso de 1 s (boca naranja que tiembla y
      vapor tenue), chorro de 1,2 s que quita un golpe si el jugador está en la
      columna de 170 px, enfriamiento de 2 s.
    - **`CrumblingPlatform`** (plataforma que se derrumba): sin ciclo
      automático; al pisarla tiembla y se agrieta 0,6 s, cae y desaparece
      2,5 s y reaparece con fundido. La colisión se desactiva con
      `set_deferred`, por eso tras `reset()` hay que esperar un frame para
      leer `is_solid()`.
    - **`GimmickZone`** (`gimmick_zone.gd`, Area2D) detecta al jugador
      (`player_inside`, señales `player_entered/exited`, grupo
      `gimmick_zones`) y **`DarkZone`** la usa para oscurecer la pantalla
      dejando un círculo de luz alrededor del jugador (capa 5, bajo el HUD,
      textura radial 12x el radio de luz, fundido de 0,5 s).
    - `TestLevel._reset_hazards()` reinicia todos los `hazards` y
      `gimmick_zones` al morir.
    - Test: `hazard_smoke_test` (32 comprobaciones: máquina de estados,
      vapor, derrumbe, oscuridad y reinicio por muerte).
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se pida.

70. **Mundo 4 "CAVERNAS Y MINAS", niveles 16-20 (2026-11-18)**: ya hay 20
    niveles jugables de 70 s. Cadena 15 -> 16 -> ... -> 20 -> pantalla final;
    `LevelRegistry` con GRUTA, MINA, CRISTALES, GALERÍA y DERRUMBE; música
    propia por nivel (índices 13-17 en `Sfx._build_music`). Superar el mundo 4
    (pasada seguida) exige los cinco niveles 16-20.
    - **`scripts/levels/cave_kit.gd` (`CaveKit`)**: fondo de cueva (degradado,
      estalagmitas con parallax, techo con estalactitas, cristales) y
      envoltorios de `CrumblingPlatform`/`SteamVent`/`DarkZone`; el suelo, las
      plataformas, los enemigos, las rocas, los murciélagos y el centinela
      reutilizan `DesertKit`.
    - **Nivel 16 GRUTA** (15000 px): diez tramos separados por fosos de 300 px
      con una plataforma que se derrumba en cada uno; lanceros, arqueros,
      babosas, orbes y dos magos. Control en la sección 4.
    - **Nivel 17 MINA** (15000 px): 18 respiraderos desfasados (0 y 1,6 s),
      puentes móviles, rocas que caen y arqueros/magos/lanceros.
    - **Nivel 18 CRISTALES** (15000 px): dos tramos a oscuras (secciones 1-3 y
      5-7; el control queda iluminado), puentes circulares, murciélagos,
      babosas, orbes, saltadores y dos respiraderos.
    - **Nivel 19 GALERÍA** (16000 px): ascensión de 28 plataformas (paso 480,
      mezcla fijas/vaivén/circulares/pinchos/derrumbe, sierras), cuatro
      cornisas con arqueros, magos, respiraderos, control y hierbas, tramo
      oscuro central, centinela y murciélagos.
    - **Nivel 20 DERRUMBE** (16000 px): cinco cadenas de seis plataformas que se
      derrumban (paso 280, periodo 2500 px) y cuatro islas (arquero + vapor,
      control + hierba, mago + bruto, saltador + babosa), rocas x3,
      murciélagos, centinela, último tramo a oscuras e isla final con bruto,
      babosa de doble salto y dos lanceros.
    - Tests: `cave_levels_smoke_test` (84) nuevo; actualizados
      `level_registry` (20 implementados), `level_results` (4-5 es el final),
      `menu_ui`, `desert_levels` (el 15 encadena al 16) y `platform_spacing`
      (incluye 16-20). `all_levels_smoke_test` recorre ya 20 niveles.
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se pida.

71. **Impulso más corto, sin doble salto y que atraviesa enemigos
    (2026-11-18)**: `dash_time` pasa de 0,36 a 0,18 s (~205 px, la mitad). El
    impulso ya NO consume el doble salto: se puede usar en el aire sin gastar
    `_jumps_used` (solo manda su enfriamiento de 0,4 s). Mientras dura
    (`Player.is_dashing()`) el jugador no recibe daño de enemigos
    (`TrainingDummy`), proyectiles (`EnemyProjectile`), peñascos
    (`ThrownBoulder`) ni ondas (`ShockWave`) y los atraviesa: los proyectiles y
    peñascos no se detienen al cruzarlo. Las trampas (pinchos, sierras,
    vapor, rocas que caen) y los pozos siguen dañando. Instrucciones, guía de
    controles ("Impulso (atraviesa enemigos)") y README actualizados. Tests:
    `dash_pass_smoke_test` nuevo (7) y `player_smoke_test` ajustado (teletransporta
    al jugador a terreno abierto: el portal podía congelarlo).
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se pida.

72. **Sin enemigos sobre las rocas del bruto (2026-11-18)**: en el nivel 13 el
    mago de la isla 27 nacía encima de la pila de rocas del bruto; ahora esa
    isla solo lleva al bruto (el nivel conserva un único mago). Test nuevo
    `pile_overlap_smoke_test` recorre todos los niveles y falla si algún
    enemigo (salvo el propio bruto) queda sobre una `RockPile`.

73. **Nivel 21 "LABERINTO" (2026-11-18)**: primer nivel que no es una franja
    lateral; ocupa el hueco 5-1 y cierra la cadena (20 -> 21 -> pantalla final).
    - **Estructura** (`level_twentyone_layout.gd`): edificio de 5 pisos
      (3600 x 1760 px) con la cámara siguiendo también en vertical
      (`HorizontalCamera.follow_y`, límites top/bottom). Dos torres separadas
      por un muro: se sube por la izquierda (en cada piso un pozo de 420 px
      en la losa con tres repisas, lejana-cercana-lejana, de 84 px de altura),
      se cruza por el piso superior (continuo) y se baja por la derecha
      cayendo por huecos a un solo piso de altura. Camino único (no hay que
      buscar la salida) de ~17000 px que serpentea entre muros.
    - **Obstáculos**: en cada corredor, tres muros alternos: bajos de 96 px
      (hay que saltarlos) y colgantes de 150 px desde el techo (se pasa por
      debajo, holgura 138 px).
    - **Sin pozos mortales, sin voladores, sin centinela ni rocas**; solo 10
      enemigos terrestres (lanceros, arqueros, babosas y un mago), un control en
      el piso superior y dos hierbas.
    - **Ruta**: `TestLevel.set_route()`/`route_progress()`: la barra de
      progreso y los umbrales de medalla usan la longitud de la ruta (no la
      distancia en x) cuando el nivel la registra.
    - **Tests**: `maze_level_smoke_test` (20): estructura, ruta, holguras y un
      robot que sigue la ruta con la física real y llega a la salida en ~52 s
      (< 70 s). El nivel 21 queda fuera de `platform_spacing` (la regla compara
      todos los pares y en un edificio de pisos hay pares que nunca se tocan).
      Actualizados `level_registry` (21 implementados), `level_results` (5-1 es
      el final), `menu_ui`, `cave_levels` (el 20 encadena al 21). Música propia
      (índice 18 en `Sfx._build_music`).
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se pida.

74. **Pulido, limpieza y ajustes de enemigos (2026-11-18)**:
    - **Babosa**: descansa 0,6-1,2 s entre saltos (antes 1,3-2,4 s).
    - **Saltador explosivo**: onda de 260 px de radio (340 el de salto largo;
      antes 150/190), detecta desde 520 px, salta hasta 470/640 px y apunta a
      donde estará el jugador al aterrizar (posición + velocidad x tiempo de
      vuelo x 0,85), para explotar lo más cerca posible.
    - **Unidad de referencia**: `GameUnits` (`scripts/core/game_units.gd`) define
      la unidad **J = 48 px** (altura del jugador; ancho 30 px) con conversiones
      y una tabla en el README (muro del laberinto 2 J, salto 2,6 J, impulso
      4,3 J, pantalla 24 J, correr 11 J/s). Todo el juego mide en píxeles.
    - **Gráficos** (guías de game feel de Godot 4): `ScreenFx`
      (`scripts/fx/screen_fx.gd`) añade una viñeta radial suave (capa 8, bajo
      el HUD) a todos los niveles y un hit-stop de 0,07 s (tiempo al 6 %,
      temporizador que ignora la escala de tiempo) al recibir daño; en headless no
      hace nada para no alterar los tests. Ya existían squash & stretch,
      polvo, estelas del impulso y sacudida de cámara.
    - **Código en desuso eliminado**: todo el sistema de ataque del jugador
      (`scripts/player/attacks/`, `basic_attack.tres`, nodo `AttackHitbox`, nodo
      `Slash`, animación y textura `attack`, `_handle_attack`, `add_weapon_range`,
      señales y variables de ataque) y funciones sin uso (`implemented_count`,
      `medal_count`, `total_best_time`, `use_fire_style`, `MovingPlatform.
      teleport_to`). Un análisis automático no encontró scripts, escenas, recursos
      ni imágenes sin referencias.
    - **Rendimiento**: medido en headless, el coste de física en régimen estable
      es de 1-2,5 ms por fotograma en todos los niveles (los niveles 1 y 7, con
      ~4800 nodos y 43 enemigos, son los más pesados); el único pico es la carga
      inicial de escenas (~1 s la primera vez). Se apagan `_process` de las
      plataformas que se derrumban, los respiraderos y las zonas oscuras cuando
      no están animándose.
    - Tests nuevos: `units_smoke_test` (9) y `screen_fx_smoke_test` (7);
      actualizados `blast_jumper` (onda de 260) y `no_combat` (sin nodos de
      ataque).
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se pida.

75. **Impulso intangible y bruto (2026-11-19)**: el impulso ya no se atascaba
    con los enemigos porque la capa de enemigos (4) está en la máscara del
    jugador (5): solo evitaba el daño. Ahora `TrainingDummy` (y por herencia
    todos los enemigos) tiene `intangible_during_dash = true` y `Player`
    añade/quita excepciones de colisión con ellos mientras `is_intangible()`
    (impulso + 0,15 s de margen, `DASH_GRACE_TIME`, para no quedar pegado a un
    enemigo y recibir daño al terminar). El margen también ignora el daño de
    enemigos y proyectiles. Las excepciones se refrescan cada fotograma, así
    incluyen a los enemigos que aparecen durante el impulso.
    - **Bruto**: sus peñascos (`ThrownBoulder`) ya no se rompen contra su pila
      de rocas (`RockPile`); lanza un 25 % más a menudo (`throw_interval`
      4,4 -> 3,52 s).
    - Tests: `dash_pass_smoke_test` 12 (el enemigo sólido bloquea sin impulso y
      se atraviesa con él; excepciones retiradas al terminar) y
      `brute_enemy_smoke_test` (peñasco sobre la pila y frecuencia).
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se pida.

76. **Niveles siempre como "zona-nivel" (2026-11-20)**: todo el juego nombra
    los niveles con su código `LevelConfig.code()` (p. ej. 3-4), igual que la
    selección de niveles, y la palabra "mundo" pasa a "zona" en los textos del
    jugador. `TestLevel._ready()` fija `level_name = "NIVEL zona-nivel"` desde
    el registro (HUD, cartel de inicio, mensaje de completado); las escenas
    `level_*.tscn` también lo llevan. Menú principal: "NIVEL 3-4 · ZONA 3 DE 8"
    y "CONTINUAR · NIVEL 3-4". Pantalla de muerte (`GameOverScreen.build(
    level_code, level_name, world_number, index_in_world, time_text, deaths)`):
    subtítulo "...en el nivel 3-4", REINTENTAR NIVEL 3-4, VOLVER A EMPEZAR
    ZONA 3 (si el nivel no es el primero de su zona) y VOLVER A ZONA 1 (si no
    se está en la zona 1). Resultados: "¡ZONA n SUPERADA!" y "PASADA DE LA ZONA".
    Tests ajustados (`survival`, `menu`, `exit`, `world_unlock`, `level_*`).
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se pida.

77. **Impulso 25 % más corto e invulnerabilidad de 0,2 s (2026-11-20)**:
    `dash_time` 0,18 -> 0,135 s (~154 px, 3,2 J) y
    `PlayerStats.invulnerability_time` 1,0 -> 0,2 s (el margen de
    invulnerabilidad tras recibir un golpe; sustituye al valor del ítem 39). El margen de
    intangibilidad del impulso (`DASH_GRACE_TIME` 0,15 s) no cambia. Tests
    `dash_pass`, `units` ajustados. `level_six_smoke_test` puede fallar de forma
    intermitente con la suite en paralelo (pasa solo).
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se pida.

78. **Corrección del horneado y trampas del jugador (2026-11-21/23)**:
    - El baker guardaba como nodos fijos los pinchos de borde que cada
      `Platform` crea sola (`SpikeLeft2`/`SpikeRight2`): quedaban activos e
      invisibles y dañaban al pisar. Limpiados en los niveles 8 y 21
      (copias en el scratchpad) y `LevelBaker._own_children` ya no los guarda.
    - **Trampas nuevas** (`scripts/world/`, escenas en `scenes/world/`):
      `ProximityMine` (Hazard: detecta, avisa 1 s, explota por radio),
      `TeleportTrap` (al inicio del nivel, meta `start_point` de `TestLevel`),
      `LaunchPad` (impulso hacia atrás o dirección fija, sin daño) y `BladeWheel`
      (cuatro cuchillas a 90°, `clockwise` editable). `Player.launch()` y
      `Player.teleport_to()`. El nivel 21 lleva 14 minas, 13 lanzadores junto
      a los muros bajos, 4 en repisas, 3 teletransportes y 3 ruedas.
    - `PlayerStats.invulnerability_time` 0,2 -> 0,5 s.
    - Tests: `new_traps_smoke_test` (18); `maze_level_smoke_test` (31).
    NOTA: falta el muro bajo de x=495 del piso 0 del nivel 21 en la escena
    (ya faltaba antes). Los niveles 8 (`level_eight`: 30 enemigos y 5 arqueros)
    y su espaciado ya fallaban antes de estos cambios.

79. **Diseño de niveles 22-40 y mundo 5 (2026-11-23)**: documento
    `DISENO_NIVELES.md` (principios, mecánicas, estructuras, cambios de reglas
    y ficha de los 19 niveles). El mundo 5 pasa a llamarse "TORRES Y ALTURAS".
    - **Mecánicas nuevas**: `UpdraftZone` (corriente ascendente; escribe
      `Player.updraft_speed/accel`, se aplica al final de la física para
      levantar también desde el suelo), `TimedPlatform` (Hazard con ciclo
      sólido-aviso-hueco), cinta transportadora (`Platform.conveyor_speed`),
      `LeverSwitch` + `SwitchGate` (palancas por canal), `CrusherTrap` (prensa
      no sólida con aviso) y `LevelRules.low_gravity()` (copia de stats).
      `Player.launch()` ya no pierde la velocidad vertical al salir del suelo.
    - **Kit**: `scripts/levels/tower_kit.gd` (cielo, losas con huecos, atajos).
    - **Niveles** (generador + escena horneada + registro + test): 22 CAMPANARIO
      (torre con corrientes), 23 PUENTES (bifurcación: escalera temporizada o
      cintas), 24 NUBES (baja gravedad, trampolín a una ruta alta), 25 CIUDADELA
      (hub con tres palancas y compuerta, no lineal). 21 -> 22 -> ... -> 25 ->
      pantalla final. Música distinta hasta el nivel 40 (`sfx.gd`).
    - Tests: `world5_mechanics_smoke_test` (27) y `world5_levels_smoke_test` (46).
    NOTA: no jugados a mano; los robots de los tests comprueban estructura y
    pasos clave (corriente, trampolín, palancas), no el nivel completo.

80. **Ajustes a los niveles 22 y 24, rocas y centinela aspirador (2026-11-23)**:
    - **Rocas que caen** (`FallingRock`, afecta a todos los niveles con
      `RockfallSpawner`): cuelgan visibles en el borde superior de la pantalla
      con clavos de hierro, grietas de magma y llamas (no parecen una
      plataforma); caen **0,2 s después de que el jugador se coloque debajo**
      (`TRIGGER_DELAY`, `TRIGGER_HALF_WIDTH` 70 px); si nadie se coloca debajo
      caen solas a los 3,5 s (`MAX_WAIT`). Se eliminó `WARNING_TIME`.
      `rockfall_smoke_test` reescrito (27).
    - **Nivel 22 CAMPANARIO**: cada corriente sube hasta la cara inferior de
      la losa del piso siguiente (`LevelTwentytwoLayout.draft_top`), que sigue
      sólida; más enemigos (10), 4 sierras de suelo y 3 techos con espinas
      (`TowerKit.spike_ceiling`: viga colgada con pinchos hacia abajo).
    - **Nivel 24 NUBES**: regla de densidad (cada isla y nube lleva al menos un
      obstáculo o enemigo), un mago en cada nube alta (nivel superior) y el
      centinela aspirador.
    - **`VacuumSentry`** (`scripts/enemies/vacuum_sentry.gd`, sin escena): versión
      azul del centinela del cielo, abajo a la izquierda de la pantalla; dispara
      un cono de 5 proyectiles y cada 12 s aspira 3,4 s objetos decorativos
      (silla, mesa, vaca, coche, espada, persona) que vuelan hacia su boca. No
      dañan. `SentryRings.palette` permite otros colores de carga.
    - Tests: `world5_mechanics_smoke_test` (36) y `world5_levels_smoke_test` (56).

81. **Segundo ajuste de niveles 22 y 25 y del centinela aspirador (2026-11-23)**:
    - **`VacuumSentry`**: los objetos aspirados ahora nacen por el **borde
      derecho de la pantalla** y cruzan hacia la boca; si tocan al jugador le
      hacen daño (`object_damage`, una vez por objeto; el impulso los atraviesa).
    - **Nivel 25**: la compuerta (`GATE_SIZE` 48x900) es un muro altísimo, no se
      puede saltar.
    - **Nivel 22 CAMPANARIO**: pisos más anchos (`WIDTH` 2200) y techo más bajo
      (`FLOOR_PITCH` 420); se eliminaron las vigas y cadenas de los techos con
      espinas (`TowerKit.spike_ceiling` ahora pega los pinchos a la losa de
      arriba, junto a la salida de cada corriente); balcones lejos de las
      aberturas; 14 enemigos (5 magos), 9 sierras y 11 prensas.
    - Tests actualizados: `world5_levels_smoke_test` y `world5_mechanics_smoke_test`.

82. **Cintas transportadoras animadas y nivel 21 (2026-11-24)**:
    - **`ConveyorVisual`** (`scripts/world/conveyor_visual.gd`): banda de goma con
      rodillos y tacos en chevron, animada con 3 fotogramas distintos; el
      sentido sigue el signo de `conveyor_speed`. `Platform` la crea (nodo
      `ConveyorBelt`) y sustituye a las flechas; el rango de `conveyor_speed`
      pasa a ±800.
    - **Velocidad +100 %**: cintas de los niveles 23 y 25 (y sus escenas)
      duplicadas (160/240 -> 320/480, 180 -> 360).
    - **Nivel 21**: los lanzadores de impulso hacia atrás se sustituyen por
      cintas de 320 px/s que empujan hacia atrás: trozos de losa a ras de suelo
      junto a cada muro bajo (`LevelTwentyoneLayout.hurdle_belts()`) y la repisa
      2 de cada subida. El nivel 24 conserva su trampolín (impulso vertical).
    - **Bug**: faltaba en la escena el muro bajo `MazeHurdle0A0` (x=495); añadido.
    - TRAMPA: `bake_levels.gd -- 21` generó un nivel equivocado (la escena
      generada no ejecutó su layout); las escenas 21/23/25 se editaron a mano.
    - Tests: `maze_level` 33 y `world5_mechanics` 40 (animación de 3 fotogramas
      y sentido). Suite 62: solo fallan los dos tests del nivel 8 de siempre.
    NOTA: el exe de `dist/` NO incluye este cambio; re-exportar cuando se pida.

## 5. En progreso / estado actual

- Suite de 52 smoke tests en verde (verificado en esta sesión) tras aplicar
  los ítems 28-48: modo plataformas lineal con un único checkpoint a mitad de
  cada nivel, tres vidas por nivel, cronómetro contrarreloj que sigue corriendo
  al morir y no regala tiempo, medallas guardadas por nivel, selector de 40
  niveles en 8 mundos con 32 plazas pendientes, resultados por nivel, inventario
  real con poción/ración y espacios Q/E, selección directa
  de nivel, soporte de mando, guardado de nivel/tiempo/muertes, pantalla de
  juego completado, fundidos de imagen y música, aviso de descanso en
  controles, trampas legibles, menú de pausa completo con guía y
  configuración, contornos negros en formas geométricas básicas, agentes
  opencode por área, murciélagos que desaparecen al salir del borde visible,
  tres golpes de vida e invulnerabilidad de 1 s.
  Las plataformas de todos los niveles llevan una textura procedural sutil
  (vetas y motas) que se adapta a su tamaño y color.
  El nivel 4 tiene las 17 plataformas de la ruta activas a la vez (sin
  reciclado ni desapariciones), con enemigos a bordo, el control central
  despejado y el inicio sin enemigos en la mitad izquierda. Sus trayectorias
  no se solapan y ninguna plataforma se inclina más de 30°.
  Los niveles 5 y 6 usan el asset modular de plataformas: el 5 es un cielo
  de 28 plataformas con voladores cada 3 s (recorrido ondulante duplicado),
  cuatro sierras suspendidas y sin aves decorativas; el 6 es una fortaleza
  de 20 plataformas con pinchos, diez sierras (cinco de suelo y cinco
  suspendidas), giros, la criatura gigante de fondo y un centinela en la
  esquina superior derecha que dispara 5 proyectiles cada 2 s. Los pozos de
  ambos niveles están cubiertos por una única FallZone a todo el ancho.
  El mago lanza orbes de energía azules con estela y sonido propios; el
  arquero y el centinela tienen efectos de sonido distintos. El ataque del
  centinela del nivel 6 es rojo (orbe, estela y estallido). La cadena
  termina en la pantalla final. Los ocho niveles tienen un límite de 70 s.
  El nivel 7 es un reflejo vertical del nivel 1 con gravedad invertida;
  todos sus enemigos usan los tipos conocidos con sombrero triangular
  amarillo y ojos almendrados. El nivel 8 reutiliza el nivel 2 como espejo
  horizontal con controles invertidos y recorrido de derecha a izquierda.
  El ejecutable de `dist/` incluye los ítems 18-46, todavía no del 47 en adelante.
- Suite de 59 smoke tests en verde tras los ítems 49-70: 20 niveles jugables
  en 4 mundos (praderas, ruinas, desierto, cavernas), medallas calibradas por
  longitud de recorrido y la base de obstáculos `Hazard`/`GimmickZone`
  (plataformas que se derrumban, respiraderos, zonas oscuras).
  `SaveGame.DEV_UNLOCK_ALL` sigue en `true` (modo de pruebas): ponerlo en
  `false` antes de exportar la versión final.

## 6. Próximos pasos (roadmap contrarreloj acordado, en orden de prioridad)

1. **Fase 3 — Registro de niveles (hecha)**: `LevelConfig`/`WorldConfig`/
   `LevelRegistry`, selector de 40 niveles con medallas y mejores tiempos,
   resultados y umbrales de medalla por longitud de recorrido (ítem 68).
2. **Fase 4 — Obstáculos/gimmicks (primera tanda hecha, ítem 69)**: `Hazard`
   y `GimmickZone` con tres implementaciones. Pendiente para los mundos 5-8:
   hielo resbaladizo, viento vertical, plataformas con temporizador,
   interruptores y zonas de gravedad (cada una con aviso, reset y test).
3. **Fase 5 — Enemigos por familias**: configuración común y lotes terrestres,
   aéreos y especiales, sin introducir combate para el jugador.
4. **Fase 6 — Producción de mundos**: mundos 1-4 completos (20 niveles) y el
   mundo 5 (niveles 21-25, ver ítem 79). Siguiente: mundos 6-8 según
   `DISENO_NIVELES.md` (cañón de pared, catapulta, puente levadizo, zonas de
   gravedad, láseres, portales, lava...). Siguiente: niveles 22-25 de "CIELO Y
   ALTURAS" (el laberinto no encaja con el tema: renombrar el mundo 5 o mover
   el laberinto), con 1-2 mecánicas nuevas de la Fase 4 y la misma
   calibración de tiempo y suite en verde.
5. **Fase 7 — Polish y exportación**: `DEV_UNLOCK_ALL = false`, créditos
   ampliados, resultados finales, optimización y nuevo ejecutable en `dist/`
   (hoy desactualizado desde el ítem 46).

## 7. Convenciones y reglas para agentes

- Idioma: código y comentarios en inglés; **comentarios de documentación en
  español** (docstrings `##` al inicio de cada archivo explicando su rol).
- Cada archivo GDScript importante lleva un comentario de cabecera con su
  propósito; los cambios relevantes se anotan con fecha corta y motivo.
- Comentarios solo donde aportan (algoritmos, decisiones, trampas conocidas).
- Tests: smoke tests headless en `tests/`, uno por sistema, patrón
  `_check(condición, mensaje)` + `_wait_physics(frames)`. Al añadir
  funcionalidad, añadir/actualizar su test.
- **Antes de terminar cualquier cambio**: correr la suite completa (sección 2)
  y actualizar las secciones 4-6 de este archivo.
- **Punto de rollback por cada cambio**: antes de empezar un cambio, el
  árbol debe estar limpio y `HEAD` marcado con un tag
  `rollback/AAAA-MM-DD-NN-descripcion-corta` (`git tag <nombre>`); al terminar
  y pasar la suite, se hace commit y se marca también ese commit con su tag.
  Cada cambio queda así reversible con `git reset --hard <tag>` (o
  `git revert`). Los tags se suben con el push (`git push --tags`). Nunca
  borrar ni mover tags de rollback existentes.
- No usar librerías externas; el motor y GDScript puro bastan.
- Nombres de nodos en las escenas base (`Player`, `ExitPortal`, `Camera`,
  `HUD/...`) son contratos usados por scripts y tests: no renombrar sin
  actualizar todo lo que referencian.
- `scenes/levels/test_level.tscn` es compartida: sus nodos sueltos son
  contenido del NIVEL 1 y las variantes 2/3 los liberan por nombre (ver
  `_prepare_level_two/three` en `test_level.gd`); el contenido nuevo de
  esas variantes se genera por código en sus layouts.
- **Subagentes opencode** (`.opencode/agent/*.md`): `player-survival`
  (jugador, vidas, daño, respawn, cámara), `levels-world` (layouts,
  plataformas, checkpoints, portal), `enemies-hazards` (IA, proyectiles,
  trampas), `ui-flow` (menús, HUD, pausa, pantalla final), `audio-fx` (música
  y partículas), `core-save` (guardado y configuración) y `testing` (smoke
  tests). Todos deben leer este archivo y correr la suite completa.
