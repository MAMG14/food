# Tareas — Spec 001 Inventario MVP

Estado: aprobado

Implementar **una tarea por vez**. Marcar checkbox al terminar. Tras cada tarea de dominio: `flutter test` en verde.

- [x] **T1. Modelo y enums de dominio.** RF-4, RF-5
  - Hecho cuando: existen tipos de artículo/enums en `lib/domain/` y el proyecto analiza sin errores nuevos en esos archivos.

- [x] **T2. Lógica pura de caducidad, filtro y orden + tests.** RF-10, RF-12, RF-13, RF-16, RNF-4
  - Hecho cuando: `flutter test test/domain/expiry_test.dart` en verde (día, mes→último día, activo/caducado, orden nombre y caducidad).

- [x] **T3. Validación de entrada + tests.** RF-2, RF-3 (cantidad > 0)
  - Hecho cuando: `flutter test test/domain/validation_test.dart` en verde (nombre vacío, fechas inválidas, cantidad ≤ 0).

- [x] **T4. SQLite + repositorio CRUD.** RF-1, RF-6, RF-7, RF-8, RNF-2
  - Hecho cuando: se puede insertar/actualizar/borrar/listar en DB (comprobado con un test de repositorio en memoria/fichero temp **o** smoke manual documentado); schema v1 creado.

- [x] **T5. i18n (gen-l10n) + MaterialApp en español.** RNF-3, RNF-1
  - Hecho cuando: la app arranca con locale `es` y al menos las cadenas de navegación/lista/formulario salen del ARB (sin literales sueltos en esas pantallas).

- [x] **T6. Pantalla de inventario (vistas, orden, vacío, tile).** RF-10–15
  - Hecho cuando: se ven Activos/Caducados, cambio de orden, empty state y filas con nombre+caducidad (datos de prueba o repo real).

- [x] **T7. Formulario crear / editar / borrar con confirmación.** RF-1–9
  - Hecho cuando: flujo manual crear (día y mes), editar, cancelar borrado y confirmar borrado funciona en dispositivo/emulador.

- [x] **T8. Integración final: quitar demo, cablear main, verificación.** Criterios de finalización
  - Hecho cuando: no queda el contador demo; `flutter analyze` sin issues bloqueantes; `flutter test` en verde; demo manual de la spec hecha; `MEMORY.md` actualizado (spec → implementada).
