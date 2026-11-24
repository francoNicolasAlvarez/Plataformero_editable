# Plataformero

Videojuego 2D de plataformas lineal hecho con **Godot 4.7 (GL Compatibility)** y
GDScript. La jugabilidad está inspirada en Super Mario Bros.: saltos, enemigos,
trampas, checkpoints y ocho niveles jugables con ambientaciones distintas dentro
de una hoja de ruta de 40 niveles repartidos en 8 mundos.

## Jugar

La forma más rápida es descargar el ejecutable incluido en el repositorio:

1. Abre `dist/PlataformasRoguelite.exe`.
2. Si GitHub muestra el archivo como "Stored with Git LFS", usa el botón de
   descarga del repositorio o ejecuta `git lfs pull` después de clonar.
3. No hace falta instalar Godot para jugar.

También puedes abrir el proyecto desde el editor de Godot 4.7:

```
Godot_v4.7.2-stable_win64_console.exe --path .
```

Y ejecutar directamente el menú principal:

```
Godot_v4.7.2-stable_win64_console.exe --path . res://scenes/ui/main_menu.tscn
```

## Objetivo

Atraviesa los ocho niveles actuales hasta llegar al final del juego. El menú ya
muestra los 40 huecos previstos en 8 mundos; los niveles todavía no creados
aparecen desactivados. Cada nivel da tres vidas: al morir reapareces en el último
control (bandera) activado con la vida completa; si te quedas sin vidas o se
agota el tiempo, la partida vuelve al nivel 1. El nivel alcanzado se guarda para
continuar la partida. El jugador aguanta tres golpes y, tras recibir daño, es
invulnerable durante 1 segundo.

Cada nivel es una prueba contrarreloj: el HUD muestra el tiempo restante, el
tiempo exacto invertido y la medalla proyectada (Oro, Plata o Bronce). El reloj
sigue corriendo mientras mueres o reapareces, así que los checkpoints no regalan
tiempo. Al completar un nivel aparece una pantalla de resultados con el tiempo,
la medalla, las muertes y la mejor marca; después puedes continuar, repetir el
nivel o volver al menú. También se guardan el mejor tiempo, la mejor medalla y
las muertes de ese nivel.

- **Nivel 1:** día, recorrido largo con colinas, pozos y plataformas.
- **Nivel 2:** atardecer, fosos con plataformas móviles, sierras y pinchos.
- **Nivel 3:** noche, granja con magos y enemigos rápidos y decoración rural.
- **Nivel 4:** "El Gran Pozo", un abismo cruzado por plataformas móviles.
- **Nivel 5:** "Cielo", recorrido aéreo de 28 plataformas con enemigos
  voladores que cruzan la pantalla ondulando y sierras suspendidas sobre los
  huecos.
- **Nivel 6:** "Fortaleza", 20 plataformas con saltos largos que exigen doble
  salto, pinchos en los bordes, sierras de suelo y suspendidas, y un centinela
  superior que dispara proyectiles apuntados cada 2 segundos.
- **Nivel 7:** "Inverso", la disposición del nivel 1 reflejada boca arriba:
  el jugador camina por el techo con gravedad invertida y los enemigos llevan
  sombrero triangular amarillo y ojos almendrados.
- **Nivel 8:** "Espejo", el nivel 2 reflejado horizontalmente: se empieza a la
  derecha, se avanza hacia la izquierda y los controles horizontales están
  invertidos.

## Controles

| Acción | Teclado | Mando |
| --- | --- | --- |
| Mover | A/D o flechas | Stick / DPAD |
| Saltar / doble salto | Espacio | A |
| Caer rápido | S o flecha abajo | Stick abajo / DPAD abajo |
| Impulso (atraviesa enemigos) | Ctrl | X |
| Pausa | Enter | Start |

Los controles de teclado se pueden reasignar desde **Opciones**. El mando usa
un mapeo fijo. En el nivel 8, D/flecha derecha mueven hacia la izquierda y
A/flecha izquierda hacia la derecha (el mando también queda invertido).

