# Spec 005 — Escaneo de código de barras (Open Food Facts)

Estado: aprobada

## Contexto y objetivo

El alta manual de artículos (001/004) pide muchos campos. Para productos empaquetados, Open Food Facts ya tiene nombre, marca, cantidad aproximada, categoría y foto. Esta spec añade un flujo de **escaneo → consulta → confirmación (caducidad + edición opcional) → guardar**, con **alta manual** siempre disponible si no hay cámara, no hay red o el producto no está en la base. No se cambia la lógica de caducidad ni de recordatorios.

## Usuarios

Los mismos que en spec 001 (casa o negocio, lista plana).

## Decisiones fijadas en esta spec

| Tema | Decisión |
|------|----------|
| Fuente de datos | Solo **consulta** a Open Food Facts (lectura). Sin subir productos ni fotos a OFF. |
| Códigos | Códigos de barras de productos empaquetados (**EAN/UPC** y equivalentes numéricos de envase). No QR genéricos ni códigos de verdura a granel. |
| Historial | **Sin** historial de escaneos guardado. |
| Entrada | Tab **Añadir** abre primero la cámara/escáner. En esa pantalla hay **«Registrar manual»**. |
| Tras match | Pantalla de confirmación: datos prellenados **editables** + **caducidad obligatoria** (como en 001). |
| Sin match / sin red / sin cámara | Formulario manual completo actual + mensaje claro. |
| Foto | Se **descarga en segundo plano** al dispositivo cuando hay URL; **no bloquea** guardar ni el uso offline. Si aún no bajó o falló, el artículo se guarda igual (sin foto o con placeholder). |
| Campos desde OFF | Nombre (y marca si aporta), cantidad/unidad si se puede interpretar, categoría por reglas simples o `otro`, foto si hay URL. Ubicación: default del formulario actual (editable). Caducidad: **siempre** la indica el usuario. |
| Edición posterior | Seguir editando artículos desde la lista (001); la foto, si existe, se muestra en lista/detalle según lo que permita el UI de esta spec. |
| Atribución | La UI reconoce el uso de datos de Open Food Facts donde el usuario vea el resultado del escaneo (texto i18n breve). |
| Offline | El inventario local sigue usable sin red; solo falla o se omite la consulta a OFF. |

## Historias de usuario

- HU-1. Como usuario, quiero escanear el código de un envase para no teclear el nombre y ver la foto del producto.
- HU-2. Como usuario, quiero indicar solo (o sobre todo) la caducidad cuando el producto ya viene de la base.
- HU-3. Como usuario, quiero corregir nombre, cantidad o categoría si la base se equivoca.
- HU-4. Como usuario, quiero registrar a mano si no hay cámara, no hay internet o el producto no existe en Open Food Facts.
- HU-5. Como usuario, quiero que la app siga funcionando sin red para lo que ya tengo guardado.

## Definiciones

- **Match**: la consulta a Open Food Facts devuelve un producto usable (al menos nombre no vacío).
- **Sin match**: código válido leído pero la base no tiene producto, o la respuesta no sirve (sin nombre).
- **Confirmación post-escaneo**: pantalla o paso donde el usuario ve los datos propuestos, puede editarlos y **debe** indicar caducidad antes de guardar.
- **Foto local**: copia de la imagen del producto en almacenamiento del dispositivo, asociada al artículo; opcional y asíncrona.
- **Código de barras soportado**: secuencia numérica típica de envase (EAN-8, EAN-13, UPC-A, UPC-E y equivalentes que el escáner lea como código de producto alimentario empaquetado).

## Requisitos funcionales (EARS)

### Entrada al alta

- RF-1: CUANDO el usuario elige el tab Añadir, EL SISTEMA abre el flujo de escaneo (cámara / lector de código de barras) como primer paso.
- RF-2: MIENTRAS el usuario está en el escáner, EL SISTEMA muestra una acción visible **Registrar manual** que abre el formulario de alta completo (001/004) sin exigir un código.
- RF-3: SI el permiso de cámara está denegado o no hay cámara usable, ENTONCES EL SISTEMA no bloquea el alta: muestra un mensaje claro y ofrece el formulario manual (o lo abre directamente).

### Lectura del código y consulta

- RF-4: CUANDO el escáner lee un código de barras soportado, EL SISTEMA consulta Open Food Facts por ese código (con indicador de carga).
- RF-5: SI hay red y hay match, ENTONCES EL SISTEMA abre la confirmación post-escaneo con datos prellenados según el mapeo de esta spec.
- RF-6: SI hay red y no hay match, ENTONCES EL SISTEMA informa que no se encontró el producto y ofrece continuar en el formulario manual (pudiendo llevar el código en notas o campo auxiliar solo si aporta; no es obligatorio mostrar el código).
- RF-7: SI no hay red o la consulta falla (tiempo agotado, error de servicio), ENTONCES EL SISTEMA informa el problema y ofrece el formulario manual; el inventario local no se corrompe.
- RF-8: EL SISTEMA no envía a Open Food Facts altas, ediciones ni fotos de productos (solo lectura).

### Mapeo y confirmación

