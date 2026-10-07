# AGENTS — Food

Guía operativa para agentes de Cursor en este proyecto.

## Qué es este proyecto

App Flutter (Android + iOS) para listar alimentos de casa o de un negocio con fecha de caducidad. MVP: inventario local (crear, editar, borrar, listar activos/caducados, ordenar). Sin login ni nube. Marca temporal: Food (`com.example.food`).

## Documentos de verdad

- `docs/constitution.md` — principios innegociables.
- `specs/NNN-*/spec.md` — qué y por qué (manda sobre el código).
- `specs/NNN-*/plan.md` y `tasks.md` — cómo y en qué orden.
- `MEMORY.md` — estado actual del proyecto (actualizar al cerrar fases).
- `docs_pdf/` — apuntes del curso (referencia; no son la spec).

## Stack (MVP)

- Flutter / Dart, plataformas android + ios.
- Base de datos local (la elige el plan de la spec; no improvisar otra).
- i18n preparado; locale activo: español.

## Comandos

- Dependencias: `flutter pub get`
- Análisis: `flutter analyze`
- Tests: `flutter test`
- Ejecutar: `flutter run`

## Flujo SDD (Cursor)

1. Leer constitución + MEMORY + spec activa antes de tocar código.
2. No pasar de fase sin aprobación explícita del usuario (spec → plan/tareas → implementación).
3. Un cambio de requisitos: primero `spec.md`, luego plan/tareas, luego código.
4. Implementar **una** tarea de `tasks.md` por vez; tests de lógica primero cuando aplique.
5. Usar la skill del proyecto `sdd` al trabajar con `docs/constitution.md` o `specs/`.

## Roles (cuando se pida flujo multiagente)

- **Coordinator**: habla con el usuario, orquesta fases, no escribe código.
- **Planner**: solo escribe bajo `specs/**` y docs de producto; no implementa app.
- **Implementer**: una tarea aprobada; no rediseña la spec.
- **Reviewer**: no modifica archivos de producto; detecta fallos vs spec/constitución.

En Cursor estos roles se invocan por instrucción explícita o subagentes; siempre pasarles rutas y contexto (no ven el hilo completo).

## Reglas de producto (resumen)

- Lista plana (sin espacios casa/negocio) en el MVP.
- Fechas sin hora, zona local; precisión día (`YYYY-MM-DD`) o mes (`YYYY-MM`); mes = último día del mes para caducidad/orden.
- Unidades fijas: pz, kg, g, L, ml.
- Categorías fijas: lácteos, carne, verdura, despensa, otro.
- Activos vs caducados en vistas separadas; borrado manual; sin recordatorios ni nube en MVP.

## Verificación

- Tras cambios de lógica: `flutter test` en verde.
- Tras cambios de UI: comprobar en dispositivo/emulador el flujo de la spec.
- No inventar dependencias ni backends “por si acaso”.
