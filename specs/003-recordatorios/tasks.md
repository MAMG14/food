# Tareas — Spec 003 Recordatorios

Estado: aprobado — código completo; pendiente verificación manual en dispositivo (T5, T7–T10)

Implementar **una tarea por vez**. Tests de lógica primero (en rojo), luego código, `flutter test` en verde, marcar y parar.

- [x] **T1. Modelo de configuración + `effectiveLeadDays` + tests.** RF-2–4, valores por defecto
  - Hecho cuando: `flutter test test/domain/reminders_test.dart` en verde para general, propia, sin aviso, global apagado y defaults.

- [x] **T2. `planReminders` (cálculo puro) + tests.** RF-8, RF-11–13, RF-15, RNF-3
  - Hecho cuando: tests en verde para aviso normal, tardío → siguiente hora, tardío → inmediato, caducado, precisión mes, agrupación por día con orden por caducidad y límite de 30 slots.
  - Añadido: registro de avisos entregados (`alreadyNotified`, `notifiedItemIds`) para no repetir avisos (ver plan).

- [x] **T3. Migración SQLite v2 + repositorio de configuración + tests.** RF-6, RNF-4
  - Hecho cuando: test con FFI comprueba defaults, guardar/leer y que una BD v1 con artículos migra a v2 sin perder ninguno.

- [x] **T4. Dependencias y configuración de plataforma.** RNF-1, RNF-2, RNF-6
  - Hecho cuando: paquetes añadidos; manifest Android (permisos y receivers), desugaring y `AppDelegate` iOS listos; `flutter build apk --debug` compila y la app arranca igual que antes.
  - Verificado: `flutter build apk --debug` y `flutter build ios --simulator --debug` compilan.

- [ ] **T5. Gateway de notificaciones + zona horaria.** RF-14, RF-19
  - Hecho cuando: existe la interfaz y su implementación real; al arrancar se fija la zona local; un aviso de prueba programado a +1 min llega en Android (verificación manual, el código de prueba no se queda).
  - Código hecho. Falta: comprobar en dispositivo con la demo manual (hora de aviso a +2 min).

- [x] **T6. `ReminderScheduler.resync` + textos i18n + tests.** RF-7, RF-14, RF-15
  - Hecho cuando: test con gateway falso verifica cancelar todo + programar los slots esperados con texto singular («X caduca mañana») y plural («N artículos por caducar»); el test también corre con `en` y obtiene los textos en inglés (sin idioma fijo en el scheduler).

- [ ] **T7. Cableado: resync al arrancar y tras crear/editar/borrar.** RF-8–10, RF-19
  - Hecho cuando: en dispositivo, crear/editar/borrar un artículo cambia los avisos pendientes; abrir la app los recalcula.
  - Código hecho (también al volver de segundo plano). Falta: prueba en dispositivo.

- [ ] **T8. Pantalla de ajustes de recordatorios.** RF-1–5, RF-7, RF-18
  - Hecho cuando: desde el inventario se abren los ajustes; switch, antelación general, hora y regla por categoría se guardan, sobreviven a reiniciar la app y relanzan `resync`; con permiso denegado aparece el banner.
  - Código hecho; tests de widget en verde a 360 dp (defaults, guardar, banner, regla cargada). Falta: prueba en dispositivo.

- [ ] **T9. Permiso al primer arranque + tap → inventario Activos.** RF-16–18
  - Hecho cuando: instalación limpia pide el permiso una sola vez; tocar el aviso (app cerrada, en segundo plano y abierta en el formulario) lleva a Activos.
  - Código hecho. Falta: prueba en dispositivo.

- [ ] **T10. Cierre.** Criterios de finalización
  - Hecho cuando: demo manual en Android e iOS (individual, agrupado, editar/borrar, reinicio del teléfono); `flutter analyze` sin errores; `flutter test` en verde; spec → implementada; `MEMORY.md` actualizado.
  - Hecho: `flutter analyze` sin errores (1 info previo), `flutter test` 100/100. Falta: demo manual.
