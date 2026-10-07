# Plan — Spec 002 Pulido visual

Estado: aprobado (junto con la spec; implementación directa)

## Enfoque

Solo presentación: tema, lista, formulario y una función pura de **urgencia**. Sin cambios de persistencia ni RF de negocio de 001.

## Archivos

| Ruta | Responsabilidad | RF |
|------|-----------------|----|
| `lib/domain/urgency.dart` | `ExpiryUrgency` + `expiryUrgency(item, today)` puro | RNF-3, definiciones |
| `test/domain/urgency_test.dart` | Umbrales crítico / alta / normal | RNF-3 |
| `lib/app.dart` | ThemeData M3 seed teal, tipografía/radios | RF-8 |
| `lib/ui/theme/food_theme.dart` | Tokens de tema reutilizables | RF-8 |
| `lib/ui/home/food_item_tile.dart` | Tile con indicador de urgencia | RF-1, RF-2 |
| `lib/ui/home/inventory_page.dart` | Márgenes, empty state, segmented/orden alineados | RF-3, RF-4 |
| `lib/ui/item/food_item_form_page.dart` | Secciones visuales + Guardar prominente | RF-5–7 |
| `lib/l10n/app_*.arb` | Cadenas nuevas (p. ej. etiquetas de urgencia si se muestran) | RF-9 |
| `lib/ui/l10n_labels.dart` | Labels de urgencia si aplica | RF-9 |

## Urgencia (dominio)

```
daysUntilEffective(item, today) → effective.difference(today).inDays  // day-only
expiryUrgency:
  days < 0  → critical
  days <= 2 → high
  else      → normal
```

## Decisiones

| Decisión | Elegido | Descartado |
|----------|---------|------------|
| Indicador en lista | Chip compacto + color barra/leading | Solo color de texto (poco accesible) |
| Theme | `foodTheme()` centralizado | Hardcode en cada widget |
| Form | Secciones con títulos sutiles + padding | Bottom sheet |

## Tests

`flutter test test/domain/urgency_test.dart` (+ suite dominio existente).
