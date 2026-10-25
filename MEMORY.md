# MEMORY — Food

Resumen para retomar el trabajo. **No es la fuente del estado**: el progreso vive en `specs/NNN-*/tasks.md` y el ciclo de vida en el `Estado:` de cada `spec.md`. Aquí solo: qué es el producto hoy, dónde mirar y qué sigue.

## Producto hoy

- Inventario local con caducidad (spec 001).
- Recordatorios locales configurables (spec 003).
- UI **Alacena Bunker** (spec 004, implementada): marca, Lottie splash, onboarding 1ª vez, Home con tarjetas Óptimo / Por caducar / Caducado, tabs Home/Añadir, edge-to-edge (D-005).
- Identificador de instalación: `com.developermarco.alacenabunker` (spec 006). El nombre visible sigue siendo Alacena Bunker.
- Fuera por ahora: nube, login, espacios casa/negocio.

## Dónde mirar

- Specs y progreso: `specs/` (`spec.md` → `plan.md` → `tasks.md`).
- Diseño Figma: `SByf2lLOAvL28x5m7cPgda`; Lottie: `assets/lottie/alacena_bunker_splash.json`.
- Decisiones: `docs/decisions.md`.

## Próximo paso

- Spec **005**: T1–T9 y T11–T14 hechas. Falta **T10** verificación manual (escaneo, sin red, manual con/sin foto cámara+galería, copy sin «Open Food Facts»).
- Spec 003: verificación manual restante aplazada.
