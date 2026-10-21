# Spec 005 — Escaneo de código de barras (Open Food Facts)

Estado: aprobada

## Contexto y objetivo

El alta manual de artículos (001/004) pide muchos campos. Para productos empaquetados, una base pública de productos ya tiene nombre, marca, cantidad aproximada, categoría y foto. Esta spec añade un flujo de **escaneo → consulta → confirmación (caducidad + edición opcional) → guardar**, con **alta manual** siempre disponible si no hay cámara, no hay red o el producto no está en la base. También permite **añadir o cambiar una foto local** (cámara o galería) en el formulario manual y al editar. No se cambia la lógica de caducidad ni de recordatorios.

La fuente de datos en red es técnica (Open Food Facts, solo lectura). **La UI no nombra ese proveedor**: al usuario se habla de internet, red o producto no encontrado.

## Usuarios

Los mismos que en spec 001 (casa o negocio, lista plana).

## Decisiones fijadas en esta spec

| Tema | Decisión |
|------|----------|
| Fuente de datos | Solo **consulta** a Open Food Facts (lectura). Sin subir productos ni fotos a OFF. Detalle técnico; no se enseña el nombre al usuario. |
| Códigos | Códigos de barras de productos empaquetados (**EAN/UPC** y equivalentes numéricos de envase). No QR genéricos ni códigos de verdura a granel. |
| Historial | **Sin** historial de escaneos guardado. |
| Entrada | Tab **Añadir** abre primero la cámara/escáner. En esa pantalla hay **«Registrar manual»**. |
| Tras match | Pantalla de confirmación: datos prellenados **editables** + **caducidad obligatoria** (como en 001). |
| Sin match / sin red / sin cámara | Formulario manual completo actual + mensaje claro (sin nombrar proveedores externos). |
| Foto (consulta en red) | Se **descarga en segundo plano** al dispositivo cuando hay URL; **no bloquea** guardar ni el uso offline. Si aún no bajó o falló, el artículo se guarda igual (sin foto o con placeholder). |
| Foto (manual / edición) | **Opcional.** Origen: **cámara y galería** (ambas). Añadir, reemplazar o quitar. No es obligatorio para guardar. |
| Campos desde la consulta | Nombre (y marca si aporta), cantidad/unidad si se puede interpretar, categoría por reglas simples o `otro`, foto si hay URL. Ubicación: default del formulario actual (editable). Caducidad: **siempre** la indica el usuario. |
| Edición posterior | Seguir editando artículos desde la lista (001); la foto, si existe, se muestra en lista/ficha; se puede cambiar o quitar según RF de foto manual. |
| Copy visible | **Sin** «Open Food Facts» ni marcas de la fuente en pantallas, snackbars ni atribuciones. Errores en términos de **internet / red / producto no encontrado**. |
| Offline | El inventario local sigue usable sin red; solo falla o se omite la consulta en red. |

## Historias de usuario

- HU-1. Como usuario, quiero escanear el código de un envase para no teclear el nombre y ver la foto del producto.
- HU-2. Como usuario, quiero indicar solo (o sobre todo) la caducidad cuando el producto ya viene de la base.
- HU-3. Como usuario, quiero corregir nombre, cantidad o categoría si la base se equivoca.
- HU-4. Como usuario, quiero registrar a mano si no hay cámara, no hay internet o el producto no se encuentra.
- HU-5. Como usuario, quiero que la app siga funcionando sin red para lo que ya tengo guardado.
- HU-6. Como usuario, quiero poder poner una foto (cámara o galería) al registrar o editar a mano para reconocer el producto en la lista.

## Definiciones

- **Match**: la consulta en red devuelve un producto usable (al menos nombre no vacío).
- **Sin match**: código válido leído pero no hay producto usable (sin nombre).
- **Confirmación post-escaneo**: pantalla o paso donde el usuario ve los datos propuestos, puede editarlos y **debe** indicar caducidad antes de guardar.
- **Foto local**: copia de la imagen del producto en almacenamiento del dispositivo, asociada al artículo; opcional y asíncrona.
- **Código de barras soportado**: secuencia numérica típica de envase (EAN-8, EAN-13, UPC-A, UPC-E y equivalentes que el escáner lea como código de producto alimentario empaquetado).

## Requisitos funcionales (EARS)

### Entrada al alta

