# Plan — Spec 005 Escaneo Open Food Facts

Estado: aprobado

## Enfoque

El tab **Añadir** deja de abrir el formulario vacío y abre un **escáner**. Tras leer un EAN/UPC se consulta Open Food Facts (solo GET, detalle técnico). Con match → pantalla de **confirmación** (datos editables + caducidad obligatoria) y descarga de foto **en background**. Sin match / sin red / sin cámara → formulario manual. En alta/edición manual: foto **opcional** desde **cámara o galería**. La UI **no** muestra el nombre del proveedor; mensajes en términos de internet/red. La lógica de mapeo es **pura** y testeable; la red y la cámara quedan detrás de interfaces.

### Ampliación (post T1–T9)

1. **Copy visible:** sustituir cadenas ARB que mencionan Open Food Facts; quitar widget de atribución en confirmación (RF-20).
2. **Foto manual:** en `FoodItemFormPage`, UI para añadir / reemplazar / quitar; copiar bytes al `ProductImageStore` al guardar; permisos cámara + fotos/galería (RF-21–23, RNF-7).

## Dependencias nuevas

| Paquete | Para qué | RF/RNF |
|---------|----------|--------|
| `mobile_scanner` (o equivalente estable al implementar) | Cámara + decodificar EAN/UPC en Android e iOS | RF-1, RF-4, RNF-1 |
| `http` | Cliente GET a la API v2 de Open Food Facts | RF-4–8, RNF-6 |
| `path_provider` + `path` | Directorio local para fotos de producto | RF-12, RF-16–17, RNF-2 |
| `image_picker` (o equivalente estable) | Cámara + galería para foto manual | RF-21–23, RNF-1, RNF-7 |

Descartado: SDK oficial pesado de OFF si solo necesitamos un GET por código; contribuir a OFF; historial de escaneos; atribución OFF en UI.

**User-Agent / identificación** (RNF-5): cabecera con nombre de app + contacto o repo (requisito de OFF). Valor concreto en implementación → `docs/decisions.md` si no cabe en un comentario.

## Archivos a crear / modificar

| Ruta | Responsabilidad | RF |
|------|-----------------|----|
| `lib/domain/models/food_item.dart` (+ enums si hace falta) | Campos opcionales: `barcode`, `imagePath` (ruta local) | RF-15–18, RNF-2 |
| `lib/domain/open_food_facts_mapping.dart` | Puros: `parseOffQuantity`, `mapOffCategories`, `buildProductName`, `OffProductDraft` | RF-9–11, RNF-3 |
| `lib/data/food_database.dart` | Schema v3: columnas `barcode`, `image_path` en `food_items`; migración v2→v3 | RNF-2 |
| `lib/data/food_item_repository.dart` | CRUD con nuevos campos; al borrar, borrar archivo de foto si existe | RF-15, caso límite borrado |
| `lib/data/product_image_store.dart` | Guardar/borrar bytes de imagen bajo app documents | RF-16–17 |
| `lib/open_food_facts/off_api_client.dart` | Interfaz + impl HTTP `fetchByBarcode(code)` → `OffProduct?` | RF-4–8 |
| `lib/open_food_facts/off_product.dart` | DTO mínimo: name, brands, quantity, categoryTags, imageUrl | RF-9–12 |
| `lib/ui/scan/barcode_scan_page.dart` | Cámara, overlay, **Registrar manual**, manejo permiso denegado | RF-1–3 |
| `lib/ui/scan/product_confirm_page.dart` | Formulario prellenado + caducidad + preview foto; **sin** atribución de proveedor | RF-5, RF-9–15, RF-18, RF-20 |
| `lib/ui/shell/home_shell.dart` | Tab Añadir → `BarcodeScanPage` (no form directo) | RF-1 |
| `lib/ui/home/food_item_tile.dart` (y/o lista) | Miniatura si hay `imagePath` | RF-18 |
| `lib/ui/item/food_item_form_page.dart` | Alta/edición manual + foto opcional (cámara/galería/quitar) | RF-2, RF-6–7, RF-19, RF-21–23 |
| `lib/data/product_image_store.dart` | Además de download URL: `attachFromFile` / borrar al quitar | RF-22–23 |
| `lib/l10n/app_*.arb` | Cadenas escáner/errores **sin** nombre de proveedor; foto manual | RF-3, RF-6–7, RF-20–23, RNF-4 |
| `android` / `ios` | Permiso cámara + lectura fotos/galería según plataforma | RF-3, RF-21, RNF-1, RNF-7 |
| `test/domain/open_food_facts_mapping_test.dart` | Parseo cantidad, categorías, nombre | RF-9–11, RNF-3 |
| `test/open_food_facts/off_api_client_test.dart` | Cliente con `http.Client` falso (match / 404 / error) | RF-5–8 |
| `test/data/…` | Migración v2→v3 conserva filas; delete limpia imagen (con store fake o temp dir) | RNF-2 |

