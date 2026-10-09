---
name: ui-design
description: >-
  Úsala al diseñar o modificar la UI de Food (lib/ui/**, lib/app.dart, tema).
  Aplica el lenguaje visual v1 (limpio, teal, urgencia de caducidad) y la spec
  activa de pulido visual si existe bajo specs/.
---

# UI Design — Food (v1)

## Principios

1. **Claridad > decoración.** Cada pantalla: una acción principal obvia.
2. **La caducidad se entiende en un vistazo** (color + texto, no solo color).
3. **Consistencia Material 3** con seed teal; no inventar un sistema paralelo.
4. **i18n siempre** para texto visible.
5. **No tocar reglas de negocio** de spec 001 salvo que una spec de UI lo pida (p. ej. umbrales de urgencia).

## Tokens v1 (orientativos)

- Seed / primary: teal (`Colors.teal` o `ColorScheme.fromSeed(seedColor: Color(0xFF0F766E))`).
- Superficie: clara; cards/tiles con separación sutil (divider o padding 12–16).
- Radios: 12 para cards/inputs; botones según M3.
- Urgencia:
  - crítica (caducado): `error` / rojo del scheme
  - alta (0–2 días): ámbar / `tertiary` o color fijo accesible
  - normal (3+): primary suave o `onSurfaceVariant`

## Lista

- Fila: nombre (título) + caducidad (subtítulo) + indicador de urgencia (chip o barra).
- Empty state centrado, padding ≥ 24, mensaje de ARB.
- AppBar simple; acciones de orden discretas.

## Formulario

- Secciones con espacio vertical 16–24.
- Caducidad agrupada (segmento precisión + picker).
- Guardar: `FilledButton` a ancho completo al final (o barra inferior estable).
- Errores en el campo; no SnackBars como único feedback de validación.

## Ciclo visual (obligatorio en cambios de UI)

No diseñar a ciegas: cada cambio visible se mira en pantalla antes de darlo por bueno.

1. Arrancar la app en el simulador iOS con el MCP `dart` (`launch_app`, o `flutter run` si no está disponible).
2. Tras cada cambio: `hot_reload` (MCP) y captura con `tool/screenshot.sh <nombre>`. La captura queda en `build/screens/` (no versionado).
3. Leer la captura y criticarla contra las referencias y esta skill: jerarquía, espaciado, alineación, contraste, texto cortado, aspecto genérico.
4. Usar el inspector de widgets del MCP (`widget_inspector`) para medir, en vez de suponer, cuando algo se ve desalineado.
5. Revisar también a ~360 dp de ancho y con texto grande.

Referencias visuales del usuario (capturas de apps que le gustan): `docs/design/referencias/`. Si existen, mandan sobre los gustos del agente; citar cuál se sigue en cada decisión.

## Checklist antes de cerrar un cambio UI

- [ ] ¿Revisado con captura real del simulador (no solo tests)?
- [ ] ¿Funciona en pantalla estrecha (~360 dp)?
- [ ] ¿Textos vía l10n?
- [ ] ¿Urgencia alineada a la spec 002 (o la activa)?
- [ ] ¿Sin hardcode de reglas de caducidad en widgets (usar dominio puro)?

## Fuera de esta skill

Dark mode, marca definitiva, animaciones fancy, nuevas features de producto.
