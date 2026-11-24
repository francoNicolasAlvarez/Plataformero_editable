# Editar los niveles a mano en Godot

Este proyecto es una copia de *Juego* en la que **cada nivel es una escena
normal (`.tscn`)** con todos los objetos ya colocados. Se editan arrastrando
nodos en el editor de Godot, sin tocar código. Aun así, todo el código sigue
ahí: puedes cambiar variables, estadísticas, colores y efectos desde los
scripts o desde el Inspector cuando lo necesites.

## Abrir y editar un nivel

1. Abre el proyecto con Godot 4.7 (`project.godot`).
2. En el panel *Sistema de archivos* abre `scenes/levels/level_XX.tscn`
   (por ejemplo `level_twelve.tscn` = nivel 3-2). Los nombres siguen a los de
   `LevelRegistry`: one, two, three... twenty, twentyone.
3. Selecciona, mueve, copia (`Ctrl+D`) o borra nodos como en cualquier escena 2D.
4. Guarda (`Ctrl+S`) y pulsa **F6** (ejecutar escena actual) para probar el
   nivel. Para jugar la cadena completa, ejecuta `scenes/ui/main_menu.tscn`.

### Qué es cada cosa dentro de un nivel

| Nodo | Qué es |
| --- | --- |
| `Player` | El jugador (su posición es el punto de inicio). |
| `ExitPortal` | La salida. |
| `Camera` | La cámara. En el Inspector: `Limit Left/Right/Top/Bottom` y `Follow Y`. |
| `Level…Generated` | Contenedor con el mundo: suelos, plataformas, enemigos, trampas, decorado. |
| `HUD` | Interfaz del nivel (compartida: `scenes/ui/level_hud.tscn`). |
| Raíz del nivel | Script `test_level.gd`: tiempo límite, medallas (`Gold/Silver/Bronze Medal Time`), nombre y siguiente nivel. |

### Añadir objetos nuevos

Arrastra la escena que quieras desde el panel de archivos al nivel:

- Plataformas: `scenes/world/platform.tscn`. En el Inspector cambia `Platform Size`,
  `Platform Color` y `Kind` (fija, vaivén, circular, pinchos, giratoria). Se ve el
  tamaño real en el editor.
- Enemigos: `scenes/enemies/*.tscn` (ranged = mago, spread = arquero, spearman,
  slug, orb, brute…). Sus opciones (`Narrow`, `Long Jump`, `Double Jump`…) están
  en el Inspector.
- Trampas: `scenes/world/spike_trap.tscn`, `saw_trap.tscn`, `fall_zone.tscn`
  (`Zone Size` = tamaño de la zona de caída mortal).
  Más trampas: `proximity_mine.tscn` (mina: `Detect Radius`, `Blast Radius`),
  `teleport_trap.tscn` (al inicio del nivel o a `Custom Target`), `launch_pad.tscn`
  (`Mode`: hacia atrás o dirección fija; sirve de trampolín) y `blade_wheel.tscn`
  (`Clockwise` cambia el sentido de giro, `Spin Speed`, `Arm Length`).
  Mundo 5: `UpdraftZone`, `TimedPlatform`, `CrusherTrap`, `LeverSwitch` y
  `SwitchGate` (mismo `Channel`) se crean por código (ver niveles 22-25); la
  cinta transportadora es `Conveyor Speed` en `platform.tscn`.
- Control (bandera): `scenes/world/checkpoint.tscn`.
- Hierba curativa: `scenes/pickups/healing_herb.tscn`.
- Decorado: `scenes/decor/*.tscn`.

> Los enemigos, las trampas con ciclo (respiraderos, plataformas que se
> derrumban) y los dibujos que se construyen por código **no se ven completos en
> el editor** (aparecen como su forma de colisión o vacíos); sí se ven al ejecutar
> el nivel. Los nombres de nodo dicen qué son.

### Unidades

Todo se mide en píxeles; la altura del jugador son 48 px (ver `README.md`,
sección *Unidad de medida*). Para colocar un salto: el jugador salta ~125 px de
alto y ~300 px de largo.

## Cómo está montado (para quien quiera meterse en el código)

- `scripts/levels/test_level.gd` controla el nivel. Si la raíz tiene
  `Baked = true` (todas las escenas de `scenes/levels/`), **no** se ejecuta el
  generador y se usa lo que hay en la escena.
- Los niveles originales, que se generan por código (`scripts/levels/*_layout.gd`),
  se conservan en `scenes/levels/generated/` con `Baked = false`.
- `tools/bake_levels.gd` convierte esos niveles generados en las escenas editables:

  ```
  godot --headless --path . --import
  godot --headless --path . --script res://tools/bake_levels.gd          # todos
  godot --headless --path . --script res://tools/bake_levels.gd -- 12    # solo el 12
  ```

  **Cuidado:** hornear sobrescribe `scenes/levels/level_*.tscn`. Si editaste a
  mano un nivel, haz copia antes. Es útil cuando cambias un generador (por ejemplo
  `level_twelve_layout.gd`) y quieres regenerar su escena.
- Para crear un nivel nuevo: duplica una escena de `scenes/levels/`, cambia
  `Level Variant`, `Next Level Path` y `Level Name`, y regístralo en
  `scripts/core/level_registry.gd` (`IMPLEMENTED_LEVELS`).

## Cambiar valores sin tocar la escena

- Jugador: `resources/player/player_stats.tres` (velocidad, salto, impulso,
  invulnerabilidad…).
- Enemigos: variables `@export` de cada script (`scripts/enemies/`), visibles en
  el Inspector de cada enemigo.
- Colores y fondos: el decorado de cada nivel son nodos (`Polygon2D`,
  `TextureRect`…) dentro del contenedor del mundo; se recolorean desde el
  Inspector. Los efectos de pantalla están en `scripts/fx/`.
- Medallas y tiempo: raíz del nivel (Inspector).

## Pruebas

La suite de pruebas (`tools/run_tests.ps1`) funciona igual que en el proyecto
original y comprueba los niveles horneados. Si mueves objetos a mano, algunas
pruebas de diseño (espaciado entre plataformas, enemigos sobre rocas, etc.)
pueden avisarte de un problema real: tómalas como una ayuda.