## Funciones puras (dominio)

```
parseOffQuantity(raw: String?) → ({double quantity, Unit unit})?
  // "155 g", "1 L", "500ml" → valores de Unit fijos; null si no parsea

mapOffCategories(tags: List<String>) → Category
  // priorizar tags en: conocidos (dairy/milk → dairy, meat → meat,
  // vegetables/fruits → vegetables, cereals/pasta/rice/canned → pantry)
  // si ninguno → Category.other

buildProductName(productName: String?, brands: String?) → String?
  // trim; si name vacío → null (tratar como sin match en capa UI/cliente)
  // si brands útil y no contenido ya en name → "name — brands" o "name (brands)"
  // regla fija en tests

OffProductDraft fromOffProduct(OffProduct) → draft
  name, quantity, unit, category, imageUrl, barcode
  defaults: quantity 1 + Unit.pz si parse falla; Category.other si map falla
```

La confirmación reutiliza la misma validación de alta que 001 (`validateFoodItemInput` o equivalente actual).

## Flujo UI (pseudocódigo)

```
HomeShell tab Añadir:
  push BarcodeScanPage
    onManual → push FoodItemFormPage (alta) ; pop scan al guardar/cancelar
    onPermissionDenied → mensaje + botón manual
    onBarcode(code):
      loading
      result = await offClient.fetchByBarcode(code)
      if match → push ProductConfirmPage(draft)
      else → mensaje + FoodItemFormPage (opcional: notes con código)
ProductConfirmPage:
  campos editables + caducidad requerida (sin texto de proveedor)
  preview: NetworkImage (URL) mientras no hay archivo local
  onSave válido →
    item = repository.insert(... imagePath: null, barcode: code)
    await downloadThenAttach(item.id, url)  // D-007: esperar antes de pop
    pop hasta Home; resync recordatorios (003)
  onCancel / pop sin guardar → no queda archivo staging (no se descarga hasta insert)

FoodItemFormPage (alta / edición):
  si hay imagePath o foto pendiente → ProductPhotoPreview (zoom)
  acciones: Añadir foto → sheet Cámara | Galería
            si hay foto → Reemplazar | Quitar
  onSave → si hay bytes/path pendiente: copy a product_images/item_{id}.jpg + updateImagePath
           si quitó: delete archivo + imagePath null
  permiso denegado → SnackBar / mensaje i18n; no bloquea guardar sin foto

BarcodeScanPage (anti-doble consulta):
  si ya hay fetch en curso → ignorar nuevos códigos hasta terminar o cancelar
```

### Contrato foto manual (RF-21–23)

1. El usuario elige imagen → se guarda un path temporal o bytes en memoria del form (aún no en inventory path definitivo si es alta sin id).
2. Tras `insert`/`update` con id conocido: copiar a `pathForItem(id)`, `updateImagePath`, borrar temp; si reemplaza, borrar archivo anterior.
3. Quitar: `deleteIfExists` + `updateImagePath(id, null)` (o null en el draft de update).
4. Fallo de permiso o de copia: mensaje; artículo se puede guardar sin foto.
5. **Cancelar / pop sin guardar:** borrar cualquier temp/staging de la sesión; no dejar archivos huérfanos ni tocar `imagePath` del artículo existente.
6. **Editar sin tocar la foto:** el `update` conserva el `imagePath` actual (no pasar `null` por omisión).

