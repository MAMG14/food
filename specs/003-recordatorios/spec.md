# Spec 003 — Recordatorios de caducidad con notificación

Estado: aprobada

## Contexto y objetivo

Ver la urgencia en la lista (spec 002) solo sirve si el usuario abre la app. Esta spec añade **avisos locales del sistema** antes de que un artículo caduque, para que pueda consumirlo a tiempo. La antelación del aviso es **configurable de forma general** y, opcionalmente, **por categoría** (p. ej. carne avisa antes que despensa). Todo sigue siendo local: sin cuenta, sin nube, sin servidor de notificaciones.

## Usuarios

Los mismos que en spec 001 (casa o negocio, lista plana).

## Historias de usuario

- HU-1. Como usuario, quiero recibir una notificación antes de que caduque un alimento para no tirarlo.
- HU-2. Como usuario, quiero elegir con cuántos días de antelación me avisa la app en general.
- HU-3. Como usuario, quiero que algunas categorías avisen con otra antelación (o no avisen) sin tener que configurar cada artículo.
- HU-4. Como usuario, quiero elegir a qué hora del día llegan los avisos para que no me molesten de madrugada.
- HU-5. Como usuario, quiero poder desactivar todos los recordatorios.
- HU-6. Como usuario, quiero que al tocar el aviso se abra la app en el inventario.

## Definiciones

- **Fecha efectiva de caducidad**: la de spec 001 (día exacto, o último día del mes si la precisión es mes).
- **Antelación**: número entero de días antes de la fecha efectiva en que se avisa. `0` = el mismo día que caduca.
- **Regla general**: antelación que se aplica a cualquier categoría sin regla propia.
- **Regla por categoría**: para una categoría concreta, puede ser:
  - **usar la general** (por defecto);
  - **antelación propia** (otro número de días);
  - **sin aviso** (esa categoría no genera notificaciones).
- **Antelación efectiva de un artículo**: la de su categoría si tiene regla propia; si no, la general.
- **Fecha de aviso**: fecha efectiva − antelación efectiva, a la **hora de aviso** configurada (hora local).
- **Hora de aviso**: hora del día (HH:MM local), única para todos los avisos.
- **Valores de antelación permitidos** (lista fija, en días): 0, 1, 2, 3, 5, 7, 10, 14, 21, 30.
- **Aviso agrupado**: una sola notificación por día de aviso que reúne todos los artículos cuyo aviso cae ese día.

## Requisitos funcionales (EARS)

### Configuración

- RF-1: EL SISTEMA ofrece una pantalla de ajustes de recordatorios accesible desde el inventario.
- RF-2: EL SISTEMA permite activar o desactivar los recordatorios globalmente.
- RF-3: EL SISTEMA permite elegir la antelación general entre los valores de antelación permitidos.
- RF-4: EL SISTEMA permite elegir, para cada una de las categorías fijas (lácteos, carne, verdura, despensa, otro), una regla: usar la general, antelación propia (de los valores permitidos) o sin aviso.
- RF-5: EL SISTEMA permite elegir la hora de aviso.
- RF-6: EL SISTEMA guarda la configuración en el dispositivo y la conserva entre reinicios de la app.
- RF-7: CUANDO el usuario cambia la configuración, EL SISTEMA reprograma los avisos pendientes de todos los artículos activos según la nueva configuración.

### Programación de avisos

- RF-8: CUANDO el usuario crea un artículo activo, EL SISTEMA programa su aviso según su antelación efectiva.
- RF-9: CUANDO el usuario edita un artículo (caducidad o categoría), EL SISTEMA cancela su aviso anterior y programa el nuevo.
- RF-10: CUANDO el usuario borra un artículo, EL SISTEMA cancela su aviso pendiente.
- RF-11: SI la fecha y hora de aviso ya pasaron pero el artículo aún no ha caducado, ENTONCES EL SISTEMA lo avisa en la siguiente hora de aviso que no sea posterior a su fecha efectiva; si no queda ninguna (caduca hoy y la hora de aviso ya pasó), lo avisa de inmediato.
- RF-12: SI el artículo ya está caducado, ENTONCES EL SISTEMA no programa aviso.
- RF-13: SI los recordatorios están desactivados o la categoría está en “sin aviso”, ENTONCES EL SISTEMA no programa avisos para esos artículos y cancela los existentes.

