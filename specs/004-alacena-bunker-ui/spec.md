# Spec 004 — UI Alacena Bunker (diseño Figma)

Estado: implementada

## Contexto y objetivo

La app ya cumple inventario (001), pulido visual teal v1 (002) y recordatorios (003). El usuario aportó un diseño en Figma («Básicos de Figma» / Alacena Bunker) y un Lottie de splash. Esta spec alinea la UI a ese diseño: marca definitiva visible, splash animado, onboarding de primera vez, Home con resumen por urgencia y navegación por tab bar, sin cambiar las reglas de negocio ni el modelo de datos de 001–003.

Referencia visual: archivo Figma `SByf2lLOAvL28x5m7cPgda` (pantallas Splash, Onboarding, Home, Add). Asset: `assets/lottie/alacena_bunker_splash.json`.

## Usuarios

Los mismos que en spec 001 (casa o negocio, lista plana).

## Decisiones fijadas en esta spec

| Tema | Decisión |
|------|----------|
| Marca | Nombre visible **Alacena Bunker** (UI, splash, onboarding, título de app en el dispositivo). El application id `com.example.food` se mantiene en esta spec (cambio de id = otra spec). |
| Splash | Arranque en frío: splash nativo estático coherente con la marca + en Flutter el Lottie (~1,5 s, duración natural del asset). Luego onboarding (1ª vez) o Home. |
| Onboarding | Una sola pantalla de bienvenida + «Iniciar»; **solo la primera vez** (flag local). No es un tutorial multipaso. |
| Tarjetas Home | Óptimo / Por caducar / Caducado con contadores; **al tocar filtran** la lista. |
| Umbrales | Los de spec 002: **Caducado** `effective < hoy`; **Por caducar** activos con urgencia alta (0–2 días); **Óptimo** activos con urgencia normal (3+ días). |
| Caducados | La tarjeta **Caducado** muestra la lista de caducados (sustituye el segmento Activos/Caducados como navegación principal). |
| Formulario | Campos de 001 se mantienen (cantidad, unidad, categoría, ubicación, notas); el layout sigue Figma en lo que muestre y el resto va debajo, scrolleable. |
| Ajustes (003) | Acceso desde **icono en Home** (p. ej. engranaje); no se elimina la pantalla de recordatorios. |
| Navegación | Tab bar: **Home** e **Añadir** (como Figma). Editar sigue abriendo el formulario al tocar un ítem. |
| Orden | Se mantiene orden por nombre o caducidad (001), accesible desde Home (menú/acción discreta). |
| Prioridad | Esta spec avanza ahora; la verificación manual restante de 003 puede hacerse después. |

## Historias de usuario

- HU-1. Como usuario, quiero ver la marca Alacena Bunker al abrir la app para reconocerla.
- HU-2. Como usuario nuevo, quiero un onboarding breve una sola vez para entender de qué va la app.
- HU-3. Como usuario, quiero ver de un vistazo cuántos artículos están óptimos, por caducar o caducados.
- HU-4. Como usuario, quiero filtrar la lista tocando esas tarjetas para centrarme en lo urgente.
- HU-5. Como usuario, quiero añadir artículos desde el tab + y seguir editando/borrando como hasta ahora.
- HU-6. Como usuario, quiero abrir los ajustes de recordatorios sin perder esa función.

## Definiciones

- **Filtro Home**: uno de `optimo` | `por_caducar` | `caducado`. Por defecto al abrir Home: `optimo` si hay alguno; si no, el primer filtro con ítems; si la app está vacía, `optimo` con estado vacío.
- **Óptimo / Por caducar / Caducado**: partición según umbrales de urgencia de spec 002 (arriba).
- **Primera ejecución**: no existe aún el flag local `onboarding_completed` (nombre de implementación libre en el plan).

## Requisitos funcionales (EARS)

### Marca y arranque

- RF-1: CUANDO el usuario abre la app en frío, EL SISTEMA muestra un splash nativo con la identidad Alacena Bunker (sin destello blanco incoherente con la marca).
- RF-2: CUANDO Flutter está listo tras el arranque en frío, EL SISTEMA reproduce el Lottie de splash una vez (~1,5 s) y no lo vuelve a mostrar al navegar dentro de la misma sesión.
- RF-3: EL SISTEMA muestra el nombre **Alacena Bunker** en onboarding, títulos relevantes y etiqueta de la app en el launcher (display name), vía i18n donde sea texto de UI.

### Onboarding

