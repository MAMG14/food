# Plan — Spec 001 Inventario MVP

Estado: aprobado

## Enfoque

Reemplazar el contador demo por una app de inventario local. Separar **dominio puro** (fechas, clasificación, orden) de **persistencia** y **UI**, según la constitución.

## Archivos a crear / modificar

| Ruta | Responsabilidad | RF |
|------|-----------------|----|
| `pubspec.yaml` | Dependencias: `sqflite`, `path`, `flutter_localizations`, `intl`; activar `generate: true` | RNF-2, RNF-3 |
| `l10n.yaml` + `lib/l10n/app_es.arb` (+ `app_en.arb` mínimo para gen-l10n) | Cadenas UI en español; claves en inglés | RNF-3 |
| `lib/domain/models/food_item.dart` | Modelo de dominio (id, name, expiryPrecision, expiryValue, quantity, unit, category, notes, location) | RF-1, RF-4, RF-5 |
| `lib/domain/models/enums.dart` | Enums: ExpiryPrecision, Unit, Category, StorageLocation, SortMode, InventoryView | RF-4, RF-5, RF-10, RF-12, RF-13 |
| `lib/domain/expiry.dart` | Funciones puras: `effectiveExpiryDate`, `isExpired(item, today)`, `compareByName`, `compareByExpiry` | RF-10, RF-12, RF-13, RF-16, RNF-4 |
| `lib/domain/validation.dart` | Validar nombre, cantidad, caducidad según precisión | RF-2, RF-3, cantidad ≤0 |
| `test/domain/expiry_test.dart` | Tests fecha efectiva, activo/caducado, orden | RNF-4 |
| `test/domain/validation_test.dart` | Tests validación | RF-2, RF-3 |
| `lib/data/food_database.dart` | Abrir SQLite, schema v1, migraciones futuras preparadas | RNF-2, RNF-5 constitución datos |
| `lib/data/food_item_repository.dart` | CRUD + listar todos; filtra/ordena en memoria con dominio + `today` | RF-1, RF-6–8, RF-10, RF-12–13 |
| `lib/app.dart` | `MaterialApp` con localizationsDelegates, locale `es` | RNF-1, RNF-3 |
| `lib/main.dart` | Bootstrap DB + `runApp` | — |
| `lib/ui/home/inventory_page.dart` | Tabs/segmento Activos \| Caducados, orden, lista, FAB crear, empty state | RF-10–15 |
| `lib/ui/home/food_item_tile.dart` | Fila: nombre + caducidad legible | RF-15 |
| `lib/ui/item/food_item_form_page.dart` | Crear/editar; precisión día/mes; confirmación borrar | RF-1–9 |
| `lib/ui/format/expiry_format.dart` | Formato legible día vs mes/año (locale) | RF-15 |
| Eliminar / dejar de usar UI del contador en `main.dart` | Quitar demo | — |

## Funciones puras (dominio)

Todas reciben fechas de calendario local construidas con `DateTime(y, m, d)` (nunca parse UTC de string fecha).

```
effectiveExpiryDate(precision, value) → DateTime (solo día)
  day:   parse YYYY-MM-DD → DateTime(y,m,d)
  month: parse YYYY-MM → DateTime(y, m+1, 0)  // último día del mes

isExpired(item, today) → effective < DateTime(today.y, today.m, today.d)

filterByView(items, view, today) → activos o caducados

sortItems(items, SortMode.name|expiry, today)
  name: compareTo ignoreCase
  expiry: por effectiveExpiryDate asc
```

Validación:

```
validateFoodItemInput(...) → ValidationResult
  nombre trim no vacío
  cantidad > 0
  day: YYYY-MM-DD válido
  month: YYYY-MM válido
```

## Persistencia

- **Elegido: sqflite** (simple, maduro, SQL local en móvil).
- **Descartado: Hive/Isar** — menos natural para consultas futuras; **Drift** — más código generado del necesario en MVP.
- Tabla `food_items`: columnas alineadas al modelo; `expiry_precision` + `expiry_value` (texto); timestamps `created_at`/`updated_at` opcionales para depuración.
- Schema version 1; `onUpgrade` vacío pero listo (constitución: no perder datos).

## Interfaz (comportamiento, no diseño fino)

1. Pantalla principal: selector **Activos / Caducados**; menú u iconos de orden (nombre / caducidad); lista; FAB “+”.
2. Estado vacío en español vía i18n.
3. Tap en ítem → formulario edición; menú o botón borrar con diálogo de confirmación.
4. Formulario: precisión (segmento día | mes) cambia el picker; campos opcionales con defaults (cantidad 1, unidad pz, categoría otro, ubicación otro).
5. Al guardar, volver a lista; reclasificación con `DateTime.now()` local truncado a día.

Orden de sesión: estado en el `State` de la página (no persistir aún) — RF-14.

## i18n

- `flutter gen-l10n` con ARB.
- `app_en.arb` plantilla (inglés mínimo) + `app_es.arb` completo para UI.
- Labels de enums vía métodos de extensión que lean `AppLocalizations`.

## Estrategia de tests

| Área | Cómo | RF |
|------|------|-----|
| Dominio fechas/orden/filtro | `flutter test` unitario | RF-10,12,13,16 |
| Validación | `flutter test` | RF-2,3 |
| UI / CRUD | Prueba manual en dispositivo (criterios de finalización de la spec) | RF-1,6–9,11,15 |

No mocks de sqflite obligatorios en MVP si el dominio está bien cubierto; repository se mantiene fino.

## Decisiones

| Decisión | Elegido | Alternativa descartada |
|----------|---------|-------------------------|
| DB local | sqflite | Hive (menos esquema claro); Drift (más boilerplate) |
| Filtrar/ordenar | En dominio tras `getAll` | SQL WHERE/ORDER BY (premature; hoy cambia en cliente) |
| Estado app | StatefulWidget + Inherited/callback simple | Riverpod/Bloc (overkill MVP) |
| Pickers fecha | `showDatePicker` + selector mes/año simple | Paquete extra de calendar |

## Orden de implementación sugerido

Coincide con `tasks.md`: dominio+tests → data → i18n/app shell → UI lista → UI form → cableado + demo.
