# MEMORY — Food

Estado vivo del proyecto. Actualizar al cerrar cada fase SDD.

## Producto

- Inventario local con caducidad (001 implementada).
- UI pulida v1 (002 implementada): tema teal, chips de urgencia, form por secciones.
- Splash de arranque: nativo (teal + hoja) + marca Flutter breve (~0,9 s) y fade al inventario.
- Pendiente producto: recordatorios, nube, login, espacios, marca definitiva.

## Decisiones de diseño v1

- Teal seed `0xFF0F766E`; urgencia crítico / alta (0–2 días) / normal (3+).
- Skill `ui-design` + rule UI.
- Splash corto (cubre la carga, no retrasa al usuario). Mismo color nativo y Flutter para evitar flash blanco.

## Fase actual

- Spec 001 y 002: **implementadas** (el splash quedó documentado en 002 como RF-10/11).
- Spec 003 (recordatorios con notificación): **aprobada**. Decisiones: antelación de valores fijos (0–30 días), regla general + por categoría (general / propia / sin aviso), aviso tardío sí, notificación agrupada por día, permiso al primer arranque, reprogramación al abrir la app.

## Próximo paso

- Plan y tareas de la spec 003 **aprobados**. Claves: `flutter_local_notifications` + `timezone`, configuración en SQLite (migración v2), `resync` total tras cada cambio, alarmas inexactas en Android, idioma de avisos = `appLocale` compartido.
- Implementación: **código completo** (T1–T9). Tests 100/100; compila Android e iOS (simulador).
- Decisión añadida en implementación: tabla `reminder_log` para no repetir avisos ya entregados (documentada en el plan).
- Siguiente: demo manual en dispositivo (T5, T7–T10) → spec 003 a implementada.
