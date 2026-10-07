# Plan — Spec 003 Recordatorios de caducidad

Estado: aprobado

## Enfoque

Un único punto de verdad: **re-sincronizar** todos los avisos cada vez que algo cambia (artículo, configuración o arranque de la app). La sincronización:

1. lee artículos + configuración,
2. calcula con una **función pura** la lista de avisos agrupados por día,
3. cancela los avisos programados y programa los nuevos.

Así RF-7 a RF-13 y RF-19 se cumplen con el mismo código, y no hay que rastrear el id de aviso de cada artículo. Con cientos de artículos el coste es despreciable (un cálculo en memoria + ≤ 30 llamadas al sistema).

## Dependencias nuevas

| Paquete | Para qué | RF/RNF |
|---------|----------|--------|
| `flutter_local_notifications` | Programar/cancelar notificaciones locales, permisos, tap | RF-14–18, RNF-1, RNF-6 |
| `timezone` | Programar a hora local (`TZDateTime`) respetando horario de verano | RF-5, RF-19 |
| `flutter_timezone` | Obtener la zona horaria del dispositivo para `timezone` | RF-19 |

Nada de servidor ni push (RNF-1). Configuración guardada en el **mismo SQLite** (no `shared_preferences`), para tener una sola base de datos con migraciones.

## Archivos a crear / modificar

| Ruta | Responsabilidad | RF |
|------|-----------------|----|
| `lib/domain/models/reminder_settings.dart` | `ReminderSettings` (enabled, generalLeadDays, notifyAt hora/minuto, `Map<Category, CategoryReminderRule>`, permissionAsked) + `CategoryReminderRule` (useGeneral / custom(days) / off) + `allowedLeadDays` + defaults | RF-2–5, valores por defecto |
| `lib/domain/reminders.dart` | Funciones puras: `effectiveLeadDays`, `planReminders` | RF-8, RF-11–13, RF-15, RNF-3 |
| `lib/data/food_database.dart` | Schema v2 + migración v1→v2 (tablas de configuración) | RF-6, RNF-4 |
| `lib/data/reminder_settings_repository.dart` | Leer/guardar configuración (defaults si no hay fila) | RF-6 |
| `lib/notifications/notification_gateway.dart` | Interfaz mínima: `init`, `requestPermission`, `areEnabled`, `cancelAll`, `schedule(id, at, title, body)`, `showNow`, stream de taps | RF-14–18 |
| `lib/notifications/local_notification_gateway.dart` | Implementación con `flutter_local_notifications` + `timezone` | RNF-2, RNF-6 |
| `lib/notifications/reminder_scheduler.dart` | `resync()`: lee repos, llama a `planReminders`, construye textos i18n y programa vía gateway | RF-7–15, RF-19 |
| `lib/ui/settings/reminder_settings_page.dart` | Pantalla de ajustes (switch, antelación general, hora, regla por categoría, aviso de permiso denegado) | RF-1–5, RF-18 |
| `lib/ui/home/inventory_page.dart` | Icono de ajustes en AppBar; `resync` tras crear/editar/borrar; forzar vista Activos al tocar aviso | RF-1, RF-8–10, RF-16 |
| `lib/app.dart`, `lib/main.dart` | Crear gateway/scheduler, `navigatorKey`, pedir permiso al primer arranque, `resync` al arrancar | RF-16, RF-17, RF-19 |
| `lib/l10n/app_es.arb`, `app_en.arb` | Textos de ajustes, notificaciones (con plural) y canal Android, en ambos idiomas | RNF-5 |
| `lib/l10n/app_locale.dart` | Constante `appLocale` compartida por `MaterialApp` y el scheduler | RNF-5 |
| `android/app/build.gradle.kts`, `AndroidManifest.xml` | Desugaring requerido por el plugin, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, receivers del plugin | RF-17, RNF-6 |
| `ios/Runner/AppDelegate.swift` | Delegado de notificaciones (avisos en primer plano y taps) | RF-14, RF-16 |
| `test/domain/reminders_test.dart` | Tests del cálculo | RNF-3 |
| `test/data/reminder_settings_repository_test.dart` | Persistencia + migración v1→v2 sin perder artículos | RF-6, RNF-4 |
| `test/notifications/reminder_scheduler_test.dart` | `resync` con gateway falso | RF-7–15 |

