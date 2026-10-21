# Plan — Spec 004 UI Alacena Bunker

Estado: aprobado

## Enfoque

Cambio de presentación y flujo de arranque/navegación según Figma. Reutiliza dominio de urgencia (002) y ajustes de recordatorios (003). Persistencia nueva mínima: flag de onboarding. Sin cambiar RF de negocio de artículos ni el scheduler de recordatorios.

## Archivos

| Ruta | Responsabilidad | RF |
|------|-----------------|----|
| `lib/domain/home_filter.dart` | Enum filtro + `countByHomeFilter` / `itemsForHomeFilter` / `defaultHomeFilter` (puros, `today`) | RF-7–10, RNF-3 |
| `test/domain/home_filter_test.dart` | Contadores, partición, default | RNF-3 |
| `lib/data/app_preferences.dart` | Flag `onboardingCompleted` (SharedPreferences); regla de skip (abajo) | RF-5–6 |
| `test/data/app_preferences_test.dart` | Flag + skip por DB previa / artículos | RF-6 |
| `pubspec.yaml` | `lottie`, `shared_preferences`; asset Lottie | RNF-4 |
| `lib/ui/theme/food_theme.dart` | Seed / tokens verde Alacena Bunker | RF-17 |
| `lib/ui/splash/splash_gate.dart` | Lottie una vez; fallback estático | RF-2 |
| `lib/ui/onboarding/onboarding_page.dart` | Bienvenida + Iniciar | RF-4–5 |
| `lib/ui/shell/home_shell.dart` | Tab bar Home / Añadir; Navigator; mapeo tap recordatorio → filtro | RF-14, puente 003 |
| `lib/ui/home/inventory_page.dart` | Tarjetas, lista filtrada, empty, orden, ajustes; **sin** SegmentedButton Activos/Caducados ni FAB | RF-7–13, RF-16 |
| `lib/ui/item/food_item_form_page.dart` | Layout Figma + campos 001 | RF-15 |
| `lib/app.dart` | splash → onboarding? → shell | RF-2–6 |
| `lib/l10n/app_*.arb` | Marca, onboarding, tarjetas, empty | RF-3, RF-18 |
| Manifest / Info.plist + launch screens | Display name + splash nativo | RF-1, RF-3 |

## Dominio (filtros)

```
HomeFilter: optimal | soon | expired

expiryUrgency → critical⇒expired, high⇒soon, normal⇒optimal

countByHomeFilter / itemsForHomeFilter / defaultHomeFilter(counts)
```

Orden: `sortByName` / `sortByExpiry` de 001 sobre la lista filtrada.

## Skip onboarding (usuarios 001–003)

Marcar `onboardingCompleted` **sin** mostrar onboarding si, al primer arranque de esta versión:

1. ya hay artículos en el repositorio, **o**
2. el archivo de la base SQLite **ya existía** antes de abrir (instalación previa, aunque el inventario esté vacío).

Instalación limpia (sin DB previa): sí muestran onboarding.

Señal concreta: comprobar existencia del path de la DB que ya usa el proyecto (mismo que abre sqflite) **antes** del primer `openDatabase` de esa sesión, o un flag de migración `ui_v4_migrated` escrito la primera vez que corre código 004 tras detectar DB previa — detalle en T2; test obligatorio: “DB previa + 0 artículos ⇒ completed”.

## Flujo de arranque

```
cold start → splash nativo → SplashGate (Lottie | fallback)
  → si !onboardingCompleted → Onboarding → Iniciar → flag → HomeShell
  → si completed → HomeShell
```

## Navegación y recordatorios

- **Tab Añadir:** siempre hace `push` del formulario de alta sobre el stack; el índice de tab seleccionado visualmente puede marcar Añadir mientras el form está abierto, pero **al cerrar (guardar o cancelar/pop) el tab vuelve a Home (índice 0)** y se refresca la lista.
- **Retirar:** `SegmentedButton` Activos/Caducados y el FAB de alta (sustituidos por tarjetas + tab).
- **Tap de notificación (003):** deja de usar `InventoryView.active`; fija el filtro Home a **`soon` (Por caducar)** y asegura tab Home. Si no hay ítems `soon`, `defaultHomeFilter` tras el resync visual es aceptable como fallback en UI, pero el intent del tap es `soon`.

## UI (resumen)

- Home: tres tarjetas + lista + empty Figma + orden + icono ajustes → `ReminderSettingsPage`.
- Form: nombre, precisión, fecha al estilo Figma; resto de campos 001 debajo.
- Tema: primary verde del Figma (token al implementar).

## Decisiones

| Decisión | Elegido | Descartado |
|----------|---------|------------|
| Flag onboarding | SharedPreferences | Tabla de recordatorios |
| App ya instalada | Existencia previa del archivo SQLite | Solo `count() > 0` |
| Contadores | Funciones puras en memoria | Query SQL nueva |
| Tab Añadir | `push` + al pop volver tab Home | Body sin stack |
| Tap recordatorio | Filtro `soon` | Filtro `optimal` / Activos legacy |
| Lottie | Paquete `lottie` | Crossfade PNG |
| Package id | Sin cambio | Renombrar id |

## Tests

- Unit: `home_filter_test`, `app_preferences_test` (incl. DB previa vacía).
- Widget/arranque: splash acortable en tests; onboarding no se muestra si flag completed.
- Punto de control manual T10: flujo 1ª instalación vs actualización; tap recordatorio → Por caducar.
- `flutter analyze` + `flutter test` en verde.

## Fuera del plan

- Verificación manual restante de 003 (salvo el puente de tap → filtro en esta spec).
- Icono launcher nuevo.