- RF-1: CUANDO el usuario elige el tab Añadir, EL SISTEMA abre el flujo de escaneo (cámara / lector de código de barras) como primer paso.
- RF-2: MIENTRAS el usuario está en el escáner, EL SISTEMA muestra una acción visible **Registrar manual** que abre el formulario de alta completo (001/004) sin exigir un código.
- RF-3: SI el permiso de cámara está denegado o no hay cámara usable, ENTONCES EL SISTEMA no bloquea el alta: muestra un mensaje claro y ofrece el formulario manual (o lo abre directamente).

### Lectura del código y consulta

- RF-4: CUANDO el escáner lee un código de barras soportado, EL SISTEMA consulta en red el producto por ese código (con indicador de carga).
- RF-5: SI hay red y hay match, ENTONCES EL SISTEMA abre la confirmación post-escaneo con datos prellenados según el mapeo de esta spec.
- RF-6: SI hay red y no hay match, ENTONCES EL SISTEMA informa que no se encontró el producto y ofrece continuar en el formulario manual (pudiendo llevar el código en notas o campo auxiliar solo si aporta; no es obligatorio mostrar el código).
- RF-7: SI no hay red o la consulta falla (tiempo agotado, error de servicio), ENTONCES EL SISTEMA informa el problema en términos de **internet/red** y ofrece el formulario manual; el inventario local no se corrompe.
- RF-8: EL SISTEMA no envía a la fuente remota altas, ediciones ni fotos de productos (solo lectura).

### Mapeo y confirmación

- RF-9: CUANDO hay match, EL SISTEMA prellena al menos el **nombre** a partir del nombre de producto de la consulta (incorporando marca si mejora la identificación y no duplica de forma absurda).
- RF-10: CUANDO la consulta aporta una cantidad textual interpretable (p. ej. «155 g»), EL SISTEMA propone cantidad y unidad de la lista fija de 001; SI no es interpretable, ENTONCES propone cantidad `1` y unidad `pz`.
- RF-11: CUANDO la consulta aporta categorías, EL SISTEMA propone una categoría de la lista fija (lácteos, carne, verdura, despensa, otro) con reglas de correspondencia; SI no hay correspondencia clara, ENTONCES propone `otro`.
- RF-12: CUANDO la consulta aporta URL de imagen frontal (o equivalente), EL SISTEMA la asocia al alta y **inicia** la descarga local en segundo plano sin impedir continuar.
- RF-13: EN la confirmación post-escaneo, EL SISTEMA permite editar nombre, cantidad, unidad, categoría, ubicación, notas y caducidad (mismos criterios de validación que 001).
- RF-14: SI la caducidad falta o es inválida en la confirmación, ENTONCES EL SISTEMA no guarda y muestra error claro (001).
- RF-15: CUANDO el usuario guarda desde confirmación o desde alta manual, EL SISTEMA persiste el artículo en el inventario local con las mismas reglas de activo/caducado que 001 y refresca Home como el alta actual.

### Foto e inventario

- RF-16: SI la descarga de foto termina con éxito, ENTONCES EL SISTEMA la conserva asociada al artículo para mostrarla sin depender de la red.
- RF-17: SI la descarga falla o el usuario guarda antes de que termine, ENTONCES EL SISTEMA mantiene el artículo válido; la foto puede quedar ausente o reintentarse en un momento posterior razonable (p. ej. al volver a ver el artículo), sin bloquear la UI.
- RF-18: EL SISTEMA muestra la foto del artículo en la confirmación (si ya hay URL o archivo) y, como mínimo, en la lista de Home o en la ficha/edición de forma reconocible (no hace falta galería de varios ítems).
- RF-19: CUANDO el usuario edita un artículo existente, EL SISTEMA permite ver/cambiar los campos de 001 y gestionar la foto local según RF-21–RF-23; si no toca la foto, la existente se conserva.
- RF-21: EN el formulario de **alta manual** y en el de **edición**, EL SISTEMA ofrece una acción clara para **añadir una foto** con origen **cámara** y **galería** (ambas opciones disponibles).
- RF-22: SI el usuario elige una foto en alta o edición, ENTONCES EL SISTEMA la guarda como **foto local** asociada al artículo al persistir (misma noción que la descargada por consulta); SI no elige foto, ENTONCES el alta/edición sigue siendo válida sin imagen.
- RF-23: CUANDO el artículo ya tiene foto local, EN edición EL SISTEMA permite **verla** (incl. ampliar/zoom si el UI de esta spec lo ofrece), **reemplazarla** o **quitarla**; al quitar o reemplazar, no quedan archivos huérfanos de forma sistemática.