## Funciones puras (dominio)

`now` es fecha-hora local; `today = dateOnly(now)`.

```
effectiveLeadDays(category, settings) → int?   // null = no avisar
  si !settings.enabled → null
  regla = settings.categoryRules[category] ?? useGeneral
  useGeneral → settings.generalLeadDays
  custom(d)  → d
  off        → null

planReminders(items, settings, now) → List<ReminderSlot>
  ReminderSlot { DateTime fireAt; bool immediate; List<FoodItem> items }  // items ordenados por caducidad

  para cada item:
    E = effectiveExpiryDate(item)
    si E < today → descartar                                   // RF-12
    L = effectiveLeadDays(item.category, settings); si null → descartar   // RF-13
    target = E − L días, a notifyAt
    si target > now → fireAt = target                           // caso normal
    si no:                                                       // RF-11, aviso tardío
      next = hoy a notifyAt si aún no pasó, si no mañana a notifyAt
      si dateOnly(next) ≤ E → fireAt = next
      si no → immediate                                         // caduca hoy y ya pasó la hora
  agrupar por día de fireAt (los immediate forman su propio slot)   // RF-14, RF-15
  ordenar slots por fireAt; devolver como máximo `maxSlots` (30)    // límite iOS
```

Id de notificación estable por slot: días desde 2000-01-01 de `fireAt` (immediate → id fijo reservado). Evita colisiones.

**Registro de avisos entregados** (decisión tomada en implementación): sin él, un aviso que ya llegó parece “tardío” en el siguiente `resync` y se repetiría cada día hasta caducar (y los inmediatos, en cada apertura). Por eso cada `resync` guarda por artículo `(fireAt, clave de caducidad)`; si `fireAt ≤ ahora` y la caducidad no cambió, el artículo ya avisó y `planReminders` lo omite (`alreadyNotified`). Editar la caducidad cambia la clave → vuelve a avisar.

```
notifiedItemIds(items, log, now) → ids con log.fireAt ≤ now y misma clave de caducidad
```

## Textos de la notificación (RF-14, RF-15)

- Título: `appTitle`.
- 1 artículo: «{nombre} caduca hoy / mañana / el {fecha}» (fecha con precisión del artículo, reutilizando `expiry_format`).
- Varios: «{n} artículos por caducar» + cuerpo con nombres ordenados por caducidad, unidos por coma; en Android estilo expandible (`InboxStyle`) para que quepan más.
- Fuera de un `BuildContext`: `lookupAppLocalizations(appLocale)`, donde `appLocale` es la **misma constante** que usa `MaterialApp.locale` (se extrae a `lib/l10n/app_locale.dart`). Nada de `Locale('es')` suelto en el scheduler.
- Fechas con `formatExpiry(item, appLocale)` (formato `intl` del idioma activo).
- Nombre y descripción del canal de notificaciones de Android también salen del ARB (se ven en los ajustes del sistema).
- Los textos se generan al programar: si en el futuro cambia el idioma, el `resync` al abrir la app los regenera.

## Persistencia (migración v1 → v2)

```
reminder_settings (una fila, id = 1)
  enabled INTEGER, general_lead_days INTEGER,
  notify_hour INTEGER, notify_minute INTEGER,
  permission_asked INTEGER

category_reminder_rules
  category TEXT PRIMARY KEY, mode TEXT ('general'|'custom'|'off'), lead_days INTEGER NULL

reminder_log
  item_id INTEGER PRIMARY KEY, fire_at TEXT, expiry_key TEXT
```

- `onCreate` (instalación nueva) crea v1 + v2; `onUpgrade(1→2)` solo **añade** tablas: `food_items` no se toca (RNF-4).
- Sin fila → defaults de la spec (activados, 2 días, 09:00, todas usan la general). Los artículos existentes reciben aviso en el primer `resync` (caso límite de la spec).

