---
name: sdd
description: >-
  Úsala siempre que trabajes con Spec-Driven Development en este proyecto
  (docs/constitution.md o cualquier archivo dentro de specs/): redactar, revisar
  o cambiar specs, planes y tareas, o implementar y validar tareas de una spec.
---

# Spec-Driven Development (SDD) — Food / Cursor

## Flujo

Constitución → Spec → Clarificación → Plan → Tareas → Implementación → Validación → Cambio.

- Nunca pases a la siguiente fase sin la **aprobación explícita** del usuario.
- La spec manda: si algo no está en la spec, no se implementa. Si falta una decisión, para y pregunta.
- Un cambio de requisitos se hace primero en la spec, luego en el plan y las tareas, y por último en el código.
- Cada spec vive en `specs/NNN-nombre/` con `spec.md`, `plan.md` y `tasks.md`.
- Al terminar cada fase, actualiza `MEMORY.md`.
- Equivalente Cursor (no OpenCode): rules en `.cursor/rules/`, esta skill, subagentes/`Task` para roles.

## Plantilla de spec (`spec.md`)

```markdown
# Spec NNN — <Nombre>

Estado: borrador | aprobada | implementada

## Contexto y objetivo
## Usuarios
## Historias de usuario
- HU-1. Como <rol>, quiero <acción> para <beneficio>.
## Definiciones
## Requisitos funcionales
## Requisitos no funcionales
## Casos límite
## Fuera de alcance
## Criterios de finalización
## Dudas abiertas
- [NECESITA ACLARACIÓN] <duda>
```

La spec describe el QUÉ y el POR QUÉ. Nada de stack, arquitectura ni nombres de archivos.

## Requisitos en EARS (español)

- RF-x: CUANDO <evento>, EL SISTEMA <respuesta>.
- RF-x: SI <condición no deseada>, ENTONCES EL SISTEMA <respuesta>.
- RF-x: MIENTRAS <estado>, EL SISTEMA <respuesta>.
- RF-x: EL SISTEMA <comportamiento permanente>.

Cada RF debe ser verificable.

## Plan (`plan.md`)

Archivos y responsabilidades · Funciones puras (con `today` local como parámetro) · Pseudocódigo · UI · Decisiones con alternativa descartada · Estrategia de tests con `flutter test`. Indica qué RF cubre cada parte.

## Tareas (`tasks.md`)

```markdown
- [ ] **Tn. <Descripción>.** RF-x, RF-y
  - Hecho cuando: <comprobación verificable>.
```

Máximo ~10 tareas por spec; 20–30 min cada una. Si salen más, propon dividir la spec.

## Implementación

Una sola tarea cada vez: tests de lógica primero (en rojo), después el código, `flutter test` en verde, marcar la tarea y parar.

## Validación

Recorrer la spec RF por RF: test o prueba manual. Veredicto `APROBADO` o `CAMBIOS NECESARIOS`.

## Roles (multiagente en Cursor)

- Coordinator: orquesta; no edita código de app.
- Planner: solo `specs/**` (+ docs de producto si se pide).
- Implementer: una tarea; no cambia la spec.
- Reviewer: no modifica producto; solo detecta.

Al delegar, pasar petición del usuario, fase, rutas y resultado de la fase anterior (los subagentes no ven el chat completo).
