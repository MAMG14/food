# Spec 002 — Pulido visual del inventario (v1)

Estado: implementada

## Contexto y objetivo

El MVP (spec 001) es usable pero la UI es la de Material por defecto: poco jerarquía, caducidad poco visible y formularios densos sin ritmo. Esta spec mejora la **claridad y la urgencia visual** sin cambiar reglas de negocio, datos ni flujos funcionales ya definidos.

## Usuarios

Los mismos que en spec 001 (casa o negocio, lista plana).

## Decisiones de diseño (v1 — fijas hasta que el usuario pida cambio)

- **Tono:** limpio / minimal, con acento fresco (comida + confianza). Sin look “infantil” ni dashboard corporativo.
- **Color:** seed **teal** (o verde azulado cercano); superficies claras; un acento ámbar/rojo solo para urgencia de caducidad.
- **Densidad:** media — legible en móvil, sin lista ultra-compacta ni excesivo espacio vacío.
- **Caducidad:** indicador de urgencia por color + texto (semáforo ligero).
- **Formulario:** sigue en **pantalla completa** (mismo flujo); se reorganiza visualmente (secciones, espaciado, CTAs claros).
- **Marca:** se mantiene el nombre temporal “Food”; no se define logo ni identidad definitiva.
- **Splash de arranque:** fondo teal del seed con una marca provisional (hoja blanca) y el nombre “Food”; breve, solo para cubrir la carga. Se sustituirá cuando haya logo definitivo.

## Historias de usuario

- HU-1. Como usuario, quiero distinguir de un vistazo qué está por caducar para priorizar consumo.
- HU-2. Como usuario, quiero una lista más clara (nombre, caducidad, datos útiles) para encontrar artículos rápido.
- HU-3. Como usuario, quiero un formulario más ordenado para crear/editar sin confusión.
- HU-4. Como usuario, quiero estados vacíos y de carga comprensibles.

## Definiciones

- **Urgencia de caducidad** (respecto a “hoy” local, usando la fecha efectiva de spec 001):
  - **Crítica:** caducado (`effective < hoy`) → estilo de peligro (rojo).
  - **Alta:** caduca en **0–2 días** inclusive (`hoy ≤ effective ≤ hoy+2`) → estilo de alerta (ámbar).
  - **Normal:** caduca en **3+ días** → estilo neutro/positivo suave (teal/verde suave).
- **Semáforo ligero:** color en un chip, punto o barra lateral + texto de caducidad; no hace falta iconografía compleja.

## Requisitos funcionales (EARS)

### Lista

- RF-1: CUANDO el usuario ve la lista de Activos, EL SISTEMA muestra en cada fila al menos nombre y caducidad formateada, con indicador visual de urgencia según las definiciones.
- RF-2: CUANDO el usuario ve la lista de Caducados, EL SISTEMA aplica el estilo de urgencia crítica de forma consistente en todas las filas.
- RF-3: CUANDO la lista está vacía, EL SISTEMA muestra un estado vacío con mensaje i18n y suficiente aire visual (no solo texto pegado al borde).
- RF-4: EL SISTEMA mantiene el selector Activos/Caducados y el control de orden, con apariencia alineada al tema (no “controles sueltos” sin margen).

### Formulario

- RF-5: CUANDO el usuario abre crear o editar, EL SISTEMA agrupa visualmente: identidad (nombre), caducidad (precisión + fecha), cantidad/unidad, y resto (categoría, ubicación, notas).
- RF-6: EL SISTEMA muestra el botón Guardar de forma prominente (fácil de alcanzar en móvil).
- RF-7: SI hay errores de validación, ENTONCES EL SISTEMA los muestra junto al campo afectado con el estilo de error del tema (sin cambiar las reglas de validación de spec 001).

### Tema e i18n

- RF-8: EL SISTEMA aplica un `ThemeData` coherente (Material 3) con el seed elegido; tipografía y radios consistentes en lista y formulario.
- RF-9: EL SISTEMA no introduce textos hardcodeados; nuevas cadenas van a ARB (español activo).

### Splash de arranque

- RF-10: CUANDO el usuario abre la app en frío, EL SISTEMA muestra una pantalla de arranque nativa con el color teal del tema y la marca provisional, sin destello blanco previo.
- RF-11: CUANDO la app termina de cargar, EL SISTEMA mantiene la misma pantalla en Flutter (marca, nombre y lema i18n) un momento breve (< 1 s) y pasa al inventario con un fundido.

## Requisitos no funcionales

- RNF-1: No se cambian modelo de datos, SQLite, ni RF de negocio de spec 001 (salvo presentación).
- RNF-2: Android e iOS con el mismo lenguaje visual.
- RNF-3: La lógica de urgencia (días hasta caducar / clasificación crítica-alta-normal) debe ser función pura testeable con `flutter test` (recibe `today`).
- RNF-4: Alcance limitado a pantallas existentes: inventario + formulario (+ tema app y splash de arranque). Sin nuevas pantallas de onboarding ni settings.

## Casos límite

- Artículo que caduca **hoy** → urgencia **alta** (ámbar), no crítica; crítica solo si `effective < hoy`.
- Precisión mes: urgencia se calcula con la fecha efectiva (último día del mes), igual que spec 001.
- Contraste: textos e indicadores deben ser legibles sobre fondo claro (evitar ámbar/rojo demasiado claros sobre blanco).

## Fuera de alcance

- Cambio de nombre de marca / icono de launcher / logo definitivo del splash.
- Animaciones elaboradas, dark mode, tipografías custom descargadas.
- Recordatorios, notificaciones, nube.
- Rediseño de arquitectura (Riverpod/Bloc, etc.).
- Ilustraciones o assets gráficos pesados.

## Criterios de finalización

- RF cubiertos en UI real en dispositivo.
- Tests en verde para la función pura de urgencia.
- `flutter analyze` sin errores.
- Skill `ui-design` respetada en los cambios de `lib/ui/**`.
- `MEMORY.md` actualizado.

## Dudas abiertas

- (ninguna bloqueante; umbrales 0–2 / 3+ son decisión v1 revisable después por el usuario)
