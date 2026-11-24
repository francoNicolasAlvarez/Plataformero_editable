# Diseño de niveles 22-40 (mundos 5 a 8)

Documento de diseño (2026-11-23). Es la guía para crear los 19 niveles que
faltan. Los niveles 1-21 ya existen. Cada nivel se construye con un generador
(`scripts/levels/level_*_layout.gd`), se hornea a escena editable y lleva su
smoke test (ver `AGENTS.md`, secciones 2 y 7).

## 1. Principios

1. **Una idea nueva por nivel.** Cada nivel introduce *una* mecánica, enemigo,
   trampa o regla; los siguientes la combinan con lo ya aprendido.
2. **Enseñar, probar, combinar.** El primer nivel de un mundo presenta la
   mecánica en un espacio seguro; el segundo la complica; el tercero la mezcla;
   el cuarto la lleva al límite; el quinto es un examen que mezcla todo el mundo.
3. **Variedad de estructura**, no solo de decorado. Cada mundo usa al menos
   tres tipos de estructura distintos (ver sección 3) y al menos dos niveles
   *no lineales*.
4. **Legibilidad.** Toda trampa avisa antes de dañar (parpadeo, temblor,
   sonido) y el aviso dura ≥ 0,5 s. Ninguna trampa mata de un golpe salvo los
   pozos.
5. **Justicia.** Todo se puede esquivar con salto (125 px de alto, ~300 px de
   largo), impulso o carrera. Las holguras de pasillo son ≥ 72 px.
6. **El tiempo es del jugador.** Cada nivel tiene 70 s de límite y medallas por
   longitud de ruta; los niveles no lineales declaran su ruta más corta con
   `set_route()`.
7. **Cada nivel tiene un control (bandera) y mínimo una hierba** a mitad del
   recorrido (regla ya existente). En los no lineales, el control está en el
   centro de la estructura.

## 2. Mecánicas (kit de bloques)

Ya existen: plataformas (fija, vaivén, circular, pinchos, giratoria), sierras,
pinchos, plataformas que se derrumban, respiraderos de vapor, zonas oscuras,
viento horizontal, rocas, murciélagos, centinela, minas, teletransporte,
lanzador, rueda de cuchillas, gravedad invertida, controles espejo.

Nuevas (la columna *Estado* indica si ya está implementada):

| Mecánica | Qué hace | Mundo | Estado |
| --- | --- | --- | --- |
| Corriente ascendente (`UpdraftZone`) | Empuja al jugador hacia arriba mientras está dentro; permite subir sin plataformas. | 5 | hecha |
| Plataforma temporizada (`TimedPlatform`) | Aparece y desaparece en ciclo, con parpadeo de aviso. | 5 | hecha |
| Cinta transportadora (`Platform.conveyor_speed`) | Arrastra al jugador a la velocidad indicada. | 5 | hecha |
| Palanca y compuerta (`LeverSwitch`, `SwitchGate`) | Mundos no lineales: activar palancas abre compuertas. | 5-6 | hecha |
| Prensa (`CrusherTrap`) | Bloque que cae tras un aviso al pasar el jugador por debajo. | 5-6 | hecha |
| Baja gravedad (regla de nivel) | Reduce la gravedad del jugador en todo el nivel. | 5 | hecha |
| Centinela aspirador (`VacuumSentry`) | Centinela azul abajo a la izquierda: dispara conos y aspira objetos decorativos. | 5 | hecha |
| Cañón de pared (`WallTurret`) | Dispara proyectiles horizontales con aviso. | 6 | pendiente |
| Catapulta | Lanza rocas en arco hacia una zona marcada. | 6 | pendiente |
| Puente levadizo | Se baja con una palanca; se levanta tras un tiempo. | 6 | pendiente |
| Zona de gravedad (`GravityZone`) | Invierte la gravedad mientras estás dentro. | 7 | pendiente |
| Rayo láser | Haz con ciclo (aviso, activo, pausa) entre dos emisores. | 7 | pendiente |
| Portales enlazados | Pareja de portales; entrar por uno sale por el otro. | 7 | pendiente |
| Cambio de reglas (sin doble salto, sin impulso, controles invertidos por zonas) | Quita o cambia una habilidad en un tramo. | 7 | pendiente |
| Lava ascendente | Línea de lava que sube y empuja a avanzar. | 8 | pendiente |
| Géiser de lava | Columna con ciclo, parecido al respiradero pero con más alcance. | 8 | pendiente |
| Plataformas que se hunden | Bajan al pisarlas y vuelven si se sale. | 8 | pendiente |

## 3. Tipos de estructura

- **Franja** (lineal horizontal): la mayoría de los niveles 1-20.
- **Torre / ascenso** (vertical): la cámara sigue en vertical; se sube.
- **Laberinto** (nivel 21): corredores serpenteantes en un edificio.
- **Bifurcación** (dos rutas que se separan y se vuelven a unir): una ruta
  corta y arriesgada, otra larga y segura.
- **Hub y radios** (central con varias ramas): se resuelven ramas en cualquier
  orden y se vuelve al hub; palancas abren la salida.
- **Descenso** (caer controlado hacia abajo).
- **Persecución** (algo avanza detrás: lava, derrumbe).
- **Arena** (una sala cerrada con oleadas de peligros y salida que se abre).

## 4. Cambios de reglas entre mapas

Cada mundo cambia al menos una regla de base en un nivel concreto:

