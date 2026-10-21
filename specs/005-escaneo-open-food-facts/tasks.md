# Tareas — Spec 005 Escaneo Open Food Facts

Estado: aprobado

Implementar por bloques (skill `sdd`): en orden, tests de lógica primero, `flutter test` en verde, marcar y commit `005/Tn: …`; parar solo en puntos de control.

- [x] **T1. Mapeo puro OFF → borrador + tests.** RF-9–11, RNF-3
  - Hecho cuando: `parseOffQuantity`, `mapOffCategories`, `buildProductName` / `OffProductDraft` cubiertos en `flutter test` (cantidad válida/inválida, tags→categoría, nombre+marca, sin nombre).

- [x] **T2. Schema v3 + repository (barcode, image_path).** RNF-2, RF-15
  - Hecho cuando: migración v2→v3 no pierde artículos; insert/update/get incluyen barcode e imagePath; al borrar se elimina el archivo de imagen si existía (store fake o temp).

- [ ] **T3. Cliente OFF (HTTP) + tests con mock.** RF-4–8, RNF-5
  - Hecho cuando: match / no encontrado / error de red cubiertos con cliente falso; User-Agent identificable; timeout definido.

- [ ] **T4. Almacén de fotos (descarga async) + contrato.** RF-12, RF-16–17
  - Hecho cuando: tras insert con `imagePath` null, download por `itemId` y update solo si el ítem existe; cancel antes de insert no deja archivos; delete durante download no deja path huérfano; fallo no bloquea UI; tests con fake/temp; **sin** reintento al reabrir (005).

- [ ] **T5. Dependencias nativas: mobile_scanner + permisos cámara.** RF-1, RF-3, RNF-1
  - Hecho cuando: dependencia en pubspec; permisos Android/iOS declarados; analyze limpio (aún sin UI completa si hace falta stub).

- [ ] **T6. Pantalla escáner + cableado tab Añadir.** RF-1–3, RF-6–7
  - Hecho cuando: Añadir abre escáner; «Registrar manual» → form 001; permiso denegado → mensaje + manual; loading en consulta; **segundo código ignorado** mientras hay fetch; **sin match** y **sin red/error** → mensaje + form manual.

- [ ] **T7. Confirmación post-match + guardado.** RF-5, RF-9–15, RF-20
  - Hecho cuando: prefill editable, caducidad obligatoria, atribución OFF; save hace insert (`imagePath` null) y luego download→update según contrato T4; vuelve a Home sin esperar la foto.

- [ ] **T8. Foto en lista / ficha + i18n.** RF-18, RNF-4
  - Hecho cuando: miniatura si hay imagePath; cadenas nuevas en ARB (es); sin hardcode de mensajes de error/escáner.

- [ ] **T9. Integración recordatorios + edición conserva foto.** RF-15, RF-19, (003)
  - Hecho cuando: alta por escaneo llama `resync` como el form actual; editar artículo no borra imagePath; analyze + suite en verde.

- [ ] **T10. Punto de control en dispositivo.** Criterios de finalización
  - Hecho cuando: prueba manual — producto conocido OFF, inexistente, modo avión, Registrar manual, permiso cámara; `MEMORY.md` y spec → `implementada` tras OK del usuario.