### Notificación

- RF-14: CUANDO llega la hora de aviso de un día con un solo artículo, EL SISTEMA muestra una notificación local con el nombre del artículo y cuándo caduca (texto i18n en español).
- RF-15: CUANDO llega la hora de aviso de un día con varios artículos, EL SISTEMA muestra un aviso agrupado con el número de artículos por caducar y, en lo que quepa, sus nombres ordenados por caducidad.
- RF-16: CUANDO el usuario toca la notificación, EL SISTEMA abre la app en el inventario (vista Activos).

### Permisos

- RF-17: CUANDO el usuario abre la app por primera vez tras instalar esta versión, EL SISTEMA pide el permiso de notificaciones del sistema operativo.
- RF-18: SI el usuario deniega el permiso, ENTONCES EL SISTEMA muestra en ajustes que los avisos no llegarán y cómo habilitarlos, sin bloquear el uso del inventario ni volver a pedirlo en cada arranque.
- RF-19: CUANDO el usuario abre la app, EL SISTEMA reprograma los avisos pendientes (cubre cambios de hora o zona horaria del dispositivo y el límite de avisos de iOS).

## Requisitos no funcionales

- RNF-1: Notificaciones **locales** únicamente; sin servidor, cuenta ni nube (constitución, principio 1).
- RNF-2: Android e iOS con el mismo comportamiento funcional, respetando los límites de cada sistema.
- RNF-3: El cálculo de antelación efectiva y fecha de aviso es una función pura que recibe la configuración, el artículo y “hoy”/“ahora”; se prueba con `flutter test`.
- RNF-4: Cambios de almacenamiento con migración compatible: ningún artículo existente se pierde (constitución, principio 5).
- RNF-5: Textos visibles vía i18n.
- RNF-6: Los avisos sobreviven al reinicio del dispositivo y al cierre de la app.

## Casos límite

- Antelación mayor que los días que faltan (p. ej. aviso a 3 días y caduca mañana) → se aplica RF-11.
- Antelación 0 y caduca hoy, con la hora de aviso ya pasada → se aplica RF-11.
- Precisión mes → la fecha de aviso se calcula desde el último día del mes.
- Artículos ya existentes al instalar esta versión → se programan sus avisos con la configuración por defecto la primera vez.
- Cambio de categoría de un artículo → su aviso se recalcula con la regla de la nueva categoría.
- Cambio de zona horaria o de hora del dispositivo → los avisos se recalculan al abrir la app (RF-19); entre tanto pueden llegar a la hora antigua.
- iOS limita los avisos locales pendientes (~64) → al agrupar por día basta con un aviso por día; se programan los días más próximos y se rellenan al abrir la app.
- Editar o borrar un artículo de un día agrupado → se recalcula el aviso de ese día (puede pasar de agrupado a individual o desaparecer).

## Fuera de alcance

- Antelación configurable **por artículo** individual.
- Varios avisos por artículo (p. ej. a 3 días y otra vez el mismo día).
- Acciones dentro de la notificación (“consumido”, “posponer”).
- Notificaciones push / remotas, nube, login.
- Resumen diario/semanal por correo o widget.
- Sonidos personalizados.

## Valores por defecto

- Recordatorios: activados (con petición de permiso al primer arranque).
- Antelación general: 2 días (alineado con la urgencia “alta” 0–2 días de spec 002).
- Todas las categorías: usar la general.
- Hora de aviso: 09:00.

## Criterios de finalización

- RF cubiertos por test de lógica (antelación efectiva, fecha de aviso, casos límite) y prueba manual en dispositivo Android y simulador/dispositivo iOS.
- Demo manual: configurar general y una categoría, crear artículo, recibir aviso, tocarlo y abrir inventario; editar y borrar cancelan/reprograman.
- `flutter test` en verde y `flutter analyze` sin errores.
- `MEMORY.md` actualizado.

## Dudas abiertas

- (ninguna bloqueante; resueltas con el usuario: valores fijos hasta 30 días, aviso tardío sí, notificación agrupada por día, permiso al iniciar, recálculo al abrir la app)
