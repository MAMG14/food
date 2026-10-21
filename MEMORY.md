# MEMORY — Food

Resumen para retomar el trabajo. **No es la fuente del estado**: el progreso vive en `specs/NNN-*/tasks.md` y el ciclo de vida en el `Estado:` de cada `spec.md`. Aquí solo: qué es el producto hoy, dónde mirar y qué sigue.

## Producto hoy

- Inventario local con caducidad (spec 001).
- Recordatorios locales configurables (spec 003).
- UI **Alacena Bunker** (spec 004): marca, Lottie splash, onboarding 1ª vez, Home con tarjetas Óptimo / Por caducar / Caducado, tabs Home/Añadir.
- Fuera por ahora: nube, login, espacios casa/negocio, cambio de `applicationId`.

## Dónde mirar

- Specs y progreso: `specs/` (`spec.md` → `plan.md` → `tasks.md`).
- Diseño Figma: `SByf2lLOAvL28x5m7cPgda`; Lottie: `assets/lottie/alacena_bunker_splash.json`.
- Decisiones: `docs/decisions.md`.

## Próximo paso

- Spec 004 **T10**: punto de control — probar en simulador/dispositivo (splash Lottie, onboarding limpio, Home/filtros/Añadir, ajustes, upgrade sin onboarding). Tras OK del usuario → `Estado: implementada`.
- Spec 003: verificación manual restante aplazada.