## Plataforma

- **Android:** `AndroidScheduleMode.inexactAllowWhileIdle`. No pide el permiso de alarmas exactas (Android 14 lo niega por defecto y Play lo restringe); un desfase de minutos es aceptable para un aviso de días. Reprogramación tras reinicio con el receiver de arranque del plugin (RNF-6). Permiso `POST_NOTIFICATIONS` (Android 13+), minSdk 24 ya compatible.
- **iOS 15+:** permiso de alerta/sonido/badge al primer arranque; ≤ 30 slots pendientes (< 64 del sistema).
- **Zona horaria:** al arrancar se fija la zona local de `timezone` con `flutter_timezone` y se hace `resync` (RF-19).

## Interfaz

1. Inventario: icono de campana en la AppBar → `ReminderSettingsPage` (RF-1).
2. Ajustes: switch global; desplegable de antelación general (valores permitidos, «el mismo día» para 0); selector de hora (`showTimePicker`); lista de 5 categorías con desplegable «Usar general (N días) / valores / Sin aviso». Controles por categoría deshabilitados si el switch global está apagado.
3. Si el permiso está denegado: banner en ajustes con explicación y botón que abre los ajustes de notificaciones del sistema (RF-18).
4. Cada cambio se guarda al momento y lanza `resync` (sin botón Guardar).
5. Primer arranque: tras el splash se pide el permiso una vez; se marca `permission_asked` (RF-17, RF-18).
6. Tap en notificación: `navigatorKey` vuelve a la raíz y el inventario pasa a Activos y recarga (RF-16).

## Estrategia de tests

| Área | Cómo | RF |
|------|------|-----|
| `effectiveLeadDays`, `planReminders` | Unitarios con `now` fijo: normal, tardío → siguiente hora, tardío → inmediato, caducado, sin aviso, global apagado, precisión mes, agrupación por día, orden, límite de slots, cambio de categoría | RF-8, RF-11–13, RF-15, RNF-3 |
| Repositorio de configuración | sqflite FFI en fichero temporal: defaults, guardar/leer, migración v1→v2 con artículo previo intacto | RF-6, RNF-4 |
| `ReminderScheduler.resync` | Gateway falso: cancela y programa lo esperado; textos singular/plural | RF-7–10, RF-14–15 |
| Plataforma, permisos, tap | Manual en Android e iOS (ver demo) | RF-16–18, RNF-6 |

**Demo manual práctica:** poner hora de aviso a +2 min y antelación 0, crear un artículo que caduca hoy → llega el aviso; crear dos → aviso agrupado; editar/borrar → cambia o desaparece; reiniciar el teléfono → sigue programado.

## Decisiones

| Decisión | Elegido | Alternativa descartada |
|----------|---------|-------------------------|
| Librería de avisos | `flutter_local_notifications` (estándar, Android+iOS, programación por zona horaria) | `awesome_notifications` (más pesada, API propia); `workmanager` + mostrar al vuelo (Android no garantiza la hora, iOS no fiable) |
| Estrategia | `resync` total tras cada cambio | Programar/cancelar por artículo (frágil con agrupación por día y cambios de configuración) |
| Configuración | Tablas en el SQLite existente (migración v2) | `shared_preferences` (segundo almacenamiento sin migraciones) |
| Alarmas Android | Inexactas | Exactas (permiso extra, rechazado por defecto en Android 14+) |
| Estado / DI | Inyección por constructor como en 001 | Riverpod/Bloc (no hace falta aún) |

## Riesgos

- `flutter_local_notifications` exige *core library desugaring* en Android: si el build falla, es lo primero que se revisa.
- Fabricantes con ahorro de batería agresivo (Xiaomi, Huawei…) pueden retrasar avisos inexactos; se documenta, no se combate en esta spec.
- La API exacta de los paquetes cambia entre versiones mayores: se verifica contra la versión instalada en la tarea correspondiente.