| Regla | Nivel | Cómo |
| --- | --- | --- |
| Baja gravedad (55 %) | 24 | Saltos más altos y largos: los huecos se hacen más anchos. |
| Sin impulso (dash) | 30 | El jugador no puede usar Ctrl: tramos más lentos. |
| Un solo golpe de vida por nivel | 33 | Fragilidad: todo daño es letal; trampas con más aviso. |
| Doble salto desactivado | 36 | Se juega solo con salto simple y plataformas más generosas. |
| Controles invertidos por zonas | 37 | Cartel claro al entrar y salir. |
| Sin control intermedio | 40 | Final: una sola pasada larga con más hierbas. |

## 5. Mundos y niveles

Los números son `nivel`/`zona-nivel`. *Estructura* y *No lineal* indican la
topología. Los enemigos nombrados ya existen salvo los marcados (nuevo).

### Mundo 5 — TORRES Y ALTURAS (21-25) · construido en esta tanda

Tema: ciudad en lo alto, torres, puentes, campanarios. Paleta cielo azul
pálido y piedra clara. Mecánicas: corrientes ascendentes, plataformas
temporizadas, cintas, palancas, prensas, baja gravedad.

| N.º | Nombre | Estructura | Idea nueva | Enemigos / trampas | No lineal |
| --- | --- | --- | --- | --- | --- |
| 21 | LABERINTO (hecho) | Laberinto | Cámara vertical, un camino largo. | Lancero, arquero, babosa, mago, minas, lanzadores, ruedas | Sí |
| 22 | CAMPANARIO | Torre | Corrientes ascendentes hasta el techo del piso siguiente (la losa sigue sólida). | Arquero, babosa, mago, lanceros, prensas, sierras, techos con espinas | Sí: balcones laterales con hierbas y atajos |
| 23 | PUENTES | Bifurcación | Plataformas temporizadas y cintas. Ruta alta (temporizadas) o baja (cintas + sierras). | Lancero, mago, sierras | Sí: dos rutas |
| 24 | NUBES | Franja con vertical | Regla: baja gravedad; trampolín a una ruta alta con un mago por nube; todas las plataformas llevan obstáculo o enemigo; centinela aspirador. | Murciélagos, ruedas, minas, magos, arqueros | Parcial: alturas opcionales |
| 25 | CIUDADELA | Hub y radios | Palancas: tres torres, tres palancas, cualquier orden; abren la compuerta del portal. | Mezcla (arquero, mago, bruto, prensas) | Sí |

### Mundo 6 — FORTALEZA MEDIEVAL (26-30)

Tema: castillo, almenas, foso, mazmorra. Mecánicas: cañón de pared, catapulta,
puente levadizo, rastrillos con palanca, prensas. Enemigos nuevos: caballero con
escudo (solo se le puede esquivar), ballestero de torre.

| N.º | Nombre | Estructura | Idea nueva | No lineal |
| --- | --- | --- | --- | --- |
| 26 | FOSO | Franja | Puente levadizo: palanca lo baja, se sube tras 8 s. | No |
| 27 | MURALLAS | Torre + cruce | Cañones de pared en las almenas. | Parcial |
| 28 | MAZMORRA | Laberinto | Rastrillos con palanca; llaves en celdas. | Sí |
| 29 | CATAPULTAS | Franja amplia | Catapultas que marcan la zona de impacto. | No |
| 30 | SALA DEL TRONO | Arena | Oleadas y salida que se abre. | No |

### Mundo 7 — LABORATORIO Y TECNOLOGÍA (31-35)

Tema: laboratorio, cintas, láseres, portales. Mecánicas: zonas de gravedad,
rayos láser, portales enlazados, cintas. Enemigos nuevos: dron patrulla
(vuela en línea recta), robot centinela de suelo.

| N.º | Nombre | Estructura | Idea nueva | No lineal |
| --- | --- | --- | --- | --- |
| 31 | CINTAS | Franja | Cintas en ambos sentidos y sierras. | No |
| 32 | LÁSERES | Franja con salas | Láseres con ciclo y salas de descanso. | No |
| 33 | PORTALES | Hub y radios | Portales enlazados y regla: un solo golpe de vida. | Sí |
| 34 | GRAVEDAD | Descenso/ascenso | Zonas de gravedad invertida. | Sí |
| 35 | NÚCLEO | Arena + bifurcación | Combina láseres, portales y gravedad. | Sí |

### Mundo 8 — VOLCÁN Y FINAL (36-40)

Tema: lava, ceniza, final. Mecánicas: lava ascendente, géiseres, plataformas
que se hunden, persecución. Enemigos nuevos: elemental de fuego (rebota).

| N.º | Nombre | Estructura | Idea nueva | No lineal |
| --- | --- | --- | --- | --- |
| 36 | CENIZA | Franja | Regla: sin doble salto; plataformas que se hunden. | No |
| 37 | GÉISERES | Franja con vertical | Géiseres y controles invertidos por zonas. | Parcial |
| 38 | ASCENSO DE LAVA | Persecución | La lava sube: ruta vertical que no se puede frenar. | No |
| 39 | CRÁTER | Hub y radios | Tres cámaras alrededor del cráter, palancas y lava. | Sí |
| 40 | CORAZÓN DEL VOLCÁN | Persecución + arena | Final: sin control intermedio, lava, géiseres y prensas. | Parcial |

## 6. Orden de construcción

1. (hecho) Kit del mundo 5 y niveles 22-25.
2. Cañón de pared, catapulta, puente levadizo y niveles 26-30.
3. Zona de gravedad, láser, portales y niveles 31-35.
4. Lava, géiser, plataforma que se hunde y niveles 36-40.
5. Pasada de equilibrio: tiempos de medalla, `DEV_UNLOCK_ALL = false`,
   créditos y exportación.

Cada paso incluye: layout, escena horneada, registro en `LevelRegistry`,
smoke test del nivel, test de cada mecánica nueva y actualización de
`AGENTS.md`.
