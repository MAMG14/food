# MEMORY — Food

Resumen para retomar el trabajo. **No es la fuente del estado**: el progreso vive en `specs/NNN-*/tasks.md` y el ciclo de vida en el `Estado:` de cada `spec.md`. Aquí solo: qué es el producto hoy, dónde mirar y qué sigue.

## Producto hoy

- Inventario local con caducidad (spec 001).
- UI teal v1 con urgencia de caducidad y splash de marca provisional (spec 002).
- Recordatorios con notificación local, configurables en general y por categoría (spec 003).
- Fuera por ahora: nube, login, espacios casa/negocio, marca definitiva.

## Dónde mirar

- Specs y progreso: `specs/` (`spec.md` → `plan.md` → `tasks.md`).
- Decisiones tomadas en implementación o de proceso: `docs/decisions.md`.
- Flujo de agentes (hooks, revisor, commits): `AGENTS.md`.

## Próximo paso

- Spec 004: plan/tareas **aprobados**; implementación en curso (`specs/004-alacena-bunker-ui/tasks.md`).
- Spec 003: código listo; verificación manual aplazada (salvo puente tap → filtro `soon` en 004).
