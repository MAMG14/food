# AGENTS — Food

Guía operativa para agentes de Cursor en este proyecto.

## Qué es este proyecto

App Flutter (Android + iOS) para listar alimentos de casa o de un negocio con fecha de caducidad. MVP: inventario local (crear, editar, borrar, listar activos/caducados, ordenar). Sin login ni nube. Marca temporal: Food (`com.example.food`).

## Documentos de verdad

- `docs/constitution.md` — principios innegociables.
- `specs/NNN-*/spec.md` — qué y por qué (manda sobre el código).
- `specs/NNN-*/plan.md` y `tasks.md` — cómo y en qué orden.
- `MEMORY.md` — resumen y próximo paso (actualizar al cerrar fases; no es fuente de estado).
- `docs/decisions.md` — decisiones tomadas durante la implementación (D-NNN).
- `docs_pdf/` — apuntes del curso (referencia; no son la spec).

Estado en una sola fuente: ciclo de vida en `Estado:` de cada `spec.md`; progreso en los checkboxes de `tasks.md`.

## Stack (MVP)

- Flutter / Dart, plataformas android + ios.
- Base de datos local (la elige el plan de la spec; no improvisar otra).
- i18n preparado; locale activo: español.

## Comandos

- Dependencias: `flutter pub get`
- Análisis: `flutter analyze`
- Tests: `flutter test`
- Tests de integración (simulador/dispositivo): `flutter test integration_test -d <device> --no-uninstall`
  - `--no-uninstall` conserva el permiso de notificaciones; la primera vez hay que pulsar «Permitir».
  - Si iOS responde «Error 2003 … Source is not authorized» con el permiso concedido, reinicia el simulador (`xcrun simctl shutdown <udid> && xcrun simctl boot <udid>`).
- Ejecutar: `flutter run`

## Flujo SDD (Cursor)

1. Leer constitución + MEMORY + spec activa antes de tocar código.
2. No pasar de fase sin aprobación explícita del usuario (spec → plan/tareas → implementación).
3. Antes de pedir aprobación del plan, revisarlo con el subagente `reviewer` (`.cursor/agents/reviewer.md`).
4. Un cambio de requisitos: primero `spec.md`, luego plan/tareas, luego código.
5. Implementar por bloques: tareas en orden, una a una, con **commit local por tarea** (`NNN/Tn: …`), sin parar entre tareas salvo en un punto de control (verificación manual, decisión abierta o fallo).
6. Usar la skill del proyecto `sdd` al trabajar con `docs/constitution.md` o `specs/`.

## Hooks (`.cursor/hooks.json`)

- `preToolUse` (Write): bloquea editar `lib/` si ninguna spec está `Estado: aprobada`.
- `postToolUse` (Write): `dart analyze` del `.dart` editado; los problemas vuelven como contexto.
- `stop`: si `lib/`, `test/` o `integration_test/` cambiaron, corre `flutter analyze` + `flutter test` y pide corregir si fallan.

## Roles (cuando se pida flujo multiagente)

- **Coordinator**: habla con el usuario, orquesta fases, no escribe código.
- **Planner**: solo escribe bajo `specs/**` y docs de producto; no implementa app.
- **Implementer**: una tarea aprobada; no rediseña la spec.
- **Reviewer**: no modifica archivos de producto; detecta fallos vs spec/constitución. Subagente de solo lectura en `.cursor/agents/reviewer.md`.

En Cursor estos roles se invocan por instrucción explícita o subagentes; siempre pasarles rutas y contexto (no ven el hilo completo).

## Reglas de producto (resumen)

- Lista plana (sin espacios casa/negocio) en el MVP.
- Fechas sin hora, zona local; precisión día (`YYYY-MM-DD`) o mes (`YYYY-MM`); mes = último día del mes para caducidad/orden.
- Unidades fijas: pz, kg, g, L, ml.
- Categorías fijas: lácteos, carne, verdura, despensa, otro.
- Activos vs caducados en vistas separadas; borrado manual; sin nube. Recordatorios locales según spec 003.

## Verificación

- Tras cambios de lógica: `flutter test` en verde.
- Lo que dependa del dispositivo (notificaciones, flujos completos): test en `integration_test/` cuando sea posible.
- Lo que quede manual: comprobar en dispositivo/emulador el flujo de la spec (punto de control).
- No inventar dependencias ni backends “por si acaso”.
