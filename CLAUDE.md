# CLAUDE.md

La guía completa del proyecto vive en AGENTS.md (única fuente de verdad, compartida con opencode). Léela antes de tocar código:

@AGENTS.md

## Notas específicas para Claude Code

- Motor Godot (no está en el PATH): `C:\Users\Usuario\Downloads\Godot_v4.7.2-stable_win64_console.exe`.
- Antes de dar un cambio por terminado, corre la suite completa de tests (sección 2 de AGENTS.md) y actualiza las secciones 4-6 de AGENTS.md.
- Tras crear/renombrar scripts o escenas: `--headless --path . --import`.
- Los subagentes por área están definidos en `.opencode/agent/`; úsalos como referencia de responsabilidades.