- RF-4: SI es la primera ejecución, ENTONCES tras el splash EL SISTEMA muestra el onboarding (bienvenida + lema + botón Iniciar) según Figma.
- RF-5: CUANDO el usuario pulsa Iniciar, EL SISTEMA marca el onboarding como completado en almacenamiento local y navega a Home.
- RF-6: SI el onboarding ya se completó, ENTONCES tras el splash EL SISTEMA va a Home sin mostrar el onboarding.

### Home y filtros

- RF-7: CUANDO el usuario está en Home, EL SISTEMA muestra tres tarjetas con contadores: Óptimo, Por caducar y Caducado.
- RF-8: CUANDO el usuario toca una tarjeta, EL SISTEMA aplica ese filtro a la lista y resalta la tarjeta activa.
- RF-9: CUANDO el filtro actual no tiene artículos, EL SISTEMA muestra el estado vacío acorde (mensaje i18n; empty de activos según Figma cuando aplique).
- RF-10: CUANDO el filtro es Óptimo o Por caducar, EL SISTEMA lista solo activos de esa urgencia; CUANDO es Caducado, solo caducados.
- RF-11: EL SISTEMA permite ordenar la lista actual por nombre o por caducidad (comportamiento de 001).
- RF-12: CUANDO el usuario toca un artículo de la lista, EL SISTEMA abre la edición (001).
- RF-13: EL SISTEMA ofrece acceso visible a los ajustes de recordatorios (003) desde Home.

### Navegación y formulario

- RF-14: EL SISTEMA ofrece tab bar con Home y Añadir; Añadir abre el formulario de alta.
- RF-15: CUANDO el usuario crea o edita, EL SISTEMA mantiene todos los campos y validaciones de spec 001; la presentación se acerca a Figma (nombre, precisión de fecha, selector de fecha) y el resto de campos permanece usable.
- RF-16: EL SISTEMA mantiene borrado con confirmación (001).

### Tema

- RF-17: EL SISTEMA aplica un tema Material 3 alineado a la paleta del Figma (verde de marca Alacena Bunker), sustituyendo el seed teal genérico de 002 donde haga falta para coherencia visual.
- RF-18: EL SISTEMA no introduce textos hardcodeados; cadenas nuevas van a ARB (español activo).

## Requisitos no funcionales

- RNF-1: No se cambian reglas de caducidad, modelo SQLite de artículos ni lógica de recordatorios de 003 (salvo persistir el flag de onboarding y, si hace falta, preferencia de filtro en sesión).
- RNF-2: Android e iOS con el mismo flujo (splash → onboarding condicional → Home).
- RNF-3: Contadores y filtros reutilizan (o derivan de) funciones puras de urgencia/clasificación testeables con `flutter test`.
- RNF-4: El Lottie se declara en `pubspec.yaml` y se carga desde `assets/lottie/`.
- RNF-5: Ciclo visual: capturas reales / Figma MCP al implementar UI (skill `ui-design`).

## Casos límite

- Inventario vacío: contadores en 0; empty state de Home; Añadir sigue disponible.
- Solo caducados: al abrir Home puede mostrarse filtro Caducado o vacío en Óptimo según la regla de default; contadores coherentes.
- Usuario que ya tiene datos al actualizar a esta versión: no ver onboarding si marcamos “completado” en migración de preferencias **o** sí verlo una vez — **decisión:** usuarios existentes **no** ven onboarding (se escribe `onboarding_completed` al migrar/arrancar si ya hay datos o si la app ya estaba instalada; detalle en plan).
- Lottie falla al cargar: mostrar frame estático de marca y continuar al destino en ≤ 2 s (no bloquear la app).

## Fuera de alcance

- Cambiar `applicationId` / bundle id (`com.example.food`).
- Icono de launcher definitivo (puede quedar el actual o un placeholder; asset de icono nuevo solo si el usuario lo aporta en esta fase).
- Dark mode, tutorial multipaso, animaciones Lottie fuera del splash.
- Nuevas features de inventario (espacios, nube, login).
- Rediseño de la lógica de recordatorios (solo acceso UI).
- Cerrar la verificación manual pendiente de spec 003.

## Criterios de finalización

- RF cubiertos en dispositivo/simulador frente a Figma (Home, Add, splash, onboarding 1ª vez).
- Tests en verde para contadores/filtros derivados de urgencia.
- `flutter analyze` y `flutter test` en verde.
- Onboarding no se repite tras Iniciar; splash Lottie solo en arranque en frío.
- Spec 003 sigue usable (ajustes desde Home).
- `MEMORY.md` actualizado al cerrar.

## Dudas abiertas

- (ninguna bloqueante; decisiones 4–8 tomadas por criterio de producto en esta redacción — el usuario puede corregir antes de aprobar)