### Copy visible al usuario

- RF-20: EL SISTEMA **no** muestra en la UI el nombre «Open Food Facts» ni otras marcas de la fuente de datos; los mensajes al usuario usan lenguaje genérico (p. ej. internet, red, producto no encontrado).

## Requisitos no funcionales

- RNF-1: Android e iOS con el mismo flujo funcional (escáner → consulta → confirmación / manual; foto manual con cámara y galería según permisos de la plataforma).
- RNF-7: SI el permiso de cámara o de galería/fotos está denegado al añadir foto manual, ENTONCES EL SISTEMA informa con claridad y no bloquea guardar el artículo sin foto.
- RNF-2: Persistencia local con migración compatible si se añaden campos (p. ej. código, ruta de foto); no se pierden artículos existentes.
- RNF-3: La lógica de parseo de cantidad, mapeo de categoría y validación de alta sigue siendo comprobable con `flutter test` (sin cámara ni red real en unitarios; la red se abstrae).
- RNF-4: Textos de UI vía i18n (español activo); sin nombres de proveedor externo en cadenas visibles.
- RNF-5: La consulta remota debe identificar la app de forma responsable (requisito típico de la API: agente/uso identificado); detalle en el plan — **no** implica mostrarlo en UI.
- RNF-6: No se introduce cuenta de usuario ni backend propio; la única red de producto es la lectura a Open Food Facts (detalle técnico).

## Casos límite

- Código leído dos veces seguidas: no crear dos consultas paralelas confusas; una en curso basta.
- Producto sin imagen en la consulta: alta válida sin foto.
- Producto sin cantidad ni categoría útiles: defaults (`1` `pz`, `otro`) + edición.
- Nombre vacío o basura en la respuesta: tratar como sin match.
- Usuario sin red en el escáner: mensaje + manual; no congelar la cámara sin salida.
- Permiso de cámara concedido a medias / revocado al volver: ofrecer manual.
- Artículo antiguo (pre-005) sin foto: se comporta como hasta ahora; se puede añadir foto al editar.
- Borrado de artículo: se elimina también la foto local asociada (sin dejar basura huérfana de forma sistemática; detalle en plan).
- Alta manual sin tocar la acción de foto: artículo válido sin imagen.
- Reemplazar foto de la consulta por una tomada a mano: permitido en edición (queda la nueva local).

## Fuera de alcance

- Contribuir productos, fotos o correcciones a Open Food Facts.
- Historial de escaneos, favoritos de códigos o «volver a escanear el mismo» como feature.
- Escaneo de QR no-producto, OCR de fecha de caducidad del envase, o lectura de códigos de báscula/granel.
- Búsqueda por nombre en la base remota (solo por código escaneado en este MVP).
- Entrada manual del código numérico (teclado) — no requerida en esta spec; solo escáner + registrar manual.
- Sincronización en la nube, login, espacios casa/negocio.
- Cambiar `applicationId` / marca.
- Nutriscore, ingredientes, alérgenos u otros paneles de la base remota en UI (solo lo necesario para el inventario).
- Sustituir o rediseñar el flujo de recordatorios (003).
- Editor de recorte/filtros avanzados de la foto; la app puede redimensionar/comprimir por tamaño si el plan lo define, pero no es un estudio fotográfico.
- Obligar foto en la **confirmación post-escaneo** (ahí basta la de la consulta si existe); la gestión manual explícita es en formulario de alta manual y en edición.
- Mostrar atribución o branding de Open Food Facts (u otro proveedor) en la UI.

## Criterios de finalización

- RF cubiertos: escaneo → match → confirmación → guardado; sin match / sin red / sin cámara → manual; foto de consulta no bloquea; **alta/edición manual con foto opcional** (cámara y galería; añadir / reemplazar / quitar); **copy sin nombres de proveedor**.
- Tests en verde para mapeo/parseo/validación y, donde aplique, cliente remoto simulado; cobertura razonable de persistencia de `imagePath` al guardar/quitar foto manual.
- `flutter analyze` y `flutter test` en verde.
- Prueba manual en dispositivo: producto conocido, inexistente, modo avión, «Registrar manual» **con y sin foto** (cámara y galería), editar/quitar foto; UI sin menciones a Open Food Facts.
- `MEMORY.md` actualizado al cerrar.

## Dudas abiertas

- (ninguna; entrada manual del código numérico sigue fuera a propósito)