**Permisos galería (detalle nativo):** Android 13+ `READ_MEDIA_IMAGES` (o el equivalente que exija `image_picker`); iOS `NSPhotoLibraryUsageDescription` (+ cámara ya declarada). Denegado → RNF-7.

## Contrato foto async (RF-12, RF-16–17)

Secuencia fija (evita carreras y huérfanos):

1. **Insert primero** con `imagePath = null` y `barcode` si aplica.
2. **Luego** `download(url) → path` y `repository.updateImagePath(id, path)` solo si el artículo **sigue existiendo**.
3. Si el usuario **cancela** la confirmación: no se inicia descarga (o se cancela; no hay staging previo al insert).
4. Si el usuario **borra** el artículo mientras baja: el update de path se omite; el archivo temporal/parcial se borra.
5. **RF-17 en 005:** no hay reintento automático al reabrir ficha; ausencia de foto es OK (otra spec si hace falta).

## API Open Food Facts

- `GET https://world.openfoodfacts.org/api/v2/product/{code}.json?fields=product_name,brands,quantity,categories_tags,image_front_url,code`
- `status == 1` y nombre usable → match; si no → sin match.
- Timeout corto (p. ej. 10–15 s); fallo de red → RF-7.

## Persistencia (migración v2 → v3)

```
ALTER TABLE food_items ADD COLUMN barcode TEXT;
ALTER TABLE food_items ADD COLUMN image_path TEXT;
```

Artículos existentes: ambas null. Borrado: `ProductImageStore.delete(path)` si no null.

## Decisiones (plan) y descartadas

| Decisión | Descartado |
|----------|------------|
| `mobile_scanner` + `http` ligeros | SDK OFF completo; ML Kit aparte |
| Foto: insert → download → update path | Solo URL remota; bloquear save; download antes del insert (huérfanos) |
| Sin reintento de foto en 005 | Reintento al abrir ficha (RF-17 opcional aplazado) |
| Tab Añadir = escáner | Escáner solo como botón dentro del form (spec dice lo contrario) |
| Sin entrada numérica a mano del código | Teclado de código (fuera de alcance 005) |
| `image_picker` cámara + galería | Solo cámara o solo galería |
| Copy genérico (internet/red) | Atribución / branding Open Food Facts en UI |
| Foto opcional en form | Foto obligatoria en alta manual |

## Estrategia de tests

| Qué | Cómo | RF |
|-----|------|-----|
| Parseo cantidad / categorías / nombre | `flutter test` unitario | RF-9–11 |
| Cliente OFF | `http` mock / fixture JSON | RF-5–8 |
| Migración + delete imagen | test data + temp dir | RNF-2 |
| `attachFromFile` / quitar foto | unitario con temp dir | RF-22–23 |
| Preview + zoom | widget test (ya) | RF-18, RF-23 |
| Cámara / galería / permiso real | verificación manual en dispositivo (punto de control) | RF-1–3, RF-21, RNF-7 |

## Cobertura RF → plan

| RF | Dónde |
|----|--------|
| RF-1, RF-2 | `home_shell`, `barcode_scan_page` |
| RF-3 | `barcode_scan_page` + permisos nativos |
| RF-4–8 | `off_api_client` |
| RF-9–11 | `open_food_facts_mapping` |
| RF-12, RF-16–17 | `product_image_store` + confirm page |
| RF-13–15 | `product_confirm_page` + repository + validación 001 |
| RF-18 | tile / confirm / form preview |
| RF-19, RF-21–23 | `food_item_form_page` + `product_image_store` + permisos |
| RF-20 | ARB + quitar atribución en confirm |
| Borrado + foto | repository + `product_image_store` (caso límite) |
