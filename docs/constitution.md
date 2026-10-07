# Constitución — Food

Principios innegociables. Toda spec, plan y tarea debe cumplirlos.

1. **Simplicidad primero**: Flutter (Dart) para Android e iOS. Persistencia local en el MVP. Sin backend, login ni nube hasta una spec explícita.
2. **La spec manda**: nada se implementa si no está en la spec activa. Si falta una decisión, se para y se pregunta.
3. **Lógica separada de interfaz**: caducidad, ordenación y clasificación activo/caducado son funciones puras que reciben “hoy” (fecha local) como parámetro. Sin UI ni base de datos dentro de esa lógica.
4. **Tests como puerta**: la lógica de dominio se prueba con `flutter test`. Prohibido dar una tarea por hecha con tests en rojo.
5. **Los datos del usuario son sagrados**: almacenamiento local con migraciones compatibles hacia atrás. Nunca se pierden artículos por un cambio de esquema sin migración.
6. **Idioma**: código (identificadores, comentarios de código) en inglés; textos de interfaz y documentación del proyecto en español; toda cadena visible al usuario pasa por i18n (aunque el MVP solo active español).

Máximo: estos 6 principios. No añadir más sin aprobación del responsable del proyecto.