Durante la partida, **Enter** abre el menú de pausa: continuar, consultar la
guía de controles, ajustar brillo/volumen/teclas, volver al menú principal o
salir del juego.

## Unidad de medida

El juego mide en **píxeles** del mundo. Como referencia visual se usa la unidad
**J (un Jugador)** = 48 px, la altura del personaje (su ancho es 30 px). Ejemplos:

| Objeto | Píxeles | En J |
| --- | --- | --- |
| Jugador (alto) | 48 | 1 |
| Muro bajo del laberinto | 96 | 2 |
| Altura de un salto | 125 | 2,6 |
| Impulso (distancia) | 154 | 3,2 |
| Pasillo del laberinto (alto) | 288 | 6 |
| Foso entre tramos | 300 | 6,3 |
| Onda del saltador explosivo (radio) | 260 | 5,4 |
| Pantalla | 1152 x 648 | 24 x 13,5 |
| Correr | 532 px/s | 11 J/s |

La utilidad `GameUnits` (`scripts/core/game_units.gd`) convierte entre píxeles,
J y metros aproximados (jugador = 1,7 m).

## Elementos del nivel

- **Hierba curativa:** restaura vida al recogerla.
- **Doble salto:** disponible siempre con una pulsación extra en el aire.
- **Plataformas:** asset modular con cinco tipos (fija, vaivén horizontal,
  órbita circular, pinchos en los bordes y giro sobre el eje). Llevan vetas y
  motas procedurales sutiles que se adaptan a su tamaño y color.
- **Contornos:** plataformas, pinchos, sierras, controles y portal llevan un
  contorno negro para separarlos del fondo.

## Enemigos y trampas

- **Dummy de entrenamiento:** enemigo básico de contacto.
- **Walker:** patrulla el suelo y persigue su ruta.
- **Mago:** lanza 3 orbes de energia azul en horizontal, con sonido propio.
- **Arquero:** dispara una flecha rápida.
- **Volador:** cruza la pantalla con un patrón ondulante; aparece cada pocos
  segundos a una altura aleatoria y desaparece al salir por el borde visible
  en su dirección.
- **Centinela:** amenaza del nivel 6; se mantiene en la esquina superior
  derecha, oscila y dispara 5 proyectiles rojos en cono cada 2 segundos.
- **Enemigos del nivel 7:** usan los mismos tipos de siempre, pero con
  gravedad invertida, sombrero triangular amarillo y ojos almendrados.
- **Sierras y pinchos:** trampas con aviso visual antes de dañar. Las sierras
  muestran una guía de su recorrido; las suspendidas cruzan el hueco entre
  plataformas. Los pinchos sueltos solo aparecen sobre suelo firme; las
  plataformas con pinchos los llevan en sus bordes.

## Desarrollo

Requisitos:

- Godot 4.7.2.
- Git LFS si vas a clonar el ejecutable incluido.

Regenerar caches tras crear o renombrar scripts/escenas:

```
Godot_v4.7.2-stable_win64_console.exe --headless --path . --import
```

Ejecutar la suite de pruebas headless:

```
Get-ChildItem tests -Filter *.gd | ForEach-Object {
    & "Godot_v4.7.2-stable_win64_console.exe" `
        --headless --path . --script "res://tests/$($_.Name)" }
```

Exportar el ejecutable de Windows:

```
Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-release "Windows Desktop"
```

El ejecutable se genera en `dist/PlataformasRoguelite.exe`.

## Estructura

```
scenes/      Escenas de menús, niveles, jugador, enemigos, mundo y UI
scripts/     Lógica en GDScript (jugador, niveles, combate, UI, audio, FX)
assets/      Sprites SVG, partículas y decoración
resources/   Recursos exportables (estadísticas del jugador, ataques)
tests/       Smoke tests headless de cada sistema
dist/        Ejecutable de Windows
```

La documentación técnica y el historial de cambios están en `AGENTS.md`.
