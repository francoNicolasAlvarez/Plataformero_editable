# Guía de diseño visual de personajes, enemigos y objetos

Resumen de la investigación del 2026-11-25 (artículos de Game Developer, Unity,
Yacht Club Games, foro de Godot, devlogs). Son buenas prácticas de oficio, no
estudios formales. Todo el arte del proyecto es procedural (Polygon2D, Line2D,
`_draw()`), así que se aplica con formas y colores, no con sprites.

## 1. Silueta primero
- Un personaje se debe reconocer rellenándolo de negro. En 2D la silueta es casi
  todo lo que hay: cada enemigo necesita una forma exterior distinta (sombrero,
  arma, postura, proporción).
- Probar siempre a tamaño real (jugador = 48 px = 1 J) y no solo ampliado.
- Lenguaje de formas: redondo = inofensivo o pisable; angular/puntiagudo =
  peligroso. Las partes que dañan (puntas, cuchillas) deben ser angulares; las
  que son seguras (sombrero pisable) deben ser redondeadas.

## 2. Paleta y contraste
- Paleta limitada por zona y un color de acento reservado para el PELIGRO
  (rojo/naranja = daño; azul/cian = magia o ayuda; verde/blanco = curación).
  No reutilizar el rojo de peligro para decoración.
- Separar por VALOR (claro/oscuro), no solo por tono: jugador, enemigos y
  plataformas deben leerse sobre el fondo; el fondo lejano va desaturado y de
  menor contraste (ya se hace con el parallax).
- Plataformas transitables = tono claro con remate superior; fondo = oscuro y
  apagado. Contorno negro de 2-3 px en todo lo interactivo (ya existe).
- Comprobar que un elemento importante (portal, control, hierba, llave) no
  desaparece en niveles oscuros (zonas a oscuras, cuevas).

## 3. Anticipación de ataques (telegrafiado)
- Todo ataque tiene tres fases: ANTICIPACIÓN (aviso), ACTIVO (hace daño) y
  RECUPERACIÓN (ventana segura). La pose inicial es el aviso.
- Usar al menos dos canales a la vez: animación/forma + color o sonido
  (ya hecho: carga del mago, arco del arquero, anillos del centinela).
- El aviso debe durar lo bastante para reaccionar (≥ 0,4 s en ataques
  rápidos, ≥ 0,8 s en los pesados) y ser distinto por enemigo.
- Marcar la zona de impacto antes de que caiga (rocas, catapultas, minas).
- Trampas con ciclo: advertir, activar, enfriar; nunca dañar sin aviso previo
  salvo que el peligro sea estático y visible (pinchos).

## 4. Superficies y objetos coherentes
- Una apariencia = un comportamiento. Si una plataforma se derrumba, lleva
  grietas desde el principio; si es una cinta, lleva rodillos y sentido visible.
  No usar el mismo aspecto para cosas seguras y peligrosas.
- Los objetos interactivos (botones, palancas, objetos sujetables, llaves) usan
  un acento propio y un brillo o movimiento suave (bob) que invita a tocarlos.
- Los objetos decorativos no llevan contorno ni acento, para no confundirse.

## 5. Game feel (juice) sin tocar las reglas
- Squash & stretch sobre el nodo visual, nunca sobre la colisión (ya hecho).
- Destello de golpe (hit flash) y hit-stop corto al recibir daño (ya hecho,
  0,07 s); sacudida de cámara proporcional al daño.
- Partículas pequeñas al saltar, aterrizar, recoger y romper; deben ser
  baratas (CPUParticles2D con la textura `spark.svg`).
- Todo efecto es opcional para la jugabilidad y se apaga en headless.

## 6. Animación procedural
- Ciclos con 2-4 fotogramas clave bien contrastados leen mejor que muchos
  sutiles. Exagerar la pose de anticipación y la de impacto.
- Enemigos con silueta cambiante (lancero que echa la lanza atrás, bruto que
  se agacha) comunican la intención sin texto.

## 7. Accesibilidad
- No depender solo del color: sumar forma, movimiento o sonido (daltonismo).
- Evitar parpadeos rápidos y muy brillantes; el aviso parpadea ≤ 3 Hz.
- Mantener contraste suficiente entre HUD y fondo (paneles oscuros, ya hecho).

## 8. Lista de revisión antes de dar por bueno un enemigo u objeto
1. ¿Se reconoce su silueta en negro a 48 px?
2. ¿Su color de acento coincide con su rol (peligro/ayuda/neutral)?
3. ¿Tiene aviso, fase activa y recuperación distinguibles?
4. ¿Se distingue del fondo en el nivel más oscuro donde aparece?
5. ¿Su aspecto adelanta su comportamiento?
6. ¿Tiene test (`_check`) que fija sus parámetros visuales clave?

## Fuentes consultadas
- Game Developer, "Enemy attacks and telegraphing" y "Anatomy of an Enemy
  Attack in Dark Souls 3".
- Unity, "Level design basics: guiding players without telling them" y
  "Kaze and the Wild Masks: designing a great pixel art character".
- Yacht Club Games, "Specter of Torment level design deep dive".
- Foro de Godot, "Game feel checklist for Godot 4" (hit stop, trauma shake,
  squash sobre el sprite y no sobre la colisión).
- AIE Lecture UX (lenguaje de formas y contraste); SRB2 wiki, "Level Design
  101 / Visual design" (coherencia de apariencia y comportamiento).
- bugnet.io, "How to design a readable enemy design".
