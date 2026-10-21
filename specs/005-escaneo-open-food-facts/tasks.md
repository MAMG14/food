# Tareas — Spec 005 Escaneo Open Food Facts

Estado: aprobado

Implementar por bloques (skill `sdd`): en orden, tests de lógica primero, `flutter test` en verde, marcar y commit `005/Tn: …`; parar solo en puntos de control.

- [x] **T1. Mapeo puro OFF → borrador + tests.** RF-9–11, RNF-3
  - Hecho cuando: `parseOffQuantity`, `mapOffCategories`, `buildProductName` / `OffProductDraft` cubiertos en `flutter test` (cantidad válida/inválida, tags→categoría, nombre+marca, sin nombre).

- [x] **T2. Schema v3 + repository (barcode, image_path).** RNF-2, RF-15
  - Hecho cuando: migración v2→v3 no pierde artículos; insert/update/get incluyen barcode e imagePath; al borrar se elimina el archivo de imagen si existía (store fake o temp).

- [x] **T3. Cliente OFF (HTTP) + tests con mock.** RF-4–8, RNF-5
  - Hecho cuando: match / no encontrado / error de red cubiertos con cliente falso; User-Agent identificable; timeout definido.

- [x] **T4. Almacén de fotos (descarga async) + contrato.** RF-12, RF-16–17
  - Hecho cuando: tras insert con `imagePath` null, download por `itemId` y update solo si el ítem existe; cancel antes de insert no deja archivos; delete durante download no deja path huérfano; fallo no bloquea UI; tests con fake/temp; **sin** reintento al reabrir (005).

- [x] **T5. Dependencias nativas: mobile_scanner + permisos cámara.** RF-1, RF-3, RNF-1
  - Hecho cuando: dependencia en pubspec; permisos Android/iOS declarados; analyze limpio (aún sin UI completa si hace falta stub).

- [x] **T6. Pantalla escáner + cableado tab Añadir.** RF-1–3, RF-6–7
  - Hecho cuando: Añadir abre escáner; «Registrar manual» → form 001; permiso denegado → mensaje + manual; loading en consulta; **segundo código ignorado** mientras hay fetch; **sin match** y **sin red/error** → mensaje + form manual.

- [x] **T7. Confirmación post-match + guardado.** RF-5, RF-9–15, RF-20
  - Hecho cuando: prefill editable, caducidad obligatoria; save hace insert (`imagePath` null) y luego download→update según contrato T4; vuelve a Home.

- [x] **T8. Foto en lista / ficha + i18n.** RF-18, RNF-4
  - Hecho cuando: miniatura si hay imagePath; cadenas nuevas en ARB (es); sin hardcode de mensajes de error/escáner.

- [x] **T9. Integración recordatorios + edición conserva foto.** RF-15, RF-19, (003)
  - Hecho cuando: alta por escaneo llama `resync` como el form actual; editar artículo no borra imagePath; analyze + suite en verde.

- [x] **T11. Copy UI sin nombre de proveedor.** RF-20, RNF-4
  - Hecho cuando: ARB (es/en) sin «Open Food Facts»; confirmación sin atribución; mensajes de no encontrado / red en términos de internet o producto; `flutter test` + analyze en verde.

- [x] **T12. ProductImageStore: adjuntar desde archivo + quitar.** RF-22–23
  - Hecho cuando: API para copiar un archivo local a `pathForItem(id)` y actualizar path; quitar borra archivo y deja `imagePath` null; cancelar sesión borra temp; tests con temp dir.

- [x] **T13. Deps + permisos: `image_picker`, cámara y galería.** RF-21, RNF-1, RNF-7
  - Hecho cuando: dependencia en pubspec; Android (`CAMERA` + lectura de imágenes/media) e iOS (`NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`) declarados; analyze limpio.

- [x] **T14. UI foto en alta/edición manual.** RF-19, RF-21–23, RNF-7
  - Hecho cuando: form ofrece **Cámara** y **Galería**; con foto existente → **Reemplazar** (vía cámara/galería) y **Quitar**; reutiliza `ProductPhotoPreview` (zoom); editar **sin tocar** la foto conserva `imagePath` (test); permiso denegado no bloquea guardar; cancelar limpia temp; analyze + suite en verde.

- [ ] **T10. Punto de control en dispositivo.** Criterios de finalización
  - Hecho cuando: prueba manual — producto conocido, inexistente, modo avión, Registrar manual **con/sin foto** (cámara y galería), editar/reemplazar/quitar foto, UI sin menciones a Open Food Facts; `MEMORY.md` y spec → `implementada` tras OK del usuario.