- RF-9: CUANDO hay match, EL SISTEMA prellena al menos el **nombre** a partir del nombre de producto de OFF (incorporando marca si mejora la identificación y no duplica de forma absurda).
- RF-10: CUANDO OFF aporta una cantidad textual interpretable (p. ej. «155 g»), EL SISTEMA propone cantidad y unidad de la lista fija de 001; SI no es interpretable, ENTONCES propone cantidad `1` y unidad `pz`.
- RF-11: CUANDO OFF aporta categorías, EL SISTEMA propone una categoría de la lista fija (lácteos, carne, verdura, despensa, otro) con reglas de correspondencia; SI no hay correspondencia clara, ENTONCES propone `otro`.
- RF-12: CUANDO OFF aporta URL de imagen frontal (o equivalente), EL SISTEMA la asocia al alta y **inicia** la descarga local en segundo plano sin impedir continuar.
- RF-13: EN la confirmación post-escaneo, EL SISTEMA permite editar nombre, cantidad, unidad, categoría, ubicación, notas y caducidad (mismos criterios de validación que 001).
- RF-14: SI la caducidad falta o es inválida en la confirmación, ENTONCES EL SISTEMA no guarda y muestra error claro (001).
- RF-15: CUANDO el usuario guarda desde confirmación o desde alta manual, EL SISTEMA persiste el artículo en el inventario local con las mismas reglas de activo/caducado que 001 y refresca Home como el alta actual.

### Foto e inventario

- RF-16: SI la descarga de foto termina con éxito, ENTONCES EL SISTEMA la conserva asociada al artículo para mostrarla sin depender de la red.
- RF-17: SI la descarga falla o el usuario guarda antes de que termine, ENTONCES EL SISTEMA mantiene el artículo válido; la foto puede quedar ausente o reintentarse en un momento posterior razonable (p. ej. al volver a ver el artículo), sin bloquear la UI.
- RF-18: EL SISTEMA muestra la foto del artículo en la confirmación (si ya hay URL o archivo) y, como mínimo, en la lista de Home o en la ficha/edición de forma reconocible (no hace falta galería).
- RF-19: CUANDO el usuario edita un artículo existente, EL SISTEMA permite ver/cambiar los campos de 001; la foto existente se conserva salvo que una edición futura (fuera de esta spec) defina reemplazo explícito — en esta spec **no** es obligatorio permitir cambiar la foto a mano.

### Transparencia

- RF-20: CUANDO el usuario ve un resultado procedente de Open Food Facts, EL SISTEMA muestra una atribución breve (i18n) de que los datos vienen de Open Food Facts.

## Requisitos no funcionales

- RNF-1: Android e iOS con el mismo flujo funcional (escáner → consulta → confirmación / manual).
- RNF-2: Persistencia local con migración compatible si se añaden campos (p. ej. código, ruta de foto); no se pierden artículos existentes.
- RNF-3: La lógica de parseo de cantidad, mapeo de categoría y validación de alta sigue siendo comprobable con `flutter test` (sin cámara ni red real en unitarios; la red se abstrae).
- RNF-4: Textos de UI vía i18n (español activo).
- RNF-5: La consulta a OFF debe identificar la app de forma responsable (requisito típico de su API: agente/uso identificado); detalle en el plan.
- RNF-6: No se introduce cuenta de usuario ni backend propio; la única red de producto es Open Food Facts (lectura).

## Casos límite

- Código leído dos veces seguidas: no crear dos consultas paralelas confusas; una en curso basta.
- Producto OFF sin imagen: alta válida sin foto.
- Producto OFF sin cantidad ni categoría útiles: defaults (`1` `pz`, `otro`) + edición.
- Nombre OFF vacío o basura: tratar como sin match.
- Usuario sin red en el escáner: mensaje + manual; no congelar la cámara sin salida.
- Permiso de cámara concedido a medias / revocado al volver: ofrecer manual.
- Artículo antiguo (pre-005) sin foto: se comporta como hasta ahora.
- Borrado de artículo: se elimina también la foto local asociada (sin dejar basura huérfana de forma sistemática; detalle en plan).

## Fuera de alcance

- Contribuir productos, fotos o correcciones a Open Food Facts.
- Historial de escaneos, favoritos de códigos o «volver a escanear el mismo» como feature.
- Escaneo de QR no-producto, OCR de fecha de caducidad del envase, o lectura de códigos de báscula/granel.
- Búsqueda por nombre en OFF (solo por código escaneado en este MVP).
- Entrada manual del código numérico (teclado) — no requerida en esta spec; solo escáner + registrar manual.
- Sincronización en la nube, login, espacios casa/negocio.
- Cambiar `applicationId` / marca.
- Nutriscore, ingredientes, alérgenos u otros paneles de OFF en UI (solo lo necesario para el inventario).
- Sustituir o rediseñar el flujo de recordatorios (003).

## Criterios de finalización

- RF cubiertos: escaneo → match → confirmación → guardado; sin match / sin red / sin cámara → manual; foto no bloquea.
- Tests en verde para mapeo/parseo/validación y, donde aplique, cliente OFF simulado.
- `flutter analyze` y `flutter test` en verde.
- Prueba manual en dispositivo: un producto conocido en OFF, uno inexistente, modo avión, y «Registrar manual».
- Atribución OFF visible en el flujo de resultado.
- `MEMORY.md` actualizado al cerrar.

## Dudas abiertas

- (ninguna bloqueante; entrada manual del código numérico queda fuera a propósito — se puede añadir en otra spec si hace falta)
