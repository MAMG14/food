# Spec 001 — Inventario MVP (listar, crear, editar, ordenar, caducados)

Estado: implementada

## Contexto y objetivo

Las personas (casa o negocio) pierden comida porque no ven a tiempo qué caduca. Esta especificación define el MVP: un inventario local de artículos con caducidad, para crearlos, editarlos, borrarlos, verlos en activos o caducados y ordenarlos por nombre o por fecha de caducidad. Sin cuenta, sin nube y sin recordatorios (irán en specs futuras).

## Usuarios

Cualquier persona que gestione alimentos en casa o en un negocio pequeño. En el MVP no hay roles ni espacios separados: una sola lista plana.

## Historias de usuario

- HU-1. Como usuario, quiero crear un artículo con nombre y caducidad para tenerlo controlado.
- HU-2. Como usuario, quiero editar un artículo tocándolo para corregir datos.
- HU-3. Como usuario, quiero borrar un artículo que ya no aplico.
- HU-4. Como usuario, quiero ver mis artículos activos y, aparte, los caducados.
- HU-5. Como usuario, quiero ordenar por nombre o por caducidad para encontrar o priorizar consumo.
- HU-6. Como usuario, quiero indicar si la caducidad es día exacto o solo mes/año, según el envase.

## Definiciones

- **Artículo**: ítem del inventario con los campos del MVP.
- **Fecha efectiva de caducidad**:
  - precisión día → ese día calendario local;
  - precisión mes → último día de ese mes en calendario local.
- **Activo**: fecha efectiva de caducidad ≥ hoy (día local).
- **Caducado**: fecha efectiva de caducidad < hoy (día local).
- **Unidades permitidas**: pz, kg, g, L, ml (lista fija).
- **Categorías permitidas**: lácteos, carne, verdura, despensa, otro (lista fija; “otro” es valor de categoría, no texto libre adicional en MVP).

## Requisitos funcionales (EARS)

### Campos y alta

- RF-1: CUANDO el usuario crea un artículo con nombre no vacío y caducidad válida (día o mes), EL SISTEMA lo guarda en el inventario local y lo muestra en la vista que corresponda (activo o caducado) según hoy.
- RF-2: SI el nombre está vacío o solo espacios, ENTONCES EL SISTEMA no guarda y muestra un error claro en español.
- RF-3: SI la caducidad es inválida o incompleta según la precisión elegida, ENTONCES EL SISTEMA no guarda y muestra un error claro en español.
- RF-4: CUANDO el usuario crea un artículo, EL SISTEMA permite opcionalmente cantidad (por defecto 1), unidad (lista fija), categoría (lista fija), notas y ubicación (nevera | despensa | otro).
- RF-5: EL SISTEMA exige elegir la precisión de caducidad (día o mes) al crear o editar.

### Edición y borrado

- RF-6: CUANDO el usuario toca un artículo en cualquier vista, EL SISTEMA abre la edición de ese artículo.
- RF-7: CUANDO el usuario guarda cambios válidos, EL SISTEMA actualiza el artículo y recalcula si es activo o caducado.
- RF-8: CUANDO el usuario confirma el borrado de un artículo, EL SISTEMA lo elimina del inventario local y deja de mostrarlo.
- RF-9: SI el usuario cancela el borrado, ENTONCES EL SISTEMA no elimina el artículo.

### Listados y ordenación

- RF-10: EL SISTEMA ofrece dos vistas: **Activos** y **Caducados**, mutuamente excluyentes según las definiciones.
- RF-11: CUANDO no hay artículos en la vista actual, EL SISTEMA muestra un estado vacío comprensible en español.
- RF-12: CUANDO el usuario elige ordenar por nombre, EL SISTEMA ordena la vista actual por nombre de forma estable (sin distinguir mayúsculas/minúsculas de forma confusa; criterio local español).
- RF-13: CUANDO el usuario elige ordenar por caducidad, EL SISTEMA ordena por fecha efectiva ascendente (caduca antes = primero).
- RF-14: MIENTRAS el usuario está en una vista, EL SISTEMA mantiene el criterio de orden elegido al volver a esa vista en la misma sesión (no hace falta persistir el orden entre reinicios de app en este MVP).

### Caducidad en UI

- RF-15: EL SISTEMA muestra en cada ítem de lista al menos: nombre y caducidad en formato legible según su precisión (día completo o mes/año).
- RF-16: EL SISTEMA no mueve artículos caducados a activos (ni al revés) salvo que cambie “hoy” o se edite la caducidad; el cambio de día calendario reclasifica automáticamente al abrir/refrescar listas.

## Requisitos no funcionales

- RNF-1: Android e iOS con el mismo comportamiento funcional.
- RNF-2: Datos solo en almacenamiento local del dispositivo.
- RNF-3: Textos de UI en español vía mecanismo de i18n (preparado para más idiomas).
- RNF-4: La lógica de fecha efectiva, clasificación activo/caducado y ordenación debe ser comprobable con tests automatizados (`flutter test`).
- RNF-5: Identidad de app temporal en esta spec: `Food` / `com.example.food`. El nombre visible lo fijó la spec 004 y el identificador la spec 006 (`com.developermarco.alacenabunker`).

## Casos límite

- Artículo creado ya caducado (fecha efectiva &lt; hoy) → aparece en Caducados.
- Precisión mes en mes actual: efectivo = último día del mes; si hoy es ese día, sigue activo; si hoy es posterior, caducado.
- Cantidad 0 o negativa → no permitir guardar.
- Notas vacías → permitido.
- Muchos artículos: la app debe seguir usable en listas modestas (cientos); no se exige paginación en este MVP.
- Cambio de día a medianoche: al volver a la app, la clasificación se recalcula con el nuevo “hoy”.

## Fuera de alcance

- Recordatorios / notificaciones.
- Nube, sincronización, premium, login.
- Espacios (casa vs restaurante), multi-usuario.
- Código de barras, fotos, proveedores.
- Texto libre para unidades o categorías (más allá de la lista fija).
- Histórico de borrados / papelera.
- Widget de sistema operativo.
- Cambio de nombre de marca / applicationId.

## Criterios de finalización

- Todos los RF anteriores cubiertos por test de lógica y/o prueba manual documentada en la validación.
- `flutter test` en verde para la lógica de dominio de esta spec.
- Demo manual: crear (día y mes), editar, borrar, ver activos/caducados, ordenar por nombre y por caducidad.
- `MEMORY.md` actualizado al cerrar la spec.

## Dudas abiertas

- (ninguna bloqueante al cierre de esta redacción; marca y recordatorios aplazados a propósito)
